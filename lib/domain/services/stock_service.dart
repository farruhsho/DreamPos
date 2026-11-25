import 'package:drift/drift.dart';

import '../../l10n/l10n.dart';
import '../../core/db/database.dart';
import '../../core/doc_number.dart';
import '../../core/money.dart';
import '../errors.dart';

/// All stock changes go through here so the ledger and cached stock agree.
class StockService {
  StockService(this.db);
  final AppDatabase db;

  /// Applies a signed [delta] to a product and writes a ledger row.
  /// Must be called inside a transaction by multi-row operations.
  /// When [enforce] is true and the product does not allow negative stock,
  /// throws if the result would be negative. [id] is the movement id
  /// (default: a new one; a one-time effect passes `effectId`, D-025).
  Future<double> move({
    String? id,
    required String productId,
    required double delta,
    required String type,
    String? refType,
    String? refId,
    String? userId,
    String? reason,
    int? unitCost,
    bool enforce = false,
  }) async {
    final p = await (db.select(db.products)..where((t) => t.id.equals(productId)))
        .getSingle();
    if (!p.trackStock) return p.stockQty;
    final after = Qty.round(p.stockQty + delta);
    if (enforce && delta < 0 && after < 0 && !p.allowNegativeStock) {
      final globalAllow = await db.getSetting('allow_negative_stock') == '1';
      if (!globalAllow) {
        throw BusinessException(
            L.current.errInsufficientStock(p.name, Qty.format(p.stockQty, p.unit)),
            code: 'stock');
      }
    }
    await (db.update(db.products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
            stockQty: Value(after), updatedAt: Value(DateTime.now())));
    await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
          id: id ?? newId(),
          productId: productId,
          type: type,
          qty: Qty.round(delta),
          qtyAfter: after,
          unitCost: Value(unitCost ?? p.costPrice),
          refType: Value(refType),
          refId: Value(refId),
          userId: Value(userId),
          reason: Value(reason),
        ));
    await db.markDirty('products', productId);
    return after;
  }

  /// Goods receipt: increases stock and recalculates weighted average cost.
  Future<void> receive({
    required String productId,
    required double qty,
    required int unitCost,
    String? refType,
    String? refId,
    String? userId,
    String? reason,
  }) async {
    if (qty <= 0) throw BusinessException(L.current.errQtyMustBePositive);
    await db.transaction(() async {
      final p = await (db.select(db.products)..where((t) => t.id.equals(productId)))
          .getSingle();
      final oldQty = p.stockQty < 0 ? 0.0 : p.stockQty;
      final newCost = (oldQty + qty) <= 0
          ? unitCost
          : ((p.costPrice * oldQty + unitCost * qty) / (oldQty + qty)).round();
      await (db.update(db.products)..where((t) => t.id.equals(productId)))
          .write(ProductsCompanion(costPrice: Value(newCost)));
      await move(
        productId: productId,
        delta: qty,
        type: 'receipt',
        refType: refType ?? 'manual',
        refId: refId,
        userId: userId,
        reason: reason,
        unitCost: unitCost,
      );
    });
  }

  Future<void> writeOff({
    required String productId,
    required double qty,
    required String reason,
    String? userId,
    String? refType,
    String? refId,
  }) async {
    if (qty <= 0) throw BusinessException(L.current.errQtyMustBePositive);
    await db.transaction(() async {
      await move(
          productId: productId,
          delta: -qty,
          type: 'writeoff',
          refType: refType ?? 'manual',
          refId: refId,
          userId: userId,
          reason: reason,
          enforce: true);
      await db.audit('stock.writeoff',
          userId: userId, entity: 'product', entityId: productId,
          details: '$qty; $reason');
    });
  }

  /// Sets stock to an absolute value (manual correction).
  Future<void> setStock({
    String? id,
    required String productId,
    required double newQty,
    required String reason,
    String? userId,
    String type = 'adjustment',
    String? refType,
    String? refId,
  }) async {
    await db.transaction(() async {
      final p = await (db.select(db.products)..where((t) => t.id.equals(productId)))
          .getSingle();
      final delta = Qty.round(newQty - p.stockQty);
      if (delta == 0) return;
      await move(
          id: id,
          productId: productId,
          delta: delta,
          type: type,
          refType: refType ?? 'manual',
          refId: refId,
          userId: userId,
          reason: reason);
      await db.audit('stock.adjust',
          userId: userId, entity: 'product', entityId: productId,
          details: '${p.stockQty} → $newQty; $reason');
    });
  }

  /// Completes an inventory count: every counted line becomes an
  /// 'inventory' movement equal to the difference counted - current stock.
  Future<void> completeCount(String countId, {String? userId}) async {
    await db.transaction(() async {
      final count = await (db.select(db.inventoryCounts)
            ..where((c) => c.id.equals(countId)))
          .getSingle();
      if (count.status != 'draft') {
        throw BusinessException(L.current.errCountClosed);
      }
      final items = await (db.select(db.inventoryCountItems)
            ..where((i) => i.countId.equals(countId) & i.countedQty.isNotNull()))
          .get();
      for (final it in items) {
        await setStock(
          // Same id on every register (D-025): one count completed on two
          // registers offline corrects the stock once, not twice.
          id: effectId('inventory_count', it.id),
          productId: it.productId,
          newQty: it.countedQty!,
          reason: 'Инвентаризация №${docNo(count.number, count.deviceCode)}',
          userId: userId,
          type: 'inventory',
          refType: 'count',
          refId: countId,
        );
      }
      await (db.update(db.inventoryCounts)..where((c) => c.id.equals(countId)))
          .write(InventoryCountsCompanion(
              status: const Value('completed'),
              completedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now())));
      await db.audit('inventory.complete',
          userId: userId, entity: 'inventory_count', entityId: countId);
    });
  }
}
