// Visual QA screenshots for the warranty module (run with SCREENSHOTS=1).
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

void main() {
  for (final size in ['desktop', 'tablet', 'phone']) {
    testWidgets('warranty screens $size', (tester) async {
      final h = await UxHarness.start(tester, size: size);
      final wide = size != 'phone';
      await h.go('/warranty');
      await h.shot('warranty_empty');

      // a receipt that has an item under warranty
      final item = await tester.runAsync(() => (h.db.select(h.db.saleItems)
            ..where((i) => i.warrantyUntil.isNotNull())
            ..orderBy([(i) => OrderingTerm(expression: i.id)])
            ..limit(1))
          .getSingleOrNull());
      final sale = item == null
          ? null
          : await tester.runAsync(
              () => (h.db.select(h.db.sales)..where((s) => s.id.equals(item.saleId))).getSingle());

      // the empty state carries the "new claim" button (no FAB on phone)
      await tester.tap(find.text('Новая заявка').first);
      await h.settle();
      await h.shot('warranty_form');
      if (sale != null) {
        await tester.enterText(find.byKey(const Key('claim-receipt')), '${sale.number}');
        await tester.tap(find.text('Найти'));
        await h.settle();
        await h.shot('warranty_form_receipt');
        final tile = find.text(item!.productName);
        if (tile.evaluate().isNotEmpty) {
          await tester.tap(tile.first);
          await h.settle();
        }
        await tester.enterText(find.byKey(const Key('claim-problem')), 'Не включается после падения');
        await h.settle();
        await h.shot('warranty_form_filled');
        await tester.ensureVisible(find.text('Принять заявку'));
        await tester.tap(find.text('Принять заявку'));
        await h.settle();
        await h.shot('warranty_created_confirm');
        if (find.text('Отмена').evaluate().isNotEmpty) {
          await tester.tap(find.text('Отмена').last);
          await h.settle();
        }
        if (!wide) {
          await h.shot('warranty_detail');
          final nav = find.byType(BackButton);
          if (nav.evaluate().isNotEmpty) {
            await tester.tap(nav.first);
            await h.settle();
          }
        }
        await h.shot('warranty_list');
      } else {
        await tester.tap(find.text('Отмена'));
        await h.settle();
      }

      // manual mode
      await tester.tap(find.text(wide ? 'Новая заявка' : 'Заявка').first);
      await h.settle();
      await tester.tap(find.text('Без чека'));
      await h.settle();
      await h.shot('warranty_form_manual');
      await tester.ensureVisible(find.text('Принять заявку'));
      await tester.tap(find.text('Принять заявку'));
      await h.settle();
      await h.shot('warranty_form_manual_errors');
      await tester.tap(find.text('Отмена').last);
      await h.settle();
      await h.finish();
    }, skip: !screenshotsEnabled);
  }
}

