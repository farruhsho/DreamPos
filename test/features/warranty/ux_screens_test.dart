// Visual QA screenshots for the warranty module (run with SCREENSHOTS=1).
import 'package:dreampos/l10n/l10n.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

void main() {
  for (final size in ['desktop', 'tablet', 'phone']) {
    testWidgets('warranty screens $size', (tester) async {
      final h = await UxHarness.start(tester, size: size);
      final l = L.of(h.locale);
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
      await tester.tap(find.text(l.warrantyNewClaim).first);
      await h.settle();
      await h.shot('warranty_form');
      if (sale != null) {
        await tester.enterText(find.byKey(const Key('claim-receipt')), '${sale.number}');
        await tester.tap(find.text(l.warrantyFind));
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
        await tester.ensureVisible(find.text(l.warrantySubmit));
        await tester.tap(find.text(l.warrantySubmit));
        await h.settle();
        await h.shot('warranty_created_confirm');
        if (find.text(l.commonCancel).evaluate().isNotEmpty) {
          await tester.tap(find.text(l.commonCancel).last);
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
        await tester.tap(find.text(l.commonCancel));
        await h.settle();
      }

      // manual mode
      await tester.tap(find.text(wide ? l.warrantyNewClaim : l.warrantyClaimFab).first);
      await h.settle();
      await tester.tap(find.text(l.warrantyWithoutReceipt));
      await h.settle();
      await h.shot('warranty_form_manual');
      await tester.ensureVisible(find.text(l.warrantySubmit));
      await tester.tap(find.text(l.warrantySubmit));
      await h.settle();
      await h.shot('warranty_form_manual_errors');
      await tester.tap(find.text(l.commonCancel).last);
      await h.settle();
      await h.finish();
    }, skip: !screenshotsEnabled);
  }
}

