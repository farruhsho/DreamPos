// Supabase implementation of [SyncTransport] (D-025, spec §8).
//
// Talks plain HTTP (package:http) to two Supabase services:
//   * GoTrue  `POST /auth/v1/token?grant_type=password|refresh_token`
//   * PostgREST `POST /rest/v1/rpc/<function>` (functions from
//     supabase/migrations/0001_dreampos_sync.sql), with `apikey` and
//     `Authorization: Bearer <access token>`.
//
// Rules: HTTPS only (plain http only for localhost / 127.0.0.1), 20 s timeout
// per request, one token refresh + retry on 401, every failure becomes a
// [SyncException]. The password is used for the sign-in request only and is
// never kept; tokens live in memory here and the engine persists only the
// refresh token (sync_state). Nothing here logs, and no exception detail ever
// contains a token, the password or a response body.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'transport.dart';

class SupabaseTransport implements SyncTransport {
  /// [client] and [timeout] are for tests; the app uses the defaults.
  SupabaseTransport(this.endpoint, {http.Client? client, this.timeout = const Duration(seconds: 20)})
      : _client = client ?? http.Client();

  final SyncEndpoint endpoint;
  final Duration timeout;
  final http.Client _client;

  SyncSession? _session;
  Future<SyncSession>? _refreshing;

  @override
  SyncSession? get session => _session;

  /// Normalised base URL of [url] (no trailing slash). Throws
  /// [SyncErrorKind.invalidUrl] for an unparsable URL and
  /// [SyncErrorKind.insecureUrl] for `http://` other than localhost /
  /// 127.0.0.1. The UI can call it to validate the field before signing in.
  static Uri validateUrl(String url) {
    final raw = url.trim();
    final u = Uri.tryParse(raw);
    if (u == null || !u.hasScheme || u.host.isEmpty || u.hasQuery || u.hasFragment || u.userInfo.isNotEmpty) {
      throw SyncException(SyncErrorKind.invalidUrl);
    }
    final scheme = u.scheme.toLowerCase();
    if (scheme == 'http') {
      final host = u.host.toLowerCase();
      if (host != 'localhost' && host != '127.0.0.1') throw SyncException(SyncErrorKind.insecureUrl);
    } else if (scheme != 'https') {
      throw SyncException(SyncErrorKind.invalidUrl);
    }
    var path = u.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return u.replace(path: path);
  }

  Uri _url(String path, [Map<String, String>? query]) {
    final base = validateUrl(endpoint.url);
    if (endpoint.anonKey.trim().isEmpty) throw SyncException(SyncErrorKind.notConfigured);
    return base.replace(path: '${base.path}$path', queryParameters: query);
  }

  // ------------------------------------------------------------------- http

  Future<http.Response> _post(Uri url, Map<String, String> headers, Object? body) async {
    try {
      return await _client
          .post(url, headers: {'Content-Type': 'application/json', 'Accept': 'application/json', ...headers},
              body: jsonEncode(body))
          .timeout(timeout);
    } on TimeoutException {
      throw SyncException(SyncErrorKind.network, detail: 'timeout');
    } on SyncException {
      rethrow;
    } on Exception catch (e) {
      // ClientException, SocketException, HandshakeException, …: no connection.
      throw SyncException(SyncErrorKind.network, detail: e.runtimeType.toString());
    }
  }

  static Object? _json(http.Response r) {
    final text = utf8.decode(r.bodyBytes, allowMalformed: true);
    if (text.trim().isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      throw SyncException(SyncErrorKind.protocol, detail: 'invalid JSON');
    }
  }

  /// Error body of PostgREST / GoTrue (`{code, message, …}`), or empty.
  static Map<String, Object?> _errorBody(http.Response r) {
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes, allowMalformed: true));
      return j is Map ? Map<String, Object?>.from(j) : const {};
    } catch (_) {
      return const {};
    }
  }

  /// Maps a non-2xx RPC response. 401 is handled by the caller (refresh).
  static SyncException _rpcError(String fn, http.Response r) {
    final status = r.statusCode;
    final body = _errorBody(r);
    final code = body['code']?.toString();
    final message = body['message']?.toString();
    if (status >= 500) return SyncException(SyncErrorKind.server, detail: 'HTTP $status');
    switch (message) {
      case 'not_member':
        return SyncException(SyncErrorKind.forbidden, detail: '403');
      case 'store_not_found':
        return SyncException(SyncErrorKind.storeNotFound);
      case 'not_authenticated':
        return SyncException(SyncErrorKind.auth, detail: '401');
    }
    if (status == 401) return SyncException(SyncErrorKind.auth, detail: '401');
    if (status == 403 || code == '42501') return SyncException(SyncErrorKind.forbidden, detail: '403');
    // PGRST202: function not found (the SQL migration was not applied).
    final what = code == null || code.isEmpty ? '' : ' $code';
    final known = message != null && RegExp(r'^[a-z_]{3,40}$').hasMatch(message) ? ' $message' : '';
    return SyncException(SyncErrorKind.server, detail: 'HTTP $status$what$known ($fn)');
  }

  // ------------------------------------------------------------------- auth

  SyncSession _sessionFrom(http.Response r, String fallbackEmail) {
    final j = _json(r);
    if (j is! Map) throw SyncException(SyncErrorKind.protocol, detail: 'token');
    final access = j['access_token'];
    final refresh = j['refresh_token'];
    final user = j['user'];
    final userId = user is Map ? user['id'] : null;
    if (access is! String || refresh is! String || userId is! String || access.isEmpty || refresh.isEmpty) {
      throw SyncException(SyncErrorKind.protocol, detail: 'token');
    }
    final email = user is Map && user['email'] is String ? user['email'] as String : fallbackEmail;
    return _session = SyncSession(userId: userId, email: email, refreshToken: refresh, accessToken: access);
  }

  Future<SyncSession> _token(String grantType, Map<String, String> body, String fallbackEmail) async {
    final r = await _post(_url('/auth/v1/token', {'grant_type': grantType}), {'apikey': endpoint.anonKey}, body);
    final s = r.statusCode;
    if (s >= 200 && s < 300) return _sessionFrom(r, fallbackEmail);
    // 400 invalid_grant (wrong password, unknown / used refresh token,
    // e-mail not confirmed), 401/403/422: the user has to sign in again.
    if (s == 400 || s == 401 || s == 403 || s == 404 || s == 422) {
      throw SyncException(SyncErrorKind.auth, detail: '$s');
    }
    throw SyncException(SyncErrorKind.server, detail: 'HTTP $s');
  }

  @override
  Future<SyncSession> signIn({required String email, required String password}) =>
      _token('password', {'email': email.trim(), 'password': password}, email.trim());

  @override
  Future<SyncSession> restoreSession(String refreshToken) =>
      _token('refresh_token', {'refresh_token': refreshToken}, _session?.email ?? '');

  /// One refresh at a time: concurrent 401s share it (tokens rotate, a second
  /// refresh with the old token would fail).
  Future<SyncSession> _refresh() {
    final pending = _refreshing;
    if (pending != null) return pending;
    final s = _session;
    if (s == null) throw SyncException(SyncErrorKind.notSignedIn);
    final f = _refreshing = restoreSession(s.refreshToken);
    return f.whenComplete(() => _refreshing = null);
  }

  @override
  Future<void> signOut() async {
    final s = _session;
    _session = null;
    final access = s?.accessToken;
    if (access == null) return;
    try {
      // scope=local: only this session; other registers on the same account
      // stay signed in.
      await _client.post(_url('/auth/v1/logout', {'scope': 'local'}), headers: {
        'apikey': endpoint.anonKey,
        'Authorization': 'Bearer $access',
      }).timeout(timeout);
    } catch (_) {
      // Best effort: the local tokens are gone anyway.
    }
  }

  // -------------------------------------------------------------------- rpc

  Future<Object?> _rpc(String fn, Map<String, Object?> params) async {
    var s = _session;
    if (s == null || s.accessToken == null) throw SyncException(SyncErrorKind.notSignedIn);
    final url = _url('/rest/v1/rpc/$fn');
    Future<http.Response> call(String access) =>
        _post(url, {'apikey': endpoint.anonKey, 'Authorization': 'Bearer $access'}, params);

    var r = await call(s.accessToken!);
    if (r.statusCode == 401) {
      // Expired access token: refresh once (or reuse a refresh another call
      // already made) and retry once.
      final current = _session;
      if (current != null && current.accessToken != null && current.accessToken != s.accessToken) {
        s = current;
      } else {
        s = await _refresh();
      }
      r = await call(s.accessToken!);
      if (r.statusCode == 401) throw SyncException(SyncErrorKind.auth, detail: '401');
    }
    if (r.statusCode < 200 || r.statusCode >= 300) throw _rpcError(fn, r);
    return _json(r);
  }

  static T _parse<T>(String what, T Function() f) {
    try {
      return f();
    } on SyncException {
      rethrow;
    } catch (_) {
      throw SyncException(SyncErrorKind.protocol, detail: what);
    }
  }

  static StoreInfo _store(Object? j) {
    final m = j as Map;
    return StoreInfo(
      id: m['id'] as String,
      name: m['name'] as String,
      environment: StoreEnvironment.parse(m['environment'] as String?),
      hasData: m['has_data'] == true,
    );
  }

  @override
  Future<List<StoreInfo>> listStores() async {
    final j = await _rpc('list_stores', const {});
    return _parse('list_stores', () => [for (final e in j as List) _store(e)]);
  }

  @override
  Future<StoreInfo> createStore({required String name, required StoreEnvironment environment}) async {
    final j = await _rpc('create_store', {'p_name': name.trim(), 'p_environment': environment.wire});
    return _parse('create_store', () {
      final id = j as String;
      if (id.isEmpty) throw const FormatException();
      return StoreInfo(id: id, name: name.trim(), environment: environment);
    });
  }

  @override
  Future<DeviceRegistration> registerDevice(
      {required String storeId, required String deviceId, required String name}) async {
    final j = await _rpc('register_device', {'p_store_id': storeId, 'p_device_id': deviceId, 'p_name': name});
    return _parse('register_device', () {
      final code = j as String;
      if (!RegExp(r'^[A-Z]+$').hasMatch(code)) throw const FormatException();
      return DeviceRegistration(deviceId: deviceId, code: code);
    });
  }

  @override
  Future<StoreInfo> storeInfo(String storeId) async {
    final j = await _rpc('store_info', {'p_store_id': storeId});
    if (j == null) throw SyncException(SyncErrorKind.storeNotFound);
    return _parse('store_info', () => _store(j));
  }

  @override
  Future<PushResult> push({required String storeId, required String deviceId, required List<SyncChange> changes}) async {
    final j = await _rpc('push_changes', {
      'p_store_id': storeId,
      'p_device_id': deviceId,
      'p_changes': [for (final c in changes) c.toJson()],
    });
    return _parse('push_changes', () {
      final m = j as Map;
      return PushResult(accepted: (m['accepted'] as num).toInt(), maxSeq: (m['max_seq'] as num).toInt());
    });
  }

  @override
  Future<PullResult> pull({required String storeId, required int since, int max = 500}) async {
    final j = await _rpc('pull_changes', {'p_store_id': storeId, 'p_since': since, 'p_max': max});
    return _parse('pull_changes', () {
      final list = [for (final e in j as List) SyncChange.fromJson(Map<String, Object?>.from(e as Map))];
      for (final c in list) {
        if (c.seq == null) throw const FormatException();
      }
      return PullResult(list);
    });
  }
}
