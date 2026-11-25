// Multi-register sync engine (D-025, docs/specs/multi-register-sync.md §2, §3,
// §5, §6, §9, §10).
//
// * Order: pull, then push. A restored / copied file learns that its device
//   id was taken over (own changes it does not know) before it pushes
//   anything under that id, so only the copy moves to a new id/code.
// * Push: the unsynced `sync_outbox` rows (written by the SQLite triggers) are
//   collapsed per entity; for each one the CURRENT raw row is read and sent
//   (or `delete` when the row is gone) with a hybrid-logical-clock version.
//   Outbox rows are marked `synced_at` only after the server confirmed. The
//   change ids and versions of an unconfirmed batch are kept
//   (`sync_state.push_inflight`), so a retry after «server accepted, response
//   lost» re-sends the very same changes (idempotent on the server).
//   Pending parents of a pushed row go first (the current row may point at a
//   parent created after it).
// * Pull: pages of server changes in seq order, each applied in ONE
//   transaction with the triggers suppressed and FK checks deferred; the cursor
//   advances in the same transaction. A change whose parent has not arrived is
//   parked and retried with later pages. Last-writer-wins on (version, device
//   id), separately for a row's user part and its bookkeeping («stat») part
//   (`statColumns`); own changes go through the same rule (a newer own change
//   means a restored / copied file: new device id and code). A void is
//   sticky. Cached columns are never taken from the payload for an existing
//   row; the caches of everything touched are recomputed from the ledgers in
//   the same transaction (`SyncAggregates.recompute`).
// * Unique keys (barcode, customer card, gift code): the row with the lower
//   version loses the value; duplicate document numbers (restore/copy): the
//   newer gets a suffixed code. Business conflicts (negative stock / gift card
//   balance / bonus after recompute, void vs return, over-return) are accepted
//   but surfaced. All are written to `sync_conflicts` and a local notification.
// * Flows: sign in, create a store and upload everything, join a store
//   (refused for a database with business data), disconnect (keeps data and
//   device code). A demo database only connects to a `test` store.
// * Scheduler: every 30 s while configured and in the foreground, plus 3 s
//   after local writes; backoff 30 s → 5 min on errors. Never runs when sync is
//   not configured, off in tests unless enabled.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sqlite3/common.dart' show SqliteException;
import 'package:uuid/uuid.dart';

import '../../l10n/l10n.dart';
import '../db/database.dart';
import 'aggregates.dart';
import 'conflict_text.dart';
import 'sync_tables.dart';
import 'transport.dart';

const _uuid = Uuid();

/// Keys of the local `sync_state` table used by the engine.
abstract final class SyncKeys {
  static const deviceId = 'device_id';
  static const hlc = 'hlc';
  static const pullCursor = 'pull_cursor';
  static const storeId = 'store_id';
  static const storeName = 'store_name';
  static const storeEnv = 'store_env';

  /// '1' while this database is connected to [storeId].
  static const connected = 'connected';
  static const endpointUrl = 'endpoint_url';
  static const anonKey = 'anon_key';
  static const refreshToken = 'refresh_token';
  static const email = 'email';
  static const lastPushAt = 'last_push_at';
  static const lastPullAt = 'last_pull_at';
  static const lastSyncAt = 'last_sync_at';

  /// `SyncErrorKind.name` of the last failed sync (cleared on success).
  static const lastError = 'last_error';
  static const pushInflight = 'push_inflight';

  /// '1' after joining a store until the first complete sync (then the
  /// device-local `setup_done` is set: users came from the cloud).
  static const joinPending = 'join_pending';

  /// Remote changes whose parent rows have not arrived yet (JSON list of
  /// [SyncChange.toJson]); retried with every later pull page.
  static const parked = 'parked';

  /// Store created on the server whose device registration did not finish
  /// (JSON `{id, name, env}`): a retry reuses it instead of creating a twin.
  static const pendingStore = 'pending_store';

  /// '1' when a pull applied a change of this device id newer than the
  /// local row (a restored / copied file) and the new device id/code is
  /// still owed. Written in the same transaction as that change, so a failed
  /// registration is retried on the next sync, before anything is pushed.
  static const reidentifyPending = 'reidentify_pending';

  /// JSON list of the ids of the active users this database had when it
  /// joined a store (not a reconnect). They are deactivated once the store's
  /// users have been pulled (see `SyncService._retireJoinLocalUsers`).
  static const joinLocalUsers = 'join_local_users';
}

/// Payload key that says which parts of a row an upsert carries: `u` (person
/// edits), `s` (bookkeeping, see `statColumns`) or `us`. Absent = the whole
/// row. Not a column, so receivers that do not know it ignore it.
const syncPartsKey = '@parts';

/// Tables whose rows make a database «not empty» for joining an existing
/// store (spec §10). Users, registers and work sessions are not business data
/// (a fresh install may already have its owner); they are uploaded on join.
const businessDataTables = <String>[
  'categories',
  'products',
  'stock_movements',
  'customers',
  'customer_ledger',
  'suppliers',
  'purchase_orders',
  'supplier_payments',
  'goods_receipts',
  'supplier_ledger',
  'shifts',
  'cash_movements',
  'sales',
  'returns',
  'gift_cards',
  'gift_card_sales',
  'promotions',
  'inventory_counts',
  'warranty_claims',
];

/// Numbered documents: (device_code, number) identifies one document
/// (UNIQUE index for sales / gift card sales, a plain index for the others).
/// Two documents only share it after a restored backup or a copied file
/// (`SyncService._resolveNumber`).
final _numberedUnique = AppDatabase.numberedDocumentTables.values.toSet();

/// Highest change version accepted from the server (2200-01-01 in
/// milliseconds). Versions are millisecond clocks (≈ 1.8e12 today); a larger
/// one can only come from a broken or hand-made client and would overflow the
/// hybrid clock (`hlc + 1`), so it is rejected like any malformed change.
const maxSyncVersion = 7258118400000;

/// Unique columns that can collide between offline registers (spec §5).
/// `partial`: the index only covers non-deleted rows.

const _uniqueColumns = <String, ({String column, bool partial})>{
  'products': (column: 'barcode', partial: true),
  'customers': (column: 'card_number', partial: true),
  'gift_cards': (column: 'code', partial: false),
};

/// Kinds written to `sync_conflicts` by the engine.
abstract final class SyncConflictKind {
  static const uniqueBarcode = 'unique_barcode';
  static const uniqueCard = 'unique_card';
  static const uniqueGiftCode = 'unique_gift_code';
  static const negativeStock = 'negative_stock';
  static const negativeGiftBalance = 'negative_gift_balance';
  static const negativeBonus = 'negative_bonus';

  /// Two documents with the same register code and number (a restored
  /// backup or a copied database): the newer one gets a suffixed code.
  static const uniqueNumber = 'unique_number';

  /// A sale voided on one register and returned on another.
  static const voidReturn = 'void_return';

  /// More returned on several registers than was sold.
  static const overReturn = 'over_return';

  /// This database turned out to be a copy (restored backup / cloned file)
  /// of a register already working in the store: it got a new device id
  /// and code.
  static const identity = 'identity';

  /// One gift card sale voided on two registers offline: both gave the
  /// money back, only one void is kept.
  static const doubleVoid = 'double_void';

  /// A change from the server that this database cannot store (a value of
  /// the wrong type, a missing required column, a broken constraint, an
  /// impossible version): skipped, so it never blocks the sync.
  static const rejected = 'rejected';

  /// A gift card spent on one register while its sale was voided (money
  /// refunded) on another.
  static const voidRedeem = 'void_redeem';

  /// The users this database had before it joined a store were deactivated
  /// (their PINs could collide with the store's users).
  static const joinUsers = 'join_users';
}

enum SyncPhase {
  /// Sync is not configured on this device.
  off,
  idle,
  syncing,
  error,

  /// Last attempt failed with a network error.
  offline;

  String labelIn(AppLocalizations l) => switch (this) {
        off => l.syncPhaseOff,
        idle => l.syncPhaseIdle,
        syncing => l.syncPhaseSyncing,
        error => l.syncPhaseError,
        offline => l.syncPhaseOffline,
      };
}

/// Snapshot for the UI (`syncStatusProvider`).
class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.off,
    this.pending = 0,
    this.lastSyncAt,
    this.lastError,
    this.storeId,
    this.storeName,
    this.environment,
    this.deviceCode,
    this.email,
    this.signedIn = false,
    this.nextRetryAt,
  });

  final SyncPhase phase;

  /// Entities waiting to be pushed (distinct rows in the unsynced outbox).
  final int pending;
  final DateTime? lastSyncAt;
  final SyncException? lastError;
  final String? storeId;
  final String? storeName;
  final StoreEnvironment? environment;

  /// This register's document code (`A`, `B`…); kept after disconnect.
  final String? deviceCode;

  /// Signed-in account (also known before a store is chosen).
  final String? email;
  final bool signedIn;

  /// When the scheduler retries after an error (backoff), if any.
  final DateTime? nextRetryAt;

  /// Connected to a store (sync runs).
  bool get configured => phase != SyncPhase.off;
  bool get isTestStore => environment == StoreEnvironment.test;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pending,
    DateTime? lastSyncAt,
    SyncException? lastError,
    bool clearError = false,
    String? storeId,
    String? storeName,
    StoreEnvironment? environment,
    String? deviceCode,
    String? email,
    bool? signedIn,
    DateTime? nextRetryAt,
    bool clearRetry = false,
  }) =>
      SyncStatus(
        phase: phase ?? this.phase,
        pending: pending ?? this.pending,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        lastError: clearError ? null : (lastError ?? this.lastError),
        storeId: storeId ?? this.storeId,
        storeName: storeName ?? this.storeName,
        environment: environment ?? this.environment,
        deviceCode: deviceCode ?? this.deviceCode,
        email: email ?? this.email,
        signedIn: signedIn ?? this.signedIn,
        nextRetryAt: clearRetry ? null : (nextRetryAt ?? this.nextRetryAt),
      );

  @override
  String toString() => 'SyncStatus(${phase.name}, pending=$pending, store=$storeName, code=$deviceCode)';
}

/// What one [SyncService.syncNow] did.
class SyncReport {
  int pushed = 0;
  int pulled = 0;
  int applied = 0;
  int skipped = 0;
  int conflicts = 0;

  /// Remote changes waiting for their parent rows (see [SyncKeys.parked]).
  int parked = 0;

  /// Malformed remote changes skipped ([SyncConflictKind.rejected]).
  int rejected = 0;

  /// This database was found to be a copy of a working register and got a
  /// new device id/code during this sync.
  bool reidentified = false;

  @override
  String toString() => 'SyncReport(pushed=$pushed, pulled=$pulled, applied=$applied, skipped=$skipped, '
      'conflicts=$conflicts, parked=$parked)';
}

/// Timings of the scheduler (spec §9). Tests pass short ones.
class SyncSchedule {
  const SyncSchedule({
    this.period = const Duration(seconds: 30),
    this.debounce = const Duration(seconds: 3),
    this.backoffMin = const Duration(seconds: 30),
    this.backoffMax = const Duration(minutes: 5),
  });
  final Duration period;
  final Duration debounce;
  final Duration backoffMin;
  final Duration backoffMax;

  Duration backoff(int failures) {
    final ms = backoffMin.inMilliseconds * math.pow(2, math.max(0, failures - 1));
    return Duration(milliseconds: math.min(ms.toInt(), backoffMax.inMilliseconds));
  }
}

/// True inside `flutter test` (the scheduler is off there unless enabled).
bool get runningInFlutterTest {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

class _Conflict {
  _Conflict(this.kind, this.entity, this.entityId, this.payload);
  final String kind;
  final String entity;
  final String entityId;

  /// Stored language-neutral; rendered by [ConflictText] on display.
  final SyncConflictPayload payload;
}

class _Group {
  _Group(this.entity, this.entityId, this.last, this.at, {required this.user, required this.stat});
  final String entity;
  final String entityId;
  final int last;
  final int at;

  /// The outbox has person edits (`upsert`/`delete`) / bookkeeping (`stat`).
  final bool user;
  final bool stat;
  String get key => '$entity\u0000$entityId';
}

/// Which parts of a row a change carries / a local version covers.
enum _Part { user, stat }

/// `sync_row_versions.entity` of a part (the stat part has its own clock).
String _versionKey(String entity, _Part p) => p == _Part.user ? entity : '$entity#s';

/// Outbox ops of a part.
String _opsOf(_Part p) => p == _Part.user ? "('upsert', 'delete')" : "('stat')";

enum _Outcome { applied, skipped, deferred }

/// A remote change this database cannot store (see [SyncConflictKind.rejected]).
class _Rejected implements Exception {
  const _Rejected();
}

/// A local row whose unique value / document code was changed by the sync
/// (it lost a collision): the change is pushed like an edit, so every
/// register ends with the same values even when the registers judged the
/// collision differently (spec §5). [at] is just above the change that
/// made it lose, so a later real edit of the row still supersedes it.
class _Owed {
  _Owed(this.table, this.id, this.at);
  final String table;
  final String id;
  final int at;
}

/// SQL type affinity / nullability of a column (`PRAGMA table_info`).
class _Col {
  _Col(this.type, {required this.notNull, required this.hasDefault});
  final String type;
  final bool notNull;
  final bool hasDefault;
}

class _ApplyFlags {
  bool settingsChanged = false;

  /// A change of this device id was newer than the local row.
  bool ownNewer = false;
}

class _Fk {
  _Fk(this.column, this.table, this.to);
  final String column;
  final String table;
  final String to;
}

class _PreparedPush {
  _PreparedPush(this.changes, this.groups);
  final List<SyncChange> changes;
  final List<_Group> groups;
}

class SyncService {
  SyncService(
    this.db, {
    SyncTransportFactory? transportFactory,
    this.schedulerEnabled = false,
    this.schedule = const SyncSchedule(),
    this.pushBatchSize = 200,
    this.pullBatchSize = 500,
    this.deviceName = 'DreamPOS',
  }) : _factory = transportFactory;

  final AppDatabase db;
  final SyncTransportFactory? _factory;

  /// Periodic / debounced sync. The app enables it; tests leave it off.
  final bool schedulerEnabled;
  final SyncSchedule schedule;
  final int pushBatchSize;
  final int pullBatchSize;

  /// Name sent with `register_device`.
  final String deviceName;

  SyncTransport? _transport;
  final _statusCtl = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = const SyncStatus();
  bool _initialized = false;
  bool _disposed = false;
  Future<void>? _initFuture;

  Future<void>? _lock;
  Future<SyncReport>? _running;
  bool _syncing = false;

  Timer? _periodic;
  Timer? _debounce;
  StreamSubscription<Set<TableUpdate>>? _updatesSub;
  bool _foreground = true;
  int _failures = 0;
  DateTime? _nextAttemptAt;

  /// Test hook: called before each remote change of a pull batch is applied
  /// (inside the batch transaction). Throwing simulates a crash mid-batch.
  @visibleForTesting
  Future<void> Function(int index, SyncChange change)? debugBeforeApply;

  /// Transport of the configured endpoint (null until signed in / configured).
  SyncTransport? get transport => _transport;

  SyncStatus get status => _status;

  /// Status updates (also emitted for pending-count changes).
  Stream<SyncStatus> get statusStream => _statusCtl.stream;

  void _emit(SyncStatus s) {
    _status = s;
    if (!_disposed) _statusCtl.add(s);
  }

  // ------------------------------------------------------------- lifecycle

  /// Loads the stored state, creates the transport of a configured endpoint
  /// and starts the scheduler when connected. Safe to call repeatedly; never
  /// throws.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      await refreshStatus();
      _initialized = true;
      if (_status.configured) {
        _transport ??= await _makeTransport(silent: true);
        _startScheduler();
      }
    } catch (_) {
      // DB closed (tests) or a broken endpoint: stay off; syncNow reports it.
    }
  }

  void dispose() {
    _disposed = true;
    _stopScheduler();
    _statusCtl.close();
  }

  /// Foreground/background (the periodic sync only runs in the foreground).
  void setForeground(bool value) {
    _foreground = value;
    if (value && _status.configured) unawaited(_tick());
  }

  /// Re-reads the persisted state into [status].
  Future<SyncStatus> refreshStatus() async {
    final st = await _allState();
    final connected = st[SyncKeys.connected] == '1';
    final lastSync = int.tryParse(st[SyncKeys.lastSyncAt] ?? '');
    final errKind = st[SyncKeys.lastError];
    final kind = errKind == null ? null : SyncErrorKind.values.where((k) => k.name == errKind).firstOrNull;
    final s = SyncStatus(
      phase: !connected
          ? SyncPhase.off
          : _syncing
              ? SyncPhase.syncing
              : kind == null
                  ? SyncPhase.idle
                  : kind == SyncErrorKind.network
                      ? SyncPhase.offline
                      : SyncPhase.error,
      pending: connected ? await pendingCount() : 0,
      lastSyncAt: lastSync == null ? null : DateTime.fromMillisecondsSinceEpoch(lastSync),
      lastError: kind == null ? null : SyncException(kind),
      storeId: connected ? st[SyncKeys.storeId] : null,
      storeName: connected ? st[SyncKeys.storeName] : null,
      environment: connected && st[SyncKeys.storeEnv] != null ? StoreEnvironment.parse(st[SyncKeys.storeEnv]) : null,
      deviceCode: await db.deviceCode(),
      email: st[SyncKeys.email],
      signedIn: st[SyncKeys.refreshToken] != null,
      nextRetryAt: _nextAttemptAt,
    );
    _emit(s);
    return s;
  }

  // ---------------------------------------------------------- sync_state io

  Future<Map<String, String>> _allState() async =>
      {for (final r in await db.select(db.syncState).get()) r.key: r.value};

  Future<String?> _get(String key) async =>
      (await (db.select(db.syncState)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _set(String key, String value) =>
      db.into(db.syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: value));

  Future<void> _del(String key) => (db.delete(db.syncState)..where((s) => s.key.equals(key))).go();

  /// This database's device id (uuid, generated once, kept forever).
  Future<String> deviceId() async {
    final v = await _get(SyncKeys.deviceId);
    if (v != null) return v;
    final id = _uuid.v4();
    await _set(SyncKeys.deviceId, id);
    return id;
  }

  /// Hybrid logical clock (highest version seen), never above
  /// [maxSyncVersion] (a clock poisoned before the bound existed).
  Future<int> _hlc() async => math.min(int.tryParse(await _get(SyncKeys.hlc) ?? '') ?? 0, maxSyncVersion);

  /// Last applied server seq.
  Future<int> pullCursor() async => int.tryParse(await _get(SyncKeys.pullCursor) ?? '') ?? 0;

  Future<bool> isConnected() async => await _get(SyncKeys.connected) == '1';

  /// Distinct entities waiting in the outbox.
  Future<int> pendingCount() async {
    final r = await db
        .customSelect("SELECT COUNT(DISTINCT entity || '/' || entity_id) AS n FROM sync_outbox WHERE synced_at IS NULL")
        .getSingle();
    return r.read<int>('n');
  }

  // ------------------------------------------------------------ transport

  Future<SyncTransport?> _makeTransport({bool silent = false}) async {
    final url = await _get(SyncKeys.endpointUrl);
    final key = await _get(SyncKeys.anonKey);
    final f = _factory;
    if (url == null || key == null || f == null) {
      if (silent) return null;
      throw SyncException(SyncErrorKind.notConfigured);
    }
    return f(SyncEndpoint(url: url, anonKey: key));
  }

  /// Transport with a live session (restored from the stored refresh token).
  Future<SyncTransport> _ready() async {
    final t = _transport ??= await _makeTransport();
    if (t == null) throw SyncException(SyncErrorKind.notConfigured);
    if (t.session == null) {
      final token = await _get(SyncKeys.refreshToken);
      if (token == null) throw SyncException(SyncErrorKind.notSignedIn);
      try {
        await t.restoreSession(token);
      } on SyncException catch (e) {
        if (e.kind == SyncErrorKind.auth) await _del(SyncKeys.refreshToken);
        rethrow;
      }
      await _persistSession();
    }
    return t;
  }

  /// Stores a rotated refresh token (never logged).
  Future<void> _persistSession() async {
    final s = _transport?.session;
    if (s == null) return;
    if (await _get(SyncKeys.refreshToken) != s.refreshToken) await _set(SyncKeys.refreshToken, s.refreshToken);
  }

  Future<T> _exclusive<T>(Future<T> Function() body) async {
    while (_lock != null) {
      try {
        await _lock;
      } catch (_) {}
    }
    final c = Completer<void>();
    _lock = c.future;
    try {
      return await body();
    } finally {
      // Also after a failure: a refresh during the call rotated the refresh
      // token (the old one is revoked), see [_persistSessionQuietly].
      await _persistSessionQuietly();
      _lock = null;
      c.complete();
    }
  }

  /// [_persistSession] that never throws. The transport refreshes an expired
  /// access token by itself and GoTrue rotates the refresh token: the new one
  /// must be stored whatever happens next (a push failing after a successful
  /// refresh), or the next app start restores a revoked token and the
  /// register has to sign in to the cloud again.
  Future<void> _persistSessionQuietly() async {
    try {
      await _persistSession();
    } catch (_) {
      // database closed (tests / shutdown): nothing to keep
    }
  }

  // ------------------------------------------------------------- connect

  /// Signs in to [endpoint] (spec §10 step 1). Stores the endpoint, e-mail and
  /// refresh token — never the password. On a connected database only the
  /// same endpoint is accepted (re-sign-in after «session expired»).
  Future<SyncSession> signIn({required SyncEndpoint endpoint, required String email, required String password}) =>
      _exclusive(() async {
        final f = _factory;
        if (f == null) throw SyncException(SyncErrorKind.notConfigured);
        if (await isConnected()) {
          final url = await _get(SyncKeys.endpointUrl);
          final key = await _get(SyncKeys.anonKey);
          if (url != endpoint.url || key != endpoint.anonKey) throw SyncException(SyncErrorKind.alreadyConnected);
        }
        final t = f(endpoint);
        final session = await t.signIn(email: email.trim(), password: password);
        _transport = t;
        await db.transaction(() async {
          await _set(SyncKeys.endpointUrl, endpoint.url);
          await _set(SyncKeys.anonKey, endpoint.anonKey);
          await _set(SyncKeys.email, session.email);
          await _set(SyncKeys.refreshToken, session.refreshToken);
        });
        await refreshStatus();
        return session;
      });

  /// Stores the signed-in account can join.
  Future<List<StoreInfo>> listStores() async {
    try {
      final t = await _ready();
      return await t.listStores();
    } finally {
      await _persistSessionQuietly();
    }
  }

  /// True when the database has rows in any [businessDataTables] table.
  Future<bool> hasBusinessData() async {
    final sql = businessDataTables.map((t) => 'SELECT 1 FROM $t').join(' UNION ALL ');
    return (await db.customSelect('SELECT EXISTS ($sql) AS e').getSingle()).read<int>('e') == 1;
  }

  Future<bool> _isDemo() async => await db.getSetting('demo_mode') == '1';

  /// Why this database cannot join an existing store (localized), or null.
  /// With [storeId]: reconnecting to the store this database was
  /// disconnected from is allowed even with business data (its own data is
  /// already there; changes made meanwhile are pushed).
  Future<String?> joinBlockReason({String? storeId}) async {
    if (await isConnected()) return SyncException(SyncErrorKind.alreadyConnected).message;
    if (storeId != null && storeId == await _get(SyncKeys.storeId)) return null;
    if (await hasBusinessData()) return SyncException(SyncErrorKind.notEmpty).message;
    return null;
  }

  /// The store this (now disconnected) database was connected to, which it
  /// may rejoin despite having data; null when connected or never connected.
  Future<({String id, String? name})?> previousStore() async {
    if (await isConnected()) return null;
    final id = await _get(SyncKeys.storeId);
    return id == null ? null : (id: id, name: await _get(SyncKeys.storeName));
  }

  /// This database was connected to a `test` store (it may hold test data
  /// pulled from other registers), so it must not seed a production store.
  Future<bool> wasOnTestStore() async => await _get(SyncKeys.storeEnv) == StoreEnvironment.test.wire;

  /// «Создать магазин в облаке»: creates the store (this database becomes its
  /// first register), registers the device (code `A`), enqueues EVERY row of
  /// every synced table and every synced setting, then pushes. A demo
  /// database, or one that was on a test store (test data of other
  /// registers), may only create a `test` store. A store created by an
  /// earlier attempt whose device registration failed is reused.
  Future<StoreInfo> createStoreAndUpload({required String name, required StoreEnvironment environment}) =>
      _exclusive(() async {
        if (await isConnected()) throw SyncException(SyncErrorKind.alreadyConnected);
        if (environment == StoreEnvironment.production) {
          if (await _isDemo()) throw SyncException(SyncErrorKind.environmentMismatch);
          if (await wasOnTestStore()) throw SyncException(SyncErrorKind.testData);
        }
        final t = await _ready();
        final trimmed = name.trim();
        final info = await _reusablePendingStore(t, trimmed, environment) ??
            await t.createStore(name: trimmed, environment: environment);
        await _set(SyncKeys.pendingStore, jsonEncode({'id': info.id, 'name': trimmed, 'env': environment.wire}));
        final devId = await deviceId();
        final reg = await t.registerDevice(storeId: info.id, deviceId: devId, name: deviceName);
        await _persistSession();
        final oldCode = await db.deviceCode();
        final own = AppDatabase.parseOwnShifts(await db.getSetting(AppDatabase.ownShiftsSettingKey));
        await db.transaction(() async {
          await _connect(info, reg.code);
          await _del(SyncKeys.pendingStore);
          await _recodeOwnShifts(oldCode, reg.code, own);
          await enqueueEverything();
        });
        db.notifyUpdates({const TableUpdate('shifts'), const TableUpdate(settingsTable)});
        await refreshStatus();
        _startScheduler();
        try {
          await _runSync();
        } on SyncException {
          // Connected; the upload continues on the next sync (status shows it).
        }
        return info;
      });

  /// A new store gave this database the code [newCode] (D-025): its own
  /// open shift (opened before sync, or under its code in a store it was
  /// disconnected from, or kept after a restore) gets the new code, so it
  /// stays the current shift. Open shifts of OTHER registers of the old
  /// store that happen to carry [newCode] are renamed `<code>~XXXX` (like
  /// duplicate document numbers), so they never become this register's
  /// current shift. Nothing of the old store sees this: the new store
  /// starts from this upload.
  Future<void> _recodeOwnShifts(String? oldCode, String newCode, Set<String> own) async {
    final ownIn = own.isEmpty ? "('')" : '(${List.filled(own.length, '?').join(', ')})';
    if (oldCode != null && oldCode != newCode) {
      await db.customStatement(
          "UPDATE shifts SET device_code = device_code || '~' || upper(substr(id, 1, 4)) "
          "WHERE status = 'open' AND device_code = ? AND id NOT IN $ownIn",
          [newCode, ...own]);
    }
    await db.customStatement(
        "UPDATE shifts SET device_code = ? WHERE status = 'open' "
        'AND (device_code IS NULL OR device_code = ? OR id IN $ownIn)',
        [newCode, oldCode ?? newCode, ...own]);
    await db.customStatement('DELETE FROM settings WHERE key = ?', [AppDatabase.ownShiftsSettingKey]);
  }

  /// The store of an interrupted [createStoreAndUpload] (same name and
  /// environment, still empty), or null.
  Future<StoreInfo?> _reusablePendingStore(SyncTransport t, String name, StoreEnvironment env) async {
    final raw = await _get(SyncKeys.pendingStore);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, Object?>;
      if (m['name'] != name || m['env'] != env.wire) return null;
      final info = await t.storeInfo(m['id']! as String);
      return info.hasData || info.environment != env ? null : info;
    } on SyncException catch (e) {
      if (e.kind == SyncErrorKind.storeNotFound || e.kind == SyncErrorKind.forbidden) {
        await _del(SyncKeys.pendingStore);
        return null;
      }
      rethrow;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// «Подключить к существующему»: only a database without business data (or
  /// one reconnecting to the store it was disconnected from). Registers the
  /// device (next letter code), pulls everything and marks setup done
  /// (`setup_done = 1` after the first complete sync; if that sync fails the
  /// database stays connected and a later [syncNow] finishes the join).
  Future<StoreInfo> joinStore(String storeId) => _exclusive(() async {
        if (await isConnected()) throw SyncException(SyncErrorKind.alreadyConnected);
        final t = await _ready();
        final info = await t.storeInfo(storeId);
        if (info.environment == StoreEnvironment.production && await _isDemo()) {
          throw SyncException(SyncErrorKind.environmentMismatch);
        }
        final reconnect = await _get(SyncKeys.storeId) == storeId;
        if (!reconnect && await hasBusinessData()) throw SyncException(SyncErrorKind.notEmpty);
        final reg = await t.registerDevice(storeId: storeId, deviceId: await deviceId(), name: deviceName);
        await _persistSession();
        await db.transaction(() async {
          await _connect(info, reg.code);
          if (!reconnect) {
            // The outbox of a never-connected database is pruned on open
            // (AppDatabase.pruneUnconnectedOutbox): upload its users,
            // registers and work sessions from the rows themselves.
            await enqueueEverything();
            // Fresh install: the store's settings win over local defaults.
            await db.customStatement("DELETE FROM sync_outbox WHERE entity = 'settings' AND synced_at IS NULL");
            await _set(SyncKeys.joinPending, '1');
            // Users made here before joining (the local setup wizard's
            // owner…) can share a PIN with a store user: salted hashes
            // cannot be compared, and one PIN would log in different people
            // on different registers. They are deactivated after the pull.
            final local = await db
                .customSelect('SELECT id FROM users WHERE is_active = 1 AND deleted_at IS NULL ORDER BY rowid')
                .get();
            if (local.isNotEmpty) {
              await _set(SyncKeys.joinLocalUsers, jsonEncode([for (final r in local) r.read<String>('id')]));
            }
          }
        });
        await refreshStatus();
        _startScheduler();
        await _runSync(); // sets setup_done once everything is pulled
        return info;
      });

  /// A join whose first download has not finished yet (the app was closed
  /// or the network failed): the setup wizard resumes it instead of creating
  /// a local store on a connected database.
  Future<bool> joinPending() async => await isConnected() && await _get(SyncKeys.joinPending) == '1';

  Future<void> _connect(StoreInfo info, String code) async {
    await db.setSetting(deviceCodeSettingKey, code);
    await _set(SyncKeys.storeId, info.id);
    await _set(SyncKeys.storeName, info.name);
    await _set(SyncKeys.storeEnv, info.environment.wire);
    await _set(SyncKeys.pullCursor, '0');
    await _set(SyncKeys.connected, '1');
    await _del(SyncKeys.pushInflight);
    await _del(SyncKeys.lastError);
    await _del(SyncKeys.parked);
  }

  /// Replaces the unsynced outbox with one entry per row of every synced
  /// table (parents first) and per synced setting.
  @visibleForTesting
  Future<void> enqueueEverything() => db.transaction(() async {
        await db.customStatement('DELETE FROM sync_outbox WHERE synced_at IS NULL');
        for (final t in syncedTables) {
          await db.customStatement('INSERT INTO sync_outbox (entity, entity_id, op, at) '
              "SELECT '$t', id, 'upsert', $sqlNowMs FROM $t ORDER BY created_at, rowid");
        }
        final keys = await db.customSelect('SELECT key FROM settings ORDER BY key').get();
        for (final r in keys) {
          final key = r.read<String>('key');
          if (isLocalSettingKey(key)) continue;
          await db.customStatement(
              "INSERT INTO sync_outbox (entity, entity_id, op, at) VALUES ('settings', ?, 'upsert', $sqlNowMs)",
              [key]);
        }
      });

  /// Stops sync, signs out and clears the tokens and the cursor. Keeps all
  /// data, the device id/code (numbers stay unique), the HLC and row
  /// versions, the outbox (changes made while disconnected are pushed after
  /// reconnecting to the same store) and the endpoint/e-mail for convenience.
  Future<void> disconnect() => _exclusive(() async {
        _stopScheduler();
        try {
          await _transport?.signOut();
        } catch (_) {}
        _transport = null;
        await db.transaction(() async {
          for (final k in [
            SyncKeys.connected,
            SyncKeys.refreshToken,
            SyncKeys.pullCursor,
            SyncKeys.pushInflight,
            SyncKeys.lastError,
            SyncKeys.joinPending,
            SyncKeys.parked,
          ]) {
            await _del(k);
          }
        });
        _failures = 0;
        _nextAttemptAt = null;
        await refreshStatus();
      });

  // ---------------------------------------------------------------- sync

  /// Push, then pull (spec §9). One sync at a time: a call while another runs
  /// returns that run. Throws [SyncException]; the status shows the outcome.
  Future<SyncReport> syncNow() {
    final r = _running;
    if (r != null) return r;
    return _exclusive(_runSync);
  }

  Future<SyncReport> _runSync() {
    final f = _running = _doSync();
    return f.whenComplete(() {
      if (identical(_running, f)) _running = null;
    });
  }

  Future<SyncReport> _doSync() async {
    if (!await isConnected()) throw SyncException(SyncErrorKind.notConfigured);
    _syncing = true;
    _emit(_status.copyWith(phase: SyncPhase.syncing));
    final report = SyncReport();
    try {
      final t = await _ready();
      final storeId = (await _get(SyncKeys.storeId))!;
      // Pull first (see the file header), then push under the — possibly
      // new — device id. A reidentification owed by an earlier failed sync
      // is done before anything else.
      await _reidentifyIfPending(t, storeId, report);
      await _pull(t, storeId, await deviceId(), report);
      await _retireJoinLocalUsers(report);
      await _reidentifyIfPending(t, storeId, report);
      report.pushed = await _push(t, storeId, await deviceId());
      await _persistSession();
      await cleanupOutbox();
      await _set(SyncKeys.lastSyncAt, '${DateTime.now().millisecondsSinceEpoch}');
      await _del(SyncKeys.lastError);
      if (await _get(SyncKeys.joinPending) == '1') {
        await db.setSetting('setup_done', '1');
        await _del(SyncKeys.joinPending);
      }
      _failures = 0;
      _nextAttemptAt = null;
      _syncing = false;
      await refreshStatus();
      return report;
    } catch (e, st) {
      _syncing = false;
      final ex = e is SyncException ? e : SyncException(SyncErrorKind.protocol, detail: e.runtimeType.toString(), cause: e);
      _failures++;
      _nextAttemptAt = DateTime.now().add(schedule.backoff(_failures));
      try {
        await _set(SyncKeys.lastError, ex.kind.name);
        await refreshStatus();
      } catch (_) {}
      _emit(_status.copyWith(
          phase: ex.isTransient ? SyncPhase.offline : SyncPhase.error, lastError: ex, nextRetryAt: _nextAttemptAt));
      if (e is SyncException) rethrow;
      Error.throwWithStackTrace(ex, st);
    }
  }

  /// After the first complete pull of a join: the users this database had
  /// before joining ([SyncKeys.joinLocalUsers]) are deactivated (and their
  /// open work sessions ended) before they are pushed, so no register ever
  /// sees them active. Their PINs could match a store user's PIN; the
  /// store's users are the ones to log in with (an owner may activate one
  /// again with a new PIN, which checks uniqueness). Only when the store
  /// has an active owner / admin of its own: a join never locks everybody
  /// out. Surfaced as a [SyncConflictKind.joinUsers] conflict.
  Future<void> _retireJoinLocalUsers(SyncReport report) async {
    final raw = await _get(SyncKeys.joinLocalUsers);
    if (raw == null) return;
    var ids = const <String>[];
    try {
      ids = [for (final e in jsonDecode(raw) as List) e as String];
    } on Object {
      // unreadable: nothing to do
    }
    final retired = await db.transaction(() async {
      await _del(SyncKeys.joinLocalUsers);
      if (ids.isEmpty) return false;
      final marks = List.filled(ids.length, '?').join(', ');
      final storeAdmin = await db.customSelect(
          'SELECT 1 FROM users WHERE is_active = 1 AND deleted_at IS NULL '
          "AND role IN ('owner', 'admin') AND id NOT IN ($marks) LIMIT 1",
          variables: [for (final id in ids) Variable.withString(id)]).get();
      if (storeAdmin.isEmpty) return false;
      final local = await (db.select(db.users)
            ..where((u) => u.id.isIn(ids) & u.isActive.equals(true) & u.deletedAt.isNull())
            ..orderBy([(u) => OrderingTerm.asc(u.name)]))
          .get();
      if (local.isEmpty) return false;
      final now = DateTime.now();
      final localIds = [for (final u in local) u.id];
      await (db.update(db.users)..where((u) => u.id.isIn(localIds)))
          .write(UsersCompanion(isActive: const Value(false), updatedAt: Value(now)));
      await (db.update(db.workSessions)
            ..where((w) => w.userId.isIn(localIds) & w.endedAt.isNull() & w.deletedAt.isNull()))
          .write(WorkSessionsCompanion(endedAt: Value(now), updatedAt: Value(now)));
      for (final u in local) {
        await db.audit('user.deactivate', entity: 'user', entityId: u.id, details: SyncConflictKind.joinUsers);
      }
      await _record(_Conflict(SyncConflictKind.joinUsers, 'users', local.first.id,
          SyncConflictPayload.joinUsers(names: [for (final u in local) u.name])));
      return true;
    });
    if (!retired) return;
    report.conflicts++;
    db.notifyUpdates({
      const TableUpdate('users'),
      const TableUpdate('work_sessions'),
      const TableUpdate('notifications'),
      const TableUpdate('sync_conflicts'),
    });
  }

  /// Deletes outbox rows synced more than [age] ago (local bookkeeping only).
  Future<int> cleanupOutbox({Duration age = const Duration(days: 7)}) => (db.delete(db.syncOutbox)
        ..where((o) => o.syncedAt.isNotNull() & o.syncedAt.isSmallerThanValue(DateTime.now().subtract(age))))
      .go();

  // ---------------------------------------------------------------- push

  Future<int> _push(SyncTransport t, String storeId, String devId) async {
    var total = 0;
    while (true) {
      final batch = await _preparePush(devId);
      if (batch == null) break;
      if (batch.changes.isNotEmpty) {
        await t.push(storeId: storeId, deviceId: devId, changes: batch.changes);
      }
      final now = DateTime.now();
      await db.transaction(() async {
        for (final g in batch.groups) {
          await (db.update(db.syncOutbox)
                ..where((o) =>
                    o.syncedAt.isNull() &
                    o.entity.equals(g.entity) &
                    o.entityId.equals(g.entityId) &
                    o.seq.isSmallerOrEqualValue(g.last)))
              .write(SyncOutboxCompanion(syncedAt: Value(now)));
        }
        await _del(SyncKeys.pushInflight);
        await _set(SyncKeys.lastPushAt, '${now.millisecondsSinceEpoch}');
      });
      total += batch.changes.length;
    }
    return total;
  }

  /// Next batch of collapsed outbox entities with their current rows, or
  /// null when nothing is pending. Assigns versions (reusing those of an
  /// unconfirmed earlier attempt) and records them in `sync_row_versions`.
  ///
  /// The current row is sent, so it may point at a parent created after it
  /// (a product moved to a new category): such pending parents are put into
  /// the batch first, so the server order never has a child before its
  /// parent (spec §9).
  Future<_PreparedPush?> _preparePush(String devId) => db.transaction(() async {
        final rows = await db.customSelect(
            'SELECT entity, entity_id, MIN(seq) AS first FROM sync_outbox '
            'WHERE synced_at IS NULL GROUP BY entity, entity_id ORDER BY first LIMIT ?',
            variables: [Variable.withInt(pushBatchSize)]).get();
        if (rows.isEmpty) return null;
        final inflightRaw = await _get(SyncKeys.pushInflight);
        final inflight = inflightRaw == null ? const <String, Object?>{} : jsonDecode(inflightRaw) as Map<String, Object?>;
        final newInflight = <String, Object?>{};
        var hlc = await _hlc();
        final changes = <SyncChange>[];
        final groups = <_Group>[];
        final visited = <String>{};
        final parents = await _parentsMap();

        Future<void> add(String entity, String entityId) async {
          if (!visited.add('$entity\u0000$entityId')) return;
          final r = await db.customSelect(
              "SELECT MAX(seq) AS last, MAX(at) AS at, MAX(op IN ('upsert', 'delete')) AS u, MAX(op = 'stat') AS s "
              'FROM sync_outbox WHERE synced_at IS NULL AND entity = ? AND entity_id = ?',
              variables: [Variable.withString(entity), Variable.withString(entityId)]).getSingle();
          final last = r.readNullable<int>('last');
          if (last == null) return; // not pending
          final g = _Group(entity, entityId, last, r.read<int>('at'),
              user: r.read<int>('u') == 1, stat: r.read<int>('s') == 1);
          Map<String, Object?>? payload;
          if (g.entity == settingsTable) {
            groups.add(g);
            if (isLocalSettingKey(g.entityId)) return;
            final s = await db
                .customSelect('SELECT key, value FROM settings WHERE key = ?', variables: [Variable.withString(g.entityId)])
                .getSingleOrNull();
            payload = s == null ? null : await _sanitize(g.entity, g.entityId, Map<String, Object?>.from(s.data));
          } else if (syncedTables.contains(g.entity)) {
            final s = await db
                .customSelect('SELECT * FROM ${g.entity} WHERE id = ?', variables: [Variable.withString(g.entityId)])
                .getSingleOrNull();
            payload = s == null ? null : await _sanitize(g.entity, g.entityId, Map<String, Object?>.from(s.data));
            if (payload != null) {
              for (final fk in parents[g.entity] ?? const <_Fk>[]) {
                final v = payload[fk.column];
                if (v is String && syncedTables.contains(fk.table)) await add(fk.table, v);
              }
              // The document an effect row belongs to (no FK) goes first
              // too: another register never holds a reversal / count
              // correction while the document still says «posted» / «draft».
              final soft = _docOfEffect[(g.entity, payload['ref_type'])];
              final ref = payload['ref_id'];
              if (soft != null && ref is String) await add(soft, ref);
            }
            groups.add(g);
          } else {
            groups.add(g);
            return; // not synced (stale outbox entry): just mark it
          }
          final prev = inflight[g.key];
          String changeId;
          int version;
          if (prev is Map && prev['last'] == g.last) {
            changeId = prev['id'] as String;
            version = (prev['v'] as num).toInt();
          } else {
            changeId = _uuid.v4();
            version = math.min(math.max(g.at, hlc + 1), maxSyncVersion);
          }
          if (version > hlc) hlc = version;
          newInflight[g.key] = {'id': changeId, 'v': version, 'last': g.last};
          final parts = payload == null
              ? const [_Part.user]
              : [if (g.user) _Part.user, if (g.stat) _Part.stat];
          if (payload != null && statColumns.containsKey(g.entity) && parts.length == 1) {
            payload[syncPartsKey] = parts.single == _Part.user ? 'u' : 's';
          }
          changes.add(SyncChange(
            changeId: changeId,
            entity: g.entity,
            entityId: g.entityId,
            op: payload == null ? SyncOp.delete : SyncOp.upsert,
            version: version,
            deviceId: devId,
            payload: payload,
          ));
          for (final p in parts) {
            await db.into(db.syncRowVersions).insertOnConflictUpdate(SyncRowVersionsCompanion.insert(
                entity: _versionKey(g.entity, p), entityId: g.entityId, version: version, deviceId: devId));
          }
        }

        for (final r in rows) {
          await add(r.read<String>('entity'), r.read<String>('entity_id'));
        }
        await _set(SyncKeys.hlc, '$hlc');
        await _set(SyncKeys.pushInflight, jsonEncode(newInflight));
        return _PreparedPush(changes, groups);
      });

  /// Postgres refuses U+0000 in jsonb text (the push would fail forever on
  /// that row): strips it from the payload and from the local row (with the
  /// triggers suppressed), so every register keeps the same text.
  Future<Map<String, Object?>> _sanitize(String entity, String id, Map<String, Object?> payload) async {
    final dirty = [
      for (final e in payload.entries)
        if (e.value is String && (e.value! as String).contains('\u0000')) e.key,
    ];
    if (dirty.isEmpty) return payload;
    for (final k in dirty) {
      payload[k] = (payload[k]! as String).replaceAll('\u0000', '');
    }
    await db.withSyncSuppressed(() async {
      if (entity == settingsTable) {
        await db.customStatement('UPDATE settings SET value = ? WHERE key = ?', [payload['value'], id]);
      } else {
        await db.customStatement('UPDATE $entity SET ${dirty.map((k) => '"$k" = ?').join(', ')} WHERE id = ?',
            [for (final k in dirty) payload[k], id]);
      }
    });
    return payload;
  }

  // ---------------------------------------------------------------- pull

  Future<void> _pull(SyncTransport t, String storeId, String devId, SyncReport report) async {
    var cursor = await pullCursor();
    while (true) {
      final page = await t.pull(storeId: storeId, since: cursor, max: pullBatchSize);
      if (page.changes.isEmpty) break;
      await _applyBatch(page.changes, devId, report);
      report.pulled += page.changes.length;
      cursor = page.lastSeq ?? cursor;
      if (page.changes.length < pullBatchSize) break;
    }
  }

  Future<void> _reidentifyIfPending(SyncTransport t, String storeId, SyncReport report) async {
    if (await _get(SyncKeys.reidentifyPending) == '1') await _reidentify(t, storeId, report);
  }

  /// This file is a restored backup or a copy of a register that kept
  /// working (the server has changes of this device id the file did not
  /// know). Those changes were applied like anyone's; from now on this
  /// database is a register of its own: new device id and code, so its
  /// documents never reuse numbers of the original (D-025).
  ///
  /// The open shifts with the old code stay this database's current shift
  /// ([AppDatabase.ownShiftsSettingKey], device-local): after a restore the
  /// drawer's cash is in that shift. The rows themselves keep their code —
  /// for a copy whose original still works the shift is the original's too,
  /// and re-coding it would take it away from that register.
  Future<void> _reidentify(SyncTransport t, String storeId, SyncReport report) async {
    final id = _uuid.v4();
    final reg = await t.registerDevice(storeId: storeId, deviceId: id, name: deviceName);
    final old = await db.deviceCode();
    await db.transaction(() async {
      await _set(SyncKeys.deviceId, id);
      await db.setSetting(deviceCodeSettingKey, reg.code);
      if (old != null) {
        final open = await db.customSelect("SELECT id FROM shifts WHERE status = 'open' AND device_code = ?",
            variables: [Variable.withString(old)]).get();
        final own = {
          ...AppDatabase.parseOwnShifts(await db.getSetting(AppDatabase.ownShiftsSettingKey)),
          for (final r in open) r.read<String>('id'),
        };
        if (own.isNotEmpty) await db.setSetting(AppDatabase.ownShiftsSettingKey, own.join(','));
      }
      await _del(SyncKeys.pushInflight);
      await _del(SyncKeys.reidentifyPending);
      await _record(_Conflict(
          SyncConflictKind.identity, 'devices', id, SyncConflictPayload.identity(oldCode: old, newCode: reg.code)));
    });
    report.reidentified = true;
    db.notifyUpdates({
      const TableUpdate('notifications'),
      const TableUpdate('sync_conflicts'),
      const TableUpdate(settingsTable),
    });
  }

  final _columnsCache = <String, Map<String, _Col>>{};
  Map<String, List<({String table, String column})>>? _referencedBy;
  Map<String, List<_Fk>>? _parentsOf;

  Future<Map<String, _Col>> _columnInfo(String table) async => _columnsCache[table] ??= {
        for (final r in await db.customSelect('PRAGMA table_info($table)').get())
          r.read<String>('name'): _Col(
            r.read<String>('type').toUpperCase(),
            notNull: r.read<int>('notnull') == 1,
            hasDefault: r.data['dflt_value'] != null,
          ),
      };

  /// Checks (and normalises) the values of a remote row against the local
  /// columns before they are bound: only scalars of the column's type (a
  /// whole double is taken for an integer column, a JSON boolean as 0/1),
  /// no null in a NOT NULL column, and on insert every required column.
  /// SQLite would store `'abc'` in an INTEGER column, and every typed read
  /// of the table would then fail. Throws [_Rejected].
  static void _validate(Map<String, _Col> cols, Map<String, Object?> data, {required bool insert}) {
    for (final k in data.keys.toList()) {
      final col = cols[k]!;
      var v = data[k];
      if (v is bool) v = data[k] = v ? 1 : 0;
      if (v == null) {
        if (col.notNull) throw const _Rejected();
        continue;
      }
      if (v is! String && v is! num) throw const _Rejected();
      final t = col.type;
      if (t.contains('INT')) {
        if (v is double) {
          if (!v.isFinite || v != v.truncateToDouble()) throw const _Rejected();
          data[k] = v.toInt();
        } else if (v is! int) {
          throw const _Rejected();
        }
      } else if (t.contains('REAL') || t.contains('FLOA') || t.contains('DOUB')) {
        if (v is! num || (v is double && !v.isFinite)) throw const _Rejected();
      } else if (t.contains('CHAR') || t.contains('CLOB') || t.contains('TEXT')) {
        if (v is! String) throw const _Rejected();
      }
    }
    if (insert) {
      for (final e in cols.entries) {
        if (e.value.notNull && !e.value.hasDefault && data[e.key] == null) throw const _Rejected();
      }
    }
  }

  /// A failure of one remote change that means «this change cannot be
  /// stored here» (skip it), not «this database cannot write» (retry later).
  static bool _rejectable(Object e) {
    final cause = e is DriftRemoteException ? e.remoteCause : e;
    if (cause is _Rejected || cause is ArgumentError || cause is TypeError || cause is FormatException) return true;
    if (cause is SqliteException) {
      // busy, locked, out of memory, I/O, corrupt, full, cannot open
      const local = {5, 6, 7, 10, 11, 13, 14};
      return !local.contains(cause.resultCode & 0xff);
    }
    return false;
  }

  /// Pushes the local rows that lost a collision in this page ([_Owed]),
  /// unless a newer change of that row was applied after it.
  Future<void> _enqueueOwed(List<_Owed> owed) async {
    for (final o in owed) {
      if (!await _exists(o.table, o.id)) continue;
      final v = await (db.select(db.syncRowVersions)
            ..where((r) => r.entity.equals(o.table) & r.entityId.equals(o.id)))
          .getSingleOrNull();
      if (v != null && v.version >= o.at) continue;
      await db.customStatement(
          "INSERT INTO sync_outbox (entity, entity_id, op, at) VALUES (?, ?, 'upsert', ?)", [o.table, o.id, o.at]);
    }
  }

  /// parent table → (child table, FK column) over the synced tables.
  Future<Map<String, List<({String table, String column})>>> _fkMap() async {
    final cached = _referencedBy;
    if (cached != null) return cached;
    final out = <String, List<({String table, String column})>>{};
    for (final child in syncedTables) {
      for (final r in await db.customSelect('PRAGMA foreign_key_list($child)').get()) {
        out.putIfAbsent(r.read<String>('table'), () => []).add((table: child, column: r.read<String>('from')));
      }
    }
    return _referencedBy = out;
  }

  /// child table → its foreign keys (column → parent table/column).
  Future<Map<String, List<_Fk>>> _parentsMap() async {
    final cached = _parentsOf;
    if (cached != null) return cached;
    final out = <String, List<_Fk>>{};
    for (final child in syncedTables) {
      for (final r in await db.customSelect('PRAGMA foreign_key_list($child)').get()) {
        out.putIfAbsent(child, () => []).add(
            _Fk(r.read<String>('from'), r.read<String>('table'), r.readNullable<String>('to') ?? 'id'));
      }
    }
    return _parentsOf = out;
  }

  /// Every non-null FK value among [keys] of [data] exists locally.
  Future<bool> _parentsPresent(String table, Map<String, Object?> data, Iterable<String> keys) async {
    final fks = (await _parentsMap())[table];
    if (fks == null) return true;
    final ks = keys.toSet();
    for (final fk in fks) {
      if (!ks.contains(fk.column)) continue;
      final v = data[fk.column];
      if (v == null) continue;
      if (fk.table == table && v == data['id']) continue;
      final hit = await db
          .customSelect('SELECT 1 FROM ${fk.table} WHERE "${fk.to}" = ? LIMIT 1', variables: [Variable(v)]).get();
      if (hit.isEmpty) return false;
    }
    return true;
  }

  Future<List<SyncChange>> _loadParked() async {
    final raw = await _get(SyncKeys.parked);
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List) SyncChange.fromJson(Map<String, Object?>.from(e as Map)),
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> _saveParked(List<SyncChange> list) =>
      list.isEmpty ? _del(SyncKeys.parked) : _set(SyncKeys.parked, jsonEncode([for (final c in list) c.toJson()]));

  /// Remote changes waiting for their parent rows.
  Future<int> parkedCount() async => (await _loadParked()).length;

  /// Applies one pull page in one transaction (spec §9), advancing the cursor
  /// in the same transaction. A change whose parent row is not here yet (it
  /// comes later, or a register sent the child first) is parked and retried
  /// with the next pages instead of failing the page forever. A change of
  /// this device id newer than the local row sets
  /// [SyncKeys.reidentifyPending] in the same transaction (see
  /// [_reidentify]).
  Future<void> _applyBatch(List<SyncChange> page, String devId, SyncReport report) async {
    final touched = <String, Set<String>>{};
    final conflicts = <_Conflict>[];
    final flags = _ApplyFlags();
    final owed = <_Owed>[];
    await db.withSyncSuppressed(() async {
      await db.customStatement('PRAGMA defer_foreign_keys = ON');
      var hlc = await _hlc();
      var deferred = <SyncChange>[];
      // Each change in its own savepoint: one this database cannot store
      // (wrong value type, missing column, broken constraint — a broken or
      // newer client, or a hand-made push) is rolled back alone, recorded
      // and skipped, so it never blocks the pull, the cursor or the push.
      Future<bool> run(SyncChange c) async {
        final conflictMark = conflicts.length, owedMark = owed.length, ownNewer = flags.ownNewer;
        await db.customStatement('SAVEPOINT sync_change');
        _Outcome outcome;
        try {
          if (c.version < 0 || c.version > maxSyncVersion) throw const _Rejected();
          outcome = await _applyOne(c, devId, touched, conflicts, flags, owed);
          await db.customStatement('RELEASE sync_change');
        } on Object catch (e) {
          if (!_rejectable(e)) rethrow;
          await db.customStatement('ROLLBACK TO sync_change');
          await db.customStatement('RELEASE sync_change');
          conflicts
            ..length = conflictMark
            ..add(_Conflict(SyncConflictKind.rejected, c.entity, c.entityId,
                SyncConflictPayload.rejected(entity: c.entity, id: c.entityId)));
          owed.length = owedMark;
          flags.ownNewer = ownNewer;
          report.rejected++;
          return false;
        }
        switch (outcome) {
          case _Outcome.applied:
            report.applied++;
          case _Outcome.skipped:
            report.skipped++;
          case _Outcome.deferred:
            deferred.add(c);
        }
        return true;
      }

      for (final c in await _loadParked()) {
        await run(c);
      }
      for (var i = 0; i < page.length; i++) {
        final c = page[i];
        final hook = debugBeforeApply;
        if (hook != null) await hook(i, c);
        if (await run(c) && c.version > hlc) hlc = c.version;
      }
      // Parents that came later in the page: retry until nothing moves.
      while (deferred.isNotEmpty) {
        final again = deferred;
        deferred = [];
        for (final c in again) {
          await run(c);
        }
        if (deferred.length == again.length) break;
      }
      await _saveParked(deferred);
      report.parked = deferred.length;
      await _trimDraftOrderLines(touched);
      await _enqueueOwed(owed);
      final changed = await SyncAggregates.recompute(db, touched);
      conflicts.addAll(await _negativeConflicts(changed));
      conflicts.addAll(await _returnConflicts(touched));
      conflicts.addAll(await _voidRedeemConflicts(touched));
      for (final k in conflicts) {
        await _record(k);
      }
      report.conflicts += conflicts.length;
      if (flags.ownNewer) await _set(SyncKeys.reidentifyPending, '1');
      await _set(SyncKeys.hlc, '$hlc');
      await _set(SyncKeys.pullCursor, '${page.last.seq ?? 0}');
      await _set(SyncKeys.lastPullAt, '${DateTime.now().millisecondsSinceEpoch}');
    });
    final updates = <TableUpdate>{
      for (final t in touched.keys) TableUpdate(t),
      // recompute may have changed owners of touched children
      for (final t in cachedColumns.keys) TableUpdate(t),
      if (flags.settingsChanged) const TableUpdate(settingsTable),
      if (conflicts.isNotEmpty) ...{const TableUpdate('notifications'), const TableUpdate('sync_conflicts')},
    };
    if (updates.isNotEmpty) db.notifyUpdates(updates);
  }

  /// Parts an upsert carries ([syncPartsKey]; tables without stat columns
  /// have only the user part).
  Set<_Part> _partsOf(SyncChange c) {
    if (!statColumns.containsKey(c.entity)) return const {_Part.user};
    return switch (c.payload?[syncPartsKey]) {
      'u' => const {_Part.user},
      's' => const {_Part.stat},
      _ => const {_Part.user, _Part.stat},
    };
  }

  /// One remote change. Own changes go through the same LWW: normally the
  /// local row already has that version and they are skipped; a newer one
  /// means this file was restored or copied ([_ApplyFlags.ownNewer]).
  Future<_Outcome> _applyOne(SyncChange c, String devId, Map<String, Set<String>> touched, List<_Conflict> conflicts,
      _ApplyFlags flags, List<_Owed> owed) async {
    final isSettings = c.entity == settingsTable;
    if (!isSettings && !syncedTables.contains(c.entity)) return _Outcome.skipped; // a table this build does not know
    if (isSettings && isLocalSettingKey(c.entityId)) return _Outcome.skipped;
    final own = c.deviceId == devId;
    if (c.op == SyncOp.delete && c.entity == 'purchase_order_items' && await _lineOfWinningRevision(c.entityId)) {
      // Only a draft save deletes order lines, and every save writes a new
      // `lines_rev`. A deleted line that still has the header's revision
      // was deleted by a save that lost (to a newer save or to the order
      // being sent / received meanwhile, see [initialStatus]): keep it and
      // send it again, so the register that deleted it gets it back.
      await db.customStatement(
          "INSERT INTO sync_outbox (entity, entity_id, op, at) VALUES ('purchase_order_items', ?, 'upsert', $sqlNowMs)",
          [c.entityId]);
      return _Outcome.skipped;
    }
    if (isSettings || c.op == SyncOp.delete) {
      if (await _localWins(c, _Part.user)) return _Outcome.skipped;
      if (isSettings) {
        if (c.op == SyncOp.delete) {
          await db.customStatement('DELETE FROM settings WHERE key = ?', [c.entityId]);
        } else {
          final v = c.payload?['value'];
          if (v != null && v is! String && v is! num) throw const _Rejected();
          await db.customStatement(
              'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [c.entityId, '${c.payload?['value'] ?? ''}']);
        }
        flags.settingsChanged = true;
      } else {
        await _applyDelete(c, touched);
      }
      await _won(c, const [_Part.user]);
      if (own) flags.ownNewer = true;
      return _Outcome.applied;
    }

    final table = c.entity;
    final cols = await _columnInfo(table);
    final data = <String, Object?>{
      for (final e in (c.payload ?? const {}).entries)
        if (cols.containsKey(e.key)) e.key: e.value,
    };
    data['id'] = c.entityId;
    final row = (await db
            .customSelect('SELECT * FROM $table WHERE id = ?', variables: [Variable.withString(c.entityId)])
            .getSingleOrNull())
        ?.data;
    _validate(cols, data, insert: row == null);

    if (row == null) {
      // New here (or deleted here later: then the delete's version wins).
      if (await _localWins(c, _Part.user)) return _Outcome.skipped;
      if (!await _parentsPresent(table, data, data.keys)) return _Outcome.deferred;
      final changedLocal = await _resolveUnique(c, data, conflicts, owed);
      if (changedLocal != null) touched.putIfAbsent(table, () => {}).add(changedLocal);
      final keys = data.keys.toList();
      await db.customStatement(
          'INSERT INTO $table (${keys.map((k) => '"$k"').join(', ')}) VALUES (${List.filled(keys.length, '?').join(', ')})',
          [for (final k in keys) data[k]]);
      touched.putIfAbsent(table, () => {}).add(c.entityId);
      await _won(c, [_Part.user, if (statColumns.containsKey(table)) _Part.stat]);
      if (own) flags.ownNewer = true;
      return _Outcome.applied;
    }

    // Existing row: the user part and the stat part are merged on their own
    // versions; cached columns are never taken (recomputed after the page).
    final parts = _partsOf(c);
    var userWin = parts.contains(_Part.user) && !await _localWins(c, _Part.user);
    final initial = initialStatus[table];
    if (initial != null && parts.contains(_Part.user) && data.containsKey('status')) {
      // A document never returns to its initial status: an edit made while
      // it was still a draft loses to the order being sent / received /
      // cancelled on another register, whatever the versions say.
      final localInitial = row['status'] == initial, incomingInitial = data['status'] == initial;
      if (!localInitial && incomingInitial) userWin = false;
      if (localInitial && !incomingInitial) userWin = true;
    }
    final statWin = parts.contains(_Part.stat) && !await _localWins(c, _Part.stat);
    final stat = statColumns[table] ?? const <String>{};
    final cached = cachedColumns[table] ?? const <String>{};
    final statusSet = statStatuses[table];
    final bothInSet = statusSet != null && statusSet.contains(row['status']) && statusSet.contains(data['status']);
    final set = <String, Object?>{};
    String? changedLocal;
    if (userWin) {
      final keys = [
        for (final k in data.keys)
          if (k != 'id' && k != 'updated_at' && !stat.contains(k) && !(k == 'status' && bothInSet)) k,
      ];
      if (!await _parentsPresent(table, data, keys)) return _Outcome.deferred;
      changedLocal = await _resolveUnique(c, data, conflicts, owed);
      for (final k in keys) {
        set[k] = data[k];
      }
    }
    if (statWin) {
      for (final k in stat) {
        if (!cached.contains(k) && data.containsKey(k)) set[k] = data[k];
      }
      if (bothInSet) set['status'] = data['status'];
    }
    // A void is irreversible: whichever register voided, the row stays
    // voided, whatever the versions say.
    final sticky = stickyStatus[table];
    if (sticky != null) {
      if (row['status'] == sticky.value) {
        if (set.containsKey('status') && set['status'] != sticky.value) {
          for (final k in sticky.columns) {
            set.remove(k);
          }
          // The newer change wins the rest of the row and supersedes a
          // pending local edit — possibly the very void / reversal /
          // completion that made the row sticky here: send the row again,
          // or the other registers never learn it.
          owed.add(_Owed(table, c.entityId, c.version + 1));
        } else if (table == 'gift_card_sales' &&
            data['status'] == sticky.value &&
            data['void_shift_id'] != null &&
            row['void_shift_id'] != null &&
            data['void_shift_id'] != row['void_shift_id']) {
          // Voided on two registers: one void is kept (LWW), but both gave
          // the money back; the other shift's report does not show it.
          final lost = set.containsKey('void_shift_id') ? row['void_shift_id'] : data['void_shift_id'];
          conflicts.add(await _doubleVoidConflict(c.entityId, row, lost! as String));
        }
      } else if (data['status'] == sticky.value) {
        for (final k in sticky.columns) {
          if (data.containsKey(k)) set[k] = data[k];
        }
      }
    }
    final upd = data['updated_at'];
    final assignments = [
      for (final k in set.keys) '"$k" = ?',
      // The latest write anywhere (independent of the order of arrival).
      if (upd != null) 'updated_at = max(updated_at, ?)',
    ];
    if (assignments.isNotEmpty) {
      await db.customStatement('UPDATE $table SET ${assignments.join(', ')} WHERE id = ?',
          [...set.values, ?upd, c.entityId]);
    }
    if (changedLocal != null) touched.putIfAbsent(table, () => {}).add(changedLocal);
    if (set.isNotEmpty) touched.putIfAbsent(table, () => {}).add(c.entityId);
    if (!userWin && !statWin) return _Outcome.skipped;
    final hadPending = (userWin && await _pendingAt(table, c.entityId, _Part.user) != null) ||
        (statWin && await _pendingAt(table, c.entityId, _Part.stat) != null);
    await _won(c, [if (userWin) _Part.user, if (statWin) _Part.stat]);
    if (own) flags.ownNewer = true;
    final localUpd = row['updated_at'];
    if (hadPending &&
        upd is int &&
        localUpd is int &&
        localUpd > upd &&
        await _pendingAt(table, c.entityId, _Part.user) == null &&
        await _pendingAt(table, c.entityId, _Part.stat) == null) {
      // The superseded local edit was never pushed, but it left a later
      // `updated_at` here (merged as the maximum everywhere): send the row
      // (now the winner's values) once more, or this register keeps a
      // different `updated_at` from all the others.
      await db.customStatement('INSERT INTO sync_outbox (entity, entity_id, op, at) VALUES (?, ?, ?, $sqlNowMs)',
          [table, c.entityId, statColumns.containsKey(table) ? 'stat' : 'upsert']);
    }
    return _Outcome.applied;
  }

  /// Records the versions of the parts [c] won and drops the pending local
  /// edits of those parts (superseded).
  Future<void> _won(SyncChange c, List<_Part> parts) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final p in parts) {
      await db.into(db.syncRowVersions).insertOnConflictUpdate(SyncRowVersionsCompanion.insert(
          entity: _versionKey(c.entity, p), entityId: c.entityId, version: c.version, deviceId: c.deviceId));
      await db.customStatement(
          'UPDATE sync_outbox SET synced_at = ? WHERE synced_at IS NULL AND entity = ? AND entity_id = ? '
          'AND op IN ${_opsOf(p)}',
          [now, c.entity, c.entityId]);
    }
  }

  /// LWW of one part (spec §3): the local row wins when its version is
  /// higher (ties by device id), or when it has an unpushed local edit of
  /// that part newer than the remote version.
  Future<bool> _localWins(SyncChange c, _Part part) async {
    final v = await (db.select(db.syncRowVersions)
          ..where((r) => r.entity.equals(_versionKey(c.entity, part)) & r.entityId.equals(c.entityId)))
        .getSingleOrNull();
    if (v != null) {
      if (c.version < v.version) return true;
      if (c.version == v.version && c.deviceId.compareTo(v.deviceId) <= 0) return true;
    }
    final pendingAt = await _pendingAt(c.entity, c.entityId, part);
    return pendingAt != null && pendingAt > c.version;
  }

  Future<int?> _pendingAt(String entity, String id, _Part part) async => (await db
          .customSelect(
              'SELECT MAX(at) AS at FROM sync_outbox WHERE entity = ? AND entity_id = ? AND synced_at IS NULL '
              'AND op IN ${_opsOf(part)}',
              variables: [Variable.withString(entity), Variable.withString(id)])
          .getSingle())
      .readNullable<int>('at');

  Future<bool> _exists(String table, String id) async =>
      (await db.customSelect('SELECT 1 FROM $table WHERE id = ?', variables: [Variable.withString(id)]).get()).isNotEmpty;

  /// The order line exists and belongs to its header's current line set.
  Future<bool> _lineOfWinningRevision(String id) async => (await db.customSelect(
          'SELECT 1 FROM purchase_order_items i JOIN purchase_orders o ON o.id = i.order_id '
          'WHERE i.id = ? AND i.lines_rev IS NOT NULL AND i.lines_rev = o.lines_rev',
          variables: [Variable.withString(id)]).get())
      .isNotEmpty;

  Future<_Conflict> _doubleVoidConflict(String saleId, Map<String, Object?> row, String lostShiftId) async {
    final card = await db.customSelect('SELECT code FROM gift_cards WHERE id = ?',
        variables: [Variable.withString('${row['gift_card_id']}')]).getSingleOrNull();
    final code = card?.read<String>('code') ?? '—';
    final shift = await db.customSelect('SELECT number, device_code FROM shifts WHERE id = ?',
        variables: [Variable.withString(lostShiftId)]).getSingleOrNull();
    return _Conflict(
        SyncConflictKind.doubleVoid,
        'gift_card_sales',
        saleId,
        SyncConflictPayload.doubleVoid(
          giftCode: code,
          number: row['number']! as int,
          code: row['device_code'] as String?,
          amount: row['amount']! as int,
          shiftNumber: shift?.read<int>('number'),
          shiftCode: shift?.readNullable<String>('device_code'),
        ));
  }

  /// Gift cards whose sale was voided (money refunded) while they were spent
  /// on another register: the balance is 0 by definition, so the negative
  /// balance check never sees it (spec §6: surfaced, not prevented).
  Future<List<_Conflict>> _voidRedeemConflicts(Map<String, Set<String>> touched) async {
    final t = await SyncAggregates.resolveTargets(db, touched);
    if (t.giftCards.isEmpty) return const [];
    final out = <_Conflict>[];
    final ids = t.giftCards.toList();
    for (var i = 0; i < ids.length; i += 500) {
      final part = ids.sublist(i, math.min(i + 500, ids.length));
      final rows = await db.customSelect(
          'SELECT g.id, g.code, '
          '(SELECT COALESCE(SUM(p.amount), 0) FROM sale_payments p JOIN sales s ON s.id = p.sale_id '
          "WHERE p.method = 'gift_card' AND (p.gift_card_id = g.id OR (p.gift_card_id IS NULL AND p.reference = g.code)) "
          "AND s.status <> 'voided' AND p.deleted_at IS NULL AND s.deleted_at IS NULL) AS redeemed "
          'FROM gift_cards g WHERE g.id IN (${List.filled(part.length, '?').join(', ')}) AND EXISTS '
          "(SELECT 1 FROM gift_card_sales v WHERE v.gift_card_id = g.id AND v.status = 'voided' AND v.deleted_at IS NULL)",
          variables: [for (final id in part) Variable.withString(id)]).get();
      for (final r in rows) {
        final redeemed = r.read<int>('redeemed');
        if (redeemed <= 0) continue;
        out.add(_Conflict(SyncConflictKind.voidRedeem, 'gift_cards', r.read<String>('id'),
            SyncConflictPayload.voidRedeem(code: r.read<String>('code'), amount: redeemed)));
      }
    }
    return out;
  }

  /// A change version (millisecond clock) as a `deleted_at` value (seconds).
  static int _versionSeconds(int version) => version ~/ 1000;

  /// (effect table, `ref_type`) → document table of `ref_id`: pushed before
  /// the effect rows ([_preparePush]).
  static const _docOfEffect = <(String, Object?), String>{
    ('stock_movements', 'receipt'): 'goods_receipts',
    ('stock_movements', 'count'): 'inventory_counts',
    ('supplier_ledger', 'goods_receipt'): 'goods_receipts',
    ('supplier_ledger', 'supplier_payment'): 'supplier_payments',
  };

  /// Rows that point at a row without a foreign key (soft references): a
  /// remote delete keeps such a row, soft-deleted, like for a real FK.
  static const _softReferences = <String, List<({String table, String column})>>{
    'purchase_order_items': [(table: 'goods_receipt_items', column: 'order_item_id')],
  };

  Future<void> _applyDelete(SyncChange c, Map<String, Set<String>> touched) async {
    final table = c.entity;
    if (!await _exists(table, c.entityId)) return;
    // Resolve cache owners while the row still exists.
    final t = await SyncAggregates.resolveTargets(db, {
      table: [c.entityId]
    });
    void add(String tbl, Set<String> ids) {
      if (ids.isNotEmpty) touched.putIfAbsent(tbl, () => {}).addAll(ids);
    }

    add('products', t.products);
    add('customers', t.customers);
    add('suppliers', t.suppliers);
    add('gift_cards', t.giftCards);
    add('purchase_orders', t.purchaseOrders);
    add('purchase_order_items', t.purchaseOrderItems);
    add('sales', t.sales);
    // A local child still references the row: keep it, soft-deleted.
    final refs = [...?(await _fkMap())[table], ...?_softReferences[table]];
    for (final r in refs) {
      final hit = await db.customSelect('SELECT 1 FROM ${r.table} WHERE "${r.column}" = ? LIMIT 1',
          variables: [Variable.withString(c.entityId)]).get();
      if (hit.isNotEmpty) {
        // Stamped from the change itself (its version is a millisecond
        // clock), not this register's clock: every register that keeps the
        // row stores the same value (the stamp is never pushed).
        await db.customStatement('UPDATE $table SET deleted_at = COALESCE(deleted_at, ?) WHERE id = ?',
            [_versionSeconds(c.version), c.entityId]);
        touched.putIfAbsent(table, () => {}).add(c.entityId);
        return;
      }
    }
    await db.customStatement('DELETE FROM $table WHERE id = ?', [c.entityId]);
  }

  /// Draft purchase orders are saved as a whole line set (new line rows,
  /// `lines_rev`). Two registers editing one draft offline would otherwise
  /// end with the union of both line sets under one header: keep only the
  /// lines of the header revision that won LWW (D-025).
  Future<void> _trimDraftOrderLines(Map<String, Set<String>> touched) async {
    final orders = <String>{...?touched['purchase_orders']};
    final items = touched['purchase_order_items']?.toList() ?? const <String>[];
    for (var i = 0; i < items.length; i += 500) {
      final part = items.sublist(i, math.min(i + 500, items.length));
      final rows = await db.customSelect(
          'SELECT DISTINCT order_id FROM purchase_order_items WHERE id IN (${List.filled(part.length, '?').join(', ')})',
          variables: [for (final id in part) Variable.withString(id)]).get();
      orders.addAll(rows.map((r) => r.read<String>('order_id')));
    }
    for (final o in orders) {
      final h = await db.customSelect('SELECT lines_rev FROM purchase_orders WHERE id = ?',
          variables: [Variable.withString(o)]).getSingleOrNull();
      final rev = h?.readNullable<String>('lines_rev');
      if (rev == null) continue;
      // Lines of a losing revision are only hidden (soft-deleted), never
      // dropped: a later header change can make their revision win again
      // (a draft edit and two offline «send order» crossing), and nobody
      // would ever send them back. The stamp is the line's own creation
      // time, the same on every register (it is not pushed).
      final hidden = await db.customSelect(
          'SELECT id FROM purchase_order_items '
          "WHERE order_id = ? AND ifnull(lines_rev, '') <> ? AND deleted_at IS NULL",
          variables: [Variable.withString(o), Variable.withString(rev)]).get();
      final shown = await db.customSelect(
          'SELECT id FROM purchase_order_items WHERE order_id = ? AND lines_rev = ? AND deleted_at IS NOT NULL',
          variables: [Variable.withString(o), Variable.withString(rev)]).get();
      if (hidden.isEmpty && shown.isEmpty) continue;
      await db.customStatement(
          "UPDATE purchase_order_items SET deleted_at = created_at WHERE order_id = ? AND ifnull(lines_rev, '') <> ? "
          'AND deleted_at IS NULL',
          [o, rev]);
      // Lines of the winning revision hidden by an earlier pull come back.
      await db.customStatement(
          'UPDATE purchase_order_items SET deleted_at = NULL WHERE order_id = ? AND lines_rev = ? AND deleted_at IS NOT NULL',
          [o, rev]);
      touched.putIfAbsent('purchase_order_items', () => {}).addAll([
        for (final r in [...hidden, ...shown]) r.read<String>('id'),
      ]);
    }
  }

  /// Unique keys that collided offline (spec §5): the row with the lower
  /// version loses the value (barcode / card / gift code); for document
  /// numbers the NEWER document gets a suffixed register code, so existing
  /// history keeps its numbers.
  ///
  /// A local row with an unpushed edit counts as newer only when that edit
  /// also wins LWW against [c] (`at > c.version`, the [_localWins] rule).
  /// Registers can still judge one collision differently (the edit that
  /// made the local row newer may be replaced before it is pushed), so the
  /// changed loser is pushed like an edit ([_Owed]): every register ends
  /// with the values of the last resolution, never a local-only clearing.
  ///
  /// Returns the id of the local row that lost (and was changed), if any.
  Future<String?> _resolveUnique(
      SyncChange c, Map<String, Object?> data, List<_Conflict> conflicts, List<_Owed> owed) async {
    final table = c.entity;
    if (_numberedUnique.contains(table)) return _resolveNumber(c, data, conflicts, owed);
    final u = _uniqueColumns[table];
    if (u == null) return null;
    final value = data[u.column];
    if (value == null) return null;
    if (u.partial && data['deleted_at'] != null) return null;
    final nameCol = table == 'gift_cards' ? 'code' : 'name';
    final other = await db.customSelect(
        'SELECT id, $nameCol AS name FROM $table WHERE "${u.column}" = ? AND id <> ?'
        '${u.partial ? ' AND deleted_at IS NULL' : ''} LIMIT 1',
        variables: [Variable(value), Variable.withString(c.entityId)]).getSingleOrNull();
    if (other == null) return null;
    final otherId = other.read<String>('id');
    final otherName = other.readNullable<String>('name') ?? '';
    final incomingLoses = !await _incomingNewer(c, table, otherId);
    final loserId = incomingLoses ? c.entityId : otherId;
    final incomingName = '${data[nameCol] ?? ''}';
    final winnerName = incomingLoses ? otherName : incomingName;
    final loserName = incomingLoses ? incomingName : otherName;
    final code = '$value';
    switch (table) {
      case 'products':
        if (incomingLoses) {
          data['barcode'] = null;
        } else {
          await db.customStatement('UPDATE products SET barcode = NULL WHERE id = ?', [otherId]);
        }
        conflicts.add(_Conflict(SyncConflictKind.uniqueBarcode, table, loserId,
            SyncConflictPayload.uniqueBarcode(code: code, winner: winnerName, loser: loserName)));
      case 'customers':
        if (incomingLoses) {
          data['card_number'] = null;
        } else {
          await db.customStatement('UPDATE customers SET card_number = NULL WHERE id = ?', [otherId]);
        }
        conflicts.add(_Conflict(SyncConflictKind.uniqueCard, table, loserId,
            SyncConflictPayload.uniqueCard(code: code, winner: winnerName, loser: loserName)));
      case 'gift_cards':
        // Redemptions point at the card id (sale_payments.gift_card_id),
        // so renaming the loser does not move its money to the winner.
        final newCode = '$code~${loserId.substring(0, math.min(8, loserId.length))}';
        if (incomingLoses) {
          data['code'] = newCode;
          data['status'] = 'blocked';
        } else {
          await db.customStatement("UPDATE gift_cards SET code = ?, status = 'blocked' WHERE id = ?", [newCode, otherId]);
        }
        conflicts.add(_Conflict(SyncConflictKind.uniqueGiftCode, table, loserId,
            SyncConflictPayload.uniqueGiftCode(code: code, newCode: newCode)));
    }
    owed.add(_Owed(table, loserId, c.version + 1));
    return incomingLoses ? null : otherId;
  }

  /// Whether [c] counts as newer than the local row [otherId] (see
  /// [_resolveUnique]).
  Future<bool> _incomingNewer(SyncChange c, String table, String otherId) async {
    final pendingAt = await _pendingAt(table, otherId, _Part.user);
    if (pendingAt != null && pendingAt > c.version) return false;
    final v = await (db.select(db.syncRowVersions)..where((r) => r.entity.equals(table) & r.entityId.equals(otherId)))
        .getSingleOrNull();
    final ov = v?.version ?? 0;
    final od = v?.deviceId ?? '';
    return c.version > ov || (c.version == ov && c.deviceId.compareTo(od) > 0);
  }

  /// (device_code, number) of numbered documents. Two documents only share
  /// them after a restored backup or a copied database file; the newer one
  /// gets the code `<code>~XXXX` (pushed, see [_resolveUnique]). A renamed
  /// open shift of this register stays its current shift
  /// ([AppDatabase.ownShiftsSettingKey]).
  Future<String?> _resolveNumber(
      SyncChange c, Map<String, Object?> data, List<_Conflict> conflicts, List<_Owed> owed) async {
    final table = c.entity;
    final number = data['number'];
    if (number is! int) return null;
    final code = data['device_code'] as String?;
    final other = await db.customSelect(
        "SELECT id FROM $table WHERE ifnull(device_code, '') = ? AND number = ? AND id <> ? LIMIT 1",
        variables: [
          Variable.withString(code ?? ''),
          Variable.withInt(number),
          Variable.withString(c.entityId),
        ]).getSingleOrNull();
    if (other == null) return null;
    final otherId = other.read<String>('id');
    final incomingNewer = await _incomingNewer(c, table, otherId);
    final loserId = incomingNewer ? c.entityId : otherId;
    final newCode = '${code ?? ''}~${loserId.substring(0, math.min(4, loserId.length)).toUpperCase()}';
    if (incomingNewer) {
      data['device_code'] = newCode;
    } else {
      if (table == 'shifts' && code != null && code == await db.deviceCode()) {
        final open = await db.customSelect("SELECT 1 FROM shifts WHERE id = ? AND status = 'open'",
            variables: [Variable.withString(otherId)]).get();
        if (open.isNotEmpty) {
          final own = {
            ...AppDatabase.parseOwnShifts(await db.getSetting(AppDatabase.ownShiftsSettingKey)),
            otherId,
          };
          await db.setSetting(AppDatabase.ownShiftsSettingKey, own.join(','));
        }
      }
      await db.customStatement('UPDATE $table SET device_code = ? WHERE id = ?', [newCode, otherId]);
    }
    conflicts.add(_Conflict(SyncConflictKind.uniqueNumber, table, loserId,
        SyncConflictPayload.uniqueNumber(number: number, code: code, newCode: newCode)));
    owed.add(_Owed(table, loserId, c.version + 1));
    return incomingNewer ? null : otherId;
  }

  /// A sale voided on one register and returned on another, or returned
  /// beyond what was sold on several registers: both are accepted (spec §6)
  /// but the double refund must reach the owner.
  Future<List<_Conflict>> _returnConflicts(Map<String, Set<String>> touched) async {
    final t = await SyncAggregates.resolveTargets(db, touched);
    if (t.sales.isEmpty) return const [];
    final out = <_Conflict>[];
    final ids = t.sales.toList();
    for (var i = 0; i < ids.length; i += 500) {
      final part = ids.sublist(i, math.min(i + 500, ids.length));
      final rows = await db.customSelect(
          'SELECT s.id, s.number, s.device_code, s.status, s.total, '
          '(SELECT COALESCE(SUM(r.total), 0) FROM returns r WHERE r.sale_id = s.id AND r.deleted_at IS NULL) AS refunded, '
          'EXISTS (SELECT 1 FROM sale_items si WHERE si.sale_id = s.id AND si.deleted_at IS NULL AND '
          '(SELECT COALESCE(SUM(ri.qty), 0) FROM return_items ri WHERE ri.sale_item_id = si.id '
          'AND ri.deleted_at IS NULL) > si.qty + 0.0000001) AS over '
          'FROM sales s WHERE s.id IN (${List.filled(part.length, '?').join(', ')})',
          variables: [for (final id in part) Variable.withString(id)]).get();
      for (final r in rows) {
        final number = r.read<int>('number');
        final code = r.readNullable<String>('device_code');
        final refunded = r.read<int>('refunded');
        final total = r.read<int>('total');
        final id = r.read<String>('id');
        if (r.read<String>('status') == 'voided') {
          if (refunded > 0) {
            out.add(_Conflict(SyncConflictKind.voidReturn, 'sales', id,
                SyncConflictPayload.voidReturn(number: number, code: code, refunded: refunded)));
          }
        } else if (r.read<int>('over') == 1 || refunded > total) {
          out.add(_Conflict(SyncConflictKind.overReturn, 'sales', id,
              SyncConflictPayload.overReturn(number: number, code: code, refunded: refunded, total: total)));
        }
      }
    }
    return out;
  }

  /// Business conflicts accepted after a batch (spec §6).
  Future<List<_Conflict>> _negativeConflicts(List<AggregateMismatch> changed) async {
    final out = <_Conflict>[];
    final globalAllow = await db.getSetting('allow_negative_stock') == '1';
    for (final m in changed) {
      final d = m.derived;
      if (d is! num || d >= 0) continue;
      switch ((m.table, m.column)) {
        case ('products', 'stock_qty'):
          if (globalAllow) continue;
          final p = await (db.select(db.products)..where((t) => t.id.equals(m.id))).getSingleOrNull();
          if (p == null || !p.trackStock || p.allowNegativeStock) continue;
          out.add(_Conflict(SyncConflictKind.negativeStock, 'products', m.id,
              SyncConflictPayload.negativeStock(name: p.name, qty: d.toDouble(), unit: p.unit)));
        case ('gift_cards', 'balance'):
          final g = await (db.select(db.giftCards)..where((t) => t.id.equals(m.id))).getSingleOrNull();
          if (g == null) continue;
          out.add(_Conflict(SyncConflictKind.negativeGiftBalance, 'gift_cards', m.id,
              SyncConflictPayload.negativeGiftBalance(code: g.code, balance: d.toInt())));
        case ('customers', 'bonus_balance'):
          final c = await (db.select(db.customers)..where((t) => t.id.equals(m.id))).getSingleOrNull();
          if (c == null) continue;
          out.add(_Conflict(SyncConflictKind.negativeBonus, 'customers', m.id,
              SyncConflictPayload.negativeBonus(name: c.name, balance: d.toInt())));
      }
    }
    return out;
  }

  /// `sync_conflicts` row (language-neutral payload, rendered by
  /// [ConflictText] in the current language) + local notification (kind
  /// `system`; its text is fixed in the UI language of the moment, like every
  /// notification). An unresolved conflict of the same kind for the same row
  /// is not repeated.
  Future<void> _record(_Conflict k) async {
    final dup = await (db.select(db.syncConflicts)
          ..where((c) => c.kind.equals(k.kind) & c.entityId.equals(k.entityId) & c.resolved.equals(false))
          ..limit(1))
        .getSingleOrNull();
    if (dup != null) return;
    final details = k.payload.encode();
    await db.into(db.syncConflicts).insert(SyncConflictsCompanion.insert(
        kind: k.kind, entity: Value(k.entity), entityId: Value(k.entityId), details: Value(details)));
    final l = L.current;
    await db.into(db.notifications).insert(NotificationsCompanion.insert(
          id: newId(),
          kind: 'system',
          title: ConflictText.titleOf(l, k.kind, details),
          body: Value(ConflictText.bodyOf(l, details)),
          refType: const Value('sync_conflict'),
          refId: Value(k.entityId),
        ));
  }

  // ------------------------------------------------------------ scheduler

  void _startScheduler() {
    if (!schedulerEnabled || _disposed || _periodic != null) return;
    _periodic = Timer.periodic(schedule.period, (_) => unawaited(_tick()));
    _updatesSub = db.tableUpdates().listen(_onLocalWrite);
  }

  void _stopScheduler() {
    _periodic?.cancel();
    _periodic = null;
    _debounce?.cancel();
    _debounce = null;
    _updatesSub?.cancel();
    _updatesSub = null;
  }

  /// True while the scheduler timers are active.
  bool get schedulerRunning => _periodic != null;

  void _onLocalWrite(Set<TableUpdate> updates) {
    if (!updates.any((u) => u.table == settingsTable || syncedTables.contains(u.table))) return;
    _debounce?.cancel();
    _debounce = Timer(schedule.debounce, () => unawaited(_tick(onlyIfPending: true)));
  }

  Future<void> _tick({bool onlyIfPending = false}) async {
    if (_disposed || !_foreground || _running != null || _lock != null) return;
    final next = _nextAttemptAt;
    if (next != null && DateTime.now().isBefore(next)) return;
    try {
      if (!await isConnected()) return;
      if (onlyIfPending && await pendingCount() == 0) {
        await refreshStatus();
        return;
      }
      await syncNow();
    } catch (_) {
      // Status and backoff are already updated by _doSync.
    }
  }

  /// Whether [init] has completed.
  bool get initialized => _initialized;
}
