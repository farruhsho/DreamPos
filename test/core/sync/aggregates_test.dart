// Cached aggregates are derived from their ledgers (D-025, spec §4).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/domain/services/customer_service.dart';
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/receipt_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/domain/services/supplier_service.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late Fixture f;
  late AppDatabase db;
  late StockService stock;
  late SaleService sales;
  late ReceiptService receipts;
  late SupplierLedgerService ledger;
  late GiftCardService gifts;
  late CustomerService customers;
  late PurchasingRepo purchasing;

  setUp(() async {
    f = await Fixture.create();
    db = f.db;
    stock = StockService(db);
    sales = SaleService(db);
    ledger = SupplierLedgerService(db);
    receipts = ReceiptService(db, stock, ledger);
    gifts = GiftCardService(db);
    customers = CustomerService(db);
    purchasing = PurchasingRepo(db, stock, receipts, ledger);
    await db.setSetting('loyalty_enabled', '1');
    await db.setSetting('loyalty_earn_percent', '5');
    await db.setSetting('loyalty_max_redeem_percent', '100');
  });
  tearDown(() => db.close());

  /// A product whose stock comes from the ledger (Fixture.product writes the
  /// cache directly, which is exactly what verifyAll reports).
  Future<Product> product(String name, {int price = 1000, double qty = 20}) async {
    final p = await f.product(name, price: price, cost: 600, stock: 0);
    await stock.receive(productId: p.id, qty: qty, unitCost: 600, userId: f.owner.id);
    return f.reload(p);
  }

  Future<Supplier> supplier(String name) async {
    final id = newId();
    await db.into(db.suppliers).insert(SuppliersCompanion.insert(id: id, name: name));
    return (db.select(db.suppliers)..where((s) => s.id.equals(id))).getSingle();
  }

  Future<CheckoutResult> sell(List<CheckoutLine> lines, List<PaymentInput> pays, {String? customerId}) =>
      sales.checkout(CheckoutRequest(
          lines: lines, payments: pays, cashierId: f.owner.id, shiftId: f.shift.id, customerId: customerId));

  /// Sales, returns, voids, receipts and their reversal, supplier payments
  /// and their cancellation, gift card sale/redeem/void, debt and bonus.
  Future<Map<String, Object>> realisticFlow() async {
    final a = await product('Чай');
    final b = await product('Кофе', price: 2500);
    final c = await f.customer('Покупатель', debtLimit: 1000000);
    final sup = await supplier('Поставщик');

    // sale with debt + bonus earn, partial then full return
    final s1 = await sell([CheckoutLine(productId: a.id, qty: 3, unitPrice: 1000)],
        [PaymentInput('cash', 1000), PaymentInput('debt', 2000)], customerId: c.id);
    final items1 = await (db.select(db.saleItems)..where((i) => i.saleId.equals(s1.sale.id))).get();
    await sales.returnItems(
        saleId: s1.sale.id, lines: [ReturnLineInput(items1.single.id, 1)], refundMethod: 'debt', userId: f.owner.id);
    await sales.returnItems(
        saleId: s1.sale.id,
        lines: [ReturnLineInput(items1.single.id, 2)],
        refundMethod: 'cash',
        userId: f.owner.id,
        shiftId: f.shift.id);

    // sale paid partly with bonus, then voided (bonus refund + claw-back)
    await customers.adjustBonus(customerId: c.id, delta: 500, userId: f.owner.id, reason: 'подарок');
    final s2 = await sell([CheckoutLine(productId: b.id, qty: 2, unitPrice: 2500)],
        [PaymentInput('bonus', 500), PaymentInput('cash', 4500)], customerId: c.id);
    await sales.voidSale(s2.sale.id, userId: f.owner.id, reason: 'ошибка', shiftId: f.shift.id);

    // debt payment
    await customers.payDebt(customerId: c.id, amount: 500, method: 'cash', userId: f.owner.id, shiftId: f.shift.id);

    // receipt + reversal, supplier payment + cancel
    final r1 = await receipts.post(
        lines: [ReceiptLineInput(productId: a.id, qty: 10, unitCost: 500)], supplierId: sup.id, userId: f.owner.id);
    await receipts.post(
        lines: [ReceiptLineInput(productId: b.id, qty: 4, unitCost: 1500)], supplierId: sup.id, userId: f.owner.id);
    await receipts.reverse(r1.id, reason: 'ошибка', userId: f.owner.id);
    final pay = await ledger.pay(supplierId: sup.id, amount: 1000, method: 'transfer', userId: f.owner.id);
    await ledger.cancelPayment(pay, reason: 'не прошла', userId: f.owner.id);

    // purchase order: partial receiving, payment against the order, reversal
    final po = await purchasing.saveDraftOrder(
        supplierId: sup.id, lines: [PoLineInput(productId: a.id, qty: 10, unitCost: 550)], userId: f.owner.id);
    await purchasing.markOrdered(po, userId: f.owner.id);
    final poItem = (await (db.select(db.purchaseOrderItems)..where((i) => i.orderId.equals(po))).get()).single;
    final rec = await purchasing.receiveOrderDoc(po, [ReceiveLineInput(itemId: poItem.id, qty: 4)], userId: f.owner.id);
    await purchasing.receiveOrderDoc(po, [ReceiveLineInput(itemId: poItem.id, qty: 3)], userId: f.owner.id);
    await receipts.reverse(rec.receipt.id, reason: 'брак', userId: f.owner.id);
    await ledger.pay(supplierId: sup.id, amount: 700, method: 'card', orderId: po, userId: f.owner.id);
    final pay2 = await ledger.pay(supplierId: sup.id, amount: 300, method: 'card', orderId: po, userId: f.owner.id);
    await ledger.cancelPayment(pay2, reason: 'дубль', userId: f.owner.id);

    // gift cards: one sold and redeemed (partly, then fully), one sold and voided
    final g1 = await gifts.sell(GiftCardSaleRequest(
        code: 'GIFTAAAA1111',
        amount: 5000,
        payments: const [GiftSalePaymentInput('cash', 5000)],
        cashierId: f.owner.id,
        shiftId: f.shift.id));
    await sell([CheckoutLine(productId: b.id, qty: 1, unitPrice: 2500)],
        [PaymentInput('gift_card', 2500, reference: g1.giftCard.code)]);
    final s4 = await sell([CheckoutLine(productId: b.id, qty: 1, unitPrice: 2500)],
        [PaymentInput('gift_card', 2500, reference: g1.giftCard.code)]);
    await sales.voidSale(s4.sale.id, userId: f.owner.id, reason: 'отмена', shiftId: f.shift.id);
    final g2 = await gifts.sell(GiftCardSaleRequest(
        code: 'GIFTBBBB2222',
        amount: 3000,
        payments: const [GiftSalePaymentInput('card', 3000)],
        cashierId: f.owner.id,
        shiftId: f.shift.id));
    await gifts.voidSale(g2.saleId, reason: 'передумал', userId: f.owner.id, shiftId: f.shift.id);

    // stock write-off and manual correction
    await stock.writeOff(productId: a.id, qty: 1.5, reason: 'бой', userId: f.owner.id);
    await stock.setStock(productId: b.id, newQty: 7, reason: 'пересчёт', userId: f.owner.id);
    return {'a': a.id, 'b': b.id, 'c': c.id, 'sup': sup.id, 'po': po, 'poItem': poItem.id, 'g1': g1.giftCard.id};
  }

  test('verifyAll is empty after a realistic flow through the real services', () async {
    final ids = await realisticFlow();
    expect(await SyncAggregates.verifyAll(db), isEmpty);
    // sanity: the flow really moved the caches
    final c = await (db.select(db.customers)..where((t) => t.id.equals(ids['c'] as String))).getSingle();
    expect(c.debtBalance, 2000 - 1000 - 500);
    final order = await (db.select(db.purchaseOrders)..where((t) => t.id.equals(ids['po'] as String))).getSingle();
    expect(order.paid, 700);
    final item = await (db.select(db.purchaseOrderItems)..where((t) => t.id.equals(ids['poItem'] as String))).getSingle();
    expect(item.receivedQty, 3);
    final g1 = await (db.select(db.giftCards)..where((t) => t.id.equals(ids['g1'] as String))).getSingle();
    expect(g1.balance, 2500);
  });

  test('voidSale writes the bonus change to the ledger', () async {
    final p = await product('Сок');
    final c = await f.customer('Бонусный');
    await customers.adjustBonus(customerId: c.id, delta: 300, userId: f.owner.id, reason: 'старт');
    final s = await sell([CheckoutLine(productId: p.id, qty: 2, unitPrice: 1000)],
        [PaymentInput('bonus', 300), PaymentInput('cash', 1700)], customerId: c.id);
    final mid = await f.reloadC(c);
    expect(mid.bonusBalance, 300 - 300 + s.sale.bonusEarned);
    await sales.voidSale(s.sale.id, userId: f.owner.id, reason: 'ошибка', shiftId: f.shift.id);
    final rows = await (db.select(db.customerLedger)
          ..where((l) => l.customerId.equals(c.id) & l.refType.equals('void')))
        .get();
    final bonusRow = rows.singleWhere((r) => r.kind == 'bonus_adjust');
    expect(bonusRow.amount, 300 - s.sale.bonusEarned);
    expect((await f.reloadC(c)).bonusBalance, 300);
    expect(await SyncAggregates.verifyAll(db), isEmpty);
  });

  test('recompute restores corrupted caches from touched children, without outbox echo', () async {
    final ids = await realisticFlow();
    final a = ids['a'] as String, c = ids['c'] as String, sup = ids['sup'] as String;
    final expected = {
      for (final t in ['products', 'customers', 'suppliers', 'gift_cards', 'purchase_orders'])
        t: await db.customSelect('SELECT * FROM $t ORDER BY id').get().then((r) => [for (final x in r) x.data]),
    };
    await db.customStatement('UPDATE products SET stock_qty = 999');
    await db.customStatement('UPDATE customers SET debt_balance = 1, bonus_balance = 2');
    await db.customStatement('UPDATE suppliers SET balance = 3');
    await db.customStatement('UPDATE gift_cards SET balance = 4');
    await db.customStatement('UPDATE purchase_orders SET paid = 5');
    await db.customStatement('UPDATE purchase_order_items SET received_qty = 6');
    await db.customStatement('UPDATE sales SET refunded_total = 7');
    await db.customStatement('UPDATE sale_items SET returned_qty = 0');
    final mismatches = await SyncAggregates.verifyAll(db);
    expect(mismatches, isNotEmpty);
    final outboxBefore = (await db.select(db.syncOutbox).get()).length;

    // Children only: a movement, a ledger row, a payment, a receipt item…
    Future<List<String>> idsOf(String sql) async =>
        [for (final r in await db.customSelect(sql).get()) r.data.values.first as String];
    final touched = <String, Iterable<String>>{
      'stock_movements': await idsOf('SELECT id FROM stock_movements'),
      'customer_ledger': await idsOf("SELECT id FROM customer_ledger WHERE customer_id = '$c'"),
      'supplier_ledger': await idsOf("SELECT id FROM supplier_ledger WHERE supplier_id = '$sup'"),
      'sale_payments': await idsOf("SELECT id FROM sale_payments WHERE method = 'gift_card'"),
      'gift_card_sales': await idsOf('SELECT id FROM gift_card_sales'),
      'supplier_payments': await idsOf('SELECT id FROM supplier_payments'),
      'goods_receipts': await idsOf('SELECT id FROM goods_receipts'),
      'return_items': await idsOf('SELECT id FROM return_items'),
      'sales': await idsOf('SELECT id FROM sales'),
    };
    final changed = await SyncAggregates.recompute(db, touched);
    expect(changed.toSet(), mismatches.toSet());
    expect(await SyncAggregates.verifyAll(db), isEmpty);
    for (final e in expected.entries) {
      final now = await db.customSelect('SELECT * FROM ${e.key} ORDER BY id').get();
      expect([for (final x in now) x.data], e.value, reason: e.key);
    }
    expect((await db.select(db.syncOutbox).get()).length, outboxBefore, reason: 'caches are not pushed');
    expect((await db.select(db.syncFlags).getSingle()).applying, 0);
    expect(await SyncAggregates.recompute(db, {'products': [a]}), isEmpty);
    expect(await SyncAggregates.recompute(db, const {}), isEmpty);
  });

  test('normalize appends difference rows for ledger caches and logs the rest', () async {
    final p = await f.product('Без журнала', stock: 12.5); // cache only
    final c = await f.customer('Старый долг', bonus: 70);
    await db.customStatement('UPDATE customers SET debt_balance = 400 WHERE id = ?', [c.id]);
    final s = await supplier('Старый');
    await ledger.post(supplierId: s.id, kind: 'receipt', amount: 1000);
    await db.customStatement('UPDATE suppliers SET balance = 1500 WHERE id = ?', [s.id]);
    await db.into(db.giftCards).insert(GiftCardsCompanion.insert(
        id: newId(), code: 'LEGACY000001', initialAmount: 1000, balance: 600));

    final found = await SyncAggregates.normalize(db);
    expect(found.where((m) => m.ledgerBacked), hasLength(4));
    expect(await SyncAggregates.verifyAll(db), [
      isA<AggregateMismatch>().having((m) => m.table, 'table', 'gift_cards'),
    ]);
    final mv = await (db.select(db.stockMovements)..where((m) => m.productId.equals(p.id))).getSingle();
    expect(mv.qty, 12.5);
    expect(mv.qtyAfter, 12.5);
    expect(mv.type, 'adjustment');
    expect(mv.reason, syncOpeningNote);
    final cl = await (db.select(db.customerLedger)..where((l) => l.customerId.equals(c.id))).get();
    expect({for (final l in cl) l.kind: l.amount}, {'debt_adjust': 400, 'bonus_adjust': 70});
    final sl = await (db.select(db.supplierLedger)
          ..where((l) => l.supplierId.equals(s.id))
          ..orderBy([(l) => OrderingTerm.asc(l.rowId)]))
        .get();
    expect(sl.last.kind, 'adjustment');
    expect(sl.last.amount, 500);
    expect(sl.last.balanceAfter, 1500);
    expect(sl.last.note, 'Начальный остаток (синхронизация)');
    final conflicts = await db.select(db.syncConflicts).get();
    expect(conflicts.single.kind, 'normalize');
    expect(conflicts.single.entity, 'gift_cards');

    // idempotent
    expect((await SyncAggregates.normalize(db)).single.table, 'gift_cards');
    expect(await db.select(db.syncConflicts).get(), hasLength(1));
    expect(await db.select(db.stockMovements).get(), hasLength(1));
  });
}
