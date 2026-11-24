import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import 'shift_logic.dart';

/// All users by id (names for "opened by", movements, history).
final shiftUsersProvider = StreamProvider<Map<String, User>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.users).watch().map((l) => {for (final u in l) u.id: u});
});

/// Live X-report: recomputed whenever sales/returns/cash/ledger change.
final shiftFiguresProvider = StreamProvider.autoDispose.family<ShiftFigures, String>((ref, shiftId) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.shifts,
          db.sales,
          db.salePayments,
          db.returns,
          db.returnItems,
          db.cashMovements,
          db.customerLedger,
          db.supplierPayments,
          db.giftCardSales,
          db.giftCardSalePayments,
        },
      )
      .watch()
      .asyncMap((_) => ShiftFigures.load(db, shiftId));
});

/// Cash movements of a shift, newest first.
final shiftMovementsProvider = StreamProvider.autoDispose.family<List<CashMovement>, String>((ref, shiftId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.cashMovements)
        ..where((m) => m.shiftId.equals(shiftId) & m.deletedAt.isNull())
        ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
      .watch();
});

/// Suggested opening float.
final openingSuggestionProvider = FutureProvider.autoDispose<int>((ref) {
  return suggestOpeningCash(ref.watch(databaseProvider));
});

/// History period filter (days back; null = all).
class HistoryPeriodNotifier extends Notifier<int?> {
  @override
  int? build() => 30;
  void set(int? days) => state = days;
}

final historyPeriodProvider = NotifierProvider<HistoryPeriodNotifier, int?>(HistoryPeriodNotifier.new);

final shiftHistoryProvider = StreamProvider<List<ShiftHistoryRow>>((ref) {
  final db = ref.watch(databaseProvider);
  final session = ref.watch(sessionProvider);
  final days = ref.watch(historyPeriodProvider);
  final all = session?.can(Perm.viewAllShifts) ?? false;
  final now = DateTime.now();
  return watchShiftHistory(
    db,
    onlyUserId: all ? null : session?.user.id ?? '-',
    from: days == null ? null : DateTime(now.year, now.month, now.day - days),
  );
});
