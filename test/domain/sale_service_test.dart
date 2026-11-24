import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/customer_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late Fixture f;
  late SaleService sales;

  setUp(() async {
    f = await Fixture.create();
    sales = SaleService(f.db);
  });
  tearDown(() => f.db.close());

  CheckoutRequest req(List<CheckoutLine> lines, List<PaymentInput> pays,
          {String? customerId, String? promo, int orderDisc = 0}) =>
      CheckoutRequest(
        lines: lines,
        payments: pays,
        cashierId: f.owner.id,
        shiftId: f.shift.id,
        customerId: customerId,
        promoCode: promo,
        manualOrderDiscountAmount: orderDisc,
      );

  test('cash sale decreases stock, computes change and writes ledger', () async {
    final p = await f.product('Milk', price: 1500, cost: 1000, stock: 5);
    final res = await sales.checkout(req(
        [CheckoutLine(productId: p.id, qty: 2, unitPrice: 1500)],
        [PaymentInput('cash', 5000)]));
    expect(res.sale.total, 3000);
    expect(res.changeDue, 2000);
    expect(res.sale.costTotal, 2000);
    expect((await f.reload(p)).stockQty, 3);
    final mv = await f.db.select(f.db.stockMovements).get();
    expect(mv.single.qty, -2);
    final pays = await f.db.select(f.db.salePayments).get();
    expect(pays.single.amount, 3000); // applied, not tendered
  });

  test('cannot oversell when negative stock disabled', () async {
    final p = await f.product('Bread', stock: 1);
    expect(
        () => sales.checkout(req([CheckoutLine(productId: p.id, qty: 2, unitPrice: 1000)],
            [PaymentInput('cash', 2000)])),
        throwsA(isA<BusinessException>()));
    expect((await f.reload(p)).stockQty, 1, reason: 'transaction rolled back');
    expect(await f.db.select(f.db.sales).get(), isEmpty);
  });

  test('insufficient payment rejected; card cannot exceed total', () async {
    final p = await f.product('A');
    expect(
        () => sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 1000)],
            [PaymentInput('cash', 999)])),
        throwsA(isA<BusinessException>()));
    expect(
        () => sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 1000)],
            [PaymentInput('card', 1500)])),
        throwsA(isA<BusinessException>()));
  });

  test('sale requires open shift', () async {
    final p = await f.product('A');
    await ShiftService(f.db).close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 10000);
    expect(
        () => sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 1000)],
            [PaymentInput('cash', 1000)])),
        throwsA(isA<BusinessException>()));
  });

  test('debt sale respects credit limit and debt payment reduces it', () async {
    final p = await f.product('TV', price: 50000, stock: 3);
    final c = await f.customer('Ali', debtLimit: 60000);
    await sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 50000)],
        [PaymentInput('debt', 50000)], customerId: c.id));
    expect((await f.reloadC(c)).debtBalance, 50000);
    expect(
        () => sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 50000)],
            [PaymentInput('debt', 50000)], customerId: c.id)),
        throwsA(isA<BusinessException>()));
    await CustomerService(f.db).payDebt(
        customerId: c.id, amount: 20000, method: 'cash', userId: f.owner.id, shiftId: f.shift.id);
    expect((await f.reloadC(c)).debtBalance, 30000);
    final rep = await ShiftService(f.db).report(f.shift.id);
    expect(rep.debtCollectedCash, 20000);
    expect(rep.expectedCash, 10000 + 20000);
  });

  test('customer discount and order discount allocate exactly', () async {
    final a = await f.product('A', price: 333);
    final b = await f.product('B', price: 667);
    final c = await f.customer('Vip', discount: 10);
    final res = await sales.checkout(req([
      CheckoutLine(productId: a.id, qty: 1, unitPrice: 333),
      CheckoutLine(productId: b.id, qty: 1, unitPrice: 667),
    ], [PaymentInput('cash', 10000)], customerId: c.id, orderDisc: 101));
    final items = await f.db.select(f.db.saleItems).get();
    expect(items.fold<int>(0, (s, i) => s + i.total), res.sale.total);
    expect(res.sale.subtotal - res.sale.discountTotal, res.sale.total);
    expect(res.sale.total, 1000 - 33 - 67 - 101);
  });

  test('partial return twice refunds exactly line total and restocks', () async {
    final p = await f.product('Soap', price: 1000, stock: 10);
    final res = await sales.checkout(req([CheckoutLine(productId: p.id, qty: 3, unitPrice: 1000)],
        [PaymentInput('cash', 3000)], orderDisc: 100)); // total 2900
    final item = (await f.db.select(f.db.saleItems).get()).single;
    expect(item.total, 2900);
    final r1 = await sales.returnItems(
        saleId: res.sale.id, lines: [ReturnLineInput(item.id, 1)], refundMethod: 'cash',
        userId: f.owner.id, shiftId: f.shift.id);
    final r2 = await sales.returnItems(
        saleId: res.sale.id, lines: [ReturnLineInput(item.id, 2)], refundMethod: 'cash',
        userId: f.owner.id, shiftId: f.shift.id);
    expect(r1.total + r2.total, 2900);
    expect((await f.reload(p)).stockQty, 10);
    final sale = await (f.db.select(f.db.sales)..where((s) => s.id.equals(res.sale.id))).getSingle();
    expect(sale.status, 'returned');
    expect(
        () => sales.returnItems(saleId: res.sale.id, lines: [ReturnLineInput(item.id, 1)],
            refundMethod: 'cash', userId: f.owner.id, shiftId: f.shift.id),
        throwsA(isA<BusinessException>()));
    final rep = await ShiftService(f.db).report(f.shift.id);
    expect(rep.expectedCash, 10000); // sold 2900, refunded 2900
  });

  test('loyalty: earn, spend, clawback on return', () async {
    await f.db.setSetting('loyalty_enabled', '1');
    await f.db.setSetting('loyalty_earn_percent', '5');
    await f.db.setSetting('loyalty_max_redeem_percent', '50');
    final p = await f.product('Shoes', price: 10000, stock: 5);
    final c = await f.customer('Bek', bonus: 1000);
    final res = await sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 10000)],
        [PaymentInput('bonus', 1000), PaymentInput('cash', 9000)], customerId: c.id));
    expect(res.sale.bonusEarned, 450); // 5% of 9000
    expect((await f.reloadC(c)).bonusBalance, 450);
    // exceeding max redeem
    expect(
        () => sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 10000)],
            [PaymentInput('bonus', 6000), PaymentInput('cash', 4000)], customerId: c.id)),
        throwsA(isA<BusinessException>()));
    final item = (await f.db.select(f.db.saleItems).get()).single;
    await sales.returnItems(saleId: res.sale.id, lines: [ReturnLineInput(item.id, 1)],
        refundMethod: 'cash', userId: f.owner.id, shiftId: f.shift.id);
    expect((await f.reloadC(c)).bonusBalance, 0);
  });

  test('void restores stock, debt and excludes sale from shift report', () async {
    final p = await f.product('Pen', price: 500, stock: 4);
    final c = await f.customer('Z', debtLimit: 0);
    final res = await sales.checkout(req([CheckoutLine(productId: p.id, qty: 2, unitPrice: 500)],
        [PaymentInput('debt', 1000)], customerId: c.id));
    await sales.voidSale(res.sale.id, userId: f.owner.id, reason: 'mistake', shiftId: f.shift.id);
    expect((await f.reload(p)).stockQty, 4);
    expect((await f.reloadC(c)).debtBalance, 0);
    final rep = await ShiftService(f.db).report(f.shift.id);
    expect(rep.salesCount, 0);
    expect(rep.voidedCount, 1);
  });

  test('gift card payment decrements balance; insufficient rejected', () async {
    final p = await f.product('Bag', price: 3000, stock: 5);
    await f.db.into(f.db.giftCards).insert(GiftCardsCompanion.insert(
        id: newId(), code: 'GC1', initialAmount: 5000, balance: 5000));
    await sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 3000)],
        [PaymentInput('gift_card', 3000, reference: 'GC1')]));
    final g = await f.db.select(f.db.giftCards).getSingle();
    expect(g.balance, 2000);
    expect(
        () => sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 3000)],
            [PaymentInput('gift_card', 3000, reference: 'GC1')])),
        throwsA(isA<BusinessException>()));
  });

  test('shift close computes expected cash and difference', () async {
    final p = await f.product('X', price: 2000, stock: 5);
    await sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 2000)],
        [PaymentInput('cash', 2000)]));
    await sales.checkout(req([CheckoutLine(productId: p.id, qty: 1, unitPrice: 2000)],
        [PaymentInput('card', 2000)]));
    final svc = ShiftService(f.db);
    await svc.cashMovement(shiftId: f.shift.id, kind: 'expense', amount: 500, userId: f.owner.id, reason: 'water');
    final rep = await svc.close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 11400);
    expect(rep.expectedCash, 10000 + 2000 - 500);
    expect(rep.difference, -100);
    expect(rep.byMethod['card'], 2000);
  });

  test('inventory count adjusts stock to counted qty', () async {
    final p = await f.product('Nuts', stock: 10);
    final countId = newId();
    await f.db.into(f.db.inventoryCounts).insert(InventoryCountsCompanion.insert(id: countId, number: 1));
    await f.db.into(f.db.inventoryCountItems).insert(InventoryCountItemsCompanion.insert(
        id: newId(), countId: countId, productId: p.id, expectedQty: 10, countedQty: const Value(7)));
    await StockService(f.db).completeCount(countId, userId: f.owner.id);
    expect((await f.reload(p)).stockQty, 7);
  });

  test('receipt recalculates weighted average cost', () async {
    final p = await f.product('Rice', cost: 100, stock: 10);
    await StockService(f.db).receive(productId: p.id, qty: 10, unitCost: 200);
    final r = await f.reload(p);
    expect(r.stockQty, 20);
    expect(r.costPrice, 150);
  });
}
