// Live drift queries for the receipts module.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import 'sales_logic.dart';

class SaleRow {
  SaleRow({required this.sale, this.cashierName, this.customerName, required this.itemsCount, required this.methods});
  final Sale sale;
  final String? cashierName;
  final String? customerName;
  final int itemsCount;
  final List<String> methods;
}

class SalesTotals {
  const SalesTotals({this.count = 0, this.gross = 0, this.refunded = 0, this.voided = 0});
  final int count;

  /// Sum of non-voided receipts.
  final int gross;

  /// Refunds made against the non-voided receipts.
  final int refunded;
  final int voided;
  int get net => gross - refunded;
}

class _Where {
  _Where(this.sql, this.vars);
  final String sql;
  final List<Variable> vars;
}

_Where _salesWhere(SalesFilter f, DateTime now) {
  final parts = <String>["s.deleted_at IS NULL", "s.status <> 'held'"];
  final vars = <Variable>[];
  final span = f.span(now);
  if (span.from != null) {
    parts.add('s.created_at >= ?');
    vars.add(Variable.withDateTime(span.from!));
  }
  if (span.to != null) {
    parts.add('s.created_at < ?');
    vars.add(Variable.withDateTime(span.to!));
  }
  if (f.status != null) {
    parts.add('s.status = ?');
    vars.add(Variable.withString(f.status!));
  }
  if (f.cashierId != null) {
    parts.add('s.cashier_id = ?');
    vars.add(Variable.withString(f.cashierId!));
  }
  if (f.shiftId != null) {
    parts.add('s.shift_id = ?');
    vars.add(Variable.withString(f.shiftId!));
  }
  if (f.method != null) {
    parts.add('EXISTS (SELECT 1 FROM sale_payments p WHERE p.sale_id = s.id AND p.method = ?)');
    vars.add(Variable.withString(f.method!));
  }
  final q = f.query.trim();
  if (q.isNotEmpty) {
    final or = <String>[];
    final n = int.tryParse(q.replaceAll('№', '').replaceAll('#', '').trim());
    if (n != null) {
      or.add('s.number = ?');
      vars.add(Variable.withInt(n));
    }
    for (final like in likeVariants(q)) {
      or.add('c.name LIKE ?');
      vars.add(Variable.withString(like));
      or.add('EXISTS (SELECT 1 FROM sale_items i WHERE i.sale_id = s.id AND i.product_name LIKE ?)');
      vars.add(Variable.withString(like));
    }
    final digits = q.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 3) {
      or.add('c.phone LIKE ?');
      vars.add(Variable.withString('%$digits%'));
    }
    parts.add('(${or.join(' OR ')})');
  }
  return _Where(parts.join(' AND '), vars);
}

Stream<List<SaleRow>> watchSales(AppDatabase db, SalesFilter f, {DateTime? now}) {
  final w = _salesWhere(f, now ?? DateTime.now());
  return db
      .customSelect(
        '''
SELECT s.*, u.name AS x_cashier, c.name AS x_customer,
  (SELECT COUNT(*) FROM sale_items i WHERE i.sale_id = s.id) AS x_items,
  (SELECT GROUP_CONCAT(DISTINCT p.method) FROM sale_payments p WHERE p.sale_id = s.id) AS x_methods
FROM sales s
LEFT JOIN users u ON u.id = s.cashier_id
LEFT JOIN customers c ON c.id = s.customer_id
WHERE ${w.sql}
ORDER BY s.created_at DESC, s.number DESC
LIMIT ?''',
        variables: [...w.vars, Variable.withInt(f.limit)],
        readsFrom: {db.sales, db.users, db.customers, db.saleItems, db.salePayments},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            SaleRow(
              sale: db.sales.map(r.data),
              cashierName: r.readNullable<String>('x_cashier'),
              customerName: r.readNullable<String>('x_customer'),
              itemsCount: r.read<int>('x_items'),
              methods: (r.readNullable<String>('x_methods') ?? '').split(',').where((m) => m.isNotEmpty).toList(),
            ),
        ],
      );
}

Stream<SalesTotals> watchSalesTotals(AppDatabase db, SalesFilter f, {DateTime? now}) {
  final w = _salesWhere(f, now ?? DateTime.now());
  return db
      .customSelect(
        '''
SELECT COUNT(*) AS cnt,
  COALESCE(SUM(CASE WHEN s.status <> 'voided' THEN s.total ELSE 0 END), 0) AS gross,
  COALESCE(SUM(CASE WHEN s.status <> 'voided' THEN s.refunded_total ELSE 0 END), 0) AS refunded,
  COALESCE(SUM(CASE WHEN s.status = 'voided' THEN 1 ELSE 0 END), 0) AS voided
FROM sales s
LEFT JOIN customers c ON c.id = s.customer_id
WHERE ${w.sql}''',
        variables: w.vars,
        readsFrom: {db.sales, db.customers, db.saleItems, db.salePayments},
      )
      .watchSingle()
      .map(
        (r) => SalesTotals(
          count: r.read<int>('cnt'),
          gross: r.read<int>('gross'),
          refunded: r.read<int>('refunded'),
          voided: r.read<int>('voided'),
        ),
      );
}

final salesListProvider = StreamProvider.autoDispose.family<List<SaleRow>, SalesFilter>(
  (ref, f) => watchSales(ref.watch(databaseProvider), f),
);

final salesTotalsProvider = StreamProvider.autoDispose.family<SalesTotals, SalesFilter>(
  (ref, f) => watchSalesTotals(ref.watch(databaseProvider), f),
);

/// Staff list for the cashier filter and name lookups.
final staffProvider = StreamProvider.autoDispose<List<User>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.users)..orderBy([(u) => OrderingTerm.asc(u.name)])).watch();
});

// ------------------------------------------------------------------ detail

class ReturnWithItems {
  ReturnWithItems({required this.ret, required this.items, this.userName});
  final Return ret;

  /// (return item, product name snapshot)
  final List<(ReturnItem, String)> items;
  final String? userName;
}

class SaleDetail {
  SaleDetail({
    required this.sale,
    required this.items,
    required this.payments,
    required this.returns,
    required this.units,
    this.cashierName,
    this.sellerName,
    this.customer,
    this.shift,
  });
  final Sale sale;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final List<ReturnWithItems> returns;

  /// productId -> unit (pcs/kg/...)
  final Map<String, String> units;
  final String? cashierName;
  final String? sellerName;
  final Customer? customer;
  final Shift? shift;

  String unitOf(SaleItem i) => units[i.productId] ?? 'pcs';
  bool get hasReturnable => items.any((i) => availableToReturn(i) > 1e-9);
}

Future<SaleDetail?> loadSaleDetail(AppDatabase db, String saleId) async {
  final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingleOrNull();
  if (sale == null) return null;
  final items =
      await (db.select(db.saleItems)
            ..where((i) => i.saleId.equals(saleId))
            ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
          .get();
  final payments = await (db.select(db.salePayments)..where((p) => p.saleId.equals(saleId))).get();
  final rets =
      await (db.select(db.returns)
            ..where((r) => r.saleId.equals(saleId))
            ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
          .get();
  final users = {for (final u in await db.select(db.users).get()) u.id: u.name};
  final names = {for (final i in items) i.id: i.productName};
  final returns = <ReturnWithItems>[];
  for (final r in rets) {
    final ri = await (db.select(db.returnItems)..where((x) => x.returnId.equals(r.id))).get();
    returns.add(
      ReturnWithItems(ret: r, items: [for (final x in ri) (x, names[x.saleItemId] ?? '—')], userName: users[r.userId]),
    );
  }
  final productIds = items.map((i) => i.productId).toSet();
  final products = await (db.select(db.products)..where((p) => p.id.isIn(productIds))).get();
  final customer = sale.customerId == null
      ? null
      : await (db.select(db.customers)..where((c) => c.id.equals(sale.customerId!))).getSingleOrNull();
  final shift = sale.shiftId == null
      ? null
      : await (db.select(db.shifts)..where((s) => s.id.equals(sale.shiftId!))).getSingleOrNull();
  return SaleDetail(
    sale: sale,
    items: items,
    payments: payments,
    returns: returns,
    units: {for (final p in products) p.id: p.unit},
    cashierName: users[sale.cashierId],
    sellerName: users[sale.sellerId],
    customer: customer,
    shift: shift,
  );
}

/// Re-loads the detail whenever any related table changes.
Stream<SaleDetail?> watchSaleDetail(AppDatabase db, String saleId) => db
    .customSelect(
      'SELECT 1',
      readsFrom: {db.sales, db.saleItems, db.salePayments, db.returns, db.returnItems, db.customers},
    )
    .watch()
    .asyncMap((_) => loadSaleDetail(db, saleId));

final saleDetailProvider = StreamProvider.autoDispose.family<SaleDetail?, String>(
  (ref, id) => watchSaleDetail(ref.watch(databaseProvider), id),
);

Future<Sale?> findSaleByNumber(AppDatabase db, int number) async {
  final list =
      await (db.select(db.sales)
            ..where((s) => s.number.equals(number) & s.deletedAt.isNull())
            ..limit(1))
          .get();
  return list.isEmpty ? null : list.first;
}

// ------------------------------------------------------------------ returns list

class ReturnsFilter {
  const ReturnsFilter({
    this.period = Period.week,
    this.custom,
    this.method,
    this.shiftId,
    this.query = '',
    this.limit = SalesFilter.pageSize,
  });
  final Period period;
  final DateSpan? custom;
  final String? method;

  /// Forced for users without "view all shifts".
  final String? shiftId;
  final String query;
  final int limit;

  ReturnsFilter copyWith({
    Period? period,
    DateSpan? custom,
    String? Function()? method,
    String? Function()? shiftId,
    String? query,
    int? limit,
  }) => ReturnsFilter(
    period: period ?? this.period,
    custom: custom ?? this.custom,
    method: method == null ? this.method : method(),
    shiftId: shiftId == null ? this.shiftId : shiftId(),
    query: query ?? this.query,
    limit: limit ?? SalesFilter.pageSize,
  );

  @override
  bool operator ==(Object other) =>
      other is ReturnsFilter &&
      other.period == period &&
      other.custom == custom &&
      other.method == method &&
      other.shiftId == shiftId &&
      other.query == query &&
      other.limit == limit;
  @override
  int get hashCode => Object.hash(period, custom, method, shiftId, query, limit);
}

class ReturnRow {
  ReturnRow({required this.ret, required this.saleNumber, this.userName, this.customerName, required this.itemsCount});
  final Return ret;
  final int saleNumber;
  final String? userName;
  final String? customerName;
  final int itemsCount;
}

class ReturnsTotals {
  const ReturnsTotals({this.count = 0, this.sum = 0});
  final int count;
  final int sum;
}

_Where _returnsWhere(ReturnsFilter f, DateTime now) {
  final parts = <String>['r.deleted_at IS NULL'];
  final vars = <Variable>[];
  if (f.shiftId != null) {
    // a restricted user sees only the current shift, whatever the period
    parts.add('r.shift_id = ?');
    vars.add(Variable.withString(f.shiftId!));
  } else {
    final span = periodSpan(f.period, now, custom: f.custom);
    if (span.from != null) {
      parts.add('r.created_at >= ?');
      vars.add(Variable.withDateTime(span.from!));
    }
    if (span.to != null) {
      parts.add('r.created_at < ?');
      vars.add(Variable.withDateTime(span.to!));
    }
  }
  if (f.method != null) {
    parts.add('r.refund_method = ?');
    vars.add(Variable.withString(f.method!));
  }
  final q = f.query.trim();
  if (q.isNotEmpty) {
    final or = <String>[];
    final n = int.tryParse(q.replaceAll('№', '').replaceAll('#', '').trim());
    if (n != null) {
      or.addAll(['r.number = ?', 's.number = ?']);
      vars.addAll([Variable.withInt(n), Variable.withInt(n)]);
    }
    for (final like in likeVariants(q)) {
      or.addAll(['r.reason LIKE ?', 'c.name LIKE ?']);
      vars.addAll([Variable.withString(like), Variable.withString(like)]);
    }
    parts.add('(${or.join(' OR ')})');
  }
  return _Where(parts.join(' AND '), vars);
}

Stream<List<ReturnRow>> watchReturns(AppDatabase db, ReturnsFilter f, {DateTime? now}) {
  final w = _returnsWhere(f, now ?? DateTime.now());
  return db
      .customSelect(
        '''
SELECT r.*, s.number AS x_sale_number, u.name AS x_user, c.name AS x_customer,
  (SELECT COUNT(*) FROM return_items ri WHERE ri.return_id = r.id) AS x_items
FROM returns r
JOIN sales s ON s.id = r.sale_id
LEFT JOIN users u ON u.id = r.user_id
LEFT JOIN customers c ON c.id = s.customer_id
WHERE ${w.sql}
ORDER BY r.created_at DESC, r.number DESC
LIMIT ?''',
        variables: [...w.vars, Variable.withInt(f.limit)],
        readsFrom: {db.returns, db.sales, db.users, db.customers, db.returnItems},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            ReturnRow(
              ret: db.returns.map(r.data),
              saleNumber: r.read<int>('x_sale_number'),
              userName: r.readNullable<String>('x_user'),
              customerName: r.readNullable<String>('x_customer'),
              itemsCount: r.read<int>('x_items'),
            ),
        ],
      );
}

/// Count and sum of ALL returns matching the filter (not only loaded rows).
Stream<ReturnsTotals> watchReturnsTotals(AppDatabase db, ReturnsFilter f, {DateTime? now}) {
  final w = _returnsWhere(f, now ?? DateTime.now());
  return db
      .customSelect(
        '''
SELECT COUNT(*) AS cnt, COALESCE(SUM(r.total), 0) AS total
FROM returns r
JOIN sales s ON s.id = r.sale_id
LEFT JOIN customers c ON c.id = s.customer_id
WHERE ${w.sql}''',
        variables: w.vars,
        readsFrom: {db.returns, db.sales, db.customers},
      )
      .watchSingle()
      .map((r) => ReturnsTotals(count: r.read<int>('cnt'), sum: r.read<int>('total')));
}

final returnsListProvider = StreamProvider.autoDispose.family<List<ReturnRow>, ReturnsFilter>(
  (ref, f) => watchReturns(ref.watch(databaseProvider), f),
);

final returnsTotalsProvider = StreamProvider.autoDispose.family<ReturnsTotals, ReturnsFilter>(
  (ref, f) => watchReturnsTotals(ref.watch(databaseProvider), f),
);
