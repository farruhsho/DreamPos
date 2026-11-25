import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/sql_functions.dart';
import 'package:dreampos/core/printing/gift_receipt.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/marketing/gift_sales_logic.dart' show GiftSalesFilter, loadGiftSales;
import 'package:dreampos/features/reports/data/period.dart';
import 'package:dreampos/features/reports/data/report_queries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late Fixture f;
  late GiftCardService svc;
  late ShiftService shifts;

  setUp(() async {
    f = await Fixture.create();
    svc = GiftCardService(f.db);
    shifts = ShiftService(f.db);
  });
  tearDown(() => f.db.close());

  GiftCardSaleRequest req({
    String code = 'GIFT2345ABCD',
    int amount = 100000,
    List<GiftSalePaymentInput>? payments,
    String? shiftId = '',
    int? cashTendered,
    DateTime? expiresAt,
    String? customerId,
  }) =>
      GiftCardSaleRequest(
        code: code,
        amount: amount,
        payments: payments ?? [GiftSalePaymentInput('cash', amount)],
        cashierId: f.owner.id,
        shiftId: shiftId == '' ? f.shift.id : shiftId,
        cashTendered: cashTendered,
        expiresAt: expiresAt,
        customerId: customerId,
      );

  Matcher biz(String text) =>
      throwsA(isA<BusinessException>().having((e) => e.message, 'message', contains(text)));

  test('sell with split payments and change', () async {
    final res = await svc.sell(req(
      code: 'gift-2345-abcd',
      payments: const [
        GiftSalePaymentInput('cash', 30000),
        GiftSalePaymentInput('card', 50000, reference: 'RRN 777'),
        GiftSalePaymentInput('transfer', 20000),
      ],
      cashTendered: 50000,
    ));
    expect(res.number, 1);
    expect(res.changeDue, 20000);
    expect(res.giftCard.code, 'GIFT2345ABCD');
    expect(res.giftCard.balance, 100000);
    expect(res.giftCard.initialAmount, 100000);
    final sale = await (f.db.select(f.db.giftCardSales)..where((s) => s.id.equals(res.saleId))).getSingle();
    expect(sale.amount, 100000);
    expect(sale.changeDue, 20000);
    expect(sale.status, 'completed');
    expect(sale.shiftId, f.shift.id);
    expect(sale.cashierId, f.owner.id);
    final pays = await (f.db.select(f.db.giftCardSalePayments)..where((p) => p.saleId.equals(res.saleId))).get();
    expect({for (final p in pays) p.method: p.amount}, {'cash': 30000, 'card': 50000, 'transfer': 20000});
    expect(pays.firstWhere((p) => p.method == 'card').reference, 'RRN 777');
    // no shift cash movement, no sales rows
    expect(await f.db.select(f.db.cashMovements).get(), isEmpty);
    expect(await f.db.select(f.db.sales).get(), isEmpty);
    // audit + outbox
    expect((await f.db.select(f.db.auditLog).get()).map((a) => a.action), contains('gift_card.sell'));
    final dirty = (await f.db.select(f.db.syncOutbox).get()).map((o) => o.entity).toList();
    expect(dirty, containsAll(['gift_cards', 'gift_card_sales', 'gift_card_sale_payments']));
    expect(dirty.where((e) => e == 'gift_card_sale_payments'), hasLength(3));
    // numbering continues
    final second = await svc.sell(req(code: 'GIFT2345ABCE', amount: 1000));
    expect(second.number, 2);
    expect(second.changeDue, 0);
  });

  test('cash tendered below the cash part is refused', () async {
    expect(() => svc.sell(req(cashTendered: 50000)), biz('меньше'));
  });

  group('sell is refused', () {
    Future<void> nothingWritten() async {
      expect(await f.db.select(f.db.giftCards).get(), isEmpty);
      expect(await f.db.select(f.db.giftCardSales).get(), isEmpty);
      expect(await f.db.select(f.db.giftCardSalePayments).get(), isEmpty);
    }

    test('without a shift (none or closed)', () async {
      await expectLater(() => svc.sell(req(shiftId: null)), biz('Откройте смену, чтобы продать сертификат'));
      await shifts.close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 10000);
      await expectLater(() => svc.sell(req()), biz('Откройте смену, чтобы продать сертификат'));
      await nothingWritten();
    });

    test('with a wrong sum', () async {
      await expectLater(
          () => svc.sell(req(payments: const [GiftSalePaymentInput('cash', 50000)])), biz('не совпадает'));
      await expectLater(
          () => svc.sell(req(payments: const [
                GiftSalePaymentInput('cash', 60000),
                GiftSalePaymentInput('card', 50000),
              ])),
          biz('не совпадает'));
      await expectLater(() => svc.sell(req(payments: const [])), throwsA(isA<BusinessException>()));
      await expectLater(() => svc.sell(req(amount: 0, payments: const [])), throwsA(isA<BusinessException>()));
      await nothingWritten();
    });

    test('with a bad method', () async {
      for (final m in ['bonus', 'debt', 'gift_card', 'free']) {
        await expectLater(
            () => svc.sell(req(payments: [GiftSalePaymentInput(m, 100000)])), throwsA(isA<BusinessException>()));
      }
      await expectLater(
          () => svc.sell(req(payments: const [
                GiftSalePaymentInput('cash', 100001),
                GiftSalePaymentInput('card', -1),
              ])),
          throwsA(isA<BusinessException>()));
      await nothingWritten();
    });

    test('with a duplicate or invalid code, or a past expiry', () async {
      await svc.sell(req(code: 'DUPL123456'));
      await expectLater(() => svc.sell(req(code: 'dupl-1234-56')), biz('уже существует'));
      await expectLater(() => svc.sell(req(code: 'ABC12')), throwsA(isA<BusinessException>()));
      await expectLater(() => svc.sell(req(code: 'ПРИВЕТ12345')), throwsA(isA<BusinessException>()));
      await expectLater(
          () => svc.sell(req(code: 'PAST123456', expiresAt: DateTime.now().subtract(const Duration(days: 1)))),
          throwsA(isA<BusinessException>()));
      expect(await f.db.select(f.db.giftCards).get(), hasLength(1));
      expect(await f.db.select(f.db.giftCardSales).get(), hasLength(1));
    });
  });

  test('the card and the document are linked', () async {
    final c = await f.customer('Покупатель');
    final exp = DateTime.now().add(const Duration(days: 365));
    final res = await svc.sell(req(customerId: c.id, expiresAt: exp));
    final card = res.giftCard;
    expect(card.soldSaleId, res.saleId);
    expect(card.customerId, c.id);
    expect(card.expiresAt!.difference(exp).inSeconds.abs(), lessThan(2));
    final sale = await (f.db.select(f.db.giftCardSales)..where((s) => s.id.equals(res.saleId))).getSingle();
    expect(sale.giftCardId, card.id);
    expect(sale.customerId, c.id);
    final rows = await loadGiftSales(f.db, const GiftSalesFilter());
    expect(rows.single.code, card.code);
    expect(rows.single.customerName, 'Покупатель');
    expect(rows.single.cashierName, 'Owner');
    expect(rows.single.payments.single.amount, 100000);
    expect(await loadGiftSales(f.db, const GiftSalesFilter(status: 'voided')), isEmpty);
  });

  test('shift report shows gift sales; expectedCash includes cash; revenue unchanged', () async {
    final p = await f.product('Товар', price: 5000, cost: 3000);
    await SaleService(f.db).checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 5000)],
      payments: [PaymentInput('cash', 5000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    final before = await shifts.report(f.shift.id);
    final now = DateTime.now();
    final period = ReportPeriod(now.subtract(const Duration(hours: 1)), now.add(const Duration(hours: 1)));
    final summaryBefore = await salesSummaryQuery(f.db, period).getSingle();
    final paymentsBefore = await paymentsQuery(f.db, period).get();

    await svc.sell(req(payments: const [
      GiftSalePaymentInput('cash', 40000),
      GiftSalePaymentInput('card', 60000),
    ], cashTendered: 50000));
    await svc.sell(req(code: 'SECOND1234', amount: 7000, payments: const [GiftSalePaymentInput('transfer', 7000)]));

    final after = await shifts.report(f.shift.id);
    expect(after.giftSalesCount, 2);
    expect(after.giftSalesByMethod, {'cash': 40000, 'card': 60000, 'transfer': 7000});
    expect(after.giftRefundsByMethod, isEmpty);
    expect(after.giftSalesTotal, 107000);
    expect(after.giftCashNet, 40000);
    expect(after.expectedCash - before.expectedCash, 40000, reason: 'cash net of change');
    // revenue figures unchanged
    expect(after.salesTotal, before.salesTotal);
    expect(after.salesCount, before.salesCount);
    expect(after.netRevenue, before.netRevenue);
    expect(after.grossProfit, before.grossProfit);
    expect(after.byMethod, before.byMethod);
    final summaryAfter = await salesSummaryQuery(f.db, period).getSingle();
    expect(summaryAfter.gross, summaryBefore.gross);
    expect(summaryAfter.net, summaryBefore.net);
    expect(summaryAfter.receipts, summaryBefore.receipts);
    final paymentsAfter = await paymentsQuery(f.db, period).get();
    expect(paymentsAfter.map((r) => (r.method, r.paid)), paymentsBefore.map((r) => (r.method, r.paid)));
    // report helper for the payments report
    final g = await giftSalesByMethod(f.db, period.start, period.end);
    expect(g.sold, {'cash': 40000, 'card': 60000, 'transfer': 7000});
    expect(g.soldCount, 2);
    expect(g.netTotal, 107000);
    // close uses the same figure
    final closed = await shifts.close(shiftId: f.shift.id, userId: f.owner.id, countedCash: after.expectedCash);
    expect(closed.shift.expectedCash, after.expectedCash);
    expect(closed.difference, 0);
  });

  test('redeeming the card in a normal sale counts as revenue only once', () async {
    final res = await svc.sell(req(amount: 8000, payments: const [GiftSalePaymentInput('cash', 8000)]));
    final p = await f.product('Товар', price: 5000, cost: 3000);
    final r1 = await shifts.report(f.shift.id);
    final sale = await SaleService(f.db).checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 5000)],
      payments: [PaymentInput('gift_card', 5000, reference: res.giftCard.code)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    expect(sale.sale.total, 5000);
    final r2 = await shifts.report(f.shift.id);
    expect(r2.salesTotal - r1.salesTotal, 5000);
    expect(r2.byMethod['gift_card'], 5000);
    expect(r2.giftSalesTotal, 8000, reason: 'advance, separate from revenue');
    expect(r2.expectedCash, r1.expectedCash, reason: 'redemption brings no cash');
    final now = DateTime.now();
    final summary = await salesSummaryQuery(
            f.db, ReportPeriod(now.subtract(const Duration(hours: 1)), now.add(const Duration(hours: 1))))
        .getSingle();
    expect(summary.gross, 5000);
    // now the card is used: void is refused
    expect(await svc.voidBlockReason(res.saleId), contains('уже использован'));
    await expectLater(
        () => svc.voidSale(res.saleId, reason: 'ошибка', userId: f.owner.id, shiftId: f.shift.id),
        biz('Сертификат уже использован — аннулирование невозможно'));
  });

  group('void', () {
    test('restores and refunds by original methods in the void shift', () async {
      final res = await svc.sell(req(payments: const [
        GiftSalePaymentInput('cash', 30000),
        GiftSalePaymentInput('card', 70000),
      ], cashTendered: 40000));
      final shiftA = f.shift;
      final repA = await shifts.report(shiftA.id);
      await shifts.close(shiftId: shiftA.id, userId: f.owner.id, countedCash: repA.expectedCash);
      final shiftB = await shifts.open(userId: f.owner.id, openingCash: repA.expectedCash);
      final repB0 = await shifts.report(shiftB.id);

      expect(await svc.voidBlockReason(res.saleId), isNull);
      await svc.voidSale(res.saleId, reason: ' клиент передумал ', userId: f.owner.id, shiftId: shiftB.id);

      final sale = await (f.db.select(f.db.giftCardSales)..where((s) => s.id.equals(res.saleId))).getSingle();
      expect(sale.status, 'voided');
      expect(sale.voidedAt, isNotNull);
      expect(sale.voidedBy, f.owner.id);
      expect(sale.voidShiftId, shiftB.id);
      expect(sale.voidReason, 'клиент передумал');
      final card = await (f.db.select(f.db.giftCards)..where((g) => g.id.equals(res.giftCard.id))).getSingle();
      expect(card.status, 'blocked');
      expect(card.balance, 0);
      expect(card.deletedAt, isNull);
      expect(card.initialAmount, 100000);

      final repB = await shifts.report(shiftB.id);
      expect(repB.giftVoidsCount, 1);
      expect(repB.giftRefundsByMethod, {'cash': 30000, 'card': 70000});
      expect(repB.giftSalesByMethod, isEmpty);
      expect(repB.expectedCash, repB0.expectedCash - 30000);
      // the sale shift keeps its figures (money did come in there)
      final repA2 = await shifts.report(shiftA.id);
      expect(repA2.giftSalesByMethod, repA.giftSalesByMethod);
      expect(repA2.expectedCash, repA.expectedCash);
      // voided card cannot be redeemed or unblocked
      final p = await f.product('Товар', price: 1000);
      await expectLater(
          () => SaleService(f.db).checkout(CheckoutRequest(
                lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 1000)],
                payments: [PaymentInput('gift_card', 1000, reference: card.code)],
                cashierId: f.owner.id,
                shiftId: shiftB.id,
              )),
          throwsA(isA<BusinessException>()));
      // period helper: sold and refunded, net 0
      final now = DateTime.now();
      final g = await giftSalesByMethod(
          f.db, now.subtract(const Duration(hours: 1)), now.add(const Duration(hours: 1)));
      expect(g.refunded, {'cash': 30000, 'card': 70000});
      expect(g.netTotal, 0);
      expect(g.voidedCount, 1);
      expect((await f.db.select(f.db.auditLog).get()).map((a) => a.action), contains('gift_card.void_sale'));
      // slip shows the marker
      final slip = (await GiftReceiptData.load(f.db, res.saleId)).toText();
      expect(slip, contains('АННУЛИРОВАН'));
    });

    test('voided in the same shift: drawer back to where it was', () async {
      final before = await shifts.report(f.shift.id);
      final res = await svc.sell(req(amount: 5000, payments: const [GiftSalePaymentInput('cash', 5000)]));
      await svc.voidSale(res.saleId, reason: 'ошибка', userId: f.owner.id, shiftId: f.shift.id);
      final after = await shifts.report(f.shift.id);
      expect(after.giftSalesCount, 1);
      expect(after.giftVoidsCount, 1);
      expect(after.giftCashNet, 0);
      expect(after.expectedCash, before.expectedCash);
    });

    test('refused twice, without a reason, or without a shift', () async {
      final res = await svc.sell(req());
      await expectLater(
          () => svc.voidSale(res.saleId, reason: '  ', userId: f.owner.id, shiftId: f.shift.id), biz('причину'));
      await expectLater(
          () => svc.voidSale(res.saleId, reason: 'ошибка', userId: f.owner.id, shiftId: null), biz('смену'));
      await svc.voidSale(res.saleId, reason: 'ошибка', userId: f.owner.id, shiftId: f.shift.id);
      await expectLater(
          () => svc.voidSale(res.saleId, reason: 'ошибка', userId: f.owner.id, shiftId: f.shift.id),
          biz('уже аннулирована'));
      expect(await svc.voidBlockReason(res.saleId), isNotNull);

      final res2 = await svc.sell(req(code: 'OTHER12345'));
      await shifts.close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 0);
      await expectLater(
          () => svc.voidSale(res2.saleId, reason: 'ошибка', userId: f.owner.id, shiftId: f.shift.id),
          biz('смену'));
      final s2 = await (f.db.select(f.db.giftCardSales)..where((s) => s.id.equals(res2.saleId))).getSingle();
      expect(s2.status, 'completed');
    });

    test('refused for a partly spent card', () async {
      final res = await svc.sell(req());
      await (f.db.update(f.db.giftCards)..where((g) => g.id.equals(res.giftCard.id)))
          .write(const GiftCardsCompanion(balance: Value(99000)));
      await expectLater(
          () => svc.voidSale(res.saleId, reason: 'ошибка', userId: f.owner.id, shiftId: f.shift.id),
          biz('уже использован'));
    });
  });

  test('gift slip text: number, grouped code, nominal, expiry, payments, change, footer', () async {
    await f.db.setSetting('store_name', 'Магазин');
    final res = await svc.sell(req(payments: const [
      GiftSalePaymentInput('cash', 40000),
      GiftSalePaymentInput('card', 60000),
    ], cashTendered: 50000));
    final text = (await GiftReceiptData.load(f.db, res.saleId)).toText();
    expect(text, contains('Продажа сертификата №1'));
    expect(text, contains('GIFT 2345 ABCD'));
    expect(text, contains('без срока'));
    expect(text, contains('Сдача'));
    expect(text, contains('фискальным чеком'));
    expect(text, isNot(contains('АННУЛИРОВАН')));
    await f.db.setSetting('gift_receipt_note', '0');
    expect((await GiftReceiptData.load(f.db, res.saleId)).toText(), isNot(contains('фискальным')));
    expect(groupGiftCode('ABCDEFGHJ'), 'ABCD EFGH J');
  });

  test('migration v3 → v4 on a file database', () async {
    final dir = Directory.systemTemp.createTempSync('dreampos_mig_v4_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final file = File('${dir.path}${Platform.pathSeparator}v3.sqlite');
    final cardId = newId();
    // Build the v4 schema, then strip it down to v3.
    final v3 = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    await v3.into(v3.giftCards).insert(
        GiftCardsCompanion.insert(id: cardId, code: 'OLDCARD123', initialAmount: 5000, balance: 5000));
    for (final sql in [
      'DROP TABLE gift_card_sale_payments',
      'DROP TABLE gift_card_sales',
      'PRAGMA user_version = 3',
    ]) {
      await v3.customStatement(sql);
    }
    await v3.close();

    final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    addTearDown(db.close);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.first, 7);
    final idx = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE '%gift_sale%'")
        .get();
    expect(
        idx.map((r) => r.read<String>('name')),
        containsAll([
          'ix_gift_sales_shift',
          'ix_gift_sales_created',
          'ix_gift_sales_void_shift',
          'ix_gift_sales_card',
          'ux_gift_sales_number',
          'ix_gift_sale_payments_sale',
        ]));
    // no back-fill: the old card keeps soldSaleId = null
    final old = await (db.select(db.giftCards)..where((g) => g.id.equals(cardId))).getSingle();
    expect(old.soldSaleId, isNull);
    expect(await db.select(db.giftCardSales).get(), isEmpty);
    // the new tables work
    final owner = await (db.select(db.users)).get();
    expect(owner, isEmpty);
    final shiftId = newId();
    final userId = newId();
    await db.into(db.users).insert(UsersCompanion.insert(id: userId, name: 'U', role: 'owner', pinHash: 'x', pinSalt: 'y'));
    await db.into(db.shifts).insert(
        ShiftsCompanion.insert(id: shiftId, number: 1, openedBy: userId, openedAt: DateTime.now()));
    final res = await GiftCardService(db).sell(GiftCardSaleRequest(
      code: 'NEWCARD123',
      amount: 1000,
      payments: const [GiftSalePaymentInput('card', 1000)],
      cashierId: userId,
      shiftId: shiftId,
    ));
    expect(res.giftCard.soldSaleId, res.saleId);
    expect((await ShiftService(db).report(shiftId)).giftSalesByMethod, {'card': 1000});
  });

  test('a half-migrated v3 file (one table already created) still upgrades', () async {
    final dir = Directory.systemTemp.createTempSync('dreampos_mig_v4_half_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final file = File('${dir.path}${Platform.pathSeparator}v3.sqlite');
    final v3 = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    await v3.customStatement('DROP TABLE gift_card_sale_payments');
    await v3.customStatement('PRAGMA user_version = 3');
    await v3.close();
    final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    addTearDown(db.close);
    expect(await db.select(db.giftCardSalePayments).get(), isEmpty);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.first, 7);
  });
}
