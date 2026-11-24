import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/services/auth_service.dart';
import '../domain/services/customer_service.dart';
import '../domain/services/sale_service.dart';
import '../domain/services/shift_service.dart';
import '../domain/services/stock_service.dart';
import 'db/database.dart';
import 'money.dart';
import 'permissions.dart';

/// Overridden in main() with the real database (and in tests with memory).
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final saleServiceProvider = Provider((ref) => SaleService(ref.watch(databaseProvider)));
final stockServiceProvider = Provider((ref) => StockService(ref.watch(databaseProvider)));
final shiftServiceProvider = Provider((ref) => ShiftService(ref.watch(databaseProvider)));
final customerServiceProvider = Provider((ref) => CustomerService(ref.watch(databaseProvider)));
final authServiceProvider = Provider((ref) => AuthService(ref.watch(databaseProvider)));

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

/// Live current open shift (single-register mode: latest open shift).
final currentShiftProvider = StreamProvider<Shift?>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.shifts)
    ..where((s) => s.status.equals('open'))
    ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
    ..limit(1);
  return q.watchSingleOrNull();
});

final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final c = db.notifications.id.count();
  final q = db.selectOnly(db.notifications)
    ..addColumns([c])
    ..where(db.notifications.isRead.equals(false) & db.notifications.deletedAt.isNull());
  return q.map((r) => r.read(c) ?? 0).watchSingle();
});
