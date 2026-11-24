// Visual QA screenshots for the sales module (run with SCREENSHOTS=1).
import 'package:dreampos/l10n/l10n.dart';
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
      final l = L.of(h.locale);
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
      await tester.ensureVisible(find.text(l.salesReceiptText));
      await tester.tap(find.text(l.salesReceiptText));
      await h.settle();
      await h.shot('sales_receipt_text');
      await tester.tap(find.text(l.commonClose));
      await h.settle();

      // return wizard
      // longer labels can scroll the action row out of view
      await tester.ensureVisible(find.text(l.commonReturn).last);
      await h.settle();
      await tester.tap(find.text(l.commonReturn).last);
      await h.settle();
      await h.shot('sales_return_wizard');
      if (find.text(l.salesReturnAll).evaluate().isNotEmpty) {
        await tester.tap(find.text(l.salesReturnAll));
        await h.settle();
        await h.shot('sales_return_wizard_all');
      }
      await popFrom(tester, find.text(l.salesWhatToReturn));
      await h.settle();
      if (!wide) {
        await popFrom(tester, find.text(l.salesReceiptText));
        await h.settle();
      }

      // returns tab
      await tester.tap(find.text(l.salesTabReturns).first);
      await h.settle();
      await h.shot('sales_returns');
      await tester.tap(find.textContaining(l.salesReturnTitle('#', '').split('#').first).first);
      await h.settle();
      await h.shot('sales_returns_detail');
      if (!wide) {
        await popFrom(tester, find.text(l.salesReceiptText));
        await h.settle();
      }

      // empty search
      await tester.tap(find.text(l.salesTitle).last);
      await h.settle();
      await tester.enterText(find.byType(TextField).first, 'zzzzzz');
      await h.settle();
      await h.shot('sales_empty');
      await h.finish();
    }, skip: !screenshotsEnabled);
  }
}

