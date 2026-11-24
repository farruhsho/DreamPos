// Purchasing (Закупки) data layer: suppliers, supplier payments, purchase
// orders with partial receiving, reorder suggestions and purchase price
// control. Stock changes go through StockService; supplier balances are
// reference data updated inside the same transaction and audited.
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../domain/errors.dart';
import '../../domain/services/stock_service.dart';

// ------------------------------------------------------------------ labels

const poStatusLabels = <String, String>{
  'draft': 'Черновик',
  'ordered': 'Заказан',
  'received': 'Получен',
  'cancelled': 'Отменён',
};

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
  (ref) => PurchasingRepo(ref.watch(databaseProvider), ref.watch(stockServiceProvider)),
);

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
  PurchasingRepo(this.db, this.stock);
  final AppDatabase db;
  final StockService stock;

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

  /// Records a payment to a supplier and decreases the balance.
  /// Cash payments require an open shift ([shiftId]); paying more than the
  /// balance requires [allowOverpay] (creates a prepayment / credit).
  Future<String> paySupplier({
    required String supplierId,
    required int amount,
    required String method,
    String? shiftId,
    String? userId,
    String? orderId,
    String? note,
    bool allowOverpay = false,
  }) async {
    if (amount <= 0) throw BusinessException('Сумма оплаты должна быть больше нуля');
    if (!paymentMethodLabels.containsKey(method)) throw BusinessException('Неизвестный способ оплаты');
    if (method == 'cash' && shiftId == null) {
      throw BusinessException('Для оплаты наличными из кассы откройте смену', code: 'shift');
    }
    final id = newId();
    await db.transaction(() async {
      final s = await (db.select(db.suppliers)..where((t) => t.id.equals(supplierId))).getSingleOrNull();
      if (s == null || s.deletedAt != null) throw BusinessException('Поставщик не найден');
      if (amount > s.balance && !allowOverpay) {
        throw BusinessException(
          'Сумма больше долга поставщику (${Money.format(math.max(0, s.balance))}). Подтвердите переплату.',
          code: 'overpay',
        );
      }
      PurchaseOrder? order;
      if (orderId != null) {
        order = await (db.select(db.purchaseOrders)..where((t) => t.id.equals(orderId))).getSingleOrNull();
        if (order == null || order.supplierId != supplierId) {
          throw BusinessException('Заказ не относится к этому поставщику');
        }
        if (order.status == 'cancelled') throw BusinessException('Заказ №${order.number} отменён');
      }
      if (shiftId != null && method == 'cash') {
        final sh = await (db.select(db.shifts)..where((t) => t.id.equals(shiftId))).getSingleOrNull();
        if (sh == null || sh.status != 'open') throw BusinessException('Смена закрыта — откройте смену');
      }
      final now = DateTime.now();
      await db
          .into(db.supplierPayments)
          .insert(
            SupplierPaymentsCompanion.insert(
              id: id,
              supplierId: supplierId,
              amount: amount,
              method: Value(method),
              orderId: Value(orderId),
              shiftId: Value(method == 'cash' ? shiftId : null),
              userId: Value(userId),
              note: Value(_clean(note)),
            ),
          );
      await (db.update(db.suppliers)..where((t) => t.id.equals(supplierId))).write(
        SuppliersCompanion(balance: Value(s.balance - amount), updatedAt: Value(now)),
      );
      if (order != null) {
        await (db.update(db.purchaseOrders)..where((t) => t.id.equals(order!.id))).write(
          PurchaseOrdersCompanion(paid: Value(order.paid + amount), updatedAt: Value(now)),
        );
        await db.markDirty('purchase_orders', order.id);
      }
      await db.markDirty('supplier_payments', id);
      await db.markDirty('suppliers', supplierId);
      await db.audit(
        'supplier.payment',
        userId: userId,
        entity: 'supplier',
        entityId: supplierId,
        details: '$amount; $method; баланс ${s.balance} → ${s.balance - amount}',
      );
    });
    return id;
  }

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

  /// Partial or full receiving. Each line is posted through
  /// StockService.receive(refType: 'purchase'); supplier balance grows by the
  /// received value; the order becomes `received` when nothing remains.
  Future<ReceiveResult> receiveOrder(String orderId, List<ReceiveLineInput> lines, {String? userId}) async {
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
      var value = 0;
      final now = DateTime.now();
      for (final l in active) {
        final it = items[l.itemId];
        if (it == null) throw BusinessException('Позиция не найдена в заказе');
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
        await stock.receive(
          productId: it.productId,
          qty: Qty.round(l.qty),
          unitCost: cost,
          refType: 'purchase',
          refId: orderId,
          userId: userId,
          reason: 'Заказ поставщику №${o.number}',
        );
        final newReceived = Qty.round(it.receivedQty + l.qty);
        await (db.update(db.purchaseOrderItems)..where((t) => t.id.equals(it.id))).write(
          PurchaseOrderItemsCompanion(receivedQty: Value(newReceived), updatedAt: Value(now)),
        );
        items[it.id] = it.copyWith(receivedQty: newReceived);
        value += (l.qty * cost).round();
      }
      final full = items.values.every((i) => remainingQty(i) <= 0);
      await (db.update(db.purchaseOrders)..where((t) => t.id.equals(orderId))).write(
        PurchaseOrdersCompanion(
          status: Value(full ? 'received' : 'ordered'),
          receivedAt: full ? Value(now) : const Value.absent(),
          updatedAt: Value(now),
        ),
      );
      final s = await (db.select(db.suppliers)..where((t) => t.id.equals(o.supplierId))).getSingle();
      await (db.update(db.suppliers)..where((t) => t.id.equals(s.id))).write(
        SuppliersCompanion(balance: Value(s.balance + value), updatedAt: Value(now)),
      );
      await db.markDirty('purchase_orders', orderId);
      await db.markDirty('suppliers', s.id);
      await db.audit(
        'po.receive',
        userId: userId,
        entity: 'purchase_order',
        entityId: orderId,
        details: '№${o.number}; поз. ${active.length}; сумма $value; ${full ? 'полностью' : 'частично'}',
      );
      return ReceiveResult(value: value, fullyReceived: full, lines: active.length);
    });
  }

  /// Received value of an order (Σ receivedQty × unitCost) from receipts.
  Future<int> receivedValue(String orderId) async {
    final rows = await (db.select(
      db.stockMovements,
    )..where((m) => m.refType.equals('purchase') & m.refId.equals(orderId) & m.type.equals('receipt'))).get();
    return rows.fold<int>(0, (s, m) => s + (m.qty * m.unitCost).round());
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
