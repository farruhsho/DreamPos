import 'package:dreampos/core/money.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/dashboard/dashboard_providers.dart';
import 'package:dreampos/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../reports/pump_helpers.dart';

void main() {
  test('store progress and stock alerts queries', () async {
    final f = await Fixture.create();
    addTearDown(f.db.close);
    var p = await storeProgressQuery(f.db).getSingle();
    expect(p.isNew, isTrue);
    expect(p.shifts, 1);
    expect(p.stepsDone, 1);
    final prod = await f.product('Молоко', stock: 0);
    await SaleService(f.db).checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: (await f.product('Хлеб', stock: 5)).id, qty: 1, unitPrice: 1000)],
      payments: [PaymentInput('cash', 1000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    p = await storeProgressQuery(f.db).getSingle();
    expect(p.isNew, isFalse);
    expect(p.stepsDone, 3);
    final a = await stockAlertsQuery(f.db).getSingle();
    expect(a.out, 1, reason: '${prod.name} has zero stock');
  });

  testWidgets('onboarding fits a 360px phone', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    await pumpScreen(tester, f.db, f.owner, const DashboardScreen(), size: const Size(360, 740));
    expect(tester.takeException(), isNull);
    expect(find.text('Сделайте первую продажу'), findsOneWidget);
    await unmount(tester);
    await tester.runAsync(f.db.close);
  });

  testWidgets('brand-new store shows onboarding steps', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    await pumpScreen(tester, f.db, f.owner, const DashboardScreen());
    expect(find.text('Добро пожаловать в DreamPOS!'), findsOneWidget);
    expect(find.text('Добавьте товары'), findsOneWidget);
    expect(find.text('Откройте смену'), findsOneWidget);
    expect(find.text('Сделайте первую продажу'), findsOneWidget);
    expect(find.text('Выполнено 1 из 3'), findsOneWidget, reason: 'fixture opened a shift');
    await unmount(tester);
    await tester.runAsync(f.db.close);
  });

  for (final size in const [Size(1400, 900), Size(390, 800), Size(360, 740)]) {
    testWidgets('dashboard with sales renders KPIs (${size.width.toInt()}px)', (tester) async {
      final f = (await tester.runAsync(() async {
        final f = await Fixture.create();
        final p = await f.product('Кофе', price: 15000, cost: 9000, stock: 10);
        await SaleService(f.db).checkout(CheckoutRequest(
          lines: [CheckoutLine(productId: p.id, qty: 2, unitPrice: 15000)],
          payments: [PaymentInput('card', 30000)],
          cashierId: f.owner.id,
          shiftId: f.shift.id,
        ));
        return f;
      }))!;
      await pumpScreen(tester, f.db, f.owner, const DashboardScreen(), size: size);
      expect(tester.takeException(), isNull);
      expect(find.text('Выручка сегодня'), findsOneWidget);
      expect(find.text(Money.format(30000)), findsWidgets);
      final list = find.byType(Scrollable).first;
      for (final title in ['Выручка за 14 дней', 'Топ-5 товаров', 'Оплаты сегодня', 'Последние чеки']) {
        await tester.scrollUntilVisible(find.text(title), 300, scrollable: list);
        await settle(tester, rounds: 2);
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Чек №1'), findsOneWidget);
      expect(find.text('Кофе'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
      await tester.runAsync(f.db.close);
    });
  }
}
