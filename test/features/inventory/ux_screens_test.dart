// Visual QA screenshots for the «Склад» module. Run with:
//   SCREENSHOTS=1 SCREENSHOTS_DIR=build/screens_inventory flutter test test/features/inventory/ux_screens_test.dart
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

Finder _tab(String label) => find.descendant(of: find.byType(TabBar).first, matching: find.text(label));

Future<void> _openTab(UxHarness h, String label) async {
  await h.tester.ensureVisible(_tab(label));
  await h.tester.pump();
  await h.tester.tap(_tab(label));
  await h.settle();
}

Future<void> _closeDialog(UxHarness h) async {
  final d = find.byType(Dialog);
  if (d.evaluate().isEmpty) return;
  Navigator.of(h.tester.element(d.last), rootNavigator: true).pop();
  await h.settle();
}

Future<void> _back(UxHarness h) async {
  final b = find.byType(BackButton);
  if (b.evaluate().isNotEmpty) {
    await h.tester.tap(b.last);
    await h.settle();
  }
}

Future<void> _rowMenu(UxHarness h) async {
  final f = find.byTooltip('Действия').first;
  await h.tester.ensureVisible(f);
  await h.settle(2);
  await h.tester.tap(f);
  await h.settle();
}

Future<void> _scan(UxHarness h, String code) async {
  final f = find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        (w.decoration?.labelText == 'Сканируйте штрихкод или введите артикул' ||
            w.decoration?.labelText == 'Штрихкод или артикул'),
  );
  await h.tester.enterText(f, code);
  await h.tester.testTextInput.receiveAction(TextInputAction.done);
  await h.settle();
}

/// Runs DB work while pumping, so drift locks held by app streams (fake-async
/// zone) can be released; a plain runAsync would deadlock.
Future<T> _drive<T>(UxHarness h, Future<T> Function() fn) async {
  T? result;
  Object? error;
  var done = false;
  fn().then(
    (v) {
      result = v;
      done = true;
    },
    onError: (Object e) {
      error = e;
      done = true;
    },
  );
  for (var i = 0; !done && i < 200; i++) {
    await h.settle(1);
  }
  if (error != null) throw error!;
  return result as T;
}

Future<void> _run(WidgetTester tester, String size) async {
  final h = await UxHarness.start(tester, size: size);
  await _drive(h, () async {
    final p = await (h.db.select(h.db.products)..limit(2)).get();
    final svc = StockService(h.db);
    await svc.writeOff(productId: p[0].id, qty: 2, reason: 'Брак', userId: h.owner.id);
    await svc.writeOff(productId: p[1].id, qty: 1, reason: 'Истёк срок годности', userId: h.owner.id);
  });
  await h.go('/inventory');
  await h.shot('inventory_stock');

  // Row actions: write-off dialog and movement history.
  await _rowMenu(h);
  await h.settle();
  await tester.tap(find.text('Списание').last);
  await h.settle();
  await h.shot('inventory_writeoff_dialog');
  await _closeDialog(h);

  await _rowMenu(h);
  await h.settle();
  await tester.tap(find.text('Приход').last);
  await h.settle();
  await h.shot('inventory_quick_receipt_dialog');
  await _closeDialog(h);

  await _rowMenu(h);
  await h.settle();
  await tester.tap(find.text('Корректировка').last);
  await h.settle();
  await h.shot('inventory_adjust_dialog');
  await _closeDialog(h);

  await _rowMenu(h);
  await h.settle();
  await tester.tap(find.text('Движения').last);
  await h.settle();
  await h.shot('inventory_history_dialog');
  await _closeDialog(h);

  // Goods receipt.
  await _openTab(h, 'Приход');
  await h.shot('inventory_receipt_empty');
  await _scan(h, '4780000000011');
  await _scan(h, '2000000000015');
  await _scan(h, '4780000000165');
  await h.shot('inventory_receipt_lines');

  await _openTab(h, 'Списание');
  await h.shot('inventory_writeoff_tab');

  await _openTab(h, 'Инвентаризация');
  await h.shot('inventory_counts_empty');
  await tester.tap(find.text('Новая инвентаризация').first);
  await h.settle();
  await h.shot('inventory_count_create');
  await tester.tap(find.text('Категория').last);
  await h.settle();
  await h.shot('inventory_count_create_category');
  await tester.tap(find.text(size == 'phone' ? 'Все' : 'Все товары').last);
  await h.settle();
  await tester.tap(find.text('Создать'));
  await h.settle(10);
  await h.shot('inventory_count_editor');
  // Count a few items by scan so differences and totals show up.
  final scanField = find.widgetWithText(TextField, 'Скан: +1 к факту');
  for (final code in ['4780000000011', '4780000000011', '4780000000189']) {
    await tester.enterText(scanField, code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();
  }
  await h.settle(10);
  await h.shot('inventory_count_editor_counted');
  await tester.tap(find.textContaining('Расхождения').first);
  await h.settle();
  await h.shot('inventory_count_editor_diffs');
  await _back(h);
  await h.shot('inventory_counts_list');

  await _openTab(h, 'Движения');
  await h.shot('inventory_movements');
  await h.finish();
}

void main() {
  for (final size in ['desktop', 'tablet', 'phone']) {
    testWidgets(
      'inventory screens $size',
      (tester) => _run(tester, size),
      skip: !screenshotsEnabled,
      timeout: const Timeout(Duration(minutes: 4)),
    );
  }
}
