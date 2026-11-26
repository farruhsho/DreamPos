// Client transport of the multi-register sync (D-025, spec §2, §7, §8).
//
// `SyncTransport` is what the engine (`sync_service.dart`) talks to. The real
// implementation (Firebase: Identity Toolkit + Firestore REST over `http`,
// D-026, `firebase_transport.dart`) plugs in via
// `syncTransportFactoryProvider`; tests use `test/support/fake_sync_server.dart`.
// Every method throws [SyncException] on failure (never a raw http/socket
// error), so the engine can map it to the status (offline / error).
import '../../l10n/l10n.dart';

/// Store environment (spec §10). A demo database may only connect to
/// [test]; a [production] store refuses it. Never changed from the client.
enum StoreEnvironment {
  test,
  production;

  /// Wire value: `'test'` / `'production'`.
  String get wire => name;

  static StoreEnvironment parse(String? v) => v == 'production' ? production : test;

  String labelIn(AppLocalizations l) => switch (this) {
        test => l.syncEnvTest,
        production => l.syncEnvProduction,
      };
}

/// Cloud project chosen by the user: the Firebase project id and its Web API
/// key (D-026). The Web API key only identifies the project to Firebase (it
/// is not a secret: access is decided by the account and the Firestore
/// rules); both are stored locally (`sync_state`), never synced.
class SyncEndpoint {
  const SyncEndpoint({required this.projectId, required this.apiKey});
  final String projectId;
  final String apiKey;

  @override
  bool operator ==(Object other) => other is SyncEndpoint && other.projectId == projectId && other.apiKey == apiKey;
  @override
  int get hashCode => Object.hash(projectId, apiKey);
  @override
  String toString() => 'SyncEndpoint($projectId)';
}

/// Signed-in account. Only [refreshToken] is persisted (local `sync_state`);
/// the password never is. Never log tokens.
class SyncSession {
  const SyncSession({required this.userId, required this.email, required this.refreshToken, this.accessToken});
  final String userId;
  final String email;
  final String refreshToken;
  final String? accessToken;

  @override
  String toString() => 'SyncSession($email)';
}

/// A store as returned by `store_info` / the store list.
class StoreInfo {
  const StoreInfo({required this.id, required this.name, required this.environment, this.hasData = false});
  final String id;
  final String name;
  final StoreEnvironment environment;

  /// True when the store already has changes on the server.
  final bool hasData;

  @override
  String toString() => 'StoreInfo($id, $name, ${environment.wire}, hasData=$hasData)';
}

/// Result of `register_device`: the letter code (`A`, `B`, … `Z`, `AA`…).
class DeviceRegistration {
  const DeviceRegistration({required this.deviceId, required this.code});
  final String deviceId;
  final String code;
}

/// Change operation on the wire.
enum SyncOp {
  upsert,
  delete;

  static SyncOp parse(String v) => v == 'delete' ? delete : upsert;
}

/// One change (spec §2): the raw SQL row (`SELECT * … WHERE id = ?`, drift
/// storage format: DateTime = int epoch seconds, bool = 0/1) of [entity]
/// (SQL table name, or `settings` with [entityId] = key). [payload] is null for
/// deletes. [seq] is set by the server (null when pushing).
class SyncChange {
  const SyncChange({
    required this.changeId,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.version,
    required this.deviceId,
    this.payload,
    this.seq,
  });

  final String changeId;
  final String entity;
  final String entityId;
  final SyncOp op;

  /// Hybrid logical clock value (epoch ms based, monotonic per device).
  final int version;
  final String deviceId;
  final Map<String, Object?>? payload;
  final int? seq;

  /// JSON shape used by `push_changes` / `pull_changes`.
  Map<String, Object?> toJson() => {
        'change_id': changeId,
        'entity': entity,
        'entity_id': entityId,
        'op': op.name,
        'version': version,
        'device_id': deviceId,
        'payload': payload,
        if (seq != null) 'seq': seq,
      };

  factory SyncChange.fromJson(Map<String, Object?> j) {
    Object? need(String k) => j[k] ?? (throw SyncException(SyncErrorKind.protocol, detail: 'missing $k'));
    final payload = j['payload'];
    return SyncChange(
      changeId: need('change_id') as String,
      entity: need('entity') as String,
      entityId: need('entity_id') as String,
      op: SyncOp.parse(need('op') as String),
      version: (need('version') as num).toInt(),
      deviceId: need('device_id') as String,
      payload: payload == null ? null : Map<String, Object?>.from(payload as Map),
      seq: (j['seq'] as num?)?.toInt(),
    );
  }

  @override
  String toString() => 'SyncChange(#$seq ${op.name} $entity/$entityId v$version from $deviceId)';
}

/// Result of `push_changes`.
class PushResult {
  const PushResult({required this.accepted, required this.maxSeq});

  /// Changes inserted now (duplicates of an earlier push are not counted).
  final int accepted;
  final int maxSeq;
}

/// Result of `pull_changes`: changes with `seq > since`, ordered by seq.
class PullResult {
  const PullResult(this.changes);
  final List<SyncChange> changes;

  /// Highest seq in this page (null when empty).
  int? get lastSeq => changes.isEmpty ? null : changes.last.seq;
}

enum SyncErrorKind {
  /// No connection / timeout / DNS. Shown as «offline», retried with backoff.
  network,

  /// Wrong credentials, or the refresh token was rejected: sign in again.
  auth,

  /// E-mail/password sign-in is not enabled in the cloud project
  /// (Firebase: Authentication → Sign-in method → Email/Password).
  signInDisabled,

  /// The account was disabled in the cloud project.
  accountDisabled,

  /// Too many failed sign-ins: the cloud blocks the account for a while.
  tooManyAttempts,

  /// The Web API key is not valid (for this project).
  invalidApiKey,

  /// The Web API key belongs to a different cloud project than the project
  /// id (the ID token's audience is another project).
  projectMismatch,

  /// Not a member of the store (Firestore rules: no member document).
  forbidden,

  /// Demo database vs production store (spec §10).
  environmentMismatch,

  /// Join refused: the local database already has business data.
  notEmpty,

  /// A database that was on a test store (it holds test data of other
  /// registers) may not create a production store.
  testData,

  /// 5xx or a cloud error the client cannot interpret further.
  server,

  /// Malformed response.
  protocol,

  /// Sync is not set up on this device.
  notConfigured,

  /// No signed-in session for an operation that needs one.
  notSignedIn,

  /// The project id is not a valid Firebase project id.
  invalidProject,

  /// Unknown store id.
  storeNotFound,

  /// createStore/join on a database that is already connected.
  alreadyConnected,
}

/// Sync failure with a localized message (resolved on access, so it follows
/// the current UI language). [detail] is technical (HTTP status, RPC error
/// code); it is appended in parentheses and must not contain tokens.
class SyncException implements Exception {
  SyncException(this.kind, {this.detail, this.cause});
  final SyncErrorKind kind;
  final String? detail;
  final Object? cause;

  /// True for errors that are expected to go away by themselves (retry with
  /// backoff, status «offline»).
  bool get isTransient => kind == SyncErrorKind.network;

  String messageIn(AppLocalizations l) {
    final base = switch (kind) {
      SyncErrorKind.network => l.syncErrNetwork,
      SyncErrorKind.auth => l.syncErrAuth,
      SyncErrorKind.signInDisabled => l.syncErrSignInDisabled,
      SyncErrorKind.accountDisabled => l.syncErrAccountDisabled,
      SyncErrorKind.tooManyAttempts => l.syncErrTooManyAttempts,
      SyncErrorKind.invalidApiKey => l.syncErrInvalidApiKey,
      SyncErrorKind.projectMismatch => l.syncErrProjectMismatch,
      SyncErrorKind.forbidden => l.syncErrForbidden,
      SyncErrorKind.environmentMismatch => l.syncErrEnvironmentMismatch,
      SyncErrorKind.notEmpty => l.syncErrNotEmpty,
      SyncErrorKind.testData => l.syncErrTestData,
      SyncErrorKind.server => l.syncErrServer,
      SyncErrorKind.protocol => l.syncErrProtocol,
      SyncErrorKind.notConfigured => l.syncErrNotConfigured,
      SyncErrorKind.notSignedIn => l.syncErrNotSignedIn,
      SyncErrorKind.invalidProject => l.syncErrInvalidProject,
      SyncErrorKind.storeNotFound => l.syncErrStoreNotFound,
      SyncErrorKind.alreadyConnected => l.syncErrAlreadyConnected,
    };
    final d = detail;
    return d == null || d.isEmpty || !_showDetail ? base : '$base ($d)';
  }

  bool get _showDetail => kind == SyncErrorKind.server || kind == SyncErrorKind.protocol;

  /// Message in the current UI language.
  String get message => messageIn(L.current);

  @override
  String toString() => message;
}

/// What the sync engine needs from the server (spec §7; Firestore mapping in
/// docs/specs/firebase-sync.md). One instance
/// per device/session: it holds the access/refresh tokens of the signed-in
/// account. All methods throw [SyncException].
abstract class SyncTransport {
  /// Email + password sign-in. The password is not kept.
  Future<SyncSession> signIn({required String email, required String password});

  /// Restores a session from a stored refresh token.
  Future<SyncSession> restoreSession(String refreshToken);

  /// Current session (its refresh token may rotate after any call; the engine
  /// persists it). Null when signed out.
  SyncSession? get session;

  /// Drops the tokens (local; best effort on the server).
  Future<void> signOut();

  /// Stores the signed-in user is a member of (for «Подключить к существующему»).
  Future<List<StoreInfo>> listStores();

  /// `create_store(name, environment)`: the caller becomes the owner.
  /// [storeId] is chosen (and saved) by the caller so a retry after a lost
  /// answer is idempotent: the store the same account already created under
  /// that id with the same name and environment is returned instead of a
  /// second one; an id that belongs to someone else -> [SyncErrorKind.forbidden].
  /// Null: the transport picks a new id.
  Future<StoreInfo> createStore({required String name, required StoreEnvironment environment, String? storeId});

  /// `register_device(store_id, device_id, name)`: next free letter code;
  /// idempotent per device id.
  Future<DeviceRegistration> registerDevice({required String storeId, required String deviceId, required String name});

  /// `store_info(store_id)`: name, environment, has_data.
  Future<StoreInfo> storeInfo(String storeId);

  /// `push_changes`: idempotent on `change_id`.
  Future<PushResult> push({required String storeId, required String deviceId, required List<SyncChange> changes});

  /// `pull_changes(store_id, since, max)`: ordered by seq.
  Future<PullResult> pull({required String storeId, required int since, int max = 500});
}

/// Creates the transport for an endpoint. The Firebase implementation is
/// provided through `syncTransportFactoryProvider` (core/providers.dart).
typedef SyncTransportFactory = SyncTransport Function(SyncEndpoint endpoint);

/// Letter code of the [index]-th device (0 → `A`, 25 → `Z`, 26 → `AA`, 27 →
/// `AB`…), spreadsheet-column style. Shared by the fake server and the
/// Firebase transport (`stores/{id}.nextCode`).
String deviceCodeForIndex(int index) {
  assert(index >= 0);
  var n = index + 1;
  final out = StringBuffer();
  final chars = <int>[];
  while (n > 0) {
    n -= 1;
    chars.add(65 + n % 26);
    n ~/= 26;
  }
  out.writeAll(chars.reversed.map(String.fromCharCode));
  return out.toString();
}
