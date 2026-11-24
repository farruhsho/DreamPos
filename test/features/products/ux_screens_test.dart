import 'package:dreampos/features/products/product_detail.dart';
import 'package:dreampos/features/products/product_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

void main() {
  testWidgets('products UX screens', (tester) async {
    final h = await UxHarness.start(tester);
    final errors = <String, List<String>>{};
    Future<void> shot(String name) async {
      final e = await h.shot(name);
      if (e.isNotEmpty) errors['${h.sizeName}_$name'] = e;
    }

    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f);
      await tester.tap(f, warnIfMissed: false);
      await h.settle();
    }

    Future<void> closeDialog() async {
      final close = find.byTooltip('Закрыть');
      final cancel = find.text('Отмена');
      if (cancel.evaluate().isNotEmpty) {
        await tap(cancel.last);
      } else if (close.evaluate().isNotEmpty) {
        await tap(close.last);
      } else {
        await tester.tapAt(const Offset(5, 5));
        await h.settle();
      }
    }

    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await h.go('/products');
      await h.settle();
      await shot('products_list');

      // Detail (master-detail on wide, page on phone).
      await tap(find.byType(ProductRow).first);
      await shot('products_detail');
      // Existing product editor from detail.
      final edit = find.text('Изменить');
      if (edit.evaluate().isNotEmpty) {
        await tap(edit.first);
        await shot('products_editor_existing');
        await tester.drag(find.byType(Form).last, const Offset(0, -420), warnIfMissed: false);
        await h.settle();
        await shot('products_editor_existing_scrolled');
        await closeDialog();
      }
      // Scroll the detail down to the movements section.
      final movements = find.text('Движение товара');
      final detailScroll = find
          .descendant(
              of: find.byType(size == 'phone' ? ProductDetailPage : ProductDetailView),
              matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(movements, 200, scrollable: detailScroll);
      await h.settle();
      await tester.drag(detailScroll, const Offset(0, -400));
      await h.settle();
      await shot('products_detail_movements');

      if (size == 'phone') {
        await tap(find.byType(BackButton).first);
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await h.settle();
      }

      // New product editor.
      if (size == 'phone') {
        await tap(find.byType(FloatingActionButton));
      } else {
        await tap(find.text('Новый товар').first);
      }
      await shot('products_editor_new');
      await tester.scrollUntilVisible(find.byKey(const ValueKey('generate-barcode')), 200,
          scrollable: find.descendant(of: find.byType(Form).last, matching: find.byType(Scrollable)).first);
      await h.settle();
      await tap(find.byKey(const ValueKey('generate-barcode')));
      await shot('products_editor_new_codes');
      await closeDialog();
      // Leaving a dirty editor asks for confirmation.
      if (find.text('Закрыть без сохранения?').evaluate().isNotEmpty) {
        await tap(find.text('Закрыть').last);
      }

      // Categories manager.
      if (size == 'phone') {
        await tap(find.byTooltip('Ещё'));
        await tap(find.text('Категории').last);
      } else {
        await tap(find.text('Категории').first);
      }
      await shot('products_categories');
      await tap(find.text('Новая категория').first);
      await shot('products_category_edit');
      await closeDialog();
      await closeDialog();

      // Import dialog.
      await tap(find.byTooltip('Ещё'));
      await tap(find.text('Импорт из CSV'));
      await shot('products_import');
      await closeDialog();

      // Bulk select bar.
      await tap(find.text('Выбрать'));
      await tap(find.byType(ProductRow).at(0));
      await tap(find.byType(ProductRow).at(1));
      await shot('products_bulk');

      // Labels dialog.
      if (size == 'phone') {
        await tap(find.byTooltip('Действия'));
        await shot('products_bulk_menu');
        await tester.tapAt(const Offset(5, 400));
        await h.settle();
        await tap(find.byTooltip('Ценники'));
      } else {
        await tap(find.text('Ценники').first);
      }
      await shot('products_labels');
      await closeDialog();
      await tap(find.byTooltip('Отменить выбор (Esc)'));

      // Empty search result.
      await tester.enterText(find.byType(TextField).first, 'zzzнетттакого');
      await h.settle();
      await shot('products_empty_search');
      await tester.enterText(find.byType(TextField).first, '');
      await h.settle();
    }
    await h.finish();
    expect(errors, isEmpty, reason: errors.keys.join(', '));
  }, skip: !screenshotsEnabled);
}
