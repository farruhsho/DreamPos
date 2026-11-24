// Data access for the products module: catalog queries (paged, filtered in
// SQL), reference-data writes (products, categories) and bulk / import ops.
// Stock is only changed through StockService (initial stock on creation).
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../domain/errors.dart';
import '../../domain/services/stock_service.dart';
import 'product_logic.dart';

/// Editable product fields (one form state -> one write).
class ProductDraft {
  ProductDraft({
    this.name = '',
    this.categoryId,
    this.unit = 'pcs',
    this.description,
    this.isActive = true,
    this.isFavorite = false,
    this.price = 0,
    this.costPrice = 0,
    this.wholesalePrice,
    this.vatPercent = 0,
    this.barcode,
    this.sku,
    this.trackStock = true,
    this.allowNegativeStock = false,
    this.minStock = 0,
    this.initialStock = 0,
    this.warrantyMonths = 0,
    this.supplierId,
  });

  factory ProductDraft.fromProduct(Product p) => ProductDraft(
        name: p.name,
        categoryId: p.categoryId,
        unit: p.unit,
        description: p.description,
        isActive: p.isActive,
        isFavorite: p.isFavorite,
        price: p.price,
        costPrice: p.costPrice,
        wholesalePrice: p.wholesalePrice,
        vatPercent: p.vatPercent,
        barcode: p.barcode,
        sku: p.sku,
        trackStock: p.trackStock,
        allowNegativeStock: p.allowNegativeStock,
        minStock: p.minStock,
        warrantyMonths: p.warrantyMonths,
        supplierId: p.supplierId,
      );

  String name;
  String? categoryId;
  String unit;
  String? description;
  bool isActive;
  bool isFavorite;
  int price;
  int costPrice;
  int? wholesalePrice;
  double vatPercent;
  String? barcode;
  String? sku;
  bool trackStock;
  bool allowNegativeStock;
  double minStock;
  double initialStock;
  int warrantyMonths;
  String? supplierId;
}

class ProductStats {
  const ProductStats({
    required this.soldQty,
    required this.revenue,
    required this.receipts,
    this.lastReceiptAt,
  });
  final double soldQty;
  final int revenue;
  final int receipts; // number of sale documents
  final DateTime? lastReceiptAt;
}

/// Result line of an import plan.
enum ImportAction { create, update, skip }

class PlannedImport {
  PlannedImport(this.row, this.action, {this.existing, this.note});
  final ImportRow row;
  final ImportAction action;
  final Product? existing;
  final String? note;
}

class ImportResult {
  ImportResult({this.created = 0, this.updated = 0, this.skipped = 0, this.categoriesCreated = 0});
  int created;
  int updated;
  int skipped;
  int categoriesCreated;
}

String? _blankToNull(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

class ProductsRepo {
  ProductsRepo(this.db, [StockService? stock]) : stock = stock ?? StockService(db);
  final AppDatabase db;
  final StockService stock;

  // ------------------------------------------------------------------ queries

  Expression<bool> _where($ProductsTable p, ProductQuery q) {
    Expression<bool> w = p.deletedAt.isNull();
    switch (q.active) {
      case ActiveFilter.active:
        w = w & p.isActive.equals(true);
      case ActiveFilter.archived:
        w = w & p.isActive.equals(false);
      case ActiveFilter.all:
        break;
    }
    if (q.categoryId == noCategoryId) {
      w = w & p.categoryId.isNull();
    } else if (q.categoryId != null) {
      w = w & p.categoryId.equals(q.categoryId!);
    }
    if (q.favoritesOnly) w = w & p.isFavorite.equals(true);
    switch (q.stock) {
      case StockFilter.all:
        break;
      case StockFilter.inStock:
        // Untracked goods (services, bags…) are always available.
        w = w & (p.trackStock.equals(false) | p.stockQty.isBiggerThanValue(0));
      case StockFilter.low:
        w = w &
            p.trackStock.equals(true) &
            p.minStock.isBiggerThanValue(0) &
            p.stockQty.isBiggerThanValue(0) &
            p.stockQty.isSmallerOrEqual(p.minStock);
      case StockFilter.out:
        w = w & p.trackStock.equals(true) & p.stockQty.isSmallerOrEqualValue(0);
      case StockFilter.negative:
        w = w & p.trackStock.equals(true) & p.stockQty.isSmallerThanValue(0);
    }
    final s = likeSafe(q.search.trim());
    if (s.isNotEmpty) {
      Expression<bool> m = p.barcode.equals(s) | p.sku.like('%$s%') | p.barcode.like('%$s%');
      for (final v in caseVariants(s)) {
        m = m | p.name.like('%$v%') | p.sku.like('%$v%');
      }
      w = w & m;
    }
    return w;
  }

  SimpleSelectStatement<$ProductsTable, Product> _select(ProductQuery q) {
    final sel = db.select(db.products)..where((p) => _where(p, q));
    final mode = q.descending ? OrderingMode.desc : OrderingMode.asc;
    sel.orderBy([
      (p) => switch (q.sort) {
            ProductSort.name => OrderingTerm(expression: p.name, mode: mode),
            ProductSort.price => OrderingTerm(expression: p.price, mode: mode),
            ProductSort.stock => OrderingTerm(expression: p.stockQty, mode: mode),
            ProductSort.margin => OrderingTerm(
                expression: const CustomExpression<double>(
                    'CASE WHEN price > 0 THEN (price - cost_price) * 1.0 / price ELSE -1 END'),
                mode: mode),
            ProductSort.updated => OrderingTerm(expression: p.updatedAt, mode: mode),
          },
      (p) => OrderingTerm.asc(p.name),
      (p) => OrderingTerm.asc(p.id),
    ]);
    if (q.limit > 0) sel.limit(q.limit);
    return sel;
  }

  Stream<List<Product>> watchProducts(ProductQuery q) => _select(q).watch();
  Future<List<Product>> listProducts(ProductQuery q) => _select(q).get();

  Stream<int> watchCount(ProductQuery q) {
    final c = db.products.id.count();
    final sel = db.selectOnly(db.products)
      ..addColumns([c])
      ..where(_where(db.products, q));
    return sel.map((r) => r.read(c) ?? 0).watchSingle();
  }

  Stream<Product?> watchProduct(String id) =>
      (db.select(db.products)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<List<Product>> byIds(Iterable<String> ids) async {
    final out = <Product>[];
    for (final chunk in ids.toList().slices(500)) {
      out.addAll(await (db.select(db.products)..where((p) => p.id.isIn(chunk))).get());
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  Stream<List<Category>> watchCategories() => (db.select(db.categories)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)]))
      .watch();

  /// Product count per category (null key = without category), non-deleted.
  Stream<Map<String?, int>> watchCategoryCounts() {
    final c = db.products.id.count();
    final sel = db.selectOnly(db.products)
      ..addColumns([db.products.categoryId, c])
      ..where(db.products.deletedAt.isNull())
      ..groupBy([db.products.categoryId]);
    return sel.watch().map((rows) =>
        {for (final r in rows) r.read(db.products.categoryId): r.read(c) ?? 0});
  }

  Stream<List<Supplier>> watchSuppliers() => (db.select(db.suppliers)
        ..where((s) => s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.asc(s.name)]))
      .watch();

  Stream<List<StockMovement>> watchMovements(String productId, {int limit = 50}) =>
      (db.select(db.stockMovements)
            ..where((m) => m.productId.equals(productId) & m.deletedAt.isNull())
            ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
            ..limit(limit))
          .watch();

  Stream<ProductStats> watchStats(String productId, {int days = 30}) {
    final since = DateTime.now().subtract(Duration(days: days));
    final sales = db.customSelect(
      'SELECT COALESCE(SUM(si.qty - si.returned_qty), 0) AS q, '
      'COALESCE(SUM(CASE WHEN si.qty > 0 THEN si.total * (si.qty - si.returned_qty) / si.qty ELSE 0 END), 0) AS r, '
      'COUNT(DISTINCT si.sale_id) AS n '
      'FROM sale_items si JOIN sales s ON s.id = si.sale_id '
      "WHERE si.product_id = ? AND s.created_at >= ? AND s.status NOT IN ('voided', 'held') "
      'AND si.deleted_at IS NULL AND s.deleted_at IS NULL',
      variables: [Variable.withString(productId), Variable.withDateTime(since)],
      readsFrom: {db.saleItems, db.sales, db.stockMovements},
    ).watchSingle();
    return sales.asyncMap((row) async {
      // Last receipt, ignoring lines of reversed receipt documents.
      final last = await db
          .customSelect(
            'SELECT MAX(m.created_at) AS mx FROM stock_movements m '
            "WHERE m.product_id = ? AND m.type = 'receipt' AND m.deleted_at IS NULL "
            "AND NOT (m.ref_type = 'receipt' AND m.ref_id IN "
            "(SELECT id FROM goods_receipts WHERE status = 'reversed'))",
            variables: [Variable.withString(productId)],
            readsFrom: {db.stockMovements, db.goodsReceipts},
          )
          .map((r) => r.readNullable<DateTime>('mx'))
          .getSingle();
      return ProductStats(
        soldQty: Qty.round(row.read<double>('q')),
        revenue: row.read<double>('r').round(),
        receipts: row.read<int>('n'),
        lastReceiptAt: last,
      );
    });
  }

  // ------------------------------------------------------------- validation

  /// Returns the product (non-deleted) that already uses [barcode], except
  /// [excludeId]; null when the barcode is free.
  Future<Product?> barcodeOwner(String barcode, {String? excludeId}) async {
    final b = barcode.trim();
    if (b.isEmpty) return null;
    final sel = db.select(db.products)
      ..where((p) => p.deletedAt.isNull() & p.barcode.equals(b))
      ..limit(1);
    if (excludeId != null) sel.where((p) => p.id.equals(excludeId).not());
    return sel.getSingleOrNull();
  }

  /// Exact lookup for scanners: barcode first, then SKU (non-deleted).
  Future<Product?> findByCode(String code) async {
    final c = code.trim();
    if (c.isEmpty) return null;
    final byBarcode = await barcodeOwner(c);
    if (byBarcode != null) return byBarcode;
    return (db.select(db.products)
          ..where((p) => p.deletedAt.isNull() & p.sku.equals(c))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<bool> isBarcodeTaken(String barcode, {String? excludeId}) async =>
      await barcodeOwner(barcode, excludeId: excludeId) != null;

  /// Next free internal EAN-13 (200…). Deleted products count too so a
  /// deleted product's label never scans as a new item.
  Future<String> nextInternalBarcode() async {
    final rows = await db.customSelect(
      "SELECT MAX(CAST(SUBSTR(barcode, 4, 9) AS INTEGER)) AS m FROM products "
      "WHERE LENGTH(barcode) = 13 AND barcode GLOB '200[0-9]*' AND barcode NOT GLOB '*[^0-9]*'",
      readsFrom: {db.products},
    ).getSingle();
    var seq = (rows.read<int?>('m') ?? 0) + 1;
    while (true) {
      final code = Ean13.internal(seq);
      if (await barcodeOwner(code) == null) return code;
      seq++;
    }
  }

  /// Suggests the next numeric SKU (max numeric SKU + 1, zero-padded to 5).
  Future<String> suggestSku() async {
    final row = await db.customSelect(
      "SELECT MAX(CAST(sku AS INTEGER)) AS m, MAX(LENGTH(sku)) AS l FROM products "
      "WHERE sku IS NOT NULL AND sku <> '' AND sku NOT GLOB '*[^0-9]*'",
      readsFrom: {db.products},
    ).getSingle();
    final next = (row.read<int?>('m') ?? 0) + 1;
    final width = (row.read<int?>('l') ?? 5).clamp(5, 12);
    return next.toString().padLeft(width, '0');
  }

  /// True when the product has any document/ledger history and therefore
  /// may only be archived, never deleted.
  Future<bool> hasHistory(String productId) async {
    final row = await db.customSelect(
      'SELECT '
      '(SELECT COUNT(*) FROM stock_movements WHERE product_id = ?1) + '
      '(SELECT COUNT(*) FROM sale_items WHERE product_id = ?1) + '
      '(SELECT COUNT(*) FROM purchase_order_items WHERE product_id = ?1) + '
      '(SELECT COUNT(*) FROM inventory_count_items WHERE product_id = ?1) + '
      '(SELECT COUNT(*) FROM return_items WHERE product_id = ?1) + '
      '(SELECT COUNT(*) FROM warranty_claims WHERE product_id = ?1) AS n',
      variables: [Variable.withString(productId)],
    ).getSingle();
    return row.read<int>('n') > 0;
  }

  // ------------------------------------------------------------------ writes

  /// Creates ([existing] == null) or updates a product.
  ///
  /// On update [existing] is the snapshot the editor was opened with: only
  /// fields the user changed relative to that snapshot are written, so a
  /// concurrent change (e.g. a receipt recalculating the average cost on
  /// another register) is not overwritten with stale values.
  /// [canEditPrices] = false rejects any change of retail/wholesale/cost/VAT
  /// of an existing product. Returns the product id.
  Future<String> saveProduct(ProductDraft d,
      {Product? existing, String? userId, bool canEditPrices = true}) async {
    final name = d.name.trim();
    if (name.isEmpty) throw BusinessException('Введите название товара');
    if (name.length > 200) throw BusinessException('Название длиннее 200 символов');
    if (d.price < 0) throw BusinessException('Цена не может быть отрицательной');
    if (d.costPrice < 0) throw BusinessException('Себестоимость не может быть отрицательной');
    if ((d.wholesalePrice ?? 0) < 0) throw BusinessException('Оптовая цена не может быть отрицательной');
    if (d.vatPercent < 0 || d.vatPercent > 100) throw BusinessException('НДС должен быть от 0 до 100%');
    if (d.minStock < 0) throw BusinessException('Минимальный остаток не может быть отрицательным');
    if (d.initialStock < 0) throw BusinessException('Начальный остаток не может быть отрицательным');
    final barcode = _blankToNull(d.barcode);
    if (barcode != null) {
      final owner = await barcodeOwner(barcode, excludeId: existing?.id);
      if (owner != null) {
        throw BusinessException('Штрихкод $barcode уже используется товаром «${owner.name}»',
            code: 'barcode');
      }
    }
    if (existing == null && d.trackStock && !Qty.isFractional(d.unit) &&
        d.initialStock != d.initialStock.roundToDouble()) {
      throw BusinessException('Начальный остаток для «${Qty.unitLabel(d.unit)}» должен быть целым');
    }
    if (existing != null && !canEditPrices) {
      if (d.price != existing.price ||
          d.costPrice != existing.costPrice ||
          d.wholesalePrice != existing.wholesalePrice ||
          d.vatPercent != existing.vatPercent) {
        throw BusinessException('Нет права менять цены', code: 'perm');
      }
    }
    final now = DateTime.now();
    return db.transaction(() async {
      // Re-check inside the transaction: another register may have saved the
      // same barcode a moment ago.
      if (barcode != null && await barcodeOwner(barcode, excludeId: existing?.id) != null) {
        throw BusinessException('Штрихкод $barcode уже используется другим товаром', code: 'barcode');
      }
      if (existing == null) {
        final id = newId();
        await db.into(db.products).insert(ProductsCompanion.insert(
              id: id,
              name: name,
              price: d.price,
              costPrice: Value(d.costPrice),
              sku: Value(_blankToNull(d.sku)),
              barcode: Value(barcode),
              categoryId: Value(d.categoryId),
              unit: Value(d.unit),
              wholesalePrice: Value(d.wholesalePrice),
              vatPercent: Value(d.vatPercent),
              trackStock: Value(d.trackStock),
              allowNegativeStock: Value(d.allowNegativeStock),
              minStock: Value(Qty.round(d.minStock)),
              warrantyMonths: Value(d.warrantyMonths),
              isActive: Value(d.isActive),
              isFavorite: Value(d.isFavorite),
              description: Value(_blankToNull(d.description)),
              supplierId: Value(d.supplierId),
              createdAt: Value(now),
              updatedAt: Value(now),
            ));
        await db.markDirty('products', id);
        await db.audit('product.create',
            userId: userId,
            entity: 'product',
            entityId: id,
            details: '$name; цена ${Money.format(d.price)}');
        if (d.trackStock && d.initialStock > 0) {
          await stock.receive(
            productId: id,
            qty: Qty.round(d.initialStock),
            unitCost: d.costPrice,
            refType: 'manual',
            userId: userId,
            reason: 'Начальный остаток',
          );
        }
        return id;
      }

      // Current row (may differ from the snapshot if someone else saved).
      final cur = await (db.select(db.products)..where((p) => p.id.equals(existing.id)))
          .getSingle();
      if (cur.deletedAt != null) throw BusinessException('Товар уже удалён');
      var c = const ProductsCompanion();
      final changes = <String>[];
      // A field is written when the user changed it relative to the snapshot
      // and it differs from the current value.
      void diff<T>(String label, T base, T current, T newV, ProductsCompanion Function(ProductsCompanion) set) {
        if (base != newV && current != newV) {
          c = set(c);
          changes.add(label);
        }
      }

      final e = existing;
      diff('название', e.name, cur.name, name, (c) => c.copyWith(name: Value(name)));
      diff('категория', e.categoryId, cur.categoryId, d.categoryId,
          (c) => c.copyWith(categoryId: Value(d.categoryId)));
      final unitChanged = e.unit != d.unit && cur.unit != d.unit;
      if (unitChanged && cur.trackStock && !Qty.isFractional(d.unit) &&
          cur.stockQty != cur.stockQty.roundToDouble()) {
        throw BusinessException('Остаток ${Qty.format(cur.stockQty, cur.unit)} дробный — '
            'сначала исправьте его в разделе «Склад», затем меняйте единицу на «${Qty.unitLabel(d.unit)}»');
      }
      diff('ед.', e.unit, cur.unit, d.unit, (c) => c.copyWith(unit: Value(d.unit)));
      final desc = _blankToNull(d.description);
      diff('описание', e.description, cur.description, desc, (c) => c.copyWith(description: Value(desc)));
      diff('активность', e.isActive, cur.isActive, d.isActive, (c) => c.copyWith(isActive: Value(d.isActive)));
      diff('избранное', e.isFavorite, cur.isFavorite, d.isFavorite,
          (c) => c.copyWith(isFavorite: Value(d.isFavorite)));
      final priceChanged = e.price != d.price && cur.price != d.price;
      diff('цена', e.price, cur.price, d.price, (c) => c.copyWith(price: Value(d.price)));
      final costChanged = e.costPrice != d.costPrice && cur.costPrice != d.costPrice;
      diff('себестоимость', e.costPrice, cur.costPrice, d.costPrice,
          (c) => c.copyWith(costPrice: Value(d.costPrice)));
      diff('опт', e.wholesalePrice, cur.wholesalePrice, d.wholesalePrice,
          (c) => c.copyWith(wholesalePrice: Value(d.wholesalePrice)));
      diff('НДС', e.vatPercent, cur.vatPercent, d.vatPercent, (c) => c.copyWith(vatPercent: Value(d.vatPercent)));
      diff('штрихкод', e.barcode, cur.barcode, barcode, (c) => c.copyWith(barcode: Value(barcode)));
      final sku = _blankToNull(d.sku);
      diff('артикул', e.sku, cur.sku, sku, (c) => c.copyWith(sku: Value(sku)));
      diff('учёт остатка', e.trackStock, cur.trackStock, d.trackStock,
          (c) => c.copyWith(trackStock: Value(d.trackStock)));
      diff('минус', e.allowNegativeStock, cur.allowNegativeStock, d.allowNegativeStock,
          (c) => c.copyWith(allowNegativeStock: Value(d.allowNegativeStock)));
      final minStock = Qty.round(d.minStock);
      diff('мин. остаток', e.minStock, cur.minStock, minStock, (c) => c.copyWith(minStock: Value(minStock)));
      diff('гарантия', e.warrantyMonths, cur.warrantyMonths, d.warrantyMonths,
          (c) => c.copyWith(warrantyMonths: Value(d.warrantyMonths)));
      diff('поставщик', e.supplierId, cur.supplierId, d.supplierId,
          (c) => c.copyWith(supplierId: Value(d.supplierId)));
      if (changes.isEmpty) return cur.id;

      await (db.update(db.products)..where((p) => p.id.equals(cur.id)))
          .write(c.copyWith(updatedAt: Value(now)));
      await db.markDirty('products', cur.id);
      if (priceChanged) {
        await db.audit('product.price',
            userId: userId,
            entity: 'product',
            entityId: cur.id,
            details: '${Money.format(cur.price)} → ${Money.format(d.price)}');
      }
      if (costChanged) {
        await db.audit('product.cost',
            userId: userId,
            entity: 'product',
            entityId: cur.id,
            details: '${Money.format(cur.costPrice)} → ${Money.format(d.costPrice)}');
      }
      await db.audit('product.update',
          userId: userId, entity: 'product', entityId: cur.id, details: changes.join(', '));
      return cur.id;
    });
  }

  Future<void> setActive(Iterable<String> ids, bool active, {String? userId}) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    await db.transaction(() async {
      for (final chunk in list.slices(500)) {
        await (db.update(db.products)..where((p) => p.id.isIn(chunk))).write(
            ProductsCompanion(isActive: Value(active), updatedAt: Value(DateTime.now())));
      }
      for (final id in list) {
        await db.markDirty('products', id);
      }
      await db.audit(active ? 'product.unarchive' : 'product.archive',
          userId: userId,
          entity: 'product',
          entityId: list.length == 1 ? list.first : null,
          details: list.length == 1 ? null : '${list.length} товаров');
    });
  }

  Future<void> setFavorite(String id, bool fav) async {
    await (db.update(db.products)..where((p) => p.id.equals(id)))
        .write(ProductsCompanion(isFavorite: Value(fav), updatedAt: Value(DateTime.now())));
    await db.markDirty('products', id);
  }

  /// Soft-deletes a product. Throws when it has history (archive instead).
  Future<void> deleteProduct(String id, {String? userId}) async {
    await db.transaction(() async {
      // Checked inside the transaction so a sale made meanwhile blocks it.
      if (await hasHistory(id)) {
        throw BusinessException('По товару есть операции (продажи, движения). Его можно только архивировать.',
            code: 'has_history');
      }
      final p = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      await (db.update(db.products)..where((t) => t.id.equals(id))).write(ProductsCompanion(
          deletedAt: Value(DateTime.now()), isActive: const Value(false), updatedAt: Value(DateTime.now())));
      await db.markDirty('products', id, op: 'delete');
      await db.audit('product.delete', userId: userId, entity: 'product', entityId: id, details: p.name);
    });
  }

  Future<void> setCategory(Iterable<String> ids, String? categoryId, {String? userId}) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    await db.transaction(() async {
      for (final chunk in list.slices(500)) {
        await (db.update(db.products)..where((p) => p.id.isIn(chunk))).write(
            ProductsCompanion(categoryId: Value(categoryId), updatedAt: Value(DateTime.now())));
      }
      for (final id in list) {
        await db.markDirty('products', id);
      }
      await db.audit('product.bulk_category',
          userId: userId, entity: 'category', entityId: categoryId, details: '${list.length} товаров');
    });
  }

  /// Applies new retail prices (productId -> price). Each change is audited.
  Future<int> applyPrices(Map<String, int> newPrices, {String? userId, String? note}) async {
    var changed = 0;
    await db.transaction(() async {
      final products = await byIds(newPrices.keys);
      final now = DateTime.now();
      for (final p in products) {
        final np = newPrices[p.id]!;
        if (np < 0) throw BusinessException('Цена не может быть отрицательной: ${p.name}');
        if (np == p.price) continue;
        await (db.update(db.products)..where((t) => t.id.equals(p.id)))
            .write(ProductsCompanion(price: Value(np), updatedAt: Value(now)));
        await db.markDirty('products', p.id);
        await db.audit('product.price',
            userId: userId,
            entity: 'product',
            entityId: p.id,
            details: '${Money.format(p.price)} → ${Money.format(np)}${note == null ? '' : '; $note'}');
        changed++;
      }
      await db.audit('product.bulk_price',
          userId: userId, details: '${note ?? ''}; изменено $changed из ${newPrices.length}');
    });
    return changed;
  }

  // -------------------------------------------------------------- categories

  Future<String> saveCategory({String? id, required String name, required int color}) async {
    final n = name.trim();
    if (n.isEmpty) throw BusinessException('Введите название категории');
    if (n.length > 120) throw BusinessException('Название длиннее 120 символов');
    final all = await (db.select(db.categories)..where((c) => c.deletedAt.isNull())).get();
    final dup = all.firstWhereOrNull((c) => c.id != id && c.name.toLowerCase() == n.toLowerCase());
    if (dup != null) throw BusinessException('Категория «${dup.name}» уже существует');
    final now = DateTime.now();
    if (id == null) {
      final newIdV = newId();
      final maxSort = all.isEmpty ? 0 : all.map((c) => c.sortOrder).max;
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: newIdV,
          name: n,
          color: Value(color),
          sortOrder: Value(maxSort + 1),
          createdAt: Value(now),
          updatedAt: Value(now)));
      await db.markDirty('categories', newIdV);
      return newIdV;
    }
    await (db.update(db.categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(name: Value(n), color: Value(color), updatedAt: Value(now)));
    await db.markDirty('categories', id);
    return id;
  }

  Future<void> reorderCategories(List<String> orderedIds) async {
    await db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (db.update(db.categories)..where((c) => c.id.equals(orderedIds[i])))
            .write(CategoriesCompanion(sortOrder: Value(i), updatedAt: Value(DateTime.now())));
        await db.markDirty('categories', orderedIds[i]);
      }
    });
  }

  Future<int> categoryProductCount(String categoryId) async {
    final c = db.products.id.count();
    return (db.selectOnly(db.products)
          ..addColumns([c])
          ..where(db.products.categoryId.equals(categoryId) & db.products.deletedAt.isNull()))
        .map((r) => r.read(c) ?? 0)
        .getSingle();
  }

  /// Soft-deletes a category. When it still has products, [moveTo] must be
  /// given: a category id, or null with [moveToNone] = true for "Без категории".
  Future<void> deleteCategory(String id,
      {String? moveTo, bool moveToNone = false, String? userId}) async {
    final count = await categoryProductCount(id);
    if (count > 0 && moveTo == null && !moveToNone) {
      throw BusinessException('В категории $count товаров — выберите, куда их перенести',
          code: 'category_in_use');
    }
    if (moveTo == id) throw BusinessException('Выберите другую категорию');
    await db.transaction(() async {
      final now = DateTime.now();
      // Move all referencing rows (deleted ones too) so nothing points to a
      // deleted category.
      final ids = await (db.selectOnly(db.products)
            ..addColumns([db.products.id])
            ..where(db.products.categoryId.equals(id)))
          .map((r) => r.read(db.products.id)!)
          .get();
      if (ids.isNotEmpty) {
        await (db.update(db.products)..where((p) => p.categoryId.equals(id)))
            .write(ProductsCompanion(categoryId: Value(moveTo), updatedAt: Value(now)));
        for (final pid in ids) {
          await db.markDirty('products', pid);
        }
      }
      await (db.update(db.categories)..where((c) => c.id.equals(id)))
          .write(CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await db.markDirty('categories', id, op: 'delete');
      await db.audit('category.delete',
          userId: userId, entity: 'category', entityId: id, details: 'перенесено товаров: ${ids.length}');
    });
  }

  // ------------------------------------------------------------ import/export

  /// Matches parsed rows with the database. Rows with errors are skipped.
  Future<List<PlannedImport>> planImport(List<ImportRow> rows, {required bool updateExisting}) async {
    final out = <PlannedImport>[];
    for (final r in rows) {
      if (!r.isValid) {
        out.add(PlannedImport(r, ImportAction.skip, note: r.errors.join('; ')));
        continue;
      }
      final existing = r.barcode == null ? null : await barcodeOwner(r.barcode!);
      if (existing == null) {
        out.add(PlannedImport(r, ImportAction.create));
      } else if (updateExisting) {
        out.add(PlannedImport(r, ImportAction.update,
            existing: existing,
            note: r.stock != null ? 'Остаток не меняется — используйте «Склад»' : null));
      } else {
        out.add(PlannedImport(r, ImportAction.skip,
            existing: existing, note: 'Штрихкод уже у товара «${existing.name}»'));
      }
    }
    return out;
  }

  Future<ImportResult> applyImport(List<PlannedImport> plan,
      {String? userId, bool canEditPrices = true, bool canSetCost = true}) async {
    final res = ImportResult();
    await db.transaction(() async {
      final cats = await (db.select(db.categories)..where((c) => c.deletedAt.isNull())).get();
      final byName = {for (final c in cats) c.name.toLowerCase(): c.id};
      var sort = cats.isEmpty ? 0 : cats.map((c) => c.sortOrder).max;
      Future<String?> catId(String? name) async {
        if (name == null) return null;
        final k = name.toLowerCase();
        final found = byName[k];
        if (found != null) return found;
        final id = newId();
        sort++;
        await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: id,
            name: name,
            sortOrder: Value(sort),
            color: Value(categoryPalette[(sort) % categoryPalette.length])));
        await db.markDirty('categories', id);
        byName[k] = id;
        res.categoriesCreated++;
        return id;
      }

      for (final pl in plan) {
        final r = pl.row;
        switch (pl.action) {
          case ImportAction.skip:
            res.skipped++;
          case ImportAction.create:
            final draft = ProductDraft(
              name: r.name,
              barcode: r.barcode,
              sku: r.sku,
              categoryId: await catId(r.category),
              price: r.price ?? 0,
              costPrice: canSetCost ? (r.cost ?? 0) : 0,
              unit: r.unit,
              initialStock: r.stock ?? 0,
            );
            await saveProduct(draft, userId: userId);
            res.created++;
          case ImportAction.update:
            final cur = await (db.select(db.products)..where((p) => p.id.equals(pl.existing!.id)))
                .getSingle();
            final draft = ProductDraft.fromProduct(cur)..name = r.name;
            // An empty unit cell must not reset e.g. «кг» to «шт».
            if (r.unitGiven) draft.unit = r.unit;
            if (r.sku != null) draft.sku = r.sku;
            if (r.category != null) draft.categoryId = await catId(r.category);
            if (canEditPrices && r.price != null) draft.price = r.price!;
            await saveProduct(draft, existing: cur, userId: userId);
            res.updated++;
        }
      }
      await db.audit('product.import',
          userId: userId,
          details: 'создано ${res.created}, обновлено ${res.updated}, пропущено ${res.skipped}');
    });
    return res;
  }

  /// CSV of products matching [q] (no limit), or of [ids] when given.
  Future<String> exportCsv(ProductQuery q, {Iterable<String>? ids, bool includeCost = true}) async {
    final products = ids != null ? await byIds(ids) : await listProducts(q.unlimited);
    final cats = await (db.select(db.categories)).get();
    final catName = {for (final c in cats) c.id: c.name};
    final rows = <List<String>>[
      ['name', 'barcode', 'sku', 'category', 'price', if (includeCost) 'cost', 'unit', 'stock'],
      for (final p in products)
        [
          p.name,
          p.barcode ?? '',
          p.sku ?? '',
          p.categoryId == null ? '' : (catName[p.categoryId] ?? ''),
          moneyCsv(p.price),
          if (includeCost) moneyCsv(p.costPrice),
          Qty.unitLabel(p.unit),
          qtyCsv(p.stockQty),
        ],
    ];
    return toCsv(rows);
  }
}

// ------------------------------------------------------------------ providers

final productsRepoProvider = Provider<ProductsRepo>(
    (ref) => ProductsRepo(ref.watch(databaseProvider), ref.watch(stockServiceProvider)));

final productListProvider = StreamProvider.autoDispose.family<List<Product>, ProductQuery>(
    (ref, q) => ref.watch(productsRepoProvider).watchProducts(q));

final productCountProvider = StreamProvider.autoDispose.family<int, ProductQuery>(
    (ref, q) => ref.watch(productsRepoProvider).watchCount(q.unlimited));

final productCategoriesProvider =
    StreamProvider<List<Category>>((ref) => ref.watch(productsRepoProvider).watchCategories());

final categoryCountsProvider = StreamProvider.autoDispose<Map<String?, int>>(
    (ref) => ref.watch(productsRepoProvider).watchCategoryCounts());

final productSuppliersProvider = StreamProvider.autoDispose<List<Supplier>>(
    (ref) => ref.watch(productsRepoProvider).watchSuppliers());

final productByIdProvider = StreamProvider.autoDispose.family<Product?, String>(
    (ref, id) => ref.watch(productsRepoProvider).watchProduct(id));

final productStatsProvider = StreamProvider.autoDispose.family<ProductStats, String>(
    (ref, id) => ref.watch(productsRepoProvider).watchStats(id));

final productMovementsProvider = StreamProvider.autoDispose.family<List<StockMovement>, String>(
    (ref, id) => ref.watch(productsRepoProvider).watchMovements(id));
