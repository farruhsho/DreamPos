import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../reports/data/report_queries.dart';

/// Counts that drive the first-run onboarding (brand-new store).
class StoreProgress {
  const StoreProgress({this.products = 0, this.shifts = 0, this.sales = 0});
  final int products;
  final int shifts;
  final int sales;
  bool get isNew => sales == 0;
  int get stepsDone => (products > 0 ? 1 : 0) + (shifts > 0 ? 1 : 0) + (sales > 0 ? 1 : 0);
}

Selectable<StoreProgress> storeProgressQuery(AppDatabase db) => db.customSelect(
      'SELECT '
      '(SELECT COUNT(*) FROM products WHERE deleted_at IS NULL) AS products, '
      '(SELECT COUNT(*) FROM shifts WHERE deleted_at IS NULL) AS shifts, '
      "(SELECT COUNT(*) FROM sales WHERE deleted_at IS NULL AND status NOT IN ('voided', 'held')) AS sales",
      readsFrom: {db.products, db.shifts, db.sales},
    ).map((r) => StoreProgress(
        products: qi(r, 'products'), shifts: qi(r, 'shifts'), sales: qi(r, 'sales')));

final storeProgressProvider = StreamProvider.autoDispose<StoreProgress>(
    (ref) => storeProgressQuery(ref.watch(databaseProvider)).watchSingle());

/// Low stock: tracked active products with stock ≤ min stock (min > 0) or ≤ 0.
class StockAlerts {
  const StockAlerts({this.low = 0, this.out = 0});
  final int low;
  final int out;
  int get total => low + out;
}

Selectable<StockAlerts> stockAlertsQuery(AppDatabase db) => db.customSelect(
      'SELECT '
      'SUM(CASE WHEN stock_qty > 0 AND min_stock > 0 AND stock_qty <= min_stock THEN 1 ELSE 0 END) AS low, '
      'SUM(CASE WHEN stock_qty <= 0 THEN 1 ELSE 0 END) AS out_ '
      'FROM products WHERE deleted_at IS NULL AND is_active = 1 AND track_stock = 1',
      readsFrom: {db.products},
    ).map((r) => StockAlerts(low: qi(r, 'low'), out: qi(r, 'out_')));

final stockAlertsProvider = StreamProvider.autoDispose<StockAlerts>(
    (ref) => stockAlertsQuery(ref.watch(databaseProvider)).watchSingle());

class DebtTotal {
  const DebtTotal(this.total, this.customers);
  final int total;
  final int customers;
}

final debtTotalProvider = StreamProvider.autoDispose<DebtTotal>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT COALESCE(SUM(debt_balance), 0) AS total, COUNT(*) AS n FROM customers '
        'WHERE deleted_at IS NULL AND debt_balance > 0',
        readsFrom: {db.customers},
      )
      .watchSingle()
      .map((r) => DebtTotal(qi(r, 'total'), qi(r, 'n')));
});

class RecentSale {
  const RecentSale(this.sale, this.cashier, this.customer);
  final Sale sale;
  final String? cashier;
  final String? customer;
}

final recentSalesProvider = StreamProvider.autoDispose<List<RecentSale>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.sales).join([
    leftOuterJoin(db.users, db.users.id.equalsExp(db.sales.cashierId)),
    leftOuterJoin(db.customers, db.customers.id.equalsExp(db.sales.customerId)),
  ])
    ..where(db.sales.deletedAt.isNull() & db.sales.status.equals('held').not())
    ..orderBy([OrderingTerm.desc(db.sales.createdAt)])
    ..limit(5);
  return q.watch().map((rows) => [
        for (final r in rows)
          RecentSale(r.readTable(db.sales), r.readTableOrNull(db.users)?.name,
              r.readTableOrNull(db.customers)?.name),
      ]);
});

class ShiftTotals {
  const ShiftTotals(this.receipts, this.revenue, this.cashier);
  final int receipts;
  final int revenue;
  final String? cashier;
}

/// Receipts and net revenue of a shift (sales − returns made in that shift).
final shiftTotalsProvider = StreamProvider.autoDispose.family<ShiftTotals, String>((ref, shiftId) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM sales s WHERE s.shift_id = ?1 AND $validSale) AS n, '
        '(SELECT COALESCE(SUM(s.total), 0) FROM sales s WHERE s.shift_id = ?1 AND $validSale) '
        ' - (SELECT COALESCE(SUM(r.total), 0) FROM returns r WHERE r.shift_id = ?1 AND r.deleted_at IS NULL) AS rev, '
        '(SELECT u.name FROM shifts sh JOIN users u ON u.id = sh.opened_by WHERE sh.id = ?1) AS cashier',
        variables: [Variable.withString(shiftId)],
        readsFrom: {db.sales, db.returns, db.shifts, db.users},
      )
      .watchSingle()
      .map((r) => ShiftTotals(qi(r, 'n'), qi(r, 'rev'), qs(r, 'cashier')));
});
