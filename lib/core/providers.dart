import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/services/auth_service.dart';
import '../domain/services/customer_service.dart';
import '../domain/services/gift_card_service.dart';
import '../domain/services/receipt_service.dart';
import '../domain/services/sale_service.dart';
import '../domain/services/shift_service.dart';
import '../domain/services/stock_service.dart';
import '../domain/services/supplier_service.dart';
import '../l10n/l10n.dart';
import 'db/database.dart';
import 'money.dart';
import 'permissions.dart';
import 'sync/supabase_transport.dart';
import 'sync/sync_tables.dart' show deviceCodeSettingKey;
import 'sync/sync_service.dart';
import 'sync/transport.dart';

/// Overridden in main() with the real database (and in tests with memory).
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final saleServiceProvider = Provider((ref) => SaleService(ref.watch(databaseProvider)));
final stockServiceProvider = Provider((ref) => StockService(ref.watch(databaseProvider)));
final shiftServiceProvider = Provider((ref) => ShiftService(ref.watch(databaseProvider)));
final customerServiceProvider = Provider((ref) => CustomerService(ref.watch(databaseProvider)));
final authServiceProvider = Provider((ref) => AuthService(ref.watch(databaseProvider)));
final supplierLedgerServiceProvider = Provider((ref) => SupplierLedgerService(ref.watch(databaseProvider)));
final receiptServiceProvider = Provider((ref) => ReceiptService(
      ref.watch(databaseProvider),
      ref.watch(stockServiceProvider),
      ref.watch(supplierLedgerServiceProvider),
    ));

final giftCardServiceProvider = Provider((ref) => GiftCardService(ref.watch(databaseProvider)));

// ------------------------------------------------------------------ sync (D-025)

/// Creates the server transport for a configured endpoint: the Supabase
/// transport (GoTrue + PostgREST RPC, `sync/supabase_transport.dart`) in the
/// app. Null inside `flutter test`, so no test can ever reach a real server
/// unless it overrides this provider (tests pass a fake server:
/// `(endpoint) => server.client()`, or a MockClient-backed
/// `SupabaseTransport`).
final syncTransportFactoryProvider =
    Provider<SyncTransportFactory?>((ref) => runningInFlutterTest ? null : SupabaseTransport.new);

/// Periodic/debounced sync. Off inside `flutter test` unless overridden.
final syncSchedulerEnabledProvider = Provider<bool>((ref) => !runningInFlutterTest);

/// The sync engine (one per database). Not configured = does nothing.
final syncServiceProvider = Provider<SyncService>((ref) {
  final s = SyncService(
    ref.watch(databaseProvider),
    transportFactory: ref.watch(syncTransportFactoryProvider),
    schedulerEnabled: ref.watch(syncSchedulerEnabledProvider),
  );
  ref.onDispose(s.dispose);
  return s;
});

/// Live sync status (off / idle / syncing / error / offline, pending count,
/// last sync, last error, store name, environment, device code). Building it
/// runs `SyncService.init()` (loads state; starts the scheduler only when
/// connected).
class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    final s = ref.watch(syncServiceProvider);
    final sub = s.statusStream.listen((v) {
      if (ref.mounted) state = v;
    });
    ref.onDispose(sub.cancel);
    unawaited(s.init());
    return s.status;
  }
}

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);

/// Transport of the configured endpoint, null until signed in / configured.
final syncTransportProvider = Provider<SyncTransport?>((ref) {
  ref.watch(syncStatusProvider);
  return ref.watch(syncServiceProvider).transport;
});

/// All settings as a live map.
final settingsProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(databaseProvider).watchSettings().map((s) {
    Money.currency = CurrencyConfig.fromSettings(s);
    return s;
  });
});

/// Read a single setting with a default, e.g. `ref.watch(settingProvider('store_name'))`.
final settingProvider = Provider.family<String?, String>(
    (ref, key) => ref.watch(settingsProvider).value?[key]);

// ------------------------------------------------------------------ language

/// UI language code (`ru`/`uz`/`ky`/`en`): a device preference stored in
/// SharedPreferences `ui_locale`, default ru. Keeps [L.current] in sync.
/// main() passes the saved value (no flash); otherwise it is loaded async.
class UiLocaleNotifier extends Notifier<String> {
  UiLocaleNotifier([this.initial]);
  final String? initial;
  static const prefsKey = 'ui_locale';

  @override
  String build() {
    final code = L.normalize(initial);
    L.setCurrent(code);
    if (initial == null) _load();
    return code;
  }

  Future<void> _load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(prefsKey);
      if (saved != null && ref.mounted && L.normalize(saved) != state) {
        L.setCurrent(saved);
        state = L.normalize(saved);
      }
    } catch (_) {/* no prefs (tests): keep ru */}
  }

  Future<void> set(String code) async {
    final c = L.normalize(code);
    L.setCurrent(c);
    state = c;
    try {
      await (await SharedPreferences.getInstance()).setString(prefsKey, c);
    } catch (_) {}
  }
}

final uiLocaleProvider = NotifierProvider<UiLocaleNotifier, String>(UiLocaleNotifier.new);

/// Language of printed customer documents: store setting `receipt_locale` (default ru).
/// Keeps [L.receipt] in sync.
final receiptLocaleProvider = Provider<String>((ref) {
  final c = L.normalize(ref.watch(settingProvider('receipt_locale')));
  L.setReceipt(c);
  return c;
});

// ------------------------------------------------------------------ session

class Session {
  const Session(this.user);
  final User user;
  Role get role => Role.parse(user.role);
  bool can(Perm p) => role.can(p);
}

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => null;

  void login(User u) => state = Session(u);
  void logout() => state = null;
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

/// Bridges session changes to go_router's refreshListenable.
class RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerRefreshProvider = Provider((ref) {
  final r = RouterRefresh();
  ref.listen(sessionProvider, (_, _) => r.ping());
  ref.listen(setupDoneProvider, (_, _) => r.ping());
  return r;
});

final setupDoneProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final done = await db.getSetting('setup_done');
  return done == '1';
});

/// This register's device code (`A`, `B`…; null while sync is off).
final deviceCodeProvider = StreamProvider<String?>((ref) {
  return ref.watch(databaseProvider).watchSettings().map((s) {
    final v = s[deviceCodeSettingKey]?.trim();
    return v == null || v.isEmpty ? null : v;
  }).distinct();
});

/// Open shifts this database kept as its own after its code changed
/// ([AppDatabase.ownShiftsSettingKey]).
final ownShiftsProvider = StreamProvider<Set<String>>((ref) {
  return ref
      .watch(databaseProvider)
      .watchSettings()
      .map((s) => s[AppDatabase.ownShiftsSettingKey] ?? '')
      .distinct()
      .map(AppDatabase.parseOwnShifts);
});

/// Live current open shift of THIS register: the latest open shift; with
/// sync on, the latest open shift with this register's code (other
/// registers' shifts are synced here too, D-025) or one this database kept
/// as its own when its code changed (same rule as ShiftService.currentShift).
final currentShiftProvider = StreamProvider<Shift?>((ref) async* {
  final db = ref.watch(databaseProvider);
  final code = await ref.watch(deviceCodeProvider.future);
  final own = await ref.watch(ownShiftsProvider.future);
  yield* db.currentShiftQuery(code, own).watchSingleOrNull();
});

final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final c = db.notifications.id.count();
  final q = db.selectOnly(db.notifications)
    ..addColumns([c])
    ..where(db.notifications.isRead.equals(false) & db.notifications.deletedAt.isNull());
  return q.map((r) => r.read(c) ?? 0).watchSingle();
});
