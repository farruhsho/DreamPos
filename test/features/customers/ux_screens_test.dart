import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

void main() {
  for (final size in uxSizes.keys) {
    testWidgets('customers screens $size', skip: !screenshotsEnabled, (tester) async {
      final h = await UxHarness.start(tester, size: size);
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
            tab('Долги и бонусы', 'Операции'), find.byType(ListView).last, const Offset(0, -200));
        await h.settle();
      }
      await tester.tap(tab('Долги и бонусы', 'Операции').first);
      await h.settle();
      await h.shot('customers_detail_ledger');
      await tester.tap(tab('Любимые товары', 'Любимое').first);
      await h.settle();
      await h.shot('customers_detail_favorites');

      if (size == 'phone') {
        await tester.drag(find.byType(ListView).last, const Offset(0, 2000));
        await h.settle();
      }
      final pay = find.text('Принять оплату долга');
      await tester.ensureVisible(pay.first);
      await tester.tap(pay.first);
      await h.settle();
      await h.shot('customers_pay_debt');
      await pop(find.text('Принять оплату долга'));

      final edit = find.text('Изменить');
      await tester.ensureVisible(edit.first);
      await tester.tap(edit.first);
      await h.settle();
      await h.shot('customers_editor_edit');
      await pop(find.text('Редактирование клиента'));

      if (size == 'phone') {
        await pop(find.text('Карточка клиента'));
      }
      final add = find.byTooltip('Новый клиент (Ctrl+N)');
      await tester.tap(add.evaluate().isNotEmpty ? add.first : find.text('Новый клиент').first);
      await h.settle();
      await h.shot('customers_editor_new');
      await pop(find.text('Новый клиент').last);

      await tester.enterText(find.byType(TextField).first, 'zzzzzz');
      await h.settle();
      await h.shot('customers_empty_search');
      await h.finish();
    });
  }
}
