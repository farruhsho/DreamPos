// Purchasing (Закупки) data layer: suppliers, supplier payments, purchase
// orders with partial receiving, reorder suggestions and purchase price
// control. Receipts are goods_receipts documents posted by ReceiptService;
// supplier balances change only through SupplierLedgerService.
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../domain/errors.dart';
import '../../domain/services/receipt_service.dart';
import '../../domain/services/stock_service.dart';
import '../../domain/services/supplier_service.dart';

export '../../domain/services/supplier_service.dart' show SupplierLedgerKind;

// ------------------------------------------------------------------ labels

const poStatusLabels = <String, String>{
  'draft': 'Черновик',
  'ordered': 'Заказан',
  poPartialStatus: 'Частично получен',
  'received': 'Получен',
  'cancelled': 'Отменён',
};

/// Display-only status for an `ordered` PO with some lines already received.
/// Never stored: the DB keeps `ordered` until everything arrives.
const poPartialStatus = 'partial';

/// Computed status shown in the UI: `ordered` + any received qty → `partial`.
String poDisplayStatus(String status, {required bool anyReceived}) =>
    status == 'ordered' && anyReceived ? poPartialStatus : status;

/// [poDisplayStatus] for an order and its lines.
String poDisplayStatusOf(PurchaseOrder o, Iterable<PurchaseOrderItem> items) =>
    poDisplayStatus(o.status, anyReceived: items.any((i) => i.deletedAt == null && i.receivedQty > 0));

const paymentMethodLabels = <String, String>{'cash': 'Наличные', 'card': 'Карта', 'transfer': 'Перечисление'};

// ------------------------------------------------------------------ providers

final purSuppliersProvider = StreamProvider<List<Supplier>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.suppliers)
        ..where((s) => s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.asc(s.name)]))
      .watch();
});

final purSupplierProvider = StreamProvider.family<Supplier?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.suppliers)..where((s) => s.id.equals(id))).watchSingleOrNull();
});

/// All suppliers incl. deleted (documents may reference them).
final purSupplierNamesProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.suppliers).watch().map((l) => {for (final s in l) s.id: s.name});
});

final purProductMapProvider = StreamProvider<Map<String, Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.products).watch().map((l) => {for (final p in l) p.id: p});
});

final purOrdersProvider = StreamProvider<List<PurchaseOrder>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.purchaseOrders)
        ..where((o) => o.deletedAt.isNull())
        ..orderBy([(o) => OrderingTerm.desc(o.number)]))
      .watch();
});

final purOrderProvider = StreamProvider.family<PurchaseOrder?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.purchaseOrders)..where((o) => o.id.equals(id))).watchSingleOrNull();
});

/// Ids of `ordered` POs that already have some lines received (→ «Частично получен»).
final purPartlyReceivedOrderIdsProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT DISTINCT i.order_id AS oid '
        'FROM purchase_order_items i JOIN purchase_orders o ON o.id = i.order_id '
        "WHERE o.status = 'ordered' AND i.received_qty > 0 AND i.deleted_at IS NULL",
        readsFrom: {db.purchaseOrderItems, db.purchaseOrders},
      )
      .watch()
      .map((rows) => {for (final r in rows) r.read<String>('oid')});
});

/// Actual received value of an order at invoice cost: Σ totals of its
/// POSTED receipt documents (reversed receipts do not count).
final purOrderReceivedValueProvider = StreamProvider.family<int, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.goodsReceipts)
        ..where((r) => r.orderId.equals(id) & r.status.equals('posted') & r.deletedAt.isNull()))
      .watch()
      .map((rows) => rows.fold<int>(0, (s, r) => s + r.total));
});

/// Receipt documents of a purchase order (all statuses), oldest first.
final purOrderReceiptsProvider = StreamProvider.family<List<GoodsReceipt>, String>((ref, orderId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.goodsReceipts)
        ..where((r) => r.orderId.equals(orderId) & r.deletedAt.isNull())
        ..orderBy([(r) => OrderingTerm.asc(r.number)]))
      .watch();
});

/// Supplier ledger («Взаиморасчёты») in chronological order; the last row's
/// `balanceAfter` equals `suppliers.balance`.
final purSupplierLedgerProvider = StreamProvider.family<List<SupplierLedgerEntry>, String>((ref, supplierId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.supplierLedger)
        ..where((l) => l.supplierId.equals(supplierId) & l.deletedAt.isNull())
        ..orderBy([(l) => OrderingTerm.asc(l.createdAt), (l) => OrderingTerm.asc(l.rowId)]))
      .watch();
});

/// Receipt stock movements for the price control tab since [days] ago,
/// excluding lines of reversed receipt documents.
final purReceiptMovementsProvider = StreamProvider.family<List<StockMovement>, int>((ref, days) {
  final db = ref.watch(databaseProvider);
  final since = DateTime.now().subtract(Duration(days: days));
  return db
      .customSelect(
        'SELECT m.* FROM stock_movements m '
        "WHERE m.type = 'receipt' AND m.created_at >= ? AND m.deleted_at IS NULL "
        "AND NOT (m.ref_type = 'receipt' AND m.ref_id IN "
        "(SELECT id FROM goods_receipts WHERE status = 'reversed'))",
        variables: [Variable.withDateTime(since)],
        readsFrom: {db.stockMovements, db.goodsReceipts},
      )
      .watch()
      .map((rows) => [for (final r in rows) db.stockMovements.map(r.data)]);
});

final purOrderItemsProvider = StreamProvider.family<List<PurchaseOrderItem>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.purchaseOrderItems)
        ..where((i) => i.orderId.equals(id) & i.deletedAt.isNull())
        ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
      .watch();
});

final purSupplierPaymentsProvider = StreamProvider.family<List<SupplierPayment>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.supplierPayments)
        ..where((p) => p.supplierId.equals(id) & p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
      .watch();
});

final purSupplierOrdersProvider = StreamProvider.family<List<PurchaseOrder>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.purchaseOrders)
        ..where((o) => o.supplierId.equals(id) & o.deletedAt.isNull())
        ..orderBy([(o) => OrderingTerm.desc(o.number)]))
      .watch();
});

final purchasingRepoProvider = Provider(
  (ref) => PurchasingRepo(
    ref.watch(databaseProvider),
    ref.watch(stockServiceProvider),
    ref.watch(receiptServiceProvider),
    ref.watch(supplierLedgerServiceProvider),
  ),
);

// ------------------------------------------------------------------ supplier statement

const supplierLedgerKindLabels = <String, String>{
  'opening': 'Начальный остаток',
  'receipt': 'Приход',
  'receipt_reversal': 'Сторно прихода',
  'payment': 'Оплата',
  'payment_cancel': 'Отмена оплаты',
  'adjustment': 'Корректировка',
};

/// Supplier statement (акт сверки) for a period built from ledger rows.
/// * [opening] — balance before [from] (last balanceAfter before it, else 0);
///   a leading `opening` (migration back-fill) row inside the period counts
///   here, not as turnover;
/// * [increase] — Σ positive amounts in the period (приход, store owes more);
/// * [decrease] — Σ |negative amounts| in the period (расход/оплаты);
/// * [closing] — opening + increase − decrease (== last balanceAfter).
class SupplierStatement {
  const SupplierStatement({
    required this.opening,
    required this.rows,
    required this.increase,
    required this.decrease,
    required this.closing,
  });
  final int opening;
  final List<SupplierLedgerEntry> rows;
  final int increase;
  final int decrease;
  final int closing;

  /// [entries] in chronological order (as [purSupplierLedgerProvider]);
  /// [from] inclusive, [to] exclusive; null = unbounded.
  static SupplierStatement of(List<SupplierLedgerEntry> entries, {DateTime? from, DateTime? to}) {
    var opening = 0;
    final rows = <SupplierLedgerEntry>[];
    for (final e in entries) {
      if (from != null && e.createdAt.isBefore(from)) {
        opening = e.balanceAfter;
      } else if (to == null || e.createdAt.isBefore(to)) {
        // The migration `opening` row is a starting balance, not turnover:
        // it becomes «Сальдо на начало» of a period that contains it.
        if (e.kind == SupplierLedgerKind.opening && rows.isEmpty) {
          opening = e.balanceAfter;
        } else {
          rows.add(e);
        }
      }
    }
    var inc = 0, dec = 0;
    for (final e in rows) {
      if (e.amount > 0) {
        inc += e.amount;
      } else {
        dec += -e.amount;
      }
    }
    return SupplierStatement(opening: opening, rows: rows, increase: inc, decrease: dec, closing: opening + inc - dec);
  }
}

/// Operation text of a ledger row: «Приход №N», «Сторно прихода №N»,
/// «Оплата (Перечисление)», «Отмена оплаты», «Корректировка»…
/// [receiptNumbers]: goods_receipts.id → number; [payments]: id → payment.
String supplierLedgerOperation(
  SupplierLedgerEntry e, {
  Map<String, int> receiptNumbers = const {},
  Map<String, SupplierPayment> payments = const {},
}) {
  final base = supplierLedgerKindLabels[e.kind] ?? e.kind;
  switch (e.kind) {
    case SupplierLedgerKind.receipt:
    case SupplierLedgerKind.receiptReversal:
      final n = e.refId == null ? null : receiptNumbers[e.refId];
      return n == null ? base : '$base №$n';
    case SupplierLedgerKind.payment:
      final p = e.refId == null ? null : payments[e.refId];
      final m = p == null ? null : paymentMethodLabels[p.method] ?? p.method;
      return m == null ? base : '$base ($m)';
    default:
      return base;
  }
}

/// Payment that a `payment` ledger row can cancel: the referenced payment
/// when it exists and is not cancelled yet; null otherwise.
SupplierPayment? cancellablePayment(SupplierLedgerEntry e, Map<String, SupplierPayment> payments) {
  if (e.kind != SupplierLedgerKind.payment || e.refId == null) return null;
  final p = payments[e.refId];
  if (p == null || p.cancelledAt != null || p.deletedAt != null) return null;
  return p;
}

/// Cancelling a cash payment returns cash to the drawer's expected balance
/// (a cash-in), so it needs `Perm.cashInOut` like paying in cash does.
bool supplierPaymentCancelAllowed(SupplierPayment p, {required bool canCash}) => p.method != 'cash' || canCash;

/// Tooltip / error when [supplierPaymentCancelAllowed] is false.
const noCashPermissionText = 'Нет права на операции с наличными';

/// Period presets of the «Взаиморасчёты» section.
enum LedgerPeriod {
  all('Всё время'),
  month('Этот месяц'),
  lastMonth('Прошлый месяц'),
  quarter('Квартал'),
  year('Год'),
  custom('Период…');

  const LedgerPeriod(this.label);
  final String label;
}

/// Half-open range `[from, to)` of [p] (null = unbounded). For
/// [LedgerPeriod.custom] pass the inclusive days [first]..[last].
({DateTime? from, DateTime? to}) ledgerPeriodRange(LedgerPeriod p, {DateTime? now, DateTime? first, DateTime? last}) {
  final n = now ?? DateTime.now();
  final tomorrow = DateTime(n.year, n.month, n.day + 1);
  return switch (p) {
    LedgerPeriod.all => (from: null, to: null),
    LedgerPeriod.month => (from: DateTime(n.year, n.month, 1), to: tomorrow),
    LedgerPeriod.lastMonth => (from: DateTime(n.year, n.month - 1, 1), to: DateTime(n.year, n.month, 1)),
    LedgerPeriod.quarter => (from: DateTime(n.year, ((n.month - 1) ~/ 3) * 3 + 1, 1), to: tomorrow),
    LedgerPeriod.year => (from: DateTime(n.year, 1, 1), to: tomorrow),
    LedgerPeriod.custom => (
      from: first == null ? null : DateTime(first.year, first.month, first.day),
      to: last == null ? null : DateTime(last.year, last.month, last.day + 1),
    ),
  };
}

/// Human period text without a preposition: «01.11.2026 – 24.11.2026»,
/// «по 24.11.2026», «всё время». Callers add «за период» / «Период» as their
/// grammar needs (see [ledgerPeriodHeading]).
String ledgerPeriodText(DateTime? from, DateTime? to, {DateTime? firstEntry}) {
  final last = to?.subtract(const Duration(days: 1));
  final start = from ?? firstEntry;
  if (start == null && last == null) return ledgerAllTimeText;
  if (start == null) return 'по ${_d(last!)}';
  return '${_d(start)} – ${_d(last ?? DateTime.now())}';
}

const ledgerAllTimeText = 'всё время';

/// Heading line of the act: «за период 01.11.2026 – 24.11.2026», «за всё время».
String ledgerPeriodHeading(String period) => period == ledgerAllTimeText ? 'за $period' : 'за период $period';

String _d(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
String _dt(DateTime d) => '${_d(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Conclusion line of the act: who owes whom at the end of the period.
String statementConclusion(int closing, {required String store, required String supplier, required String at}) {
  if (closing == 0) return 'На $at задолженность между сторонами отсутствует.';
  if (closing > 0) return 'На $at задолженность «$store» перед «$supplier» составляет ${Money.format(closing)}.';
  return 'На $at задолженность «$supplier» перед «$store» (аванс) составляет ${Money.format(-closing)}.';
}

/// A plain (possibly negative) number as [_csvMoney] writes it («-1250,5»).
/// Only such cells may start with «-» without the formula escape.
final _csvNumber = RegExp(r'^-?\d+(,\d+)?$');

String _csvCell(String v) {
  var s = v;
  // CSV injection: text a spreadsheet would treat as a formula.
  if (s.isNotEmpty && const ['=', '+', '-', '@', '\t', '\r'].contains(s[0]) && !_csvNumber.hasMatch(s)) {
    s = "'$s";
  }
  if (s.contains(';') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String _csvMoney(int minor) => Money.toInput(minor).replaceAll('.', ',');

/// Reconciliation act (акт сверки) as semicolon-separated CSV (Excel, Russian
/// locale): header, opening balance, rows, turnovers, closing balance.
/// [operation] renders the operation text of a row.
String supplierStatementCsv({
  required SupplierStatement st,
  required String supplierName,
  required String storeName,
  required String period,
  required String Function(SupplierLedgerEntry) operation,
}) {
  final rows = <List<String>>[
    ['Акт сверки взаиморасчётов'],
    ['Магазин', storeName],
    ['Поставщик', supplierName],
    ['Период', period],
    [],
    ['Дата', 'Операция', 'Комментарий', 'Приход (+)', 'Расход (−)', 'Баланс'],
    ['', 'Сальдо на начало периода', '', '', '', _csvMoney(st.opening)],
    for (final e in st.rows)
      [
        _dt(e.createdAt),
        operation(e),
        e.note == null || e.note == operation(e) ? '' : e.note!,
        e.amount > 0 ? _csvMoney(e.amount) : '',
        e.amount < 0 ? _csvMoney(-e.amount) : '',
        _csvMoney(e.balanceAfter),
      ],
    ['', 'Обороты за период', '', _csvMoney(st.increase), _csvMoney(st.decrease), ''],
    ['', 'Сальдо на конец периода', '', '', '', _csvMoney(st.closing)],
  ];
  return rows.map((r) => r.map(_csvCell).join(';')).join('\r\n');
}

// ------------------------------------------------------------------ value types

class SupplierInput {
  const SupplierInput({required this.name, this.phone, this.contactPerson, this.taxId, this.address, this.note});
  final String name;
  final String? phone;
  final String? contactPerson;
  final String? taxId;
  final String? address;
  final String? note;
}

class PoLineInput {
  PoLineInput({required this.productId, required this.qty, required this.unitCost});
  final String productId;
  final double qty;
  final int unitCost;
}

class ReceiveLineInput {
  const ReceiveLineInput({required this.itemId, required this.qty, this.unitCost});
  final String itemId;
  final double qty;

  /// Actual invoice cost; null = ordered cost.
  final int? unitCost;
}

class ReceiveResult {
  const ReceiveResult({required this.value, required this.fullyReceived, required this.lines});
  final int value;
  final bool fullyReceived;
  final int lines;
}

double remainingQty(PurchaseOrderItem i) => math.max(0, Qty.round(i.qty - i.receivedQty));

int poLinesTotal(Iterable<PoLineInput> lines) => lines.fold(0, (s, l) => s + (l.qty * l.unitCost).round());

String? _clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

// ------------------------------------------------------------------ reorder

class ReorderSuggestion {
  ReorderSuggestion({
    required this.product,
    required this.avgDaily,
    required this.onOrder,
    required this.suggestedQty,
    required this.daysOfCover,
  });
  final Product product;
  final double avgDaily;
  final double onOrder;
  final double suggestedQty;

  /// Days current stock lasts; null = no sales.
  final double? daysOfCover;

  int get estimatedCost => (suggestedQty * product.costPrice).round();
}

/// Pure reorder math.
///
/// * `avgDaily = soldQty / lookbackDays`
/// * `daysOfCover = stock / avgDaily`
/// * need = max(targetDays × avgDaily, minStock) − stock − onOrder,
///   rounded up to whole units for piece goods.
/// A product is suggested when stock ≤ minStock (minStock > 0) or when it
/// will run out within the target period, and need > 0.
ReorderSuggestion? computeReorder({
  required Product product,
  required double soldQty,
  required int lookbackDays,
  required int targetDays,
  double onOrder = 0,
}) {
  if (!product.trackStock || !product.isActive || product.deletedAt != null) return null;
  final avg = lookbackDays <= 0 ? 0.0 : math.max(0.0, soldQty) / lookbackDays;
  final stock = product.stockQty;
  final cover = avg > 0 ? math.max(0.0, stock) / avg : null;
  final belowMin = product.minStock > 0 && stock <= product.minStock;
  final runsOut = cover != null && cover < targetDays;
  if (!belowMin && !runsOut) return null;
  var need = math.max(targetDays * avg, product.minStock) - stock - onOrder;
  if (need <= 0) return null;
  need = Qty.isFractional(product.unit) ? Qty.round(need) : need.ceilToDouble();
  if (need <= 0) return null;
  return ReorderSuggestion(product: product, avgDaily: avg, onOrder: onOrder, suggestedQty: need, daysOfCover: cover);
}

// ------------------------------------------------------------------ price control

class PricePoint {
  const PricePoint({required this.at, required this.unitCost, required this.qty, this.prevCost});
  final DateTime at;
  final int unitCost;
  final double qty;
  final int? prevCost;

  /// Percent change vs previous receipt; null for the first one.
  double? get changePercent => prevCost == null || prevCost == 0 ? null : (unitCost - prevCost!) * 100 / prevCost!;
  bool get isSpike => (changePercent ?? 0) > 10;
}

/// Groups receipt movements (any order) into per-product chronological
/// histories with change vs previous receipt.
Map<String, List<PricePoint>> buildPriceHistory(Iterable<StockMovement> receipts) {
  final byProduct = <String, List<StockMovement>>{};
  for (final m in receipts) {
    if (m.type != 'receipt' || m.qty <= 0) continue;
    byProduct.putIfAbsent(m.productId, () => []).add(m);
  }
  final out = <String, List<PricePoint>>{};
  for (final e in byProduct.entries) {
    e.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    int? prev;
    out[e.key] = [
      for (final m in e.value)
        () {
          final p = PricePoint(at: m.createdAt, unitCost: m.unitCost, qty: m.qty, prevCost: prev);
          prev = m.unitCost;
          return p;
        }(),
    ];
  }
  return out;
}

// ------------------------------------------------------------------ repository

class PurchasingRepo {
  PurchasingRepo(this.db, this.stock, [ReceiptService? receipts, SupplierLedgerService? ledger])
    : ledger = ledger ?? SupplierLedgerService(db),
      receipts = receipts ?? ReceiptService(db, stock, ledger ?? SupplierLedgerService(db));
  final AppDatabase db;
  final StockService stock;
  final ReceiptService receipts;
  final SupplierLedgerService ledger;

  // ---- suppliers

  Future<String> saveSupplier(SupplierInput input, {String? id, String? userId}) async {
    final name = input.name.trim();
    if (name.isEmpty) throw BusinessException('Укажите название поставщика');
    if (name.length > 160) throw BusinessException('Название слишком длинное');
    // SQLite lower() is ASCII-only, so compare Cyrillic names in Dart.
    final existing = await (db.select(db.suppliers)..where((s) => s.deletedAt.isNull())).get();
    final key = name.toLowerCase();
    if (existing.any((s) => s.id != id && s.name.trim().toLowerCase() == key)) {
      throw BusinessException('Поставщик «$name» уже есть');
    }
    final now = DateTime.now();
    final sid = id ?? newId();
    final comp = SuppliersCompanion(
      name: Value(name),
      phone: Value(_clean(input.phone)),
      contactPerson: Value(_clean(input.contactPerson)),
      taxId: Value(_clean(input.taxId)),
      address: Value(_clean(input.address)),
      note: Value(_clean(input.note)),
      updatedAt: Value(now),
    );
    await db.transaction(() async {
      if (id == null) {
        await db.into(db.suppliers).insert(comp.copyWith(id: Value(sid), createdAt: Value(now)));
      } else {
        await (db.update(db.suppliers)..where((s) => s.id.equals(id))).write(comp);
      }
      await db.markDirty('suppliers', sid);
    });
    return sid;
  }

  Future<void> deleteSupplier(String id, {String? userId}) async {
    await db.transaction(() async {
      final s = await (db.select(db.suppliers)..where((t) => t.id.equals(id))).getSingle();
      if (s.balance != 0) {
        throw BusinessException('Нельзя удалить поставщика с ненулевым балансом (${Money.format(s.balance)})');
      }
      final open = await (db.select(
        db.purchaseOrders,
      )..where((o) => o.supplierId.equals(id) & o.status.isIn(['draft', 'ordered']) & o.deletedAt.isNull())).get();
      if (open.isNotEmpty) throw BusinessException('У поставщика есть незакрытые заказы (${open.length})');
      final now = DateTime.now();
      await (db.update(
        db.suppliers,
      )..where((t) => t.id.equals(id))).write(SuppliersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await db.markDirty('suppliers', id, op: 'delete');
      await db.audit('supplier.delete', userId: userId, entity: 'supplier', entityId: id, details: s.name);
    });
  }

  /// Records a payment to a supplier and decreases the balance
  /// (delegates to [SupplierLedgerService.pay]). Cash payments require an
  /// open shift ([shiftId]); paying more than the balance requires
  /// [allowOverpay] (creates a prepayment / credit). Returns the payment id.
  Future<String> paySupplier({
    required String supplierId,
    required int amount,
    required String method,
    String? shiftId,
    String? userId,
    String? orderId,
    String? note,
    bool allowOverpay = false,
  }) => ledger.pay(
    supplierId: supplierId,
    amount: amount,
    method: method,
    shiftId: shiftId,
    userId: userId,
    orderId: orderId,
    note: note,
    allowOverpay: allowOverpay,
  );

  /// Cancels a supplier payment (reason required; cash only while its shift
  /// is open). See [SupplierLedgerService.cancelPayment].
  Future<void> cancelSupplierPayment(String paymentId, {required String reason, String? userId}) =>
      ledger.cancelPayment(paymentId, reason: reason, userId: userId);

  /// Manual supplier balance correction (UI: `Perm.manageSettings` only).
  /// Returns the new balance.
  Future<int> adjustSupplierBalance(String supplierId, int amount, {required String reason, String? userId}) =>
      ledger.adjust(supplierId, amount, reason: reason, userId: userId);

  // ---- purchase orders

  void _validateLines(List<PoLineInput> lines) {
    if (lines.isEmpty) throw BusinessException('Добавьте в заказ хотя бы один товар');
    final seen = <String>{};
    for (final l in lines) {
      if (l.qty <= 0) throw BusinessException('Количество должно быть больше нуля');
      if (l.unitCost < 0) throw BusinessException('Цена не может быть отрицательной');
      if (!seen.add(l.productId)) throw BusinessException('Товар повторяется в заказе — объедините строки');
    }
  }

  /// Creates (id == null) or rewrites a draft PO. Returns the order id.
  Future<String> saveDraftOrder({
    String? id,
    required String supplierId,
    required List<PoLineInput> lines,
    DateTime? expectedAt,
    String? note,
    String? userId,
  }) async {
    _validateLines(lines);
    final oid = id ?? newId();
    final total = poLinesTotal(lines);
    await db.transaction(() async {
      final s = await (db.select(db.suppliers)..where((t) => t.id.equals(supplierId))).getSingleOrNull();
      if (s == null || s.deletedAt != null) throw BusinessException('Выберите поставщика');
      final now = DateTime.now();
      if (id == null) {
        final number = await db.nextNumber('po');
        await db
            .into(db.purchaseOrders)
            .insert(
              PurchaseOrdersCompanion.insert(
                id: oid,
                number: number,
                supplierId: supplierId,
                total: Value(total),
                expectedAt: Value(expectedAt),
                note: Value(_clean(note)),
                userId: Value(userId),
              ),
            );
      } else {
        final o = await (db.select(db.purchaseOrders)..where((t) => t.id.equals(id))).getSingle();
        if (o.status != 'draft') throw BusinessException('Изменять можно только черновик заказа');
        await (db.update(db.purchaseOrders)..where((t) => t.id.equals(id))).write(
          PurchaseOrdersCompanion(
            supplierId: Value(supplierId),
            total: Value(total),
            expectedAt: Value(expectedAt),
            note: Value(_clean(note)),
            updatedAt: Value(now),
          ),
        );
        await (db.delete(db.purchaseOrderItems)..where((i) => i.orderId.equals(id))).go();
      }
      for (final l in lines) {
        final iid = newId();
        await db
            .into(db.purchaseOrderItems)
            .insert(
              PurchaseOrderItemsCompanion.insert(
                id: iid,
                orderId: oid,
                productId: l.productId,
                qty: Qty.round(l.qty),
                unitCost: l.unitCost,
              ),
            );
      }
      await db.markDirty('purchase_orders', oid);
    });
    return oid;
  }

  Future<PurchaseOrder> _order(String id) => (db.select(db.purchaseOrders)..where((t) => t.id.equals(id))).getSingle();

  Future<void> markOrdered(String orderId, {String? userId}) async {
    await db.transaction(() async {
      final o = await _order(orderId);
      if (o.status != 'draft') throw BusinessException('Заказ уже отправлен');
      final n = await (db.select(db.purchaseOrderItems)..where((i) => i.orderId.equals(orderId))).get();
      if (n.isEmpty) throw BusinessException('В заказе нет позиций');
      await (db.update(db.purchaseOrders)..where((t) => t.id.equals(orderId))).write(
        PurchaseOrdersCompanion(status: const Value('ordered'), updatedAt: Value(DateTime.now())),
      );
      await db.markDirty('purchase_orders', orderId);
      await db.audit(
        'po.ordered',
        userId: userId,
        entity: 'purchase_order',
        entityId: orderId,
        details: '№${o.number}',
      );
    });
  }

  /// Cancels a draft/ordered PO. A partially received order is instead
  /// closed (status received) because its receipts are already posted.
  Future<void> cancelOrder(String orderId, {String? userId, String? reason}) async {
    await db.transaction(() async {
      final o = await _order(orderId);
      if (o.status != 'draft' && o.status != 'ordered') throw BusinessException('Заказ уже закрыт');
      final items = await (db.select(db.purchaseOrderItems)..where((i) => i.orderId.equals(orderId))).get();
      final anyReceived = items.any((i) => i.receivedQty > 0);
      final now = DateTime.now();
      await (db.update(db.purchaseOrders)..where((t) => t.id.equals(orderId))).write(
        PurchaseOrdersCompanion(
          status: Value(anyReceived ? 'received' : 'cancelled'),
          receivedAt: anyReceived ? Value(now) : const Value.absent(),
          note: reason == null || reason.trim().isEmpty
              ? const Value.absent()
              : Value([if (o.note != null) o.note!, 'Закрыт: ${reason.trim()}'].join('\n')),
          updatedAt: Value(now),
        ),
      );
      await db.markDirty('purchase_orders', orderId);
      await db.audit(
        anyReceived ? 'po.close' : 'po.cancel',
        userId: userId,
        entity: 'purchase_order',
        entityId: orderId,
        details: '№${o.number}; ${reason ?? ''}',
      );
    });
  }

  /// Partial or full receiving. Creates one receipt document
  /// ([ReceiptService.post] with `orderId` and `orderItemId` per line: stock,
  /// supplier ledger, numbering); updates receivedQty and the order status
  /// (`received` when nothing remains) in the same transaction.
  Future<ReceiveResult> receiveOrder(String orderId, List<ReceiveLineInput> lines, {String? userId}) async =>
      (await receiveOrderDoc(orderId, lines, userId: userId)).result;

  /// Same as [receiveOrder] but also returns the posted receipt document
  /// (id, number) for «Приход №N проведён».
  Future<({ReceiveResult result, PostedReceipt receipt})> receiveOrderDoc(
    String orderId,
    List<ReceiveLineInput> lines, {
    String? userId,
    String? supplierInvoice,
    String? note,
  }) async {
    final active = lines.where((l) => l.qty > 0).toList();
    if (active.isEmpty) throw BusinessException('Укажите количество хотя бы по одной позиции');
    return db.transaction(() async {
      final o = await _order(orderId);
      if (o.status != 'ordered' && o.status != 'draft') {
        throw BusinessException('Заказ №${o.number} уже ${poStatusLabels[o.status]?.toLowerCase() ?? o.status}');
      }
      final items = {
        for (final i in await (db.select(db.purchaseOrderItems)..where((i) => i.orderId.equals(orderId))).get())
          i.id: i,
      };
      final inputs = <ReceiptLineInput>[];
      final seen = <String>{};
      for (final l in active) {
        final it = items[l.itemId];
        if (it == null) throw BusinessException('Позиция не найдена в заказе');
        if (!seen.add(it.id)) throw BusinessException('Позиция заказа указана дважды');
        final p = await (db.select(db.products)..where((t) => t.id.equals(it.productId))).getSingle();
        final rest = remainingQty(it);
        if (Qty.round(l.qty) > rest + 1e-9) {
          throw BusinessException('«${p.name}»: можно принять не больше ${Qty.format(rest, p.unit)}');
        }
        if (!Qty.isFractional(p.unit) && l.qty != l.qty.roundToDouble()) {
          throw BusinessException('«${p.name}»: только целое количество');
        }
        final cost = l.unitCost ?? it.unitCost;
        if (cost < 0) throw BusinessException('«${p.name}»: цена не может быть отрицательной');
        inputs.add(
          ReceiptLineInput(productId: it.productId, qty: Qty.round(l.qty), unitCost: cost, orderItemId: it.id),
        );
      }
      final doc = await receipts.post(
        lines: inputs,
        supplierId: o.supplierId,
        orderId: orderId,
        supplierInvoice: supplierInvoice,
        note: note,
        userId: userId,
      );
      final now = DateTime.now();
      for (final l in inputs) {
        final it = items[l.orderItemId]!;
        final newReceived = Qty.round(it.receivedQty + l.qty);
        await (db.update(db.purchaseOrderItems)..where((t) => t.id.equals(it.id))).write(
          PurchaseOrderItemsCompanion(receivedQty: Value(newReceived), updatedAt: Value(now)),
        );
        items[it.id] = it.copyWith(receivedQty: newReceived);
      }
      final full = items.values.where((i) => i.deletedAt == null).every((i) => remainingQty(i) <= 0);
      await (db.update(db.purchaseOrders)..where((t) => t.id.equals(orderId))).write(
        PurchaseOrdersCompanion(
          status: Value(full ? 'received' : 'ordered'),
          receivedAt: full ? Value(now) : const Value.absent(),
          updatedAt: Value(now),
        ),
      );
      await db.markDirty('purchase_orders', orderId);
      await db.audit(
        'po.receive',
        userId: userId,
        entity: 'purchase_order',
        entityId: orderId,
        details:
            '№${o.number}; приход №${doc.number}; поз. ${active.length}; сумма ${doc.total}; '
            '${full ? 'полностью' : 'частично'}',
      );
      return (result: ReceiveResult(value: doc.total, fullyReceived: full, lines: active.length), receipt: doc);
    });
  }

  /// Received value of an order at invoice cost: Σ totals of its posted
  /// receipt documents (reversed ones excluded).
  Future<int> receivedValue(String orderId) async {
    final rows = await (db.select(
      db.goodsReceipts,
    )..where((r) => r.orderId.equals(orderId) & r.status.equals('posted') & r.deletedAt.isNull())).get();
    return rows.fold<int>(0, (s, r) => s + r.total);
  }

  // ---- reorder

  /// Net sold qty per product since [since] (excludes voided/held sales).
  Future<Map<String, double>> soldQtySince(DateTime since) async {
    final rows = await db
        .customSelect(
          'SELECT si.product_id AS pid, SUM(si.qty - si.returned_qty) AS q '
          'FROM sale_items si JOIN sales s ON s.id = si.sale_id '
          "WHERE s.created_at >= ? AND s.status NOT IN ('voided', 'held') AND s.deleted_at IS NULL "
          'GROUP BY si.product_id',
          variables: [Variable.withDateTime(since)],
          readsFrom: {db.saleItems, db.sales},
        )
        .get();
    return {for (final r in rows) r.read<String>('pid'): r.read<double?>('q') ?? 0};
  }

  /// Remaining qty on open POs (drafts and ordered) per product. Drafts count
  /// too, so re-running «Автозаказ» does not suggest the same goods twice.
  Future<Map<String, double>> onOrderQty() async {
    final rows = await db
        .customSelect(
          'SELECT i.product_id AS pid, SUM(i.qty - i.received_qty) AS q '
          'FROM purchase_order_items i JOIN purchase_orders o ON o.id = i.order_id '
          "WHERE o.status IN ('draft', 'ordered') AND o.deleted_at IS NULL AND i.deleted_at IS NULL "
          'GROUP BY i.product_id',
          readsFrom: {db.purchaseOrderItems, db.purchaseOrders},
        )
        .get();
    return {for (final r in rows) r.read<String>('pid'): math.max(0, r.read<double?>('q') ?? 0)};
  }

  Future<List<ReorderSuggestion>> reorderSuggestions({
    int targetDays = 14,
    int lookbackDays = 30,
    DateTime? now,
  }) async {
    final since = (now ?? DateTime.now()).subtract(Duration(days: lookbackDays));
    final sold = await soldQtySince(since);
    final onOrder = await onOrderQty();
    final products =
        await (db.select(db.products)
              ..where((p) => p.deletedAt.isNull() & p.isActive.equals(true) & p.trackStock.equals(true))
              ..orderBy([(p) => OrderingTerm.asc(p.name)]))
            .get();
    return [
      for (final p in products)
        ?computeReorder(
          product: p,
          soldQty: sold[p.id] ?? 0,
          lookbackDays: lookbackDays,
          targetDays: targetDays,
          onOrder: onOrder[p.id] ?? 0,
        ),
    ];
  }

  /// Creates one draft PO per supplier. [groups]: supplierId -> lines.
  Future<List<String>> createOrdersFromSuggestions(Map<String, List<PoLineInput>> groups, {String? userId}) async {
    final ids = <String>[];
    await db.transaction(() async {
      for (final e in groups.entries) {
        if (e.value.isEmpty) continue;
        ids.add(await saveDraftOrder(supplierId: e.key, lines: e.value, userId: userId, note: 'Автозаказ'));
      }
    });
    if (ids.isEmpty) throw BusinessException('Нет позиций для заказа');
    return ids;
  }
}
