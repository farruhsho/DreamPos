import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/sales/sales_logic.dart';
import 'package:dreampos/features/sales/sales_queries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Fixture f;
  late SaleService sales;

  setUp(() async {
    f = await Fixture.create();
    sales = SaleService(f.db);
  });
  tearDown(() => f.db.close());

  Future<Sale> sell(
    List<CheckoutLine> lines,
    List<PaymentInput> pays, {
    String? customerId,
    int orderDisc = 0,
    String? shiftId,
  }) async {
    final r = await sales.checkout(
      CheckoutRequest(
        lines: lines,
        payments: pays,
        cashierId: f.owner.id,
        shiftId: shiftId ?? f.shift.id,
        customerId: customerId,
        manualOrderDiscountAmount: orderDisc,
      ),
    );
    return r.sale;
  }

  Future<List<SaleItem>> items(String saleId) =>
      (f.db.select(f.db.saleItems)..where((i) => i.saleId.equals(saleId))).get();

  group('return preview equals SaleService.returnItems', () {
    test('partial returns with distributed order discount, last unit takes remainder', () async {
      final a = await f.product('A', price: 333, stock: 10);
      final b = await f.product('B', price: 1001, stock: 10);
      final sale = await sell(
        [CheckoutLine(productId: a.id, qty: 3, unitPrice: 333), CheckoutLine(productId: b.id, qty: 7, unitPrice: 1001)],
        [PaymentInput('cash', 100000)],
        orderDisc: 777,
      );

      // three successive partial returns of item B: 2, 4, 1 (last)
      for (final q in [2.0, 4.0, 1.0]) {
        final its = await items(sale.id);
        final itB = its.firstWhere((i) => i.productId == b.id);
        final preview = previewRefund(its, {itB.id: q});
        final ret = await sales.returnItems(
          saleId: sale.id,
          lines: [ReturnLineInput(itB.id, q)],
          refundMethod: 'cash',
          userId: f.owner.id,
          shiftId: f.shift.id,
        );
        expect(ret.total, preview, reason: 'qty $q');
      }
      final itB = (await items(sale.id)).firstWhere((i) => i.productId == b.id);
      final refunded = (await f.db.select(f.db.returns).get()).fold<int>(0, (s, r) => s + r.total);
      expect(refunded, itB.total, reason: 'all returns add up to the paid line total');
    });

    test('multi-line return and fractional (kg) quantities', () async {
      final kg = await f.product('Сыр', price: 85000, stock: 5);
      await (f.db.update(
        f.db.products,
      )..where((p) => p.id.equals(kg.id))).write(const ProductsCompanion(unit: Value('kg')));
      final pcs = await f.product('Хлеб', price: 4500, stock: 10);
      final sale = await sell(
        [
          CheckoutLine(productId: kg.id, qty: 1.237, unitPrice: 85000),
          CheckoutLine(productId: pcs.id, qty: 3, unitPrice: 4500),
        ],
        [PaymentInput('card', 0), PaymentInput('cash', 200000)],
        orderDisc: 1000,
      );
      final its = await items(sale.id);
      final itKg = its.firstWhere((i) => i.productId == kg.id);
      final itPcs = its.firstWhere((i) => i.productId == pcs.id);
      final sel = {itKg.id: 0.5, itPcs.id: 1.0};
      final preview = previewRefund(its, sel);
      final ret = await sales.returnItems(
        saleId: sale.id,
        lines: [for (final e in sel.entries) ReturnLineInput(e.key, e.value)],
        refundMethod: 'cash',
        userId: f.owner.id,
        shiftId: f.shift.id,
      );
      expect(ret.total, preview);
      // rest of the kg line, last portion
      final its2 = await items(sale.id);
      final itKg2 = its2.firstWhere((i) => i.productId == kg.id);
      expect(availableToReturn(itKg2), closeTo(0.737, 1e-9));
      final p2 = previewLineRefund(itKg2, availableToReturn(itKg2));
      final ret2 = await sales.returnItems(
        saleId: sale.id,
        lines: [ReturnLineInput(itKg2.id, availableToReturn(itKg2))],
        refundMethod: 'cash',
        userId: f.owner.id,
        shiftId: f.shift.id,
      );
      expect(ret2.total, p2);
      expect(ret.total + ret2.total - previewLineRefund(itPcs, 1), itKg.total);
    });

    test('zero / empty selection previews 0', () async {
      final a = await f.product('A');
      final sale = await sell([CheckoutLine(productId: a.id, qty: 2, unitPrice: 1000)], [PaymentInput('cash', 2000)]);
      final its = await items(sale.id);
      expect(previewRefund(its, {}), 0);
      expect(previewLineRefund(its.first, 0), 0);
    });
  });

  group('void rules mirror SaleService.voidSale', () {
    test('completed sale in the current shift can be voided', () async {
      final a = await f.product('A');
      final sale = await sell([CheckoutLine(productId: a.id, qty: 1, unitPrice: 1000)], [PaymentInput('cash', 1000)]);
      expect(voidBlockReason(sale, f.shift), isNull);
      await sales.voidSale(sale.id, userId: f.owner.id, reason: 'Ошибка', shiftId: f.shift.id);
      final after = await (f.db.select(f.db.sales)..where((s) => s.id.equals(sale.id))).getSingle();
      expect(after.status, 'voided');
      expect(voidBlockReason(after, f.shift), isNotNull);
      expect((await f.reload(a)).stockQty, 10);
    });

    test('sale with returns cannot be voided', () async {
      final a = await f.product('A');
      final sale = await sell([CheckoutLine(productId: a.id, qty: 2, unitPrice: 1000)], [PaymentInput('cash', 2000)]);
      final it = (await items(sale.id)).single;
      await sales.returnItems(
        saleId: sale.id,
        lines: [ReturnLineInput(it.id, 1)],
        refundMethod: 'cash',
        userId: f.owner.id,
        shiftId: f.shift.id,
      );
      final after = await (f.db.select(f.db.sales)..where((s) => s.id.equals(sale.id))).getSingle();
      expect(after.status, 'partially_returned');
      expect(voidBlockReason(after, f.shift), contains('без возвратов'));
      expect(
        () => sales.voidSale(sale.id, userId: f.owner.id, reason: 'x', shiftId: f.shift.id),
        throwsA(isA<BusinessException>()),
      );
    });

    test('sale from a previous shift cannot be voided', () async {
      final a = await f.product('A');
      final sale = await sell([CheckoutLine(productId: a.id, qty: 1, unitPrice: 1000)], [PaymentInput('cash', 1000)]);
      final shifts = ShiftService(f.db);
      await shifts.close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 11000);
      expect(voidBlockReason(sale, null), isNotNull, reason: 'no open shift');
      final next = await shifts.open(userId: f.owner.id, openingCash: 0);
      expect(voidBlockReason(sale, next), contains('другой смены'));
      expect(
        () => sales.voidSale(sale.id, userId: f.owner.id, reason: 'x', shiftId: next.id),
        throwsA(isA<BusinessException>()),
      );
    });
  });

  group('helpers', () {
    test('return period expiry mirrors return_days', () async {
      final a = await f.product('A');
      final sale = await sell([CheckoutLine(productId: a.id, qty: 1, unitPrice: 1000)], [PaymentInput('cash', 1000)]);
      final later = sale.createdAt.add(const Duration(days: 15));
      expect(returnPeriodExpired(sale, null, sale.createdAt), isNull);
      expect(returnPeriodExpired(sale, null, later), contains('14'));
      expect(returnPeriodExpired(sale, '30', later), isNull);
      expect(returnPeriodExpired(sale, '0', later), isNull, reason: '0 = unlimited');
      final it = (await items(sale.id)).single;
      expect(
        () => sales.returnItems(
          saleId: sale.id,
          lines: [ReturnLineInput(it.id, 1)],
          refundMethod: 'cash',
          userId: f.owner.id,
          shiftId: f.shift.id,
          now: later,
        ),
        throwsA(isA<BusinessException>()),
      );
    });

    test('refund method options and default', () async {
      expect(refundMethodOptions(hasCustomer: false), isNot(contains('debt')));
      expect(refundMethodOptions(hasCustomer: true), containsAll(['debt', 'bonus']));
      SalePayment pay(String m, int a) =>
          SalePayment(id: m, saleId: 's', method: m, amount: a, createdAt: DateTime(2026), updatedAt: DateTime(2026));
      expect(defaultRefundMethod([pay('cash', 100), pay('card', 900)], hasCustomer: false), 'card');
      expect(defaultRefundMethod([pay('debt', 900), pay('cash', 100)], hasCustomer: false), 'cash');
      expect(defaultRefundMethod([pay('debt', 900), pay('cash', 100)], hasCustomer: true), 'debt');
      expect(defaultRefundMethod([pay('gift_card', 900)], hasCustomer: true), 'cash');
    });

    test('period spans', () {
      final now = DateTime(2026, 11, 24, 15);
      expect(periodSpan(Period.today, now).from, DateTime(2026, 11, 24));
      expect(periodSpan(Period.today, now).to, DateTime(2026, 11, 25));
      expect(periodSpan(Period.yesterday, now).from, DateTime(2026, 11, 23));
      expect(periodSpan(Period.week, now).from, DateTime(2026, 11, 18));
      expect(periodSpan(Period.all, now).from, isNull);
      expect(periodSpan(Period.month, now).from, DateTime(2026, 10, 24));
      // 31 March -> end of February, not 3 March
      expect(periodSpan(Period.month, DateTime(2026, 3, 31, 10)).from, DateTime(2026, 2, 28));
      expect(periodSpan(Period.month, DateTime(2026, 1, 15)).from, DateTime(2025, 12, 15));
    });

    test('filter copyWith resets paging only when the filter changes', () {
      const f = SalesFilter(limit: 300, query: 'x');
      expect(f.copyWith(query: 'x').limit, 300, reason: 'same query keeps loaded pages');
      expect(f.copyWith(query: 'y').limit, SalesFilter.pageSize);
      expect(f.copyWith(status: () => 'voided').limit, SalesFilter.pageSize);
      expect(f.copyWith(custom: const DateSpan(null, null)).limit, SalesFilter.pageSize);
      expect(f.hasFilters, isTrue);
      expect(const SalesFilter().hasFilters, isFalse);
    });

    test('bonus clawback preview equals the service', () async {
      await f.db.setSetting('loyalty_enabled', '1');
      await f.db.setSetting('loyalty_earn_percent', '10');
      final a = await f.product('A', price: 10000);
      final c = await f.customer('Клиент');
      final sale = await sell(
        [CheckoutLine(productId: a.id, qty: 4, unitPrice: 10000)],
        [PaymentInput('cash', 40000)],
        customerId: c.id,
      );
      expect(sale.bonusEarned, greaterThan(0));
      final it = (await items(sale.id)).single;
      final before = (await f.reloadC(c)).bonusBalance;
      final refund = previewLineRefund(it, 1);
      final claw = previewBonusClawback(sale, refund, fully: false);
      await sales.returnItems(
        saleId: sale.id,
        lines: [ReturnLineInput(it.id, 1)],
        refundMethod: 'cash',
        userId: f.owner.id,
        shiftId: f.shift.id,
      );
      expect(before - (await f.reloadC(c)).bonusBalance, claw);
    });
  });

  group('queries', () {
    test('list filters, search and totals', () async {
      final milk = await f.product('Молоко', price: 1500, stock: 50);
      final bread = await f.product('Хлеб', price: 500, stock: 50);
      final c = await f.customer('Иван Петров');
      final s1 = await sell([CheckoutLine(productId: milk.id, qty: 2, unitPrice: 1500)], [PaymentInput('cash', 3000)]);
      final s2 = await sell(
        [CheckoutLine(productId: bread.id, qty: 1, unitPrice: 500)],
        [PaymentInput('card', 500)],
        customerId: c.id,
      );
      final s3 = await sell([CheckoutLine(productId: bread.id, qty: 2, unitPrice: 500)], [PaymentInput('cash', 1000)]);
      await sales.voidSale(s3.id, userId: f.owner.id, reason: 'ошибка', shiftId: f.shift.id);

      Future<List<SaleRow>> q(SalesFilter flt) => watchSales(f.db, flt).first;
      final all = await q(const SalesFilter());
      expect(all.map((r) => r.sale.number), [s3.number, s2.number, s1.number]);
      expect(all.firstWhere((r) => r.sale.id == s2.id).customerName, 'Иван Петров');
      expect(all.firstWhere((r) => r.sale.id == s2.id).methods, ['card']);
      expect(all.firstWhere((r) => r.sale.id == s1.id).cashierName, 'Owner');

      expect((await q(const SalesFilter(method: 'card'))).single.sale.id, s2.id);
      expect((await q(const SalesFilter(status: 'voided'))).single.sale.id, s3.id);
      expect((await q(const SalesFilter(query: 'молоко'))).single.sale.id, s1.id, reason: 'cyrillic case-insensitive');
      expect((await q(const SalesFilter(query: 'иван'))).single.sale.id, s2.id);
      expect((await q(SalesFilter(query: '${s2.number}'))).map((r) => r.sale.id), contains(s2.id));
      expect(await q(const SalesFilter(period: Period.yesterday)), isEmpty);
      expect((await q(const SalesFilter(limit: 2))).length, 2);

      final it = (await items(s1.id)).single;
      await sales.returnItems(
        saleId: s1.id,
        lines: [ReturnLineInput(it.id, 1)],
        refundMethod: 'cash',
        userId: f.owner.id,
        shiftId: f.shift.id,
      );
      final totals = await watchSalesTotals(f.db, const SalesFilter()).first;
      expect(totals.count, 3);
      expect(totals.gross, 3500);
      expect(totals.refunded, 1500);
      expect(totals.net, 2000);
      expect(totals.voided, 1);

      final rets = await watchReturns(f.db, const ReturnsFilter()).first;
      expect(rets.single.saleNumber, s1.number);
      expect(rets.single.itemsCount, 1);

      final rt = await watchReturnsTotals(f.db, const ReturnsFilter()).first;
      expect(rt.count, 1);
      expect(rt.sum, 1500);
      expect(await watchReturns(f.db, ReturnsFilter(shiftId: f.shift.id)).first, hasLength(1));
      expect(
        await watchReturns(f.db, const ReturnsFilter(shiftId: 'other-shift')).first,
        isEmpty,
        reason: 'restricted users see only returns of their shift',
      );
      expect((await watchReturnsTotals(f.db, const ReturnsFilter(method: 'card')).first).count, 0);
      expect(
        await watchReturns(f.db, const ReturnsFilter(query: 'молоко')).first,
        isEmpty,
        reason: 'returns search covers numbers, customer and reason only',
      );

      final d = (await loadSaleDetail(f.db, s1.id))!;
      expect(d.returns.single.items.single.$2, 'Молоко');
      expect(d.cashierName, 'Owner');
      expect(d.hasReturnable, isTrue);
    });
  });
}
