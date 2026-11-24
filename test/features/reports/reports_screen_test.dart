import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/reports/data/report_table.dart';
import 'package:dreampos/features/reports/reports_screen.dart';
import 'package:dreampos/features/reports/widgets/report_table_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import 'pump_helpers.dart';

void main() {
  const tabs = ['Продажи', 'Товары', 'Сотрудники', 'Оплаты', 'Склад', 'Прогноз спроса', 'AI-аналитика'];

  Future<Fixture> seeded() async {
    final f = await Fixture.create();
    final p = await f.product('Хлеб', price: 4000, cost: 3000, stock: 20);
    final sales = SaleService(f.db);
    for (var i = 0; i < 3; i++) {
      await sales.checkout(CheckoutRequest(
        lines: [CheckoutLine(productId: p.id, qty: 2, unitPrice: 4000)],
        payments: [PaymentInput(i.isEven ? 'cash' : 'card', 8000)],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ));
    }
    return f;
  }

  for (final size in const [Size(1400, 900), Size(390, 800)]) {
    testWidgets('reports: every tab renders (${size.width.toInt()}px)', (tester) async {
      final f = (await tester.runAsync(seeded))!;
      await pumpScreen(tester, f.db, f.owner, const ReportsScreen(), size: size);
      expect(find.text('Отчёты'), findsOneWidget);
      expect(find.text('Чистая выручка'), findsWidgets);

      for (final t in tabs) {
        await tester.ensureVisible(find.text(t).first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text(t).first);
        await tester.pump(const Duration(milliseconds: 400));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'tab $t');
      }
      // the forecast tab shows the explanation; the insights tab its intro
      expect(find.textContaining('Подсказки по вашим данным'), findsOneWidget);

      await unmount(tester);
      await tester.runAsync(f.db.close);
    });
  }

  testWidgets('reports: empty store shows "no sales" hint', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    await pumpScreen(tester, f.db, f.owner, const ReportsScreen());
    expect(find.text('За выбранный период продаж нет'), findsOneWidget);
    await unmount(tester);
    await tester.runAsync(f.db.close);
  });

  test('CSV: semicolons, quotes, BOM-free text and formula injection are handled', () {
    final t = RTable(title: 'T', columns: const [RCol('Товар'), RCol('Сумма', numeric: true)], rows: [
      [const RCell('=HYPERLINK("x")'), RCell.money(-1500)],
      [const RCell('Сок; яблочный'), RCell.money(0)],
    ]);
    final lines = t.toCsv().trim().split('\n');
    expect(lines[0], 'Товар;Сумма');
    expect(lines[1], startsWith("\"'=HYPERLINK(\"\"x\"\")\""));
    expect(lines[1], endsWith(';-1500'), reason: 'numbers are not escaped');
    expect(lines[2], '"Сок; яблочный";0');
  });

  testWidgets('table keeps working when its columns shrink after sorting', (tester) async {
    Widget host(int cols) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReportTableCard(
                table: RTable(
                  title: 'Таблица',
                  columns: [for (var i = 0; i < cols; i++) RCol('C$i', numeric: i > 0)],
                  rows: [
                    for (var r = 0; r < 3; r++)
                      [for (var i = 0; i < cols; i++) RCell.integer(r * 10 + i)],
                  ],
                ),
              ),
            ),
          ),
        );
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(ProviderScope(child: host(5)));
    await tester.tap(find.text('C4'));
    await tester.pump();
    await tester.pumpWidget(ProviderScope(child: host(2)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('C1'), findsOneWidget);
  });
}
