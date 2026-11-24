import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../errors.dart';
import 'stock_service.dart';
import 'supplier_service.dart';

/// One line of a goods receipt document.
class ReceiptLineInput {
  const ReceiptLineInput({
    required this.productId,
    required this.qty,
    required this.unitCost,
    this.newPrice,
    this.orderItemId,
  });
  final String productId;
  final double qty;
  final int unitCost;

  /// New retail price; null = keep current.
  final int? newPrice;

  /// `purchase_order_items.id` when received against a purchase order.
  final String? orderItemId;

  int get total => (qty * unitCost).round();
}

/// Result of [ReceiptService.post].
class PostedReceipt {
  const PostedReceipt({required this.id, required this.number, required this.total});
  final String id;
  final int number;
  final int total;
}

/// Goods receipt status values.
abstract final class ReceiptStatus {
  static const posted = 'posted';
  static const reversed = 'reversed';
}

/// Numbered goods receipt documents («Приход №N») and their reversal
/// («сторно»). The only writer of `goods_receipts` / `goods_receipt_items`.
/// Stock goes through [StockService], supplier debt through
/// [SupplierLedgerService]; everything inside one transaction.
class ReceiptService {
  ReceiptService(this.db, [StockService? stock, SupplierLedgerService? ledger])
      : stock = stock ?? StockService(db),
        ledger = ledger ?? SupplierLedgerService(db);
  final AppDatabase db;
  final StockService stock;
  final SupplierLedgerService ledger;

  /// Posts a receipt document. All-or-nothing.
  Future<PostedReceipt> post({
    required List<ReceiptLineInput> lines,
    String? supplierId,
    String? orderId,
    String? supplierInvoice,
    String? note,
    String? userId,
    bool canEditPrices = true,
  }) async {
    if (lines.isEmpty) throw BusinessException('Добавьте хотя бы одну позицию');
    for (final l in lines) {
      if (l.unitCost < 0) throw BusinessException('Цена закупки не может быть отрицательной');
      if (l.newPrice != null && l.newPrice! <= 0) {
        throw BusinessException('Розничная цена должна быть больше нуля');
      }
    }
    return db.transaction(() async {
      // ---- validation (before any write)
      final products = <String, Product>{};
      final seen = <String>{};
      for (final l in lines) {
        final p = products[l.productId] ??=
            (await (db.select(db.products)..where((t) => t.id.equals(l.productId))).getSingleOrNull())
                ?? (throw BusinessException('Товар не найден'));
        if (p.deletedAt != null) throw BusinessException('Товар «${p.name}» удалён');
        final err = _qtyError(l.qty, p.unit);
        if (err != null) throw BusinessException('${p.name}: $err');
        if (l.unitCost < 0) throw BusinessException('${p.name}: цена закупки отрицательная');
        if (!seen.add('${l.productId}|${l.orderItemId ?? ''}')) {
          throw BusinessException('Товар «${p.name}» повторяется в документе — объедините строки');
        }
      }
      Supplier? sup;
      if (supplierId != null) {
        sup = await (db.select(db.suppliers)..where((s) => s.id.equals(supplierId))).getSingleOrNull();
        if (sup == null || sup.deletedAt != null) throw BusinessException('Поставщик не найден');
      }
      PurchaseOrder? order;
      if (orderId != null) {
        order = await (db.select(db.purchaseOrders)..where((t) => t.id.equals(orderId))).getSingleOrNull();
        if (order == null || order.deletedAt != null) throw BusinessException('Заказ не найден');
        if (sup == null) {
          sup = await (db.select(db.suppliers)..where((s) => s.id.equals(order!.supplierId))).getSingleOrNull();
          if (sup == null || sup.deletedAt != null) throw BusinessException('Поставщик не найден');
        } else if (order.supplierId != sup.id) {
          throw BusinessException('Заказ не относится к этому поставщику');
        }
        if (order.status != 'ordered' && order.status != 'draft') {
          throw BusinessException('Заказ №${order.number} уже закрыт');
        }
        final itemIds = {
          for (final i in await (db.select(db.purchaseOrderItems)..where((i) => i.orderId.equals(orderId))).get())
            i.id: i,
        };
        for (final l in lines) {
          if (l.orderItemId == null) continue;
          final it = itemIds[l.orderItemId];
          if (it == null || it.productId != l.productId) throw BusinessException('Позиция не найдена в заказе');
        }
      } else if (lines.any((l) => l.orderItemId != null)) {
        throw BusinessException('Позиция заказа указана без заказа');
      }

      // ---- header
      final id = newId();
      final number = await db.nextNumber('receipt');
      final total = lines.fold<int>(0, (s, l) => s + l.total);
      final cleanNote = _clean(note);
      await db.into(db.goodsReceipts).insert(GoodsReceiptsCompanion.insert(
            id: id,
            number: number,
            supplierId: Value(sup?.id),
            orderId: Value(orderId),
            supplierInvoice: Value(_clean(supplierInvoice)),
            total: Value(total),
            userId: Value(userId),
            note: Value(cleanNote),
          ));
      final reason = [
        'Приход №$number',
        if (sup != null) 'Поставщик: ${sup.name}',
        if (order != null) 'Заказ поставщику №${order.number}',
        ?cleanNote,
      ].join('; ');

      // ---- lines
      for (final l in lines) {
        final qty = Qty.round(l.qty);
        await stock.receive(
          productId: l.productId,
          qty: qty,
          unitCost: l.unitCost,
          refType: 'receipt',
          refId: id,
          userId: userId,
          reason: reason,
        );
        int? oldPrice, newPrice;
        if (canEditPrices && l.newPrice != null) {
          final cur = await (db.select(db.products)..where((p) => p.id.equals(l.productId))).getSingle();
          if (cur.price != l.newPrice) {
            oldPrice = cur.price;
            newPrice = l.newPrice;
            await (db.update(db.products)..where((p) => p.id.equals(cur.id)))
                .write(ProductsCompanion(price: Value(l.newPrice!), updatedAt: Value(DateTime.now())));
            await db.markDirty('products', cur.id);
            await db.audit('product.price',
                userId: userId,
                entity: 'product',
                entityId: cur.id,
                details: '${cur.price} → ${l.newPrice}; приход №$number');
          }
        }
        final itemId = newId();
        await db.into(db.goodsReceiptItems).insert(GoodsReceiptItemsCompanion.insert(
              id: itemId,
              receiptId: id,
              productId: l.productId,
              orderItemId: Value(l.orderItemId),
              qty: qty,
              unitCost: l.unitCost,
              oldPrice: Value(oldPrice),
              newPrice: Value(newPrice),
            ));
        await db.markDirty('goods_receipt_items', itemId);
      }

      // ---- supplier debt
      if (sup != null && total != 0) {
        await ledger.post(
          supplierId: sup.id,
          kind: SupplierLedgerKind.receipt,
          amount: total,
          refType: 'goods_receipt',
          refId: id,
          userId: userId,
          note: 'Приход №$number',
        );
      }
      await db.markDirty('goods_receipts', id);
      await db.audit('receipt.post',
          userId: userId,
          entity: 'goods_receipt',
          entityId: id,
          details: '№$number; позиций ${lines.length}; сумма $total'
              '${sup != null ? '; поставщик ${sup.name}' : ''}'
              '${order != null ? '; заказ №${order.number}' : ''}');
      return PostedReceipt(id: id, number: number, total: total);
    });
  }

  /// Reverses («сторно») a posted receipt: stock, average cost, retail price,
  /// purchase order received quantities and supplier debt. All-or-nothing.
  Future<void> reverse(String receiptId, {required String reason, String? userId}) async {
    final why = reason.trim();
    if (why.isEmpty) throw BusinessException('Укажите причину сторно');
    await db.transaction(() async {
      final r = await (db.select(db.goodsReceipts)..where((t) => t.id.equals(receiptId))).getSingleOrNull();
      if (r == null || r.deletedAt != null) throw BusinessException('Приход не найден');
      if (r.status != ReceiptStatus.posted) throw BusinessException('Приход №${r.number} уже сторнирован');
      if (r.supplierId != null && r.total != 0) {
        final sup =
            await (db.select(db.suppliers)..where((t) => t.id.equals(r.supplierId!))).getSingleOrNull();
        if (sup != null && sup.deletedAt != null) {
          throw BusinessException('Поставщик «${sup.name}» удалён — сторно прихода №${r.number} невозможно');
        }
      }
      final items = await (db.select(db.goodsReceiptItems)
            ..where((i) => i.receiptId.equals(receiptId) & i.deletedAt.isNull())
            ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
          .get();
      final now = DateTime.now();
      final reasonText = 'Сторно прихода №${r.number}: $why';
      for (final it in items) {
        final p = await (db.select(db.products)..where((t) => t.id.equals(it.productId))).getSingle();
        final s = p.stockQty;
        final c = p.costPrice;
        await stock.move(
          productId: it.productId,
          delta: -it.qty,
          type: 'receipt_reversal',
          refType: 'receipt',
          refId: receiptId,
          userId: userId,
          reason: reasonText,
          unitCost: it.unitCost,
          enforce: true,
        );
        final rest = Qty.round(s - it.qty);
        final value = c * s - it.unitCost * it.qty;
        final newCost = rest > 0 && value > 0 ? (value / rest).round() : c;
        var price = p.price;
        if (it.newPrice != null && it.oldPrice != null && p.price == it.newPrice) {
          price = it.oldPrice!;
          await db.audit('product.price',
              userId: userId,
              entity: 'product',
              entityId: p.id,
              details: '${p.price} → $price; сторно прихода №${r.number}');
        }
        if (newCost != c || price != p.price) {
          await (db.update(db.products)..where((t) => t.id.equals(p.id)))
              .write(ProductsCompanion(costPrice: Value(newCost), price: Value(price), updatedAt: Value(now)));
          await db.markDirty('products', p.id);
        }
      }

      // ---- purchase order
      if (r.orderId != null) {
        final order = await (db.select(db.purchaseOrders)..where((t) => t.id.equals(r.orderId!))).getSingleOrNull();
        if (order != null) {
          for (final it in items.where((i) => i.orderItemId != null)) {
            final poi =
                await (db.select(db.purchaseOrderItems)..where((t) => t.id.equals(it.orderItemId!))).getSingleOrNull();
            if (poi == null) continue;
            await (db.update(db.purchaseOrderItems)..where((t) => t.id.equals(poi.id))).write(
              PurchaseOrderItemsCompanion(
                receivedQty: Value(math.max(0.0, Qty.round(poi.receivedQty - it.qty))),
                updatedAt: Value(now),
              ),
            );
          }
          if (order.status == 'received') {
            final all = await (db.select(db.purchaseOrderItems)
                  ..where((i) => i.orderId.equals(order.id) & i.deletedAt.isNull()))
                .get();
            if (all.any((i) => Qty.round(i.qty - i.receivedQty) > 0)) {
              await (db.update(db.purchaseOrders)..where((t) => t.id.equals(order.id))).write(
                PurchaseOrdersCompanion(
                  status: const Value('ordered'),
                  receivedAt: const Value(null),
                  updatedAt: Value(now),
                ),
              );
            }
          } else {
            await (db.update(db.purchaseOrders)..where((t) => t.id.equals(order.id)))
                .write(PurchaseOrdersCompanion(updatedAt: Value(now)));
          }
          await db.markDirty('purchase_orders', order.id);
        }
      }

      // ---- supplier debt
      if (r.supplierId != null && r.total != 0) {
        await ledger.post(
          supplierId: r.supplierId!,
          kind: SupplierLedgerKind.receiptReversal,
          amount: -r.total,
          refType: 'goods_receipt',
          refId: r.id,
          userId: userId,
          note: reasonText,
        );
      }
      await (db.update(db.goodsReceipts)..where((t) => t.id.equals(r.id))).write(GoodsReceiptsCompanion(
        status: const Value(ReceiptStatus.reversed),
        reversedAt: Value(now),
        reversedBy: Value(userId),
        reverseReason: Value(why),
        updatedAt: Value(now),
      ));
      await db.markDirty('goods_receipts', r.id);
      await db.audit('receipt.reverse',
          userId: userId,
          entity: 'goods_receipt',
          entityId: r.id,
          details: '№${r.number}; сумма ${r.total}; $why');
    });
  }
}

String? _qtyError(double q, String unit) {
  if (q <= 0) return 'Количество должно быть больше нуля';
  if (!Qty.isFractional(unit) && q != q.roundToDouble()) {
    return 'Для «${Qty.unitLabel(unit)}» допускается только целое число';
  }
  if (q > 1e7) return 'Слишком большое количество';
  return null;
}

String? _clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
