// In-memory sync server with the semantics of the Supabase SQL (spec §7):
// global `seq`, idempotent `change_id`, device codes A, B, … Z, AA…, store
// environment, `has_data`, membership checks. Payloads go through a JSON
// round-trip, like the real wire.
//
//   final server = FakeSyncServer()..addUser('owner@test.local', 'secret');
//   final transport = server.client();      // one per device/session
//
// Failure injection: [FakeSyncServer.failNextPush] (before / after the server
// accepted the batch), [FakeSyncServer.failNextPull], [FakeSyncServer.offline].
import 'dart:convert';

import 'package:dreampos/core/sync/transport.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum FakeFailure {
  /// Network error before the server stored anything.
  beforeAccept,

  /// The server stored the batch, then the response was lost.
  afterAccept,
}

class FakeStore {
  FakeStore(this.id, this.name, this.environment, this.createdBy);
  final String id;
  final String name;
  final StoreEnvironment environment;
  final String createdBy;
  final members = <String, String>{}; // userId -> role
  final devices = <String, ({String code, String name})>{}; // deviceId -> code
}

class _State {
  final users = <String, ({String id, String password})>{}; // email ->
  final refreshTokens = <String, String>{}; // token -> userId
  final stores = <String, FakeStore>{};
  final changes = <SyncChange>[]; // seq order, with store id kept aside
  final changeStore = <int, String>{}; // seq -> store id
  final changeIds = <String>{};
  var seq = 0;

  FakeFailure? failNextPush;
  bool failNextPull = false;
  bool offline = false;
  int pushCalls = 0;
  int pullCalls = 0;
}

/// One client view (session) of a shared in-memory server. [client] makes
/// another view of the same server for another device.
class FakeSyncServer implements SyncTransport {
  FakeSyncServer() : _s = _State();
  FakeSyncServer._(this._s);

  final _State _s;
  SyncSession? _session;

  /// A new transport (own session) talking to the same server.
  FakeSyncServer client() => FakeSyncServer._(_s);

  // ------------------------------------------------------------ test helpers

  void addUser(String email, String password) =>
      _s.users[email.toLowerCase()] = (id: _uuid.v4(), password: password);

  String userIdOf(String email) => _s.users[email.toLowerCase()]!.id;

  /// Adds [email] as a member of [storeId].
  void addMember(String storeId, String email, {String role = 'cashier'}) =>
      _s.stores[storeId]!.members[userIdOf(email)] = role;

  /// Creates a store directly (as if made from another client).
  FakeStore seedStore(String name, StoreEnvironment env, {required String ownerEmail}) {
    final id = _uuid.v4();
    final st = FakeStore(id, name, env, userIdOf(ownerEmail));
    st.members[userIdOf(ownerEmail)] = 'owner';
    _s.stores[id] = st;
    return st;
  }

  FakeStore store(String id) => _s.stores[id]!;
  Iterable<FakeStore> get stores => _s.stores.values;

  /// All changes of [storeId] in seq order.
  List<SyncChange> changesOf(String storeId) =>
      [for (final c in _s.changes) if (_s.changeStore[c.seq] == storeId) c];

  set failNextPush(FakeFailure? f) => _s.failNextPush = f;
  set failNextPull(bool v) => _s.failNextPull = v;
  set offline(bool v) => _s.offline = v;
  bool get offline => _s.offline;
  int get pushCalls => _s.pushCalls;
  int get pullCalls => _s.pullCalls;
  int get maxSeq => _s.seq;

  /// Stores [change] for [storeId] as it is, bypassing the push checks (a
  /// row written before those checks existed, or by a hand-made client
  /// talking to the database directly). Returns its seq.
  int injectRaw(String storeId, SyncChange change) {
    final seq = ++_s.seq;
    _s.changes.add(SyncChange(
      changeId: change.changeId,
      entity: change.entity,
      entityId: change.entityId,
      op: change.op,
      version: change.version,
      deviceId: change.deviceId,
      payload: change.payload,
      seq: seq,
    ));
    _s.changeIds.add(change.changeId);
    _s.changeStore[seq] = storeId;
    return seq;
  }

  /// Invalidates every refresh token (forces «sign in again»).
  void revokeAllSessions() => _s.refreshTokens.clear();

  // --------------------------------------------------------------- internals

  void _net() {
    if (_s.offline) throw SyncException(SyncErrorKind.network, detail: 'offline');
  }

  String _user() {
    final s = _session;
    if (s == null) throw SyncException(SyncErrorKind.notSignedIn);
    if (_s.refreshTokens[s.refreshToken] != s.userId) throw SyncException(SyncErrorKind.auth, detail: '401');
    return s.userId;
  }

  FakeStore _member(String storeId) {
    final uid = _user();
    final st = _s.stores[storeId];
    if (st == null) throw SyncException(SyncErrorKind.storeNotFound);
    if (!st.members.containsKey(uid)) throw SyncException(SyncErrorKind.forbidden, detail: '403');
    return st;
  }

  SyncSession _issue(String userId, String email) {
    final token = _uuid.v4();
    _s.refreshTokens[token] = userId;
    return _session = SyncSession(userId: userId, email: email, refreshToken: token, accessToken: _uuid.v4());
  }

  StoreInfo _info(FakeStore st) => StoreInfo(
        id: st.id,
        name: st.name,
        environment: st.environment,
        hasData: _s.changeStore.values.any((v) => v == st.id),
      );

  // --------------------------------------------------------- SyncTransport

  @override
  SyncSession? get session => _session;

  @override
  Future<SyncSession> signIn({required String email, required String password}) async {
    _net();
    final u = _s.users[email.toLowerCase()];
    if (u == null || u.password != password) throw SyncException(SyncErrorKind.auth, detail: '400');
    return _issue(u.id, email);
  }

  @override
  Future<SyncSession> restoreSession(String refreshToken) async {
    _net();
    final uid = _s.refreshTokens.remove(refreshToken); // rotating tokens
    if (uid == null) throw SyncException(SyncErrorKind.auth, detail: 'refresh');
    final email = _s.users.entries.firstWhere((e) => e.value.id == uid).key;
    return _issue(uid, email);
  }

  @override
  Future<void> signOut() async {
    final s = _session;
    if (s != null) _s.refreshTokens.remove(s.refreshToken);
    _session = null;
  }

  @override
  Future<List<StoreInfo>> listStores() async {
    _net();
    final uid = _user();
    return [for (final st in _s.stores.values) if (st.members.containsKey(uid)) _info(st)];
  }

  @override
  Future<StoreInfo> createStore({required String name, required StoreEnvironment environment}) async {
    _net();
    final uid = _user();
    final st = FakeStore(_uuid.v4(), name, environment, uid);
    st.members[uid] = 'owner';
    _s.stores[st.id] = st;
    return _info(st);
  }

  @override
  Future<DeviceRegistration> registerDevice(
      {required String storeId, required String deviceId, required String name}) async {
    _net();
    final st = _member(storeId);
    final existing = st.devices[deviceId];
    if (existing != null) return DeviceRegistration(deviceId: deviceId, code: existing.code);
    final used = {for (final d in st.devices.values) d.code};
    var i = 0;
    while (used.contains(deviceCodeForIndex(i))) {
      i++;
    }
    final code = deviceCodeForIndex(i);
    st.devices[deviceId] = (code: code, name: name);
    return DeviceRegistration(deviceId: deviceId, code: code);
  }

  @override
  Future<StoreInfo> storeInfo(String storeId) async {
    _net();
    return _info(_member(storeId));
  }

  @override
  Future<PushResult> push(
      {required String storeId, required String deviceId, required List<SyncChange> changes}) async {
    _net();
    _s.pushCalls++;
    final st = _member(storeId);
    if (_s.failNextPush == FakeFailure.beforeAccept) {
      _s.failNextPush = null;
      throw SyncException(SyncErrorKind.network, detail: 'injected before accept');
    }
    // Postgres jsonb refuses U+0000 in text (push_changes fails with HTTP
    // 400 and nothing is stored): same contract here.
    for (final c in changes) {
      if (c.payload?.values.any((v) => v is String && v.contains('\u0000')) ?? false) {
        throw SyncException(SyncErrorKind.server, detail: 'HTTP 400');
      }
      // check (version between 0 and 7258118400000); a payload of scalars
      if (c.version < 0 ||
          c.version > 7258118400000 ||
          (c.payload?.values.any((v) => v is Map || v is List) ?? false)) {
        throw SyncException(SyncErrorKind.server, detail: 'HTTP 400');
      }
    }
    // The wire: JSON.
    final wire = (jsonDecode(jsonEncode([for (final c in changes) c.toJson()])) as List)
        .map((e) => SyncChange.fromJson(Map<String, Object?>.from(e as Map)));
    var accepted = 0;
    for (final c in wire) {
      if (!_s.changeIds.add(c.changeId)) continue; // on conflict (change_id) do nothing
      final seq = ++_s.seq;
      _s.changes.add(SyncChange(
        changeId: c.changeId,
        entity: c.entity,
        entityId: c.entityId,
        op: c.op,
        version: c.version,
        deviceId: c.deviceId,
        payload: c.payload,
        seq: seq,
      ));
      _s.changeStore[seq] = st.id;
      accepted++;
    }
    if (_s.failNextPush == FakeFailure.afterAccept) {
      _s.failNextPush = null;
      throw SyncException(SyncErrorKind.network, detail: 'injected after accept');
    }
    return PushResult(accepted: accepted, maxSeq: _s.seq);
  }

  @override
  Future<PullResult> pull({required String storeId, required int since, int max = 500}) async {
    _net();
    _s.pullCalls++;
    final st = _member(storeId);
    if (_s.failNextPull) {
      _s.failNextPull = false;
      throw SyncException(SyncErrorKind.network, detail: 'injected pull');
    }
    final out = <SyncChange>[];
    for (final c in _s.changes) {
      if (c.seq! <= since || _s.changeStore[c.seq] != st.id) continue;
      out.add(SyncChange.fromJson(Map<String, Object?>.from(jsonDecode(jsonEncode(c.toJson())) as Map)));
      if (out.length >= max) break;
    }
    return PullResult(out);
  }
}
