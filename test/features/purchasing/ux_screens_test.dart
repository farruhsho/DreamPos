// Visual QA screenshots for the «Закупки» module. Run with:
//   SCREENSHOTS=1 SCREENSHOTS_DIR=build/screens_purchasing flutter test test/features/purchasing/ux_screens_test.dart
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

Finder _tab(String label) => find.descendant(
  of: find.ancestor(of: find.text('Поставщики'), matching: find.byType(TabBar)),
  matching: find.text(label),
);

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
    final db = h.db;
    final repo = PurchasingRepo(db, StockService(db));
    final sup = await (db.select(db.suppliers)..limit(1)).getSingle();
    final products = await (db.select(db.products)..limit(6)).get();
    final p2 = await repo.saveSupplier(
      const SupplierInput(
        name: 'ИП Каримов — бытовая химия и хозтовары',
        phone: '+998 97 765 43 21',
        contactPerson: 'Бахтиёр',
      ),
    );
    final ordered = await repo.saveDraftOrder(
      supplierId: sup.id,
      note: 'Доставка до 10:00',
      lines: [for (final p in products.take(4)) PoLineInput(productId: p.id, qty: 24, unitCost: p.costPrice)],
    );
    await repo.markOrdered(ordered, userId: h.owner.id);
    await repo.receiveOrder(ordered, [
      ReceiveLineInput(
        itemId:
            (await (db.select(db.purchaseOrderItems)
                      ..where((i) => i.orderId.equals(ordered))
                      ..limit(1))
                    .getSingle())
                .id,
        qty: 24,
        unitCost: products.first.costPrice,
      ),
    ], userId: h.owner.id);
    await repo.saveDraftOrder(
      supplierId: p2,
      lines: [for (final p in products.skip(4)) PoLineInput(productId: p.id, qty: 10, unitCost: p.costPrice)],
    );
  });
  await h.go('/purchasing');
  await h.shot('purchasing_suppliers');
  await tester.tap(find.text('ООО «Оптовик»').first);
  await h.settle();
  await h.shot('purchasing_supplier_detail');
  await tester.tap(find.text('Оплатить').first);
  await h.settle();
  await h.shot('purchasing_supplier_payment');
  await _closeDialog(h);
  await tester.tap(find.byTooltip('Изменить').first);
  await h.settle();
  await h.shot('purchasing_supplier_form');
  await _closeDialog(h);
  await tester.tap(find.text('Оплаты').last);
  await h.settle();
  await h.shot('purchasing_supplier_payments');
  await _back(h);

  await _openTab(h, 'Заказы');
  await h.shot('purchasing_orders');
  await tester.tap(find.textContaining('ООО «Оптовик»').first);
  await h.settle();
  await h.shot('purchasing_order_detail');
  await tester.tap(find.text('Принять товар').first);
  await h.settle();
  await h.shot('purchasing_receive_dialog');
  await _closeDialog(h);
  await _back(h);
  await tester.tap(find.textContaining('ИП Каримов').first);
  await h.settle();
  await h.shot('purchasing_order_draft');
  await tester.tap(find.text('Изменить').first);
  await h.settle();
  await h.shot('purchasing_po_editor');
  await _closeDialog(h);
  await _back(h);
  await tester.tap(find.text('Заказ').first);
  await h.settle();
  await h.shot('purchasing_po_editor_new');
  await _closeDialog(h);

  await _openTab(h, 'Автозаказ');
  await h.shot('purchasing_reorder');
  await _openTab(h, 'Закупочные цены');
  await h.shot('purchasing_prices');
  await h.finish();
}

void main() {
  for (final size in ['desktop', 'tablet', 'phone']) {
    testWidgets('purchasing screens $size', (tester) => _run(tester, size), skip: !screenshotsEnabled);
  }
}
