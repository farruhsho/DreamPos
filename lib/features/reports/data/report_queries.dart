// SQL aggregations for reports and the dashboard.
//
// Conventions:
//  * Drift stores DateTime as unix seconds (INTEGER); we bind with
//    Variable.withDateTime. Local day / hour buckets are computed as
//    `date(x + offset, 'unixepoch')` with the device UTC offset passed as a
//    parameter (SQLite's 'localtime' modifier is not available in every
//    bundled SQLite build, and Central Asia has no DST).
//  * Periods are half-open: created_at >= start AND created_at < end.
//  * Valid sales exclude voided and parked (held) receipts and soft-deleted rows.
//  * Returns are subtracted by RETURN date (cash-basis), so a return today of a
//    sale made last week reduces today's net revenue.
//  * Gross profit = net revenue − net cost; the cost of returned goods is only
//    given back when the goods were restocked (a non-restocked return is a loss).
import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import 'period.dart';

const validSale = "s.deleted_at IS NULL AND s.status NOT IN ('voided', 'held')";

int qi(QueryRow r, String k) => (r.data[k] as num?)?.round() ?? 0;
double qd(QueryRow r, String k) => (r.data[k] as num?)?.toDouble() ?? 0;
String? qs(QueryRow r, String k) => r.data[k] as String?;

List<Variable> periodVars(ReportPeriod p) =>
    [Variable.withDateTime(p.start), Variable.withDateTime(p.end)];

/// Period bounds + local UTC offset in seconds (?3) for day/hour bucketing.
List<Variable> periodVarsTz(ReportPeriod p) =>
    [...periodVars(p), Variable.withInt(p.start.timeZoneOffset.inSeconds)];

// ------------------------------------------------------------------ summary

class SalesSummary {
  const SalesSummary({
    this.receipts = 0,
    this.gross = 0,
    this.subtotal = 0,
    this.discounts = 0,
    this.cost = 0,
    this.returnsTotal = 0,
    this.returnsCount = 0,
    this.returnsCost = 0,
    this.voids = 0,
  });

  /// Valid receipts (not voided/held).
  final int receipts;
  /// Sum of receipt totals (after discounts), before returns.
  final int gross;
  /// Sum before discounts.
  final int subtotal;
  final int discounts;
  /// Cost of goods sold (before returns).
  final int cost;
  final int returnsTotal;
  final int returnsCount;
  /// Cost given back by restocked returns.
  final int returnsCost;
  final int voids;

  int get net => gross - returnsTotal;
  int get netCost => cost - returnsCost;
  int get profit => net - netCost;
  double get marginPct => net == 0 ? 0 : profit * 100 / net;
  int get avgCheck => receipts == 0 ? 0 : (gross / receipts).round();
  double get discountPct => subtotal == 0 ? 0 : discounts * 100 / subtotal;
  double get returnsPct => gross == 0 ? 0 : returnsTotal * 100 / gross;
  bool get isEmpty => receipts == 0 && returnsCount == 0 && voids == 0;
}

const _summarySql = '''
SELECT
  (SELECT COUNT(*) FROM sales s WHERE s.created_at >= ?1 AND s.created_at < ?2 AND $validSale) AS receipts,
  (SELECT COALESCE(SUM(s.total), 0) FROM sales s WHERE s.created_at >= ?1 AND s.created_at < ?2 AND $validSale) AS gross,
  (SELECT COALESCE(SUM(s.subtotal), 0) FROM sales s WHERE s.created_at >= ?1 AND s.created_at < ?2 AND $validSale) AS subtotal,
  (SELECT COALESCE(SUM(s.discount_total), 0) FROM sales s WHERE s.created_at >= ?1 AND s.created_at < ?2 AND $validSale) AS discounts,
  (SELECT COALESCE(SUM(s.cost_total), 0) FROM sales s WHERE s.created_at >= ?1 AND s.created_at < ?2 AND $validSale) AS cost,
  (SELECT COUNT(*) FROM sales s WHERE s.created_at >= ?1 AND s.created_at < ?2 AND s.deleted_at IS NULL AND s.status = 'voided') AS voids,
  (SELECT COALESCE(SUM(r.total), 0) FROM returns r WHERE r.created_at >= ?1 AND r.created_at < ?2 AND r.deleted_at IS NULL) AS returns_total,
  (SELECT COUNT(*) FROM returns r WHERE r.created_at >= ?1 AND r.created_at < ?2 AND r.deleted_at IS NULL) AS returns_count,
  (SELECT COALESCE(SUM(ri.qty * si.unit_cost), 0)
     FROM return_items ri
     JOIN returns r ON r.id = ri.return_id
     JOIN sale_items si ON si.id = ri.sale_item_id
    WHERE r.created_at >= ?1 AND r.created_at < ?2 AND r.deleted_at IS NULL AND r.restock = 1) AS returns_cost
''';

Selectable<SalesSummary> salesSummaryQuery(AppDatabase db, ReportPeriod p) => db
    .customSelect(_summarySql,
        variables: periodVars(p),
        readsFrom: {db.sales, db.returns, db.returnItems, db.saleItems})
    .map((r) => SalesSummary(
          receipts: qi(r, 'receipts'),
          gross: qi(r, 'gross'),
          subtotal: qi(r, 'subtotal'),
          discounts: qi(r, 'discounts'),
          cost: qi(r, 'cost'),
          voids: qi(r, 'voids'),
          returnsTotal: qi(r, 'returns_total'),
          returnsCount: qi(r, 'returns_count'),
          returnsCost: qi(r, 'returns_cost'),
        ));

Stream<SalesSummary> watchSalesSummary(AppDatabase db, ReportPeriod p) =>
    salesSummaryQuery(db, p).watchSingle();

// ------------------------------------------------------------------ by day

class DayPoint {
  const DayPoint(this.day,
      {this.gross = 0, this.returns = 0, this.cost = 0, this.receipts = 0, this.discounts = 0});
  final DateTime day;
  final int gross;
  final int returns;
  /// Net cost (sales cost − restocked returns cost).
  final int cost;
  final int receipts;
  final int discounts;
  int get net => gross - returns;
  int get profit => net - cost;
  int get avgCheck => receipts == 0 ? 0 : (gross / receipts).round();
}

const _byDaySql = '''
SELECT d, SUM(g) AS gross, SUM(rt) AS returns, SUM(c) AS cost, SUM(n) AS receipts, SUM(disc) AS discounts FROM (
  SELECT date(s.created_at + ?3, 'unixepoch') AS d, s.total AS g, 0 AS rt, s.cost_total AS c, 1 AS n, s.discount_total AS disc
    FROM sales s WHERE s.created_at >= ?1 AND s.created_at < ?2 AND $validSale
  UNION ALL
  SELECT date(r.created_at + ?3, 'unixepoch'), 0, r.total,
         -CASE WHEN r.restock = 1 THEN COALESCE((SELECT SUM(ri.qty * si.unit_cost) FROM return_items ri
              JOIN sale_items si ON si.id = ri.sale_item_id WHERE ri.return_id = r.id), 0) ELSE 0 END,
         0, 0
    FROM returns r WHERE r.created_at >= ?1 AND r.created_at < ?2 AND r.deleted_at IS NULL
) GROUP BY d ORDER BY d
''';

/// One point per calendar day of the period (zero-filled).
Stream<List<DayPoint>> watchByDay(AppDatabase db, ReportPeriod p) => db
    .customSelect(_byDaySql,
        variables: periodVarsTz(p),
        readsFrom: {db.sales, db.returns, db.returnItems, db.saleItems})
    .watch()
    .map((rows) {
      final byKey = {for (final r in rows) qs(r, 'd'): r};
      return [
        for (final d in p.days)
          if (byKey[dayKey(d)] case final r?)
            DayPoint(d,
                gross: qi(r, 'gross'),
                returns: qi(r, 'returns'),
                cost: qi(r, 'cost'),
                receipts: qi(r, 'receipts'),
                discounts: qi(r, 'discounts'))
          else
            DayPoint(d),
      ];
    });

// ------------------------------------------------------------------ by hour

class HourCell {
  const HourCell(this.weekday, this.hour, this.receipts, this.revenue);
  /// 1 = Monday … 7 = Sunday.
  final int weekday;
  final int hour;
  final int receipts;
  final int revenue;
}

const _byHourSql = '''
SELECT CAST(strftime('%w', s.created_at + ?3, 'unixepoch') AS INTEGER) AS wd,
       CAST(strftime('%H', s.created_at + ?3, 'unixepoch') AS INTEGER) AS h,
       COUNT(*) AS n, SUM(s.total) AS rev
  FROM sales s WHERE s.created_at >= ?1 AND s.created_at < ?2 AND $validSale
 GROUP BY wd, h
''';

Stream<List<HourCell>> watchByHour(AppDatabase db, ReportPeriod p) => db
    .customSelect(_byHourSql, variables: periodVarsTz(p), readsFrom: {db.sales})
    .watch()
    .map((rows) => [
          for (final r in rows)
            HourCell(qi(r, 'wd') == 0 ? 7 : qi(r, 'wd'), qi(r, 'h'), qi(r, 'n'), qi(r, 'rev')),
        ]);

// ------------------------------------------------------------------ products

class ProductRow {
  const ProductRow({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.unit = 'pcs',
    this.qty = 0,
    this.revenue = 0,
    this.cost = 0,
  });
  final String id;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String unit;
  /// Net quantity (sold − returned).
  final double qty;
  final int revenue;
  final int cost;
  int get profit => revenue - cost;
  double get marginPct => revenue == 0 ? 0 : profit * 100 / revenue;
}

/// Net movement lines per product: sales in period (+) and returns in period (−).
const _netLinesSql = '''
  SELECT si.product_id AS pid, si.qty AS qty, si.total AS rev, si.qty * si.unit_cost AS cost, si.product_name AS pname
    FROM sale_items si JOIN sales s ON s.id = si.sale_id
   WHERE s.created_at >= ?1 AND s.created_at < ?2 AND $validSale
  UNION ALL
  SELECT ri.product_id, -ri.qty, -ri.amount,
         CASE WHEN r.restock = 1 THEN -ri.qty * si.unit_cost ELSE 0 END, si.product_name
    FROM return_items ri
    JOIN returns r ON r.id = ri.return_id
    JOIN sale_items si ON si.id = ri.sale_item_id
   WHERE r.created_at >= ?1 AND r.created_at < ?2 AND r.deleted_at IS NULL
''';

const _byProductSql = '''
SELECT x.pid AS pid, COALESCE(p.name, MAX(x.pname)) AS name, p.category_id AS cid, c.name AS cname,
       COALESCE(p.unit, 'pcs') AS unit, SUM(x.qty) AS qty, SUM(x.rev) AS rev, SUM(x.cost) AS cost
  FROM ($_netLinesSql) x
  LEFT JOIN products p ON p.id = x.pid
  LEFT JOIN categories c ON c.id = p.category_id
 GROUP BY x.pid
 ORDER BY rev DESC
''';

Selectable<ProductRow> byProductQuery(AppDatabase db, ReportPeriod p) => db
    .customSelect(_byProductSql,
        variables: periodVars(p),
        readsFrom: {db.sales, db.saleItems, db.returns, db.returnItems, db.products, db.categories})
    .map((r) => ProductRow(
          id: qs(r, 'pid') ?? '',
          name: qs(r, 'name') ?? '—',
          categoryId: qs(r, 'cid'),
          categoryName: qs(r, 'cname'),
          unit: qs(r, 'unit') ?? 'pcs',
          qty: qd(r, 'qty'),
          revenue: qi(r, 'rev'),
          cost: qi(r, 'cost'),
        ));

Stream<List<ProductRow>> watchByProduct(AppDatabase db, ReportPeriod p) =>
    byProductQuery(db, p).watch();

class CategoryRow {
  const CategoryRow(this.id, this.name, this.qty, this.revenue, this.cost, this.products);
  final String? id;
  final String name;
  final double qty;
  final int revenue;
  final int cost;
  final int products;
  int get profit => revenue - cost;
  double get marginPct => revenue == 0 ? 0 : profit * 100 / revenue;
}

const _byCategorySql = '''
SELECT p.category_id AS cid, COALESCE(c.name, 'Без категории') AS cname,
       SUM(x.qty) AS qty, SUM(x.rev) AS rev, SUM(x.cost) AS cost, COUNT(DISTINCT x.pid) AS n
  FROM ($_netLinesSql) x
  LEFT JOIN products p ON p.id = x.pid
  LEFT JOIN categories c ON c.id = p.category_id
 GROUP BY p.category_id
 ORDER BY rev DESC
''';

Selectable<CategoryRow> byCategoryQuery(AppDatabase db, ReportPeriod p) => db
    .customSelect(_byCategorySql,
        variables: periodVars(p),
        readsFrom: {db.sales, db.saleItems, db.returns, db.returnItems, db.products, db.categories})
    .map((r) => CategoryRow(qs(r, 'cid'), qs(r, 'cname') ?? 'Без категории', qd(r, 'qty'),
        qi(r, 'rev'), qi(r, 'cost'), qi(r, 'n')));

Stream<List<CategoryRow>> watchByCategory(AppDatabase db, ReportPeriod p) =>
    byCategoryQuery(db, p).watch();

// ------------------------------------------------------------------ staff

enum StaffGrouping { cashier, seller }

class StaffRow {
  const StaffRow({
    required this.userId,
    required this.name,
    this.receipts = 0,
    this.revenue = 0,
    this.discounts = 0,
    this.returnsTotal = 0,
    this.returnsCount = 0,
    this.voids = 0,
  });
  final String? userId;
  final String name;
  final int receipts;
  final int revenue;
  final int discounts;
  /// Returns against this employee's receipts (by return date).
  final int returnsTotal;
  final int returnsCount;
  final int voids;
  int get net => revenue - returnsTotal;
  int get avgCheck => receipts == 0 ? 0 : (revenue / receipts).round();
}

String _staffSql(StaffGrouping g) {
  final col = g == StaffGrouping.cashier ? 'cashier_id' : 'seller_id';
  return '''
SELECT x.uid AS uid, COALESCE(u.name, 'Не указан') AS name,
       SUM(x.n) AS receipts, SUM(x.rev) AS rev, SUM(x.disc) AS disc,
       SUM(x.ret) AS ret, SUM(x.retn) AS retn, SUM(x.v) AS voids
  FROM (
    SELECT s.$col AS uid,
           CASE WHEN s.status NOT IN ('voided', 'held') THEN 1 ELSE 0 END AS n,
           CASE WHEN s.status NOT IN ('voided', 'held') THEN s.total ELSE 0 END AS rev,
           CASE WHEN s.status NOT IN ('voided', 'held') THEN s.discount_total ELSE 0 END AS disc,
           0 AS ret, 0 AS retn,
           CASE WHEN s.status = 'voided' THEN 1 ELSE 0 END AS v
      FROM sales s WHERE s.created_at >= ?1 AND s.created_at < ?2 AND s.deleted_at IS NULL
    UNION ALL
    SELECT s.$col, 0, 0, 0, r.total, 1, 0
      FROM returns r JOIN sales s ON s.id = r.sale_id
     WHERE r.created_at >= ?1 AND r.created_at < ?2 AND r.deleted_at IS NULL
  ) x
  LEFT JOIN users u ON u.id = x.uid
 GROUP BY x.uid
 ORDER BY rev DESC
''';
}

Stream<List<StaffRow>> watchByStaff(AppDatabase db, ReportPeriod p, StaffGrouping g) => db
    .customSelect(_staffSql(g),
        variables: periodVars(p), readsFrom: {db.sales, db.returns, db.users})
    .watch()
    .map((rows) => [
          for (final r in rows)
            StaffRow(
              userId: qs(r, 'uid'),
              name: qs(r, 'name') ?? 'Не указан',
              receipts: qi(r, 'receipts'),
              revenue: qi(r, 'rev'),
              discounts: qi(r, 'disc'),
              returnsTotal: qi(r, 'ret'),
              returnsCount: qi(r, 'retn'),
              voids: qi(r, 'voids'),
            ),
        ]);

// ------------------------------------------------------------------ payments

class PaymentRow {
  const PaymentRow(this.method, this.paid, this.refunded, this.receipts);
  final String method;
  final int paid;
  final int refunded;
  final int receipts;
  int get net => paid - refunded;
}

const _paymentsSql = '''
SELECT m, SUM(paid) AS paid, SUM(ref) AS ref, SUM(n) AS n FROM (
  SELECT sp.method AS m, sp.amount AS paid, 0 AS ref, 1 AS n
    FROM sale_payments sp JOIN sales s ON s.id = sp.sale_id
   WHERE s.created_at >= ?1 AND s.created_at < ?2 AND $validSale AND sp.deleted_at IS NULL
  UNION ALL
  SELECT r.refund_method, 0, r.total, 0
    FROM returns r WHERE r.created_at >= ?1 AND r.created_at < ?2 AND r.deleted_at IS NULL
) GROUP BY m ORDER BY paid DESC
''';

Selectable<PaymentRow> paymentsQuery(AppDatabase db, ReportPeriod p) => db
    .customSelect(_paymentsSql,
        variables: periodVars(p), readsFrom: {db.sales, db.salePayments, db.returns})
    .map((r) => PaymentRow(qs(r, 'm') ?? '?', qi(r, 'paid'), qi(r, 'ref'), qi(r, 'n')));

Stream<List<PaymentRow>> watchPayments(AppDatabase db, ReportPeriod p) =>
    paymentsQuery(db, p).watch();

class DebtSummary {
  const DebtSummary(
      {this.issued = 0, this.collected = 0, this.adjusted = 0, this.outstanding = 0, this.debtors = 0});
  /// Sold on credit in the period.
  final int issued;
  /// Paid back by customers in the period.
  final int collected;
  /// Returns / voids / manual corrections (signed, usually negative).
  final int adjusted;
  /// Total debt right now.
  final int outstanding;
  final int debtors;
  int get netChange => issued - collected + adjusted;
}

const _debtSql = '''
SELECT
  (SELECT COALESCE(SUM(amount), 0) FROM customer_ledger WHERE kind = 'debt_sale' AND created_at >= ?1 AND created_at < ?2 AND deleted_at IS NULL) AS issued,
  (SELECT COALESCE(-SUM(amount), 0) FROM customer_ledger WHERE kind = 'debt_payment' AND created_at >= ?1 AND created_at < ?2 AND deleted_at IS NULL) AS collected,
  (SELECT COALESCE(SUM(amount), 0) FROM customer_ledger WHERE kind = 'debt_adjust' AND created_at >= ?1 AND created_at < ?2 AND deleted_at IS NULL) AS adjusted,
  (SELECT COALESCE(SUM(debt_balance), 0) FROM customers WHERE deleted_at IS NULL AND debt_balance > 0) AS outstanding,
  (SELECT COUNT(*) FROM customers WHERE deleted_at IS NULL AND debt_balance > 0) AS debtors
''';

Stream<DebtSummary> watchDebts(AppDatabase db, ReportPeriod p) => db
    .customSelect(_debtSql, variables: periodVars(p), readsFrom: {db.customerLedger, db.customers})
    .watchSingle()
    .map((r) => DebtSummary(
          issued: qi(r, 'issued'),
          collected: qi(r, 'collected'),
          adjusted: qi(r, 'adjusted'),
          outstanding: qi(r, 'outstanding'),
          debtors: qi(r, 'debtors'),
        ));

// ------------------------------------------------------------------ stock

class StockValueRow {
  const StockValueRow(this.categoryName, this.items, this.qty, this.costValue, this.retailValue);
  final String categoryName;
  final int items;
  final double qty;
  final int costValue;
  final int retailValue;
  int get potentialProfit => retailValue - costValue;
}

const _stockValueSql = '''
SELECT COALESCE(c.name, 'Без категории') AS cname, COUNT(*) AS n, SUM(p.stock_qty) AS qty,
       SUM(p.stock_qty * p.cost_price) AS cost_value, SUM(p.stock_qty * p.price) AS retail_value
  FROM products p LEFT JOIN categories c ON c.id = p.category_id
 WHERE p.deleted_at IS NULL AND p.track_stock = 1 AND p.stock_qty > 0
 GROUP BY p.category_id
 ORDER BY cost_value DESC
''';

Stream<List<StockValueRow>> watchStockValue(AppDatabase db) => db
    .customSelect(_stockValueSql, readsFrom: {db.products, db.categories})
    .watch()
    .map((rows) => [
          for (final r in rows)
            StockValueRow(qs(r, 'cname') ?? 'Без категории', qi(r, 'n'), qd(r, 'qty'),
                qi(r, 'cost_value'), qi(r, 'retail_value')),
        ]);

class DeadStockRow {
  const DeadStockRow(this.id, this.name, this.unit, this.qty, this.value, this.lastSale);
  final String id;
  final String name;
  final String unit;
  final double qty;
  final int value;
  final DateTime? lastSale;
}

const deadStockDays = 60;

const _deadStockSql = '''
SELECT p.id AS id, p.name AS name, p.unit AS unit, p.stock_qty AS qty,
       p.stock_qty * p.cost_price AS value,
       (SELECT MAX(s.created_at) FROM sale_items si JOIN sales s ON s.id = si.sale_id
         WHERE si.product_id = p.id AND $validSale) AS last_sale
  FROM products p
 WHERE p.deleted_at IS NULL AND p.track_stock = 1 AND p.stock_qty > 0 AND p.created_at < ?1
   AND NOT EXISTS (SELECT 1 FROM sale_items si JOIN sales s ON s.id = si.sale_id
                    WHERE si.product_id = p.id AND s.created_at >= ?1 AND $validSale)
 ORDER BY value DESC
''';

/// Products with stock > 0, older than [days] and without sales in [days].
Selectable<DeadStockRow> deadStockQuery(AppDatabase db, {DateTime? now, int days = deadStockDays}) {
  final n = now ?? DateTime.now();
  return db
      .customSelect(_deadStockSql,
          variables: [Variable.withDateTime(n.subtract(Duration(days: days)))],
          readsFrom: {db.products, db.sales, db.saleItems})
      .map((r) => DeadStockRow(qs(r, 'id') ?? '', qs(r, 'name') ?? '', qs(r, 'unit') ?? 'pcs',
          qd(r, 'qty'), qi(r, 'value'), r.readNullable<DateTime>('last_sale')));
}

class WriteOffRow {
  const WriteOffRow(this.reason, this.count, this.qty, this.cost);
  final String reason;
  final int count;
  final double qty;
  final int cost;
}

const _writeOffSql = '''
SELECT COALESCE(NULLIF(TRIM(reason), ''), 'Без причины') AS reason, COUNT(*) AS n,
       SUM(-qty) AS qty, SUM(-qty * unit_cost) AS cost
  FROM stock_movements
 WHERE type = 'writeoff' AND created_at >= ?1 AND created_at < ?2 AND deleted_at IS NULL
 GROUP BY 1
 ORDER BY cost DESC
''';

Stream<List<WriteOffRow>> watchWriteOffs(AppDatabase db, ReportPeriod p) => db
    .customSelect(_writeOffSql, variables: periodVars(p), readsFrom: {db.stockMovements})
    .watch()
    .map((rows) => [
          for (final r in rows)
            WriteOffRow(qs(r, 'reason') ?? '', qi(r, 'n'), qd(r, 'qty'), qi(r, 'cost')),
        ]);

// ------------------------------------------------------------------ demand

class DemandRow {
  const DemandRow({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    required this.minStock,
    required this.costPrice,
    required this.createdAt,
    required this.sold28,
    required this.sold7,
  });
  final String id;
  final String name;
  final String unit;
  final double stock;
  final double minStock;
  final int costPrice;
  final DateTime createdAt;
  /// Net units sold in the last 28 days / 7 days.
  final double sold28;
  final double sold7;
}

const _demandSql = '''
SELECT p.id AS id, p.name AS name, p.unit AS unit, p.stock_qty AS stock, p.min_stock AS min_stock,
       p.cost_price AS cost, p.created_at AS created_at,
       COALESCE((SELECT SUM(si.qty - si.returned_qty) FROM sale_items si JOIN sales s ON s.id = si.sale_id
                  WHERE si.product_id = p.id AND s.created_at >= ?1 AND s.created_at < ?3 AND $validSale), 0) AS sold28,
       COALESCE((SELECT SUM(si.qty - si.returned_qty) FROM sale_items si JOIN sales s ON s.id = si.sale_id
                  WHERE si.product_id = p.id AND s.created_at >= ?2 AND s.created_at < ?3 AND $validSale), 0) AS sold7
  FROM products p
 WHERE p.deleted_at IS NULL AND p.is_active = 1 AND p.track_stock = 1
''';

Selectable<DemandRow> demandQuery(AppDatabase db, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return db
      .customSelect(_demandSql, variables: [
        Variable.withDateTime(n.subtract(const Duration(days: 28))),
        Variable.withDateTime(n.subtract(const Duration(days: 7))),
        Variable.withDateTime(n),
      ], readsFrom: {
        db.products,
        db.sales,
        db.saleItems
      })
      .map((r) => DemandRow(
            id: qs(r, 'id') ?? '',
            name: qs(r, 'name') ?? '',
            unit: qs(r, 'unit') ?? 'pcs',
            stock: qd(r, 'stock'),
            minStock: qd(r, 'min_stock'),
            costPrice: qi(r, 'cost'),
            createdAt: r.read<DateTime>('created_at'),
            sold28: qd(r, 'sold28'),
            sold7: qd(r, 'sold7'),
          ));
}
