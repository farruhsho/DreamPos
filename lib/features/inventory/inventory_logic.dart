// Warehouse (Склад) data layer: live providers, pure calculations and the
// few document writes that have no dedicated domain service (stocktake
// drafts). Receipt documents are posted/reversed by ReceiptService; all stock
// changes go through StockService.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../domain/errors.dart';
import '../../domain/services/receipt_service.dart';
import '../../domain/services/stock_service.dart';
import '../../l10n/l10n.dart';

export '../../domain/services/receipt_service.dart' show PostedReceipt, ReceiptLineInput, ReceiptStatus;

// ------------------------------------------------------------------ labels

Map<String, String> movementTypeLabelsOf(AppLocalizations l) => {
  'sale': l.commonSale,
  'return': l.commonReturn,
  'receipt': l.invReceipt,
  'receipt_reversal': l.invMoveReceiptReversal,
  'writeoff': l.invWriteoff,
  'adjustment': l.invAdjustment,
  'inventory': l.invCount,
  'transfer': l.invMoveTransfer,
};

/// Movement type labels in the UI language.
Map<String, String> get movementTypeLabels => movementTypeLabelsOf(L.current);

String movementLabel(String type, [AppLocalizations? l]) => movementTypeLabelsOf(l ?? L.current)[type] ?? type;

/// Write-off reason chips; the last one is «Другое» (comment required).
/// The chosen label is written to the movement reason as typed text.
List<String> writeOffReasonsOf(AppLocalizations l) => [
  l.invReasonDefect,
  l.invReasonExpired,
  l.invReasonSpoiled,
  l.invReasonShortage,
  l.invReasonPersonalUse,
  l.invReasonOther,
];

List<String> get writeOffReasons => writeOffReasonsOf(L.current);

Map<String, String> receiptStatusLabelsOf(AppLocalizations l) => {
  'posted': l.invReceiptPosted,
  'reversed': l.invReceiptReversed,
};

/// Receipt status labels in the UI language (also used by purchasing).
Map<String, String> get receiptStatusLabels => receiptStatusLabelsOf(L.current);

Map<String, String> countStatusLabelsOf(AppLocalizations l) => {
  'draft': l.invCountDraft,
  'completed': l.invCountCompleted,
  'cancelled': l.invCountCancelled,
};

Map<String, String> get countStatusLabels => countStatusLabelsOf(L.current);

// ------------------------------------------------------------------ providers

/// All tracked, non-deleted products (live).
final invProductsProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.products)
        ..where((p) => p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .watch();
});

/// Every product including deleted ones, by id (journals reference old rows).
final invProductMapProvider = StreamProvider<Map<String, Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.products).watch().map((l) => {for (final p in l) p.id: p});
});

final invCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)]))
      .watch();
});

final invSuppliersProvider = StreamProvider<List<Supplier>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.suppliers)
        ..where((s) => s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.asc(s.name)]))
      .watch();
});

final invUserNamesProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.users).watch().map((l) => {for (final u in l) u.id: u.name});
});

final inventoryCountsProvider = StreamProvider<List<InventoryCount>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.inventoryCounts)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.desc(c.createdAt), (c) => OrderingTerm.desc(c.number)]))
      .watch();
});

final inventoryCountProvider = StreamProvider.family<InventoryCount?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.inventoryCounts)..where((c) => c.id.equals(id))).watchSingleOrNull();
});

final inventoryCountItemsProvider = StreamProvider.family<List<InventoryCountItem>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.inventoryCountItems)..where((i) => i.countId.equals(id) & i.deletedAt.isNull())).watch();
});

final inventoryRepoProvider = Provider(
  (ref) => InventoryRepo(
    ref.watch(databaseProvider),
    ref.watch(stockServiceProvider),
    ref.watch(receiptServiceProvider),
  ),
);

// ------------------------------------------------------------------ receipt documents

/// Filter for [goodsReceiptsProvider]. Records compare by value, so equal
/// filters share one provider instance.
/// * [from] inclusive, [to] exclusive (createdAt);
/// * [status]: `posted` | `reversed` | null (all);
/// * [search]: document number («15», «№15») or part of the supplier invoice.
typedef ReceiptsFilter = ({DateTime? from, DateTime? to, String? supplierId, String? status, String? search});

const ReceiptsFilter allReceipts = (from: null, to: null, supplierId: null, status: null, search: null);

/// One row of the receipt document list.
class ReceiptListRow {
  const ReceiptListRow({required this.receipt, required this.lineCount, this.orderNumber});
  final GoodsReceipt receipt;
  final int lineCount;

  /// Purchase order number when the receipt was made against an order.
  final int? orderNumber;
}

const receiptsLimit = 500;

/// Receipt documents, newest first (max [receiptsLimit]).
final goodsReceiptsProvider = StreamProvider.family<List<ReceiptListRow>, ReceiptsFilter>((ref, f) {
  return watchGoodsReceipts(ref.watch(databaseProvider), f);
});

/// Query behind [goodsReceiptsProvider] (also usable without Riverpod).
Stream<List<ReceiptListRow>> watchGoodsReceipts(AppDatabase db, ReceiptsFilter f) {
  final where = <String>['r.deleted_at IS NULL'];
  final vars = <Variable>[];
  if (f.from != null) {
    where.add('r.created_at >= ?');
    vars.add(Variable.withDateTime(f.from!));
  }
  if (f.to != null) {
    where.add('r.created_at < ?');
    vars.add(Variable.withDateTime(f.to!));
  }
  if (f.supplierId != null) {
    where.add('r.supplier_id = ?');
    vars.add(Variable.withString(f.supplierId!));
  }
  if (f.status != null) {
    where.add('r.status = ?');
    vars.add(Variable.withString(f.status!));
  }
  final q = f.search?.replaceAll('№', '').trim() ?? '';
  if (q.isNotEmpty) {
    where.add('(CAST(r.number AS TEXT) = ? OR r.supplier_invoice LIKE ?)');
    vars
      ..add(Variable.withString(q))
      ..add(Variable.withString('%$q%'));
  }
  return db
      .customSelect(
        'SELECT r.*, '
        '(SELECT COUNT(*) FROM goods_receipt_items i WHERE i.receipt_id = r.id AND i.deleted_at IS NULL) AS line_count, '
        'o.number AS order_number '
        'FROM goods_receipts r LEFT JOIN purchase_orders o ON o.id = r.order_id '
        'WHERE ${where.join(' AND ')} '
        'ORDER BY r.number DESC LIMIT $receiptsLimit',
        variables: vars,
        readsFrom: {db.goodsReceipts, db.goodsReceiptItems, db.purchaseOrders},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            ReceiptListRow(
              receipt: db.goodsReceipts.map(r.data),
              lineCount: r.read<int>('line_count'),
              orderNumber: r.readNullable<int>('order_number'),
            ),
        ],
      );
}

/// One receipt document (live; null when missing).
final goodsReceiptProvider = StreamProvider.family<GoodsReceipt?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.goodsReceipts)..where((r) => r.id.equals(id))).watchSingleOrNull();
});

/// Lines of a receipt document in entry order.
final goodsReceiptItemsProvider = StreamProvider.family<List<GoodsReceiptItem>, String>((ref, receiptId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.goodsReceiptItems)
        ..where((i) => i.receiptId.equals(receiptId) & i.deletedAt.isNull())
        ..orderBy([(i) => OrderingTerm.asc(i.createdAt), (i) => OrderingTerm.asc(i.rowId)]))
      .watch();
});

/// Receipt number by id — movements with `refType == 'receipt'` show «Приход №N».
final goodsReceiptNumbersProvider = StreamProvider<Map<String, int>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.goodsReceipts).watch().map((l) => {for (final r in l) r.id: r.number});
});

/// Every supplier name by id, including deleted suppliers (documents keep
/// referencing them).
final invSupplierNamesProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.suppliers).watch().map((l) => {for (final s in l) s.id: s.name});
});

/// Purchase order number by id (null when missing).
final invOrderNumberProvider = StreamProvider.family<int?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.purchaseOrders)..where((o) => o.id.equals(id))).watchSingleOrNull().map((o) => o?.number);
});

/// One line of a receipt document joined with its product (may be deleted).
class ReceiptDocLine {
  const ReceiptDocLine(this.item, this.product);
  final GoodsReceiptItem item;
  final Product? product;

  String get name => product?.name ?? L.current.invDeletedProduct;
  String get unit => product?.unit ?? 'pcs';
  int get total => lineValue(item.qty, item.unitCost);

  /// Retail price changed by this receipt.
  bool get priceChanged => item.newPrice != null && item.newPrice != item.oldPrice;
}

List<ReceiptDocLine> receiptDocLines(List<GoodsReceiptItem> items, Map<String, Product> products) => [
  for (final i in items) ReceiptDocLine(i, products[i.productId]),
];

/// «Приход №N» reference text for a stock movement, or null.
String? movementReference(StockMovement m, Map<String, int> receiptNumbers) {
  if (m.refType != 'receipt' || m.refId == null) return null;
  final n = receiptNumbers[m.refId];
  return n == null ? null : L.current.invReceiptRef('$n');
}

// ------------------------------------------------------------------ stock overview

enum StockFilter {
  all,
  low,
  out,
  negative;

  String labelIn(AppLocalizations l) => switch (this) {
    StockFilter.all => l.commonAll,
    StockFilter.low => l.invFilterLow,
    StockFilter.out => l.invFilterOut,
    StockFilter.negative => l.invFilterNegative,
  };

  String get label => labelIn(L.current);
}

bool isLow(Product p) => p.minStock > 0 && p.stockQty > 0 && p.stockQty <= p.minStock;
bool isOut(Product p) => p.stockQty == 0;
bool isNegative(Product p) => p.stockQty < 0;

bool matchesStockFilter(Product p, StockFilter f) => switch (f) {
  StockFilter.all => true,
  StockFilter.low => isLow(p),
  StockFilter.out => isOut(p),
  StockFilter.negative => isNegative(p),
};

bool matchesQuery(Product p, String q) {
  final s = q.trim().toLowerCase();
  if (s.isEmpty) return true;
  return p.name.toLowerCase().contains(s) ||
      (p.sku?.toLowerCase().contains(s) ?? false) ||
      (p.barcode?.contains(s) ?? false);
}

/// Stock valuation of a set of products. Negative stock is not valued.
class StockValuation {
  const StockValuation({
    required this.positions,
    required this.costValue,
    required this.retailValue,
    required this.lowCount,
    required this.outCount,
    required this.negativeCount,
  });
  final int positions;
  final int costValue;
  final int retailValue;
  final int lowCount;
  final int outCount;
  final int negativeCount;

  int get potentialMargin => retailValue - costValue;

  static StockValuation of(Iterable<Product> products) {
    var positions = 0, cost = 0, retail = 0, low = 0, out = 0, neg = 0;
    for (final p in products) {
      if (!p.trackStock) continue;
      positions++;
      if (p.stockQty > 0) {
        cost += (p.costPrice * p.stockQty).round();
        retail += (p.price * p.stockQty).round();
      }
      if (isLow(p)) low++;
      if (isOut(p)) out++;
      if (isNegative(p)) neg++;
    }
    return StockValuation(
      positions: positions,
      costValue: cost,
      retailValue: retail,
      lowCount: low,
      outCount: out,
      negativeCount: neg,
    );
  }
}

int lineValue(double qty, int unitCost) => (qty * unitCost).round();

/// Validates a quantity for the product's unit. Returns an error or null.
String? validateQty(double? q, String unit, {bool allowZero = false}) {
  final l = L.current;
  if (q == null) return l.invQtyRequired;
  if (q < 0) return l.invQtyNegative;
  if (!allowZero && q == 0) return l.invQtyPositive;
  if (!Qty.isFractional(unit) && q != q.roundToDouble()) {
    return l.invQtyIntegerOnly(Qty.unitLabel(unit, l));
  }
  if (q > 1e7) return l.invQtyTooLarge;
  return null;
}

// ------------------------------------------------------------------ receipt document

class ReceiptLine {
  ReceiptLine({required this.product, required this.qty, required this.unitCost, this.newPrice});
  final Product product;
  double qty;
  int unitCost;

  /// New retail price; null = keep current.
  int? newPrice;

  int get total => lineValue(qty, unitCost);

  ReceiptLineInput toInput() =>
      ReceiptLineInput(productId: product.id, qty: Qty.round(qty), unitCost: unitCost, newPrice: newPrice);
}

// ------------------------------------------------------------------ count

enum CountScope { all, category, selected }

/// One stocktake line joined with its product and live stock.
class CountLine {
  CountLine(this.item, this.product);
  final InventoryCountItem item;
  final Product? product;

  String get name => product?.name ?? L.current.invDeletedProduct;
  String get unit => product?.unit ?? 'pcs';
  double get currentQty => product?.stockQty ?? item.expectedQty;
  int get unitCost => item.unitCost;

  /// Stock moved (sales etc.) since the count was created.
  bool get stockChanged => Qty.round(currentQty - item.expectedQty) != 0;

  /// Difference against the CURRENT stock: this is what completion posts.
  double? get diff => item.countedQty == null ? null : Qty.round(item.countedQty! - currentQty);
  int get diffValue => diff == null ? 0 : lineValue(diff!, unitCost);
}

class CountSummary {
  const CountSummary({
    required this.lines,
    required this.counted,
    required this.uncounted,
    required this.surplusLines,
    required this.shortageLines,
    required this.surplusValue,
    required this.shortageValue,
    required this.changedSinceStart,
  });
  final int lines;
  final int counted;
  final int uncounted;
  final int surplusLines;
  final int shortageLines;
  final int surplusValue; // positive
  final int shortageValue; // positive
  final int changedSinceStart;

  int get netValue => surplusValue - shortageValue;

  static CountSummary of(List<CountLine> lines) {
    var counted = 0, sL = 0, shL = 0, sV = 0, shV = 0, changed = 0;
    for (final l in lines) {
      if (l.stockChanged) changed++;
      final d = l.diff;
      if (d == null) continue;
      counted++;
      if (d > 0) {
        sL++;
        sV += l.diffValue;
      } else if (d < 0) {
        shL++;
        shV += -l.diffValue;
      }
    }
    return CountSummary(
      lines: lines.length,
      counted: counted,
      uncounted: lines.length - counted,
      surplusLines: sL,
      shortageLines: shL,
      surplusValue: sV,
      shortageValue: shV,
      changedSinceStart: changed,
    );
  }
}

// ------------------------------------------------------------------ repository

class InventoryRepo {
  InventoryRepo(this.db, this.stock, [ReceiptService? receipts]) : receipts = receipts ?? ReceiptService(db, stock);
  final AppDatabase db;
  final StockService stock;
  final ReceiptService receipts;

  /// Posts a goods receipt document (no purchase order) through
  /// [ReceiptService.post]: numbered document, stock via StockService,
  /// supplier debt via the supplier ledger. All-or-nothing.
  /// Returns the document id (= `refId` of the movements); use
  /// [postReceiptDoc] when the number is needed («Приход №N проведён»).
  Future<String> postReceipt({
    required List<ReceiptLine> lines,
    String? supplierId,
    String? userId,
    String? note,
    String? supplierInvoice,
    bool canEditPrices = true,
  }) async => (await postReceiptDoc(
    lines: lines,
    supplierId: supplierId,
    userId: userId,
    note: note,
    supplierInvoice: supplierInvoice,
    canEditPrices: canEditPrices,
  )).id;

  /// Same as [postReceipt] but returns id, number and total of the document.
  Future<PostedReceipt> postReceiptDoc({
    required List<ReceiptLine> lines,
    String? supplierId,
    String? userId,
    String? note,
    String? supplierInvoice,
    bool canEditPrices = true,
  }) async {
    if (lines.isEmpty) throw BusinessException(L.current.invAddAtLeastOneLine);
    for (final l in lines) {
      final err = validateQty(l.qty, l.product.unit);
      if (err != null) throw BusinessException('${l.product.name}: $err');
      if (l.unitCost < 0) throw BusinessException(L.current.invCostNegative(l.product.name));
      if (l.newPrice != null && l.newPrice! <= 0) {
        throw BusinessException(L.current.invRetailMustBePositive(l.product.name));
      }
    }
    return receipts.post(
      lines: [for (final l in lines) l.toInput()],
      supplierId: supplierId,
      supplierInvoice: supplierInvoice,
      note: note,
      userId: userId,
      canEditPrices: canEditPrices,
    );
  }

  /// Reverses («сторно») a posted receipt document (reason required).
  Future<void> reverseReceipt(String receiptId, {required String reason, String? userId}) =>
      receipts.reverse(receiptId, reason: reason, userId: userId);

  /// Creates a stocktake draft with an expected-qty snapshot.
  Future<String> createCount({
    required CountScope scope,
    String? categoryId,
    List<String> productIds = const [],
    String? userId,
    String? note,
  }) async {
    final sel = db.select(db.products)
      ..where((p) => p.deletedAt.isNull() & p.trackStock.equals(true))
      ..orderBy([(p) => OrderingTerm.asc(p.name)]);
    switch (scope) {
      case CountScope.all:
        sel.where((p) => p.isActive.equals(true));
      case CountScope.category:
        if (categoryId == null) throw BusinessException(L.current.invSelectCategory);
        sel.where((p) => p.categoryId.equals(categoryId) & p.isActive.equals(true));
      case CountScope.selected:
        if (productIds.isEmpty) throw BusinessException(L.current.invSelectProducts);
        sel.where((p) => p.id.isIn(productIds));
    }
    final products = await sel.get();
    if (products.isEmpty) throw BusinessException(L.current.invNoProductsToCount);
    final id = newId();
    await db.transaction(() async {
      final number = await db.nextNumber('inventory');
      await db
          .into(db.inventoryCounts)
          .insert(
            InventoryCountsCompanion.insert(
              id: id,
              number: number,
              userId: Value(userId),
              note: Value(note == null || note.trim().isEmpty ? null : note.trim()),
            ),
          );
      await db.batch((b) {
        b.insertAll(db.inventoryCountItems, [
          for (final p in products)
            InventoryCountItemsCompanion.insert(
              id: newId(),
              countId: id,
              productId: p.id,
              expectedQty: p.stockQty,
              unitCost: Value(p.costPrice),
            ),
        ]);
      });
      await db.markDirty('inventory_counts', id);
      await db.audit(
        'inventory.create',
        userId: userId,
        entity: 'inventory_count',
        entityId: id,
        details: '№$number; ${products.length} поз.', // l10n-ignore: audit text stored in the DB
      );
    });
    return id;
  }

  Future<InventoryCount> _draft(String countId) async {
    final c = await (db.select(db.inventoryCounts)..where((t) => t.id.equals(countId))).getSingle();
    if (c.status != 'draft') throw BusinessException(L.current.invCountClosed);
    return c;
  }

  /// Persists counted quantities (itemId -> qty, null clears).
  Future<void> saveCounted(String countId, Map<String, double?> values) async {
    if (values.isEmpty) return;
    await db.transaction(() async {
      await _draft(countId);
      final now = DateTime.now();
      for (final e in values.entries) {
        final v = e.value;
        if (v != null && v < 0) throw BusinessException(L.current.invQtyNegative);
        await (db.update(db.inventoryCountItems)..where((i) => i.id.equals(e.key) & i.countId.equals(countId))).write(
          InventoryCountItemsCompanion(countedQty: Value(v == null ? null : Qty.round(v)), updatedAt: Value(now)),
        );
      }
      await (db.update(
        db.inventoryCounts,
      )..where((c) => c.id.equals(countId))).write(InventoryCountsCompanion(updatedAt: Value(now)));
      await db.markDirty('inventory_counts', countId);
    });
  }

  /// Adds a product to an open count (e.g. found while scanning).
  Future<String> addCountItem(String countId, Product p, {double? counted}) async {
    return db.transaction(() async {
      await _draft(countId);
      final existing = await (db.select(
        db.inventoryCountItems,
      )..where((i) => i.countId.equals(countId) & i.productId.equals(p.id))).getSingleOrNull();
      if (existing != null) return existing.id;
      final id = newId();
      final fresh = await (db.select(db.products)..where((t) => t.id.equals(p.id))).getSingle();
      await db
          .into(db.inventoryCountItems)
          .insert(
            InventoryCountItemsCompanion.insert(
              id: id,
              countId: countId,
              productId: p.id,
              expectedQty: fresh.stockQty,
              countedQty: Value(counted),
              unitCost: Value(fresh.costPrice),
            ),
          );
      await db.markDirty('inventory_counts', countId);
      return id;
    });
  }

  Future<void> cancelCount(String countId, {String? userId}) async {
    await db.transaction(() async {
      final c = await _draft(countId);
      await (db.update(db.inventoryCounts)..where((t) => t.id.equals(countId))).write(
        InventoryCountsCompanion(status: const Value('cancelled'), updatedAt: Value(DateTime.now())),
      );
      await db.markDirty('inventory_counts', countId);
      await db.audit(
        'inventory.cancel',
        userId: userId,
        entity: 'inventory_count',
        entityId: countId,
        details: '№${c.number}',
      );
    });
  }

  /// Saves pending values and posts the count through StockService.
  Future<void> completeCount(String countId, {String? userId, Map<String, double?> pending = const {}}) async {
    await db.transaction(() async {
      await saveCounted(countId, pending);
      final counted = await (db.select(
        db.inventoryCountItems,
      )..where((i) => i.countId.equals(countId) & i.countedQty.isNotNull())).get();
      if (counted.isEmpty) throw BusinessException(L.current.invNoCountedQty);
      await stock.completeCount(countId, userId: userId);
    });
  }

  /// Loads count lines joined with current product state.
  Future<List<CountLine>> loadLines(String countId) async {
    final items = await (db.select(db.inventoryCountItems)..where((i) => i.countId.equals(countId))).get();
    final ids = items.map((i) => i.productId).toSet().toList();
    final products = await (db.select(db.products)..where((p) => p.id.isIn(ids))).get();
    final map = {for (final p in products) p.id: p};
    return [for (final i in items) CountLine(i, map[i.productId])]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
