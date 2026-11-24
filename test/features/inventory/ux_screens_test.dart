// Visual QA screenshots for the «Склад» module. Run with:
//   SCREENSHOTS=1 SCREENSHOTS_DIR=build/screens_inventory flutter test test/features/inventory/ux_screens_test.dart
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/inventory/inventory_logic.dart';
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

/// Receipt document: dialog on desktop/tablet, page on phones.
Future<void> _closeDocument(UxHarness h, String size) async {
  if (size == 'phone') {
    final close = find.byType(CloseButton);
    if (close.evaluate().isNotEmpty) {
      await h.tester.tap(close.last);
      await h.settle();
    }
  } else {
    await _closeDialog(h);
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
    // Receipt documents: one from a supplier with an invoice, one reversed.
    final more = await (h.db.select(h.db.products)..limit(6)).get();
    final sup = await (h.db.select(h.db.suppliers)..limit(1)).getSingleOrNull();
    final repo = InventoryRepo(h.db, svc);
    await repo.postReceipt(
      lines: [
        for (final x in more.take(4))
          ReceiptLine(product: x, qty: x.unit == 'kg' ? 2.5 : 12, unitCost: x.costPrice, newPrice: x == more.first ? x.price + 1000 : null),
      ],
      supplierId: sup?.id,
      supplierInvoice: 'ТН-004512',
      note: 'Поставка по графику',
      userId: h.owner.id,
    );
    final wrong = await repo.postReceipt(
      lines: [ReceiptLine(product: more[5], qty: 3, unitCost: more[5].costPrice)],
      userId: h.owner.id,
    );
    await repo.reverseReceipt(wrong, reason: 'Ошибочный ввод количества', userId: h.owner.id);
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

  // Receipt documents journal, detail and reversal dialog.
  ScaffoldMessenger.of(tester.element(find.byType(TabBar).first)).clearSnackBars();
  await tester.tap(find.text('Документы').first);
  await h.settle();
  await h.shot('inventory_receipt_documents');
  await tester.tap(find.textContaining('ТН-004512').first);
  await h.settle();
  await h.shot('inventory_receipt_document');
  await tester.tap(find.text('Сторнировать').first);
  await h.settle();
  await h.shot('inventory_receipt_reverse_dialog');
  await tester.tap(find.text('Отмена').last);
  await h.settle();
  await _closeDocument(h, size);
  await tester.tap(find.text('Сторнирован').first);
  await h.settle();
  await h.shot('inventory_receipt_document_reversed');
  await _closeDocument(h, size);
  await tester.tap(find.text('Новый приход').first);
  await h.settle();

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
