// Firebase implementation of [SyncTransport] (D-026, docs/specs/firebase-sync.md).
//
// Plain HTTP (package:http, no FlutterFire: the same code on Windows and
// Android) against three Google REST APIs:
//   * Identity Toolkit `accounts:signInWithPassword` (e-mail + password) and
//     `accounts:signUp` (registering the owner account from the app),
//   * Secure Token `token` (refresh token -> new ID token),
//   * Cloud Firestore REST v1 (documents, transactions, queries) with
//     `Authorization: Bearer <ID token>`; access is decided by the security
//     rules in firebase/firestore.rules (store members only).
//
// Data model (see the spec): `stores/{store}` with the counters `nextSeq` /
// `nextCode`, `stores/{store}/members/{uid}`, `users/{uid}/stores/{store}`
// (index for the store list), `stores/{store}/devices/{deviceId}`,
// `stores/{store}/codes/{code}` and the change log
// `stores/{store}/changes/{changeId}` (`seq` assigned in a transaction, so a
// commit is all-or-nothing and a re-push of the same change id is a no-op).
//
// Rules: HTTPS only (fixed Google hosts), 20 s timeout per request, the ID
// token is refreshed shortly before it expires and once more on a 401, every
// failure becomes a [SyncException]. The password is used for the sign-in
// request only and is never kept; tokens live in memory here and the engine
// persists only the refresh token (sync_state). Nothing here logs, and no
// exception detail ever contains a token, the password, the API key or a
// response body.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'sync_service.dart' show maxSyncVersion;
import 'transport.dart';

const _uuid = Uuid();

/// Error of a Firestore REST call (`{error: {code, status, details}}`).
/// Internal: mapped to [SyncException] before it leaves the transport.
class _FsFailure implements Exception {
  _FsFailure(this.code, this.status, this.reasons);
  final int code;
  final String status;
  final Set<String> reasons;

  bool get contention => status == 'ABORTED' || status == 'ALREADY_EXISTS';

  @override
  String toString() => 'HTTP $code $status';
}

class FirebaseTransport implements SyncTransport {
  /// [client], [timeout], [clock] and [retryDelay] are for tests; the app
  /// uses the defaults.
  FirebaseTransport(
    this.endpoint, {
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
    DateTime Function()? clock,
    Duration Function(int attempt)? retryDelay,
  })  : _client = client ?? http.Client(),
        _clock = clock ?? DateTime.now,
        _retryDelay = retryDelay ?? _jitter;

  final SyncEndpoint endpoint;
  final Duration timeout;
  final http.Client _client;
  final DateTime Function() _clock;
  final Duration Function(int attempt) _retryDelay;

  /// Writes per Firestore commit (the hard limit is 500): a push chunk is
  /// this many change documents minus the store and device updates.
  static const maxCommitWrites = 400;

  /// Attempts of a transaction that hits contention (ABORTED).
  static const maxAttempts = 5;

  /// Highest page size of [pull].
  static const maxPullPage = 1000;

  static const _identity = 'https://identitytoolkit.googleapis.com/v1';
  static const _secureToken = 'https://securetoken.googleapis.com/v1';
  static const _firestore = 'https://firestore.googleapis.com/v1';

  /// Firebase / Google Cloud project id: 6–30 characters, lowercase letters,
  /// digits and hyphens, starting with a letter, not ending with a hyphen.
  static final projectIdPattern = RegExp(r'^[a-z][a-z0-9-]{4,28}[a-z0-9]$');

  /// Web API key characters (Google keys look like `AIza…`, 39 characters).
  static final apiKeyPattern = RegExp(r'^[A-Za-z0-9_-]{8,200}$');

  /// Document ids this transport writes or reads (uuids, letter codes).
  static final _docId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  SyncSession? _session;
  Future<SyncSession>? _refreshing;
  DateTime? _expiresAt;

  @override
  SyncSession? get session => _session;

  static Duration _jitter(int attempt) {
    final base = 100 * (1 << math.min(attempt, 5));
    return Duration(milliseconds: base ~/ 2 + math.Random().nextInt(base));
  }

  /// Trimmed project id; throws [SyncErrorKind.invalidProject]. The UI calls
  /// it to validate the field before signing in.
  static String validateProjectId(String projectId) {
    final p = projectId.trim();
    if (!projectIdPattern.hasMatch(p)) throw SyncException(SyncErrorKind.invalidProject);
    return p;
  }

  /// Trimmed Web API key; throws [SyncErrorKind.notConfigured] when empty and
  /// [SyncErrorKind.invalidApiKey] for characters a key never has.
  static String validateApiKey(String apiKey) {
    final k = apiKey.trim();
    if (k.isEmpty) throw SyncException(SyncErrorKind.notConfigured);
    if (!apiKeyPattern.hasMatch(k)) throw SyncException(SyncErrorKind.invalidApiKey);
    return k;
  }

  String get _key => validateApiKey(endpoint.apiKey);

  /// `projects/{p}/databases/(default)/documents`.
  String get _root => 'projects/${validateProjectId(endpoint.projectId)}/databases/(default)/documents';

  /// Full resource name of the document at [path] (relative to the root).
  String _doc(String path) => '$_root/$path';

  static String _idOf(String name) => name.substring(name.lastIndexOf('/') + 1);

  static String _checkId(String id) {
    if (!_docId.hasMatch(id)) throw SyncException(SyncErrorKind.protocol, detail: 'id');
    return id;
  }

  // ------------------------------------------------------------------- http

  Future<http.Response> _send(String method, Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      final h = {'Accept': 'application/json', ...?headers};
      final Future<http.Response> f;
      if (method == 'GET') {
        f = _client.get(url, headers: h);
      } else if (body is String) {
        f = _client.post(url, headers: {'Content-Type': 'application/x-www-form-urlencoded', ...h}, body: body);
      } else {
        f = _client.post(url, headers: {'Content-Type': 'application/json', ...h}, body: jsonEncode(body ?? const {}));
      }
      return await f.timeout(timeout);
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

  /// `{error: {code, message, status, details: [{reason}]}}` of a Google API,
  /// or empty values.
  static ({String message, String status, Set<String> reasons}) _googleError(http.Response r) {
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes, allowMalformed: true));
      final e = j is Map ? j['error'] : null;
      if (e is Map) {
        final reasons = <String>{};
        for (final d in (e['details'] is List ? e['details'] as List : const [])) {
          if (d is Map && d['reason'] is String) reasons.add(d['reason'] as String);
        }
        for (final d in (e['errors'] is List ? e['errors'] as List : const [])) {
          if (d is Map && d['reason'] is String) reasons.add(d['reason'] as String);
        }
        return (
          message: e['message'] is String ? e['message'] as String : '',
          status: e['status'] is String ? e['status'] as String : '',
          reasons: reasons,
        );
      }
      if (j is Map && j['error'] is String) {
        // Secure Token sometimes answers {error: "invalid_grant", …}.
        return (message: (j['error'] as String).toUpperCase(), status: '', reasons: const {});
      }
    } catch (_) {}
    return (message: '', status: '', reasons: const {});
  }

  static bool _apiKeyProblem(String message, Set<String> reasons) =>
      reasons.any((r) => r.startsWith('API_KEY') || r == 'keyInvalid') ||
      message.startsWith('API key not valid') ||
      message.startsWith('INVALID_API_KEY') ||
      message.startsWith('PROJECT_NUMBER_MISMATCH');

  // ------------------------------------------------------------------- auth

  /// Maps an Identity Toolkit / Secure Token error. Only the stable upper
  /// case code goes into the detail, never free text.
  static SyncException _authError(http.Response r) {
    final s = r.statusCode;
    if (s >= 500) return SyncException(SyncErrorKind.server, detail: 'HTTP $s');
    final e = _googleError(r);
    // "TOO_MANY_ATTEMPTS_TRY_LATER : Access to this account …" -> code only.
    final code = RegExp(r'^[A-Z_]+').stringMatch(e.message) ?? '';
    if (_apiKeyProblem(e.message, e.reasons)) return SyncException(SyncErrorKind.invalidApiKey);
    switch (code) {
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'INVALID_EMAIL':
      case 'MISSING_PASSWORD':
      case 'MISSING_EMAIL':
      case 'INVALID_REFRESH_TOKEN':
      case 'TOKEN_EXPIRED':
      case 'USER_NOT_FOUND':
      case 'INVALID_GRANT':
      case 'INVALID_GRANT_TYPE':
      case 'MISSING_REFRESH_TOKEN':
      case 'INVALID_ID_TOKEN':
      case 'CREDENTIAL_TOO_OLD_LOGIN_AGAIN':
        return SyncException(SyncErrorKind.auth, detail: code);
      case 'USER_DISABLED':
        return SyncException(SyncErrorKind.accountDisabled);
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return SyncException(SyncErrorKind.tooManyAttempts);
      case 'OPERATION_NOT_ALLOWED':
      case 'PASSWORD_LOGIN_DISABLED':
      case 'CONFIGURATION_NOT_FOUND':
        return SyncException(SyncErrorKind.signInDisabled, detail: code);
    }
    if (s == 401 || (s == 400 && code.isEmpty)) return SyncException(SyncErrorKind.auth, detail: '$s');
    final what = code.length >= 3 && code.length <= 60 ? ' $code' : '';
    return SyncException(SyncErrorKind.server, detail: 'HTTP $s$what (auth)');
  }

  /// Maps an `accounts:signUp` error; codes that sign-up shares with
  /// sign-in (API key, 5xx, USER_DISABLED, …) go through [_authError].
  static SyncException _signUpError(http.Response r) {
    final s = r.statusCode;
    final e = _googleError(r);
    if (s >= 500 || _apiKeyProblem(e.message, e.reasons)) return _authError(r);
    // "WEAK_PASSWORD : Password should be at least 6 characters" -> code only.
    final code = RegExp(r'^[A-Z_]+').stringMatch(e.message) ?? '';
    switch (code) {
      case 'EMAIL_EXISTS':
        return SyncException(SyncErrorKind.emailExists);
      case 'WEAK_PASSWORD':
      case 'MISSING_PASSWORD':
        return SyncException(SyncErrorKind.weakPassword);
      case 'PASSWORD_DOES_NOT_MEET_REQUIREMENTS':
        // The project's own password policy (Authentication › Settings ›
        // Password policy) — not just the length. Its requirement list is
        // free English text and is not passed on.
        return SyncException(SyncErrorKind.passwordPolicy, detail: code);
      case 'INVALID_EMAIL':
      case 'MISSING_EMAIL':
        return SyncException(SyncErrorKind.invalidEmail);
      case 'ADMIN_ONLY_OPERATION':
        // «Enable create (sign-up)» is off. OPERATION_NOT_ALLOWED /
        // PASSWORD_LOGIN_DISABLED / CONFIGURATION_NOT_FOUND mean the
        // Email/Password provider itself is off: [_authError] maps them to
        // signInDisabled, which names the real cause.
        return SyncException(SyncErrorKind.signUpDisabled, detail: code);
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return SyncException(SyncErrorKind.signUpTooManyAttempts);
    }
    return _authError(r);
  }

  /// Claims of an ID token (a JWT), or null. The token is not verified here
  /// (Firebase verifies it on every request); it is only read.
  static Map<Object?, Object?>? _jwtClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final claims = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return claims is Map ? claims : null;
    } catch (_) {
      return null;
    }
  }

  SyncSession _start(
      {required Object? idToken,
      required Object? refreshToken,
      required Object? userId,
      required Object? expiresIn,
      required String email}) {
    if (idToken is! String || refreshToken is! String || userId is! String) {
      throw SyncException(SyncErrorKind.protocol, detail: 'token');
    }
    if (idToken.isEmpty || refreshToken.isEmpty || !_docId.hasMatch(userId)) {
      throw SyncException(SyncErrorKind.protocol, detail: 'token');
    }
    // The API key alone picks the project that signs the user in; the
    // project id only appears in Firestore paths. A key of another project
    // (test vs production) signs in fine and then every Firestore call is
    // refused as 401, which looks like an expired session. The token's
    // audience names the issuing project: check it before anything else.
    final claims = _jwtClaims(idToken);
    if (claims == null || claims['aud'] is! String) throw SyncException(SyncErrorKind.protocol, detail: 'token');
    if (claims['aud'] != validateProjectId(endpoint.projectId)) {
      _session = null;
      _expiresAt = null;
      throw SyncException(SyncErrorKind.projectMismatch);
    }
    final claimedEmail = claims['email'];
    final seconds = int.tryParse('$expiresIn') ?? 3600;
    // Refresh a minute early: a request never starts with a token that
    // expires on the way.
    _expiresAt = _clock().add(Duration(seconds: math.max(seconds - 60, 0)));
    return _session = SyncSession(
      userId: userId,
      email: claimedEmail is String && claimedEmail.isNotEmpty ? claimedEmail : email,
      refreshToken: refreshToken,
      accessToken: idToken,
    );
  }

  @override
  Future<SyncSession> signIn({required String email, required String password}) async {
    final key = _key;
    validateProjectId(endpoint.projectId); // before the password leaves the device
    final r = await _send('POST', Uri.parse('$_identity/accounts:signInWithPassword?key=$key'),
        body: {'email': email.trim(), 'password': password, 'returnSecureToken': true});
    if (r.statusCode < 200 || r.statusCode >= 300) throw _authError(r);
    final j = _json(r);
    if (j is! Map) throw SyncException(SyncErrorKind.protocol, detail: 'token');
    return _start(
      idToken: j['idToken'],
      refreshToken: j['refreshToken'],
      userId: j['localId'],
      expiresIn: j['expiresIn'],
      email: j['email'] is String ? j['email'] as String : email.trim(),
    );
  }

  /// Registers the account (`accounts:signUp`). Like [signIn], the project
  /// id and key are checked before the password leaves the device, and the
  /// ID token's audience must be the project (a key of another project
  /// creates the account there and then fails with
  /// [SyncErrorKind.projectMismatch]; that stray account is deleted again
  /// with its fresh ID token, best effort, and nothing is stored locally).
  @override
  Future<SyncSession> signUp({required String email, required String password}) async {
    final key = _key;
    validateProjectId(endpoint.projectId);
    final r = await _send('POST', Uri.parse('$_identity/accounts:signUp?key=$key'),
        body: {'email': email.trim(), 'password': password, 'returnSecureToken': true});
    if (r.statusCode < 200 || r.statusCode >= 300) throw _signUpError(r);
    final j = _json(r);
    if (j is! Map) throw SyncException(SyncErrorKind.protocol, detail: 'token');
    final idToken = j['idToken'];
    try {
      return _start(
        idToken: idToken,
        refreshToken: j['refreshToken'],
        userId: j['localId'],
        expiresIn: j['expiresIn'],
        email: j['email'] is String ? j['email'] as String : email.trim(),
      );
    } on SyncException catch (e) {
      if (e.kind == SyncErrorKind.projectMismatch && idToken is String) {
        await _deleteStrayAccount(key, idToken);
      }
      rethrow;
    }
  }

  /// `accounts:delete` of the account an ID token belongs to. Used only for
  /// an account [signUp] just created in the wrong project (the key belongs
  /// to another project than the project id): it must not stay behind.
  /// Best effort: any failure is ignored (the original error is what counts).
  Future<void> _deleteStrayAccount(String key, String idToken) async {
    try {
      await _send('POST', Uri.parse('$_identity/accounts:delete?key=$key'), body: {'idToken': idToken});
    } catch (_) {}
  }

  @override
  Future<SyncSession> restoreSession(String refreshToken) async {
    final key = _key;
    validateProjectId(endpoint.projectId);
    final r = await _send('POST', Uri.parse('$_secureToken/token?key=$key'),
        body: 'grant_type=refresh_token&refresh_token=${Uri.encodeQueryComponent(refreshToken)}');
    if (r.statusCode < 200 || r.statusCode >= 300) throw _authError(r);
    final j = _json(r);
    if (j is! Map) throw SyncException(SyncErrorKind.protocol, detail: 'token');
    return _start(
      idToken: j['id_token'],
      refreshToken: j['refresh_token'],
      userId: j['user_id'],
      expiresIn: j['expires_in'],
      email: _session?.email ?? '',
    );
  }

  /// One refresh at a time: concurrent callers share it (a rotated refresh
  /// token must not be used twice).
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
    // Firebase has no client-side revoke over REST: the tokens are dropped
    // here; the engine deletes the stored refresh token.
    _session = null;
    _expiresAt = null;
  }

  // -------------------------------------------------------------- firestore

  /// Firestore REST call ([path] relative to `https://firestore…/v1/`). GET
  /// when [body] is null and [post] is false. Throws [_FsFailure] for a
  /// non-2xx answer (after one refresh + retry on 401).
  Future<Object?> _fs(String path, {Object? body, bool post = false}) async {
    var s = _session;
    if (s == null || s.accessToken == null) throw SyncException(SyncErrorKind.notSignedIn);
    final url = Uri.parse('$_firestore/$path');
    final method = body != null || post ? 'POST' : 'GET';
    Future<http.Response> call(String token) =>
        _send(method, url, headers: {'Authorization': 'Bearer $token'}, body: body);

    final exp = _expiresAt;
    if (exp != null && !_clock().isBefore(exp)) s = await _refresh();
    var r = await call(s.accessToken!);
    if (r.statusCode == 401) {
      // Expired / revoked ID token: refresh once (or reuse a refresh another
      // call already made) and retry once.
      final current = _session;
      if (current != null && current.accessToken != null && current.accessToken != s.accessToken) {
        s = current;
      } else {
        s = await _refresh();
      }
      r = await call(s.accessToken!);
      if (r.statusCode == 401) throw SyncException(SyncErrorKind.auth, detail: '401');
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final e = _googleError(r);
      throw _FsFailure(r.statusCode, e.status, {
        ...e.reasons,
        if (_apiKeyProblem(e.message, e.reasons)) 'API_KEY_INVALID',
        // "The database (default) does not exist for project …"
        if (e.status == 'NOT_FOUND' && e.message.contains('database')) 'NO_DATABASE',
      });
    }
    return _json(r);
  }

  /// HTTP status of a google.rpc status name (the `code` of an error element
  /// in a streamed answer may be the HTTP or the RPC code).
  static int _httpOf(String status) => switch (status) {
        'INVALID_ARGUMENT' || 'FAILED_PRECONDITION' || 'OUT_OF_RANGE' => 400,
        'UNAUTHENTICATED' => 401,
        'PERMISSION_DENIED' => 403,
        'NOT_FOUND' => 404,
        'ABORTED' || 'ALREADY_EXISTS' => 409,
        'RESOURCE_EXHAUSTED' => 429,
        'UNAVAILABLE' => 503,
        'DEADLINE_EXCEEDED' => 504,
        _ => 500,
      };

  /// Streamed answers (`batchGet`, `runQuery`) are JSON arrays sent with
  /// HTTP 200 before the stream ends: a failure after the first result
  /// arrives as a last `{error: {code, status, message}}` element. Throws it
  /// as a [_FsFailure] like a non-2xx answer.
  static void _throwStreamError(Object? element) {
    if (element is! Map || !element.containsKey('error')) return;
    final e = element['error'];
    final status = e is Map && e['status'] is String ? e['status'] as String : '';
    final code = e is Map && e['code'] is int ? e['code'] as int : 0;
    throw _FsFailure(code >= 400 && code < 600 ? code : _httpOf(status), status, const {});
  }

  /// Default mapping of a Firestore failure of operation [what].
  static SyncException _mapFs(_FsFailure f, String what) {
    if (f.reasons.contains('API_KEY_INVALID')) return SyncException(SyncErrorKind.invalidApiKey);
    if (f.reasons.contains('SERVICE_DISABLED')) {
      return SyncException(SyncErrorKind.server, detail: 'HTTP ${f.code} SERVICE_DISABLED ($what)');
    }
    if (f.reasons.contains('NO_DATABASE')) {
      return SyncException(SyncErrorKind.server, detail: 'HTTP ${f.code} NO_DATABASE ($what)');
    }
    if (f.code >= 500) return SyncException(SyncErrorKind.server, detail: 'HTTP ${f.code}');
    if (f.code == 401 || f.status == 'UNAUTHENTICATED') return SyncException(SyncErrorKind.auth, detail: '401');
    if (f.code == 403 || f.status == 'PERMISSION_DENIED') return SyncException(SyncErrorKind.forbidden, detail: '403');
    final status = RegExp(r'^[A-Z_]{3,40}$').hasMatch(f.status) ? ' ${f.status}' : '';
    return SyncException(SyncErrorKind.server, detail: 'HTTP ${f.code}$status ($what)');
  }

  /// Runs [body], mapping Firestore failures and malformed answers.
  static Future<T> _guard<T>(String what, Future<T> Function() body) async {
    try {
      return await body();
    } on SyncException {
      rethrow;
    } on _FsFailure catch (f) {
      throw _mapFs(f, what);
    } catch (_) {
      throw SyncException(SyncErrorKind.protocol, detail: what);
    }
  }

  // --------------------------------------------------------- value coding

  /// Firestore `Value` of a JSON scalar (or a [DateTime]). Integers travel
  /// as strings.
  static Map<String, Object?> encodeValue(Object? v) => switch (v) {
        null => const {'nullValue': null},
        final bool b => {'booleanValue': b},
        final int i => {'integerValue': '$i'},
        final double d => {'doubleValue': d.isFinite ? d : '$d'},
        final String s => {'stringValue': s},
        final DateTime t => {'timestampValue': t.toUtc().toIso8601String()},
        _ => throw ArgumentError.value(v, 'v', 'not a Firestore scalar'),
      };

  /// Dart value of a Firestore `Value` (`integerValue` is a string on the
  /// wire, timestamps stay ISO strings).
  static Object? decodeValue(Object? value) {
    if (value is! Map) throw const FormatException('value');
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('booleanValue')) return value['booleanValue'] as bool;
    if (value.containsKey('integerValue')) {
      final v = value['integerValue'];
      return v is num ? v.toInt() : int.parse(v as String);
    }
    if (value.containsKey('doubleValue')) {
      final v = value['doubleValue'];
      return v is num ? v.toDouble() : double.parse(v as String);
    }
    if (value.containsKey('stringValue')) return value['stringValue'] as String;
    if (value.containsKey('timestampValue')) return value['timestampValue'] as String;
    if (value.containsKey('mapValue')) {
      final fields = (value['mapValue'] as Map)['fields'];
      return {
        if (fields is Map)
          for (final e in fields.entries) e.key as String: decodeValue(e.value),
      };
    }
    if (value.containsKey('arrayValue')) {
      final values = (value['arrayValue'] as Map)['values'];
      return [if (values is List) for (final v in values) decodeValue(v)];
    }
    throw const FormatException('value type');
  }

  static Map<String, Object?> _fields(Object? doc) {
    final f = (doc as Map)['fields'];
    return {if (f is Map) for (final e in f.entries) e.key as String: decodeValue(e.value)};
  }

  static Map<String, Object?> _encodeFields(Map<String, Object?> m) =>
      {for (final e in m.entries) e.key: encodeValue(e.value)};

  /// A create (`exists: false` precondition) of [name] with [fields] and the
  /// server time in [timeFields].
  static Map<String, Object?> _create(String name, Map<String, Object?> fields,
          {List<String> timeFields = const []}) =>
      {
        'update': {'name': name, 'fields': _encodeFields(fields)},
        if (timeFields.isNotEmpty)
          'updateTransforms': [
            for (final f in timeFields) {'fieldPath': f, 'setToServerValue': 'REQUEST_TIME'},
          ],
        'currentDocument': {'exists': false},
      };

  /// An update of only [fields] (+ server time in [timeFields]) of an
  /// existing document.
  static Map<String, Object?> _patch(String name, Map<String, Object?> fields,
          {List<String> timeFields = const []}) =>
      {
        'update': {'name': name, 'fields': _encodeFields(fields)},
        'updateMask': {'fieldPaths': fields.keys.toList()},
        if (timeFields.isNotEmpty)
          'updateTransforms': [
            for (final f in timeFields) {'fieldPath': f, 'setToServerValue': 'REQUEST_TIME'},
          ],
        'currentDocument': {'exists': true},
      };

  static StoreInfo _storeInfo(String id, Object? doc) {
    final f = _fields(doc);
    final env = f['environment'];
    return StoreInfo(
      id: id,
      name: f['name'] as String,
      environment: StoreEnvironment.parse(env is String ? env : null),
      hasData: f['hasData'] == true,
    );
  }

  // ---------------------------------------------------------- transactions

  Future<String> _begin() async {
    final j = await _fs('$_root:beginTransaction', body: {
      'options': {'readWrite': <String, Object?>{}},
    });
    final tx = (j as Map)['transaction'];
    if (tx is! String || tx.isEmpty) throw const FormatException('transaction');
    return tx;
  }

  Future<void> _rollback(String tx) async {
    try {
      await _fs('$_root:rollback', body: {'transaction': tx});
    } catch (_) {
      // Best effort: an unfinished transaction expires by itself.
    }
  }

  /// Documents [names] read in [tx]: name -> document (absent = missing).
  /// Every name must come back as `found` or `missing`: an error element or
  /// a cut-off answer never makes a document look absent.
  Future<Map<String, Object?>> _batchGet(List<String> names, String tx) async {
    final j = await _fs('$_root:batchGet', body: {'documents': names, 'transaction': tx});
    final out = <String, Object?>{};
    final answered = <String>{};
    for (final e in j as List) {
      _throwStreamError(e);
      final found = (e as Map)['found'];
      final missing = e['missing'];
      if (found is Map) {
        final name = found['name'] as String;
        out[name] = found;
        answered.add(name);
      } else if (missing is String) {
        answered.add(missing);
      }
    }
    if (!answered.containsAll(names)) throw const FormatException('batchGet incomplete');
    return out;
  }

  Future<void> _commit(List<Map<String, Object?>> writes, {String? tx}) =>
      _fs('$_root:commit', body: {'writes': writes, 'transaction': ?tx});

  /// Runs [attempt] in a read-write transaction, retrying on contention
  /// (ABORTED / ALREADY_EXISTS) up to [maxAttempts] times with jittered
  /// backoff. [attempt] commits, or returns without writing (then the
  /// transaction is rolled back).
  Future<T> _transaction<T>(String what, Future<(T, List<Map<String, Object?>>?)> Function(String tx) attempt) async {
    for (var n = 1;; n++) {
      final tx = await _begin();
      var finished = false;
      try {
        final (result, writes) = await attempt(tx);
        if (writes == null || writes.isEmpty) {
          finished = true;
          await _rollback(tx);
          return result;
        }
        finished = true; // a failed commit ends the transaction
        await _commit(writes, tx: tx);
        return result;
      } on _FsFailure catch (f) {
        if (!finished) await _rollback(tx);
        if (!f.contention) rethrow;
        if (n >= maxAttempts) {
          throw SyncException(SyncErrorKind.server, detail: 'HTTP ${f.code} ${f.status} ($what)');
        }
      } catch (_) {
        if (!finished) await _rollback(tx);
        rethrow;
      }
      await Future<void>.delayed(_retryDelay(n));
    }
  }

  // ---------------------------------------------------------------- stores

  String _requireSession() {
    final s = _session;
    if (s == null || s.accessToken == null) throw SyncException(SyncErrorKind.notSignedIn);
    return s.userId;
  }

  @override
  Future<List<StoreInfo>> listStores() => _guard('list_stores', () async {
        final uid = _requireSession();
        final ids = <String>[];
        String? page;
        do {
          final q = page == null ? '' : '&pageToken=${Uri.encodeQueryComponent(page)}';
          final j = await _fs('$_root/users/$uid/stores?pageSize=300$q');
          final m = (j ?? const <String, Object?>{}) as Map;
          for (final d in (m['documents'] as List?) ?? const []) {
            ids.add(_idOf((d as Map)['name'] as String));
          }
          page = m['nextPageToken'] as String?;
          if (page != null && page.isEmpty) page = null;
        } while (page != null);
        // The index only says where to look; name, environment and has-data
        // come from the store documents. A store this account can no longer
        // read (membership removed in the console) is left out.
        final stores = await Future.wait([
          for (final id in ids)
            if (_docId.hasMatch(id))
              _fs('$_root/stores/$id').then<StoreInfo?>((d) => _storeInfo(id, d)).catchError(
                    (Object _) => null,
                    test: (e) => e is _FsFailure && (e.code == 403 || e.code == 404),
                  ),
        ]);
        return [for (final s in stores) ?s];
      });

  @override
  Future<StoreInfo> createStore({required String name, required StoreEnvironment environment, String? storeId}) =>
      _guard('create_store', () async {
        final uid = _requireSession();
        final id = storeId == null ? _uuid.v4() : _checkId(storeId);
        final trimmed = name.trim();
        try {
          await _commit([
            _create(
                _doc('stores/$id'),
                {
                  'name': trimmed,
                  'environment': environment.wire,
                  'createdBy': uid,
                  'nextSeq': 0,
                  'nextCode': 0,
                  'hasData': false,
                },
                timeFields: ['createdAt']),
            _create(_doc('stores/$id/members/$uid'), {'role': 'owner'}, timeFields: ['addedAt']),
            _create(_doc('users/$uid/stores/$id'), {'name': trimmed, 'environment': environment.wire}),
          ]);
        } on _FsFailure catch (f) {
          // The store document exists already (ALREADY_EXISTS, or the rules
          // refuse the member create because the store exists): an earlier
          // attempt with this id whose answer was lost. That store is the
          // result, never a second one.
          if (f.code == 403 || f.code == 409) {
            final own = await _ownStore(id, uid, trimmed, environment);
            if (own != null) return own;
            if (f.code == 409) throw SyncException(SyncErrorKind.forbidden, detail: 'store_id_taken');
          }
          // A refused create is a rules problem (rules not deployed), not
          // a missing membership.
          if (f.code == 403) {
            throw SyncException(SyncErrorKind.server, detail: 'HTTP 403 PERMISSION_DENIED (create_store)');
          }
          rethrow;
        }
        return StoreInfo(id: id, name: trimmed, environment: environment);
      });

  /// The store [id] when this account created it with [name] and [env] (an
  /// earlier create whose answer was lost); null when it does not exist or
  /// cannot be read; [SyncErrorKind.forbidden] when it is someone else's.
  Future<StoreInfo?> _ownStore(String id, String uid, String name, StoreEnvironment env) async {
    final Object? doc;
    try {
      doc = await _fs('$_root/stores/$id');
    } on _FsFailure catch (f) {
      if (f.code == 403 || (f.code == 404 && !f.reasons.contains('NO_DATABASE'))) return null;
      rethrow;
    }
    final fields = _fields(doc);
    if (fields['createdBy'] != uid || fields['name'] != name || fields['environment'] != env.wire) {
      throw SyncException(SyncErrorKind.forbidden, detail: 'store_id_taken');
    }
    return _storeInfo(id, doc);
  }

  @override
  Future<StoreInfo> storeInfo(String storeId) => _guard('store_info', () async {
        _requireSession();
        if (!_docId.hasMatch(storeId)) throw SyncException(SyncErrorKind.storeNotFound);
        try {
          return _storeInfo(storeId, await _fs('$_root/stores/$storeId'));
        } on _FsFailure catch (f) {
          if (f.code == 404 && !f.reasons.contains('NO_DATABASE')) throw SyncException(SyncErrorKind.storeNotFound);
          rethrow;
        }
      });

  @override
  Future<DeviceRegistration> registerDevice(
          {required String storeId, required String deviceId, required String name}) =>
      _guard('register_device', () async {
        _requireSession();
        if (!_docId.hasMatch(storeId)) throw SyncException(SyncErrorKind.storeNotFound);
        _checkId(deviceId);
        final storeDoc = _doc('stores/$storeId');
        final deviceDoc = _doc('stores/$storeId/devices/$deviceId');
        final shortName = name.length > 200 ? name.substring(0, 200) : name;
        return _transaction('register_device', (tx) async {
          final docs = await _batchGet([storeDoc, deviceDoc], tx);
          final store = docs[storeDoc];
          if (store == null) throw SyncException(SyncErrorKind.storeNotFound);
          final existing = docs[deviceDoc];
          if (existing != null) {
            // Idempotent per device id: the same code again.
            final code = _fields(existing)['code'];
            if (code is! String || !RegExp(r'^[A-Z]+$').hasMatch(code)) throw const FormatException('code');
            return (DeviceRegistration(deviceId: deviceId, code: code), null);
          }
          final next = _fields(store)['nextCode'];
          if (next is! int || next < 0) throw const FormatException('nextCode');
          final code = deviceCodeForIndex(next);
          return (
            DeviceRegistration(deviceId: deviceId, code: code),
            [
              _create(deviceDoc, {'code': code, 'name': shortName}, timeFields: ['createdAt', 'lastSeenAt']),
              _create(_doc('stores/$storeId/codes/$code'), {'deviceId': deviceId}),
              _patch(storeDoc, {'nextCode': next + 1}),
            ],
          );
        });
      });

  // ------------------------------------------------------------ push / pull

  /// Same checks as the server rules (and the old SQL), so a bad batch is
  /// refused before anything is sent.
  static void _validate(String deviceId, SyncChange c) {
    if (c.deviceId != deviceId) throw SyncException(SyncErrorKind.server, detail: 'device_mismatch');
    final p = c.payload;
    if (!_docId.hasMatch(c.changeId) ||
        c.entity.isEmpty ||
        c.entity.length > 100 ||
        c.entityId.isEmpty ||
        c.entityId.length > 200 ||
        c.version < 0 ||
        c.version > maxSyncVersion ||
        (c.op == SyncOp.delete) != (p == null) ||
        (p?.values.any((v) => v is Map || v is List) ?? false)) {
      throw SyncException(SyncErrorKind.server, detail: 'invalid_changes');
    }
  }

  @override
  Future<PushResult> push({required String storeId, required String deviceId, required List<SyncChange> changes}) =>
      _guard('push_changes', () async {
        _requireSession();
        if (!_docId.hasMatch(storeId)) throw SyncException(SyncErrorKind.storeNotFound);
        _checkId(deviceId);
        final unique = <String, SyncChange>{};
        for (final c in changes) {
          _validate(deviceId, c);
          unique.putIfAbsent(c.changeId, () => c);
        }
        final list = unique.values.toList();
        // Store + device update share the commit with the change documents.
        const chunk = maxCommitWrites - 2;
        var accepted = 0;
        var maxSeq = 0;
        var i = 0;
        do {
          final part = list.sublist(i, math.min(i + chunk, list.length));
          final r = await _pushChunk(storeId, deviceId, part);
          accepted += r.accepted;
          maxSeq = r.maxSeq;
          i += chunk;
        } while (i < list.length);
        return PushResult(accepted: accepted, maxSeq: maxSeq);
      });

  Future<PushResult> _pushChunk(String storeId, String deviceId, List<SyncChange> part) {
    final storeDoc = _doc('stores/$storeId');
    final deviceDoc = _doc('stores/$storeId/devices/$deviceId');
    String changeDoc(SyncChange c) => _doc('stores/$storeId/changes/${c.changeId}');
    return _transaction('push_changes', (tx) async {
      final docs = await _batchGet([storeDoc, deviceDoc, for (final c in part) changeDoc(c)], tx);
      final store = docs[storeDoc];
      if (store == null) throw SyncException(SyncErrorKind.storeNotFound);
      if (docs[deviceDoc] == null) throw SyncException(SyncErrorKind.server, detail: 'device_not_registered');
      final next = _fields(store)['nextSeq'];
      if (next is! int || next < 0) throw const FormatException('nextSeq');
      // Idempotent: a change id already in the log (an earlier push whose
      // answer was lost) is skipped.
      final fresh = [for (final c in part) if (!docs.containsKey(changeDoc(c))) c];
      if (fresh.isEmpty) return (PushResult(accepted: 0, maxSeq: next), null);
      final last = next + fresh.length;
      return (
        PushResult(accepted: fresh.length, maxSeq: last),
        [
          for (var k = 0; k < fresh.length; k++)
            _create(
                changeDoc(fresh[k]),
                {
                  'seq': next + 1 + k,
                  'deviceId': deviceId,
                  'entity': fresh[k].entity,
                  'entityId': fresh[k].entityId,
                  'op': fresh[k].op.name,
                  'version': fresh[k].version,
                  // One string: no Firestore typing of the row's columns.
                  'payload': fresh[k].payload == null ? null : jsonEncode(fresh[k].payload),
                },
                timeFields: ['receivedAt']),
          _patch(storeDoc, {'nextSeq': last, 'hasData': true}),
          // Informational, register clock (a server-time transform would
          // need an empty update mask).
          _patch(deviceDoc, {'lastSeenAt': _clock()}),
        ],
      );
    });
  }

  static SyncChange _change(Object? doc) {
    final d = doc as Map;
    final f = _fields(d);
    final payload = f['payload'];
    final op = f['op'] as String;
    if (op != 'upsert' && op != 'delete') throw const FormatException('op');
    return SyncChange(
      changeId: _idOf(d['name'] as String),
      entity: f['entity'] as String,
      entityId: f['entityId'] as String,
      op: SyncOp.parse(op),
      version: f['version'] as int,
      deviceId: f['deviceId'] as String,
      payload: payload == null ? null : Map<String, Object?>.from(jsonDecode(payload as String) as Map),
      seq: f['seq'] as int,
    );
  }

  @override
  Future<PullResult> pull({required String storeId, required int since, int max = 500}) =>
      _guard('pull_changes', () async {
        _requireSession();
        if (!_docId.hasMatch(storeId)) throw SyncException(SyncErrorKind.storeNotFound);
        final j = await _fs('$_root/stores/$storeId:runQuery', body: {
          'structuredQuery': {
            'from': [
              {'collectionId': 'changes'},
            ],
            'where': {
              'fieldFilter': {
                'field': {'fieldPath': 'seq'},
                'op': 'GREATER_THAN',
                'value': encodeValue(math.max(since, 0)),
              },
            },
            'orderBy': [
              {
                'field': {'fieldPath': 'seq'},
                'direction': 'ASCENDING',
              },
            ],
            'limit': max.clamp(1, maxPullPage),
          },
        });
        final out = <SyncChange>[];
        for (final e in j as List) {
          // A failure after the first results: never a short page that
          // looks complete.
          _throwStreamError(e);
          // Elements without a document carry only a readTime.
          if ((e as Map)['document'] != null) out.add(_change(e['document']));
        }
        for (var k = 1; k < out.length; k++) {
          if (out[k].seq! <= out[k - 1].seq!) throw const FormatException('order');
        }
        return PullResult(out);
      });
}
