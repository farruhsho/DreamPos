import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

Product _p({double stock = 0, double min = 0, String unit = 'pcs', int cost = 100}) => Product(
      id: 'p',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      name: 'Товар',
      unit: unit,
      price: 200,
      costPrice: cost,
      vatPercent: 0,
      trackStock: true,
      allowNegativeStock: false,
      stockQty: stock,
      minStock: min,
      warrantyMonths: 0,
      isActive: true,
      isFavorite: false,
    );

void main() {
  test('poDisplayStatus: ordered with some received lines is «Частично получен»', () {
    expect(poDisplayStatus('ordered', anyReceived: true), poPartialStatus);
    expect(poStatusLabels[poPartialStatus], 'Частично получен');
    expect(poDisplayStatus('ordered', anyReceived: false), 'ordered');
    expect(poDisplayStatus('received', anyReceived: true), 'received');
    expect(poStatusLabels['received'], 'Получен');
    expect(poDisplayStatus('draft', anyReceived: false), 'draft');
    expect(poDisplayStatus('cancelled', anyReceived: false), 'cancelled');
  });

  group('computeReorder (pure math)', () {
    test('sales velocity drives the suggestion', () {
      // 60 sold in 30 days -> 2/day; 14 days -> 28; stock 5 -> 23.
      final s = computeReorder(product: _p(stock: 5), soldQty: 60, lookbackDays: 30, targetDays: 14)!;
      expect(s.avgDaily, 2);
      expect(s.daysOfCover, 2.5);
      expect(s.suggestedQty, 23);
      expect(s.estimatedCost, 2300);
    });

    test('quantity already on order is subtracted', () {
      final s = computeReorder(product: _p(stock: 5), soldQty: 60, lookbackDays: 30, targetDays: 14, onOrder: 10)!;
      expect(s.suggestedQty, 13);
      expect(computeReorder(product: _p(stock: 5), soldQty: 60, lookbackDays: 30, targetDays: 14, onOrder: 30),
          isNull);
    });

    test('enough cover -> no suggestion', () {
      expect(computeReorder(product: _p(stock: 100), soldQty: 60, lookbackDays: 30, targetDays: 14), isNull);
    });

    test('below minimum without sales tops up to minimum', () {
      final s = computeReorder(product: _p(stock: 3, min: 10), soldQty: 0, lookbackDays: 30, targetDays: 14)!;
      expect(s.daysOfCover, isNull);
      expect(s.suggestedQty, 7);
    });

    test('piece goods are rounded up, weighted goods keep decimals', () {
      final pcs = computeReorder(product: _p(stock: 0), soldQty: 10, lookbackDays: 30, targetDays: 14)!;
      expect(pcs.suggestedQty, 5); // 4.67 -> 5
      final kg = computeReorder(product: _p(stock: 0, unit: 'kg'), soldQty: 10, lookbackDays: 30, targetDays: 14)!;
      expect(kg.suggestedQty, closeTo(4.667, 0.001));
    });

    test('target days changes the result', () {
      final s = computeReorder(product: _p(stock: 5), soldQty: 60, lookbackDays: 30, targetDays: 7)!;
      expect(s.suggestedQty, 9);
    });
  });

  group('repo', () {
    late Fixture f;
    late PurchasingRepo repo;

    setUp(() async {
      f = await Fixture.create();
      repo = PurchasingRepo(f.db, StockService(f.db));
    });
    tearDown(() => f.db.close());

    Future<Supplier> supplier([int balance = 0]) async {
      final id = await repo.saveSupplier(const SupplierInput(name: 'ООО Поставка', phone: '+998 90 123 45 67'));
      if (balance != 0) {
        await (f.db.update(f.db.suppliers)..where((s) => s.id.equals(id)))
            .write(SuppliersCompanion(balance: Value(balance)));
      }
      return (f.db.select(f.db.suppliers)..where((s) => s.id.equals(id))).getSingle();
    }

    Future<Supplier> reloadS(Supplier s) => (f.db.select(f.db.suppliers)..where((t) => t.id.equals(s.id))).getSingle();

    test('supplier name is required and unique', () async {
      await supplier();
      await expectLater(() => repo.saveSupplier(const SupplierInput(name: '  ')), throwsA(isA<BusinessException>()));
      await expectLater(() => repo.saveSupplier(const SupplierInput(name: 'ооо поставка')), throwsA(isA<BusinessException>()));
    });

    test('partial PO receiving updates stock, cost, balance and status', () async {
      final s = await supplier();
      final a = await f.product('Сок', cost: 0, stock: 0);
      final b = await f.product('Вода', cost: 0, stock: 0);
      final oid = await repo.saveDraftOrder(supplierId: s.id, lines: [
        PoLineInput(productId: a.id, qty: 10, unitCost: 500),
        PoLineInput(productId: b.id, qty: 5, unitCost: 200),
      ]);
      var o = await (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
      expect(o.number, 1);
      expect(o.total, 6000);
      expect(o.status, 'draft');
      await repo.markOrdered(oid);

      final items = await (f.db.select(f.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid))).get();
      final ia = items.firstWhere((i) => i.productId == a.id);
      final ib = items.firstWhere((i) => i.productId == b.id);

      final r1 = await repo.receiveOrder(oid, [ReceiveLineInput(itemId: ia.id, qty: 4)], userId: f.owner.id);
      expect(r1.value, 2000);
      expect(r1.fullyReceived, isFalse);
      expect((await f.reload(a)).stockQty, 4);
      expect((await f.reload(a)).costPrice, 500);
      expect((await reloadS(s)).balance, 2000);
      o = await (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
      expect(o.status, 'ordered');

      // Over-receiving is refused.
      await expectLater(() => repo.receiveOrder(oid, [ReceiveLineInput(itemId: ia.id, qty: 7)]),
          throwsA(isA<BusinessException>()));

      // Rest arrives, B with a higher invoice price.
      final r2 = await repo.receiveOrder(oid, [
        ReceiveLineInput(itemId: ia.id, qty: 6),
        ReceiveLineInput(itemId: ib.id, qty: 5, unitCost: 250),
      ]);
      expect(r2.fullyReceived, isTrue);
      expect(r2.value, 3000 + 1250);
      expect((await f.reload(a)).stockQty, 10);
      expect((await f.reload(b)).stockQty, 5);
      expect((await f.reload(b)).costPrice, 250);
      expect((await reloadS(s)).balance, 2000 + 4250);
      o = await (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
      expect(o.status, 'received');
      expect(o.receivedAt, isNotNull);

      final docs = await (f.db.select(f.db.goodsReceipts)..where((r) => r.orderId.equals(oid))).get();
      expect(docs.map((d) => d.number).toList()..sort(), [1, 2], reason: 'one receipt document per receiving');
      expect(docs.every((d) => d.supplierId == s.id && d.status == 'posted'), isTrue);
      final moves = await (f.db.select(f.db.stockMovements)..where((m) => m.refId.isIn(docs.map((d) => d.id)))).get();
      expect(moves.length, 3);
      expect(moves.every((m) => m.refType == 'receipt' && m.type == 'receipt'), isTrue);
      final docItems = await f.db.select(f.db.goodsReceiptItems).get();
      expect(docItems.length, 3);
      expect(docItems.every((i) => i.orderItemId != null), isTrue);
      expect(await repo.receivedValue(oid), 6250);

      // Closed order can't be received again.
      await expectLater(() => repo.receiveOrder(oid, [ReceiveLineInput(itemId: ia.id, qty: 1)]),
          throwsA(isA<BusinessException>()));
    });

    test('computed partial status and received value at invoice cost (providers)', () async {
      final s = await supplier();
      final a = await f.product('Сок', cost: 0, stock: 0);
      final b = await f.product('Вода', cost: 0, stock: 0);
      final oid = await repo.saveDraftOrder(supplierId: s.id, lines: [
        PoLineInput(productId: a.id, qty: 10, unitCost: 500),
        PoLineInput(productId: b.id, qty: 5, unitCost: 200),
      ]);
      await repo.markOrdered(oid);
      final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(f.db)]);
      addTearDown(c.dispose);
      final subIds = c.listen(purPartlyReceivedOrderIdsProvider, (_, _) {});
      final subVal = c.listen(purOrderReceivedValueProvider(oid), (_, _) {});
      addTearDown(subIds.close);
      addTearDown(subVal.close);
      Future<PurchaseOrder> order() => (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
      Future<List<PurchaseOrderItem>> items() =>
          (f.db.select(f.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid))).get();

      expect(await c.read(purPartlyReceivedOrderIdsProvider.future), isEmpty);
      expect(poDisplayStatusOf(await order(), await items()), 'ordered');

      final ia = (await items()).firstWhere((i) => i.productId == a.id);
      final ib = (await items()).firstWhere((i) => i.productId == b.id);
      // A arrives in full at a higher invoice price, B not yet.
      await repo.receiveOrder(oid, [ReceiveLineInput(itemId: ia.id, qty: 10, unitCost: 550)]);
      await pumpEventQueue();
      expect((await order()).status, 'ordered', reason: 'schema status unchanged');
      expect(poDisplayStatusOf(await order(), await items()), poPartialStatus);
      expect(c.read(purPartlyReceivedOrderIdsProvider).value, {oid});
      expect(c.read(purOrderReceivedValueProvider(oid)).value, 5500, reason: 'invoice cost, not 5000 ordered');
      expect((await order()).total, 6000, reason: 'ordered total stays');

      await repo.receiveOrder(oid, [ReceiveLineInput(itemId: ib.id, qty: 5)]);
      await pumpEventQueue();
      expect(poDisplayStatusOf(await order(), await items()), 'received');
      expect(c.read(purPartlyReceivedOrderIdsProvider).value, isEmpty);
      expect(c.read(purOrderReceivedValueProvider(oid)).value, 6500);
    });

    test('cancelling a partially received order closes it instead', () async {
      final s = await supplier();
      final a = await f.product('Сок', cost: 0, stock: 0);
      final oid = await repo.saveDraftOrder(supplierId: s.id, lines: [PoLineInput(productId: a.id, qty: 10, unitCost: 100)]);
      await repo.markOrdered(oid);
      final it = (await (f.db.select(f.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid))).get()).single;
      await repo.receiveOrder(oid, [ReceiveLineInput(itemId: it.id, qty: 3)]);
      await repo.cancelOrder(oid, reason: 'недопоставка');
      final o = await (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
      expect(o.status, 'received');
      expect((await f.reload(a)).stockQty, 3);
    });

    test('draft edit replaces lines; non-draft cannot be edited', () async {
      final s = await supplier();
      final a = await f.product('A');
      final b = await f.product('B');
      final oid = await repo.saveDraftOrder(supplierId: s.id, lines: [PoLineInput(productId: a.id, qty: 1, unitCost: 10)]);
      await repo.saveDraftOrder(id: oid, supplierId: s.id, lines: [PoLineInput(productId: b.id, qty: 2, unitCost: 10)]);
      final items = await (f.db.select(f.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid))).get();
      expect(items.single.productId, b.id);
      await repo.markOrdered(oid);
      await expectLater(
          () => repo.saveDraftOrder(id: oid, supplierId: s.id, lines: [PoLineInput(productId: a.id, qty: 1, unitCost: 1)]),
          throwsA(isA<BusinessException>()));
      await expectLater(() => repo.saveDraftOrder(supplierId: s.id, lines: []), throwsA(isA<BusinessException>()));
    });

    test('supplier payment validation and balance', () async {
      final s = await supplier(10000);
      await expectLater(() => repo.paySupplier(supplierId: s.id, amount: 0, method: 'transfer'), throwsA(isA<BusinessException>()));
      // Cash requires an open shift.
      await expectLater(() => repo.paySupplier(supplierId: s.id, amount: 100, method: 'cash'),
          throwsA(isA<BusinessException>().having((e) => e.code, 'code', 'shift')));
      // Overpay needs confirmation.
      await expectLater(() => repo.paySupplier(supplierId: s.id, amount: 12000, method: 'transfer'),
          throwsA(isA<BusinessException>().having((e) => e.code, 'code', 'overpay')));

      await repo.paySupplier(supplierId: s.id, amount: 4000, method: 'cash', shiftId: f.shift.id, userId: f.owner.id);
      expect((await reloadS(s)).balance, 6000);
      final pay = (await f.db.select(f.db.supplierPayments).get()).single;
      expect(pay.shiftId, f.shift.id);
      expect(pay.method, 'cash');
      final report = await ShiftService(f.db).report(f.shift.id);
      expect(report.supplierCashPaid, 4000);

      await repo.paySupplier(supplierId: s.id, amount: 8000, method: 'card', allowOverpay: true);
      expect((await reloadS(s)).balance, -2000);
      final card = (await f.db.select(f.db.supplierPayments).get()).firstWhere((p) => p.method == 'card');
      expect(card.shiftId, isNull);
      final audit = await f.db.select(f.db.auditLog).get();
      expect(audit.where((a) => a.action == 'supplier.payment').length, 2);
    });

    test('cash payment into a closed shift is refused', () async {
      final s = await supplier(1000);
      await ShiftService(f.db).close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 10000);
      await expectLater(() => repo.paySupplier(supplierId: s.id, amount: 100, method: 'cash', shiftId: f.shift.id),
          throwsA(isA<BusinessException>()));
    });

    test('supplier with debt cannot be deleted', () async {
      final s = await supplier(500);
      await expectLater(() => repo.deleteSupplier(s.id), throwsA(isA<BusinessException>()));
      await repo.paySupplier(supplierId: s.id, amount: 500, method: 'transfer');
      await repo.deleteSupplier(s.id);
      expect((await reloadS(s)).deletedAt, isNotNull);
    });

    test('reorder suggestions from real sales, grouped orders created', () async {
      final s = await supplier();
      final milk = await f.product('Молоко', price: 1000, cost: 600, stock: 40);
      await (f.db.update(f.db.products)..where((p) => p.id.equals(milk.id)))
          .write(ProductsCompanion(supplierId: Value(s.id)));
      final slow = await f.product('Соль', stock: 100);
      final sales = SaleService(f.db);
      await sales.checkout(CheckoutRequest(
        lines: [
          CheckoutLine(productId: milk.id, qty: 30, unitPrice: 1000),
          CheckoutLine(productId: slow.id, qty: 1, unitPrice: 1000),
        ],
        payments: [PaymentInput('cash', 31000)],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ));
      // milk: 30 sold / 30 days = 1/day, stock 10 -> 14 - 10 = 4
      final list = await repo.reorderSuggestions(targetDays: 14);
      expect(list.map((e) => e.product.id), [milk.id]);
      expect(list.single.suggestedQty, 4);

      final ids = await repo.createOrdersFromSuggestions({
        s.id: [PoLineInput(productId: milk.id, qty: 4, unitCost: 600)],
      });
      final o = (await f.db.select(f.db.purchaseOrders).get()).single;
      expect(ids, [o.id]);
      expect(o.status, 'draft');
      // The new draft already covers the need: re-running must not suggest
      // the same goods again (drafts count as "on order").
      expect(await repo.reorderSuggestions(targetDays: 14), isEmpty);
      await repo.markOrdered(o.id);
      expect(await repo.reorderSuggestions(targetDays: 14), isEmpty);
      // A cancelled order no longer covers anything.
      await repo.cancelOrder(o.id);
      expect((await repo.reorderSuggestions(targetDays: 14)).single.suggestedQty, 4);
    });

    test('payment linked to an order: must be the same supplier, adds to paid', () async {
      final s = await supplier(10000);
      final other = await repo.saveSupplier(const SupplierInput(name: 'Другой поставщик'));
      final p = await f.product('Сахар', cost: 500, stock: 0);
      final oid = await repo.saveDraftOrder(
          supplierId: other, lines: [PoLineInput(productId: p.id, qty: 2, unitCost: 500)]);
      await expectLater(() => repo.paySupplier(supplierId: s.id, amount: 100, method: 'transfer', orderId: oid),
          throwsA(isA<BusinessException>()));
      expect((await reloadS(s)).balance, 10000, reason: 'rejected payment changes nothing');
      expect(await f.db.select(f.db.supplierPayments).get(), isEmpty);

      final own = await repo.saveDraftOrder(
          supplierId: s.id, lines: [PoLineInput(productId: p.id, qty: 4, unitCost: 500)]);
      await repo.paySupplier(supplierId: s.id, amount: 1500, method: 'transfer', orderId: own);
      final o = await (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(own))).getSingle();
      expect(o.paid, 1500);
      expect((await reloadS(s)).balance, 8500);

      await repo.cancelOrder(own);
      await expectLater(() => repo.paySupplier(supplierId: s.id, amount: 100, method: 'transfer', orderId: own),
          throwsA(isA<BusinessException>()));
    });

    test('receiving rolls back entirely when one line is invalid', () async {
      final s = await supplier();
      final a = await f.product('Мука', cost: 100, stock: 0);
      final b = await f.product('Масло', cost: 100, stock: 0);
      final oid = await repo.saveDraftOrder(supplierId: s.id, lines: [
        PoLineInput(productId: a.id, qty: 5, unitCost: 100),
        PoLineInput(productId: b.id, qty: 2, unitCost: 100),
      ]);
      await repo.markOrdered(oid);
      final items = await (f.db.select(f.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid))).get();
      final ia = items.firstWhere((i) => i.productId == a.id);
      final ib = items.firstWhere((i) => i.productId == b.id);
      await expectLater(
          () => repo.receiveOrder(oid, [
                ReceiveLineInput(itemId: ia.id, qty: 5),
                ReceiveLineInput(itemId: ib.id, qty: 3), // more than ordered
              ]),
          throwsA(isA<BusinessException>()));
      expect((await f.reload(a)).stockQty, 0);
      expect((await reloadS(s)).balance, 0);
      final again = await (f.db.select(f.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid))).get();
      expect(again.every((i) => i.receivedQty == 0), isTrue);
      expect(await f.db.select(f.db.stockMovements).get(), isEmpty);
    });

    test('price history flags increases over 10%', () {
      StockMovement m(String pid, int cost, int day) => StockMovement(
            id: '$pid$day',
            createdAt: DateTime(2026, 1, day),
            updatedAt: DateTime(2026, 1, day),
            productId: pid,
            type: 'receipt',
            qty: 1,
            qtyAfter: 1,
            unitCost: cost,
          );
      final h = buildPriceHistory([m('a', 1100, 3), m('a', 1000, 1), m('a', 1120, 2), m('b', 500, 1)]);
      final a = h['a']!;
      expect(a.map((p) => p.unitCost), [1000, 1120, 1100]);
      expect(a.first.changePercent, isNull);
      expect(a[1].changePercent, closeTo(12, 0.001));
      expect(a[1].isSpike, isTrue);
      expect(a[2].isSpike, isFalse);
      expect(h['b']!.single.isSpike, isFalse);
    });
  });
}
