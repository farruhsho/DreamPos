// Payments report block «Продажа сертификатов (аванс, не выручка)» (D-023).
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/reports/data/gift_sales_report.dart';
import 'package:dreampos/features/reports/data/period.dart';
import 'package:dreampos/features/reports/data/report_queries.dart';
import 'package:dreampos/features/reports/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import 'pump_helpers.dart';

Future<String> _sell(Fixture f, String code, int amount, List<GiftSalePaymentInput> pays) async =>
    (await GiftCardService(f.db).sell(GiftCardSaleRequest(
      code: code,
      amount: amount,
      payments: pays,
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    )))
        .saleId;

void main() {
  final period = ReportPeriod.preset(PeriodPreset.today);

  test('table: methods in standard order, voided subtracted, totals and CSV', () {
    const g = GiftSalesByMethod(
      sold: {'transfer': 2000, 'cash': 5000, 'card': 3000},
      refunded: {'cash': 1000},
      soldCount: 3,
      voidedCount: 1,
    );
    expect(giftReportMethods(g), ['cash', 'card', 'transfer']);
    final t = giftSalesTable(g, period);
    expect(t.title, giftSalesReportTitle);
    expect(t.subtitle, contains('продано 3, аннулировано 1'));
    expect(t.rows.first.map((c) => c.csv).toList(), ['Наличные', '5000', '1000', '4000']);
    expect(t.totals!.map((c) => c.csv).toList(), ['Итого', '10000', '1000', '9000']);
    final csv = t.toCsv().trim().split('\n');
    expect(csv.first, 'Способ оплаты;Продано;Аннулировано;Итого');
    expect(csv.last, 'Итого;10000;1000;9000');
  });

  test('empty figures -> empty table without totals', () {
    final t = giftSalesTable(const GiftSalesByMethod(), period);
    expect(t.isEmpty, isTrue);
    expect(t.totals, isNull);
  });

  test('period figures: net of voids, revenue and payments table unchanged', () async {
    final f = await Fixture.create();
    addTearDown(f.db.close);
    final p = await f.product('Хлеб', price: 4000, stock: 10);
    await SaleService(f.db).checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 4000)],
      payments: [PaymentInput('cash', 4000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    final before = await salesSummaryQuery(f.db, period).getSingle();
    final paysBefore = await paymentsQuery(f.db, period).get();

    await _sell(f, 'REPGIFT001', 10000, const [GiftSalePaymentInput('cash', 4000), GiftSalePaymentInput('card', 6000)]);
    final v = await _sell(f, 'REPGIFT002', 3000, const [GiftSalePaymentInput('transfer', 3000)]);
    await GiftCardService(f.db).voidSale(v, reason: 'Ошибка', userId: f.owner.id, shiftId: f.shift.id);

    final g = await giftSalesByMethod(f.db, period.start, period.end);
    final t = giftSalesTable(g, period);
    expect(t.totals!.map((c) => c.csv).toList(), ['Итого', '13000', '3000', '10000']);
    expect(t.rows.last.map((c) => c.csv).toList(), ['Перевод', '3000', '3000', '0']);

    final after = await salesSummaryQuery(f.db, period).getSingle();
    expect(after.gross, before.gross, reason: 'gift advances are not revenue');
    final paysAfter = await paymentsQuery(f.db, period).get();
    expect(paysAfter.map((r) => (r.method, r.net)), paysBefore.map((r) => (r.method, r.net)));
  });

  for (final size in const [Size(1440, 2400), Size(390, 2400)]) {
    testWidgets('payments tab shows the gift block only when there are gift sales (${size.width.toInt()}px)',
        (tester) async {
      final f = (await tester.runAsync(Fixture.create))!;
      await pumpScreen(tester, f.db, f.owner, const ReportsScreen(), size: size);
      await tester.ensureVisible(find.text('Оплаты').first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Оплаты').first);
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      expect(find.text(giftSalesReportTitle), findsNothing);

      await tester.runAsync(() => _sell(f, 'REPGIFT003', 5000, const [GiftSalePaymentInput('card', 5000)]));
      await settle(tester);
      await tester.scrollUntilVisible(find.text(giftSalesReportTitle), 300,
          scrollable: find.descendant(of: find.byType(TabBarView), matching: find.byType(Scrollable)).first);
      await settle(tester);
      expect(find.text(giftSalesReportTitle), findsOneWidget);
      expect(find.text(giftSalesReportHint), findsOneWidget);
      expect(tester.takeException(), isNull);

      await unmount(tester);
      await tester.runAsync(f.db.close);
    });
  }
}
