// Warehouse (Склад) data layer: live providers, pure calculations and the
// few document writes that have no dedicated domain service (receipt
// documents with supplier debt, stocktake drafts). All stock changes still go
// through StockService.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../domain/errors.dart';
import '../../domain/services/stock_service.dart';

// ------------------------------------------------------------------ labels

const movementTypeLabels = <String, String>{
  'sale': 'Продажа',
  'return': 'Возврат',
  'receipt': 'Приход',
  'writeoff': 'Списание',
  'adjustment': 'Корректировка',
  'inventory': 'Инвентаризация',
  'transfer': 'Перемещение',
};

String movementLabel(String type) => movementTypeLabels[type] ?? type;

const writeOffReasons = <String>['Брак', 'Просрочка', 'Порча', 'Недостача', 'Личное потребление', 'Другое'];

const countStatusLabels = <String, String>{'draft': 'Черновик', 'completed': 'Проведена', 'cancelled': 'Отменена'};

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
  (ref) => InventoryRepo(ref.watch(databaseProvider), ref.watch(stockServiceProvider)),
);

// ------------------------------------------------------------------ stock overview

enum StockFilter {
  all('Все'),
  low('Мало'),
  out('Нет в наличии'),
  negative('Минус');

  const StockFilter(this.label);
  final String label;
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
  if (q == null) return 'Введите количество';
  if (q < 0) return 'Количество не может быть отрицательным';
  if (!allowZero && q == 0) return 'Количество должно быть больше нуля';
  if (!Qty.isFractional(unit) && q != q.roundToDouble()) {
    return 'Для «${Qty.unitLabel(unit)}» допускается только целое число';
  }
  if (q > 1e7) return 'Слишком большое количество';
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
}

// ------------------------------------------------------------------ count

enum CountScope { all, category, selected }

/// One stocktake line joined with its product and live stock.
class CountLine {
  CountLine(this.item, this.product);
  final InventoryCountItem item;
  final Product? product;

  String get name => product?.name ?? 'Удалённый товар';
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
  InventoryRepo(this.db, this.stock);
  final AppDatabase db;
  final StockService stock;

  /// Posts a goods receipt document (no purchase order). Every line goes
  /// through [StockService.receive]; when a supplier is given the store's
  /// debt to that supplier grows by the document total. All-or-nothing.
  /// Returns the document id used as `refId` of the movements.
  Future<String> postReceipt({
    required List<ReceiptLine> lines,
    String? supplierId,
    String? userId,
    String? note,
    bool canEditPrices = true,
  }) async {
    if (lines.isEmpty) throw BusinessException('Добавьте хотя бы одну позицию');
    for (final l in lines) {
      final err = validateQty(l.qty, l.product.unit);
      if (err != null) throw BusinessException('${l.product.name}: $err');
      if (l.unitCost < 0) throw BusinessException('${l.product.name}: цена закупки отрицательная');
      if (l.newPrice != null && l.newPrice! <= 0) {
        throw BusinessException('${l.product.name}: розничная цена должна быть больше нуля');
      }
    }
    final docId = newId();
    final total = lines.fold<int>(0, (s, l) => s + l.total);
    await db.transaction(() async {
      Supplier? sup;
      if (supplierId != null) {
        sup = await (db.select(db.suppliers)..where((s) => s.id.equals(supplierId))).getSingleOrNull();
        if (sup == null || sup.deletedAt != null) {
          throw BusinessException('Поставщик не найден');
        }
      }
      final reason = [
        if (sup != null) 'Поставщик: ${sup.name}',
        if (note != null && note.trim().isNotEmpty) note.trim(),
      ].join('; ');
      for (final l in lines) {
        await stock.receive(
          productId: l.product.id,
          qty: Qty.round(l.qty),
          unitCost: l.unitCost,
          refType: 'manual',
          refId: docId,
          userId: userId,
          reason: reason.isEmpty ? null : reason,
        );
        if (canEditPrices && l.newPrice != null) {
          final cur = await (db.select(db.products)..where((p) => p.id.equals(l.product.id))).getSingle();
          if (cur.price != l.newPrice) {
            await (db.update(db.products)..where((p) => p.id.equals(cur.id))).write(
              ProductsCompanion(price: Value(l.newPrice!), updatedAt: Value(DateTime.now())),
            );
            await db.markDirty('products', cur.id);
            await db.audit(
              'product.price',
              userId: userId,
              entity: 'product',
              entityId: cur.id,
              details: '${cur.price} → ${l.newPrice}; приход',
            );
          }
        }
      }
      if (sup != null && total != 0) {
        await (db.update(db.suppliers)..where((s) => s.id.equals(sup!.id))).write(
          SuppliersCompanion(balance: Value(sup.balance + total), updatedAt: Value(DateTime.now())),
        );
        await db.markDirty('suppliers', sup.id);
      }
      await db.audit(
        'stock.receipt',
        userId: userId,
        entity: 'supplier',
        entityId: supplierId,
        details: 'doc $docId; позиций ${lines.length}; сумма $total',
      );
    });
    return docId;
  }

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
        if (categoryId == null) throw BusinessException('Выберите категорию');
        sel.where((p) => p.categoryId.equals(categoryId) & p.isActive.equals(true));
      case CountScope.selected:
        if (productIds.isEmpty) throw BusinessException('Выберите товары');
        sel.where((p) => p.id.isIn(productIds));
    }
    final products = await sel.get();
    if (products.isEmpty) throw BusinessException('Нет товаров для инвентаризации');
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
        details: '№$number; ${products.length} поз.',
      );
    });
    return id;
  }

  Future<InventoryCount> _draft(String countId) async {
    final c = await (db.select(db.inventoryCounts)..where((t) => t.id.equals(countId))).getSingle();
    if (c.status != 'draft') throw BusinessException('Инвентаризация уже закрыта');
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
        if (v != null && v < 0) throw BusinessException('Количество не может быть отрицательным');
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
      if (counted.isEmpty) throw BusinessException('Не введено ни одного фактического количества');
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
