// Visual QA screenshots for the sales module (run with SCREENSHOTS=1).
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

void main() {
  Future<void> popFrom(WidgetTester tester, Finder f) async {
    Navigator.of(tester.element(f.last)).pop();
  }

  for (final size in ['desktop', 'tablet', 'phone']) {
    testWidgets('sales screens $size', (tester) async {
      final h = await UxHarness.start(tester, size: size);
      final wide = size != 'phone';
      await h.go('/sales');
      await h.shot('sales_list');

      // detail of the most recent receipt
      final latest = await tester.runAsync(() => (h.db.select(h.db.sales)
            ..orderBy([(s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc)])
            ..limit(1))
          .getSingle());
      await tester.tap(find.text('№${latest!.number}').first);
      await h.settle();
      await h.shot('sales_detail');

      // receipt text preview
      await tester.ensureVisible(find.text('Текст чека'));
      await tester.tap(find.text('Текст чека'));
      await h.settle();
      await h.shot('sales_receipt_text');
      await tester.tap(find.text('Закрыть'));
      await h.settle();

      // return wizard
      await tester.tap(find.text('Возврат').last);
      await h.settle();
      await h.shot('sales_return_wizard');
      if (find.text('Вернуть всё').evaluate().isNotEmpty) {
        await tester.tap(find.text('Вернуть всё'));
        await h.settle();
        await h.shot('sales_return_wizard_all');
      }
      await popFrom(tester, find.text('Что возвращаем'));
      await h.settle();
      if (!wide) {
        await popFrom(tester, find.text('Текст чека'));
        await h.settle();
      }

      // returns tab
      await tester.tap(find.text('Возвраты').first);
      await h.settle();
      await h.shot('sales_returns');
      await tester.tap(find.textContaining('Возврат №').first);
      await h.settle();
      await h.shot('sales_returns_detail');
      if (!wide) {
        await popFrom(tester, find.text('Текст чека'));
        await h.settle();
      }

      // empty search
      await tester.tap(find.text('Чеки').last);
      await h.settle();
      await tester.enterText(find.byType(TextField).first, 'zzzzzz');
      await h.settle();
      await h.shot('sales_empty');
      await h.finish();
    }, skip: !screenshotsEnabled);
  }
}

