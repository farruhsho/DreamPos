import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

void main() {
  for (final size in uxSizes.keys) {
    testWidgets('customers screens $size', skip: !screenshotsEnabled, (tester) async {
      final h = await UxHarness.start(tester, size: size);
      // finders follow the screenshot language (SCREENSHOTS_LOCALE)
      final l = L.of(h.locale);
      Future<void> pop(Finder inside) async {
        Navigator.of(tester.element(inside.last)).pop();
        await h.settle();
      }

      await h.go('/customers');
      await h.shot('customers_list');

      await tester.tap(find.text('Дилноза Юсупова').first);
      await h.settle();
      await h.shot('customers_detail');

      Finder tab(String full, String short) =>
          find.text(full).evaluate().isNotEmpty ? find.text(full) : find.text(short);
      if (size == 'phone') {
        await tester.dragUntilVisible(
            tab(l.custTabLedger, l.custTabLedgerShort), find.byType(ListView).last, const Offset(0, -200));
        await h.settle();
      }
      await tester.tap(tab(l.custTabLedger, l.custTabLedgerShort).first);
      await h.settle();
      await h.shot('customers_detail_ledger');
      await tester.tap(tab(l.custTabFav, l.custTabFavShort).first);
      await h.settle();
      await h.shot('customers_detail_favorites');

      if (size == 'phone') {
        await tester.drag(find.byType(ListView).last, const Offset(0, 2000));
        await h.settle();
      }
      final pay = find.text(l.custAcceptDebtPayment);
      await tester.ensureVisible(pay.first);
      await tester.tap(pay.first);
      await h.settle();
      await h.shot('customers_pay_debt');
      await pop(find.text(l.custAcceptDebtPayment));

      final edit = find.text(l.commonEdit);
      await tester.ensureVisible(edit.first);
      await tester.tap(edit.first);
      await h.settle();
      await h.shot('customers_editor_edit');
      await pop(find.text(l.custEditTitle));

      if (size == 'phone') {
        await pop(find.text(l.custCardTitle));
      }
      final add = find.byTooltip(l.custNewTooltip);
      await tester.tap(add.evaluate().isNotEmpty ? add.first : find.text(l.custNew).first);
      await h.settle();
      await h.shot('customers_editor_new');
      await pop(find.text(l.custNew).last);

      await tester.enterText(find.byType(TextField).first, 'zzzzzz');
      await h.settle();
      await h.shot('customers_empty_search');
      await h.finish();
    });
  }
}
