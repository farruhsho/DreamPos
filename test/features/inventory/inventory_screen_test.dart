import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/inventory/inventory_logic.dart';
import 'package:dreampos/features/inventory/inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

class _LoggedIn extends SessionNotifier {
  _LoggedIn(this.u);
  final User u;
  @override
  Session? build() => Session(u);
}

Finder _tab(String label) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(label));

/// Taps a top tab, scrolling the (scrollable) tab bar first on phones.
Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.ensureVisible(_tab(label));
  await tester.pump();
  await tester.tap(_tab(label));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<Fixture> _seed() async {
  final f = await Fixture.create();
  final p = await f.product('Молоко 1л', price: 12000, cost: 9000, stock: 2);
  await (f.db.update(f.db.products)..where((t) => t.id.equals(p.id)))
      .write(const ProductsCompanion(minStock: Value(5), barcode: Value('4780001')));
  await f.product('Хлеб', price: 4000, cost: 2500, stock: 30);
  await f.db.into(f.db.suppliers).insert(SuppliersCompanion.insert(id: newId(), name: 'Молочный завод'));
  return f;
}

Future<void> _pump(WidgetTester tester, Fixture f, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(f.db),
      sessionProvider.overrideWith(() => _LoggedIn(f.owner)),
    ],
    child: const MaterialApp(home: InventoryScreen()),
  ));
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester, Fixture f) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
  await f.db.close();
}

void main() {
  testWidgets('desktop: stock overview, receipt by scan, other tabs', (tester) async {
    final f = (await tester.runAsync(_seed))!;
    await _pump(tester, f, const Size(1440, 900));

    expect(find.text('Склад'), findsOneWidget);
    expect(find.text('Молоко 1л'), findsOneWidget);
    expect(find.text('Хлеб'), findsOneWidget);
    expect(find.text('Запас по себестоимости'), findsOneWidget);
    expect(find.text('Мало'), findsWidgets);

    // Filter: low stock only.
    await tester.tap(find.textContaining('Мало ('));
    await _settle(tester);
    expect(find.text('Хлеб'), findsNothing);
    expect(find.text('Молоко 1л'), findsOneWidget);

    // Receipt tab: scan a barcode -> line appears -> post.
    await tester.tap(_tab('Приход'));
    await _settle(tester);
    expect(find.text('Документ пуст'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Сканируйте штрихкод или введите артикул'), '4780001');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);
    expect(find.textContaining('1. Молоко 1л'), findsOneWidget);
    await tester.tap(find.text('Провести приход'));
    await _settle(tester);
    expect(find.text('Провести приход?'), findsOneWidget);
    await tester.tap(find.text('Провести'));
    await _settle(tester);
    final milk = await tester.runAsync(() =>
        (f.db.select(f.db.products)..where((p) => p.barcode.equals('4780001'))).getSingle());
    expect(milk!.stockQty, 3);

    await tester.tap(_tab('Списание'));
    await _settle(tester);
    expect(find.text('Новое списание'), findsOneWidget);
    expect(find.text('Просрочка'), findsOneWidget);

    await tester.tap(_tab('Инвентаризация'));
    await _settle(tester);
    expect(find.text('Новая инвентаризация'), findsOneWidget);

    await tester.tap(_tab('Движения'));
    await _settle(tester);
    expect(find.textContaining('Записей:'), findsOneWidget);

    await _dispose(tester, f);
  });

  testWidgets('phone width renders without overflow', (tester) async {
    final f = (await tester.runAsync(_seed))!;
    await _pump(tester, f, const Size(380, 800));
    expect(find.text('Позиций на учёте'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await _settle(tester);
    expect(find.text('Молоко 1л'), findsOneWidget);
    for (final tab in ['Приход', 'Списание', 'Инвентаризация', 'Движения']) {
      await _openTab(tester, tab);
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: tab);
    }
    expect(tester.takeException(), isNull);
    await _dispose(tester, f);
  });

  testWidgets('stocktake: scan increments, complete posts difference', (tester) async {
    final f = (await tester.runAsync(_seed))!;
    await tester.runAsync(() => InventoryRepo(f.db, StockService(f.db)).createCount(scope: CountScope.all));
    await _pump(tester, f, const Size(1440, 900));
    await tester.tap(_tab('Инвентаризация'));
    await _settle(tester);
    await tester.tap(find.text('Инвентаризация №1'));
    await _settle(tester);
    expect(find.text('Посчитано 0/2'), findsOneWidget);

    // Two scans of milk -> counted 2 (book stock 2, no difference).
    for (var i = 0; i < 2; i++) {
      await tester.enterText(find.widgetWithText(TextField, 'Скан: +1 к факту'), '4780001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
    }
    expect(find.text('Посчитано 1/2'), findsOneWidget);

    await tester.tap(find.text('Провести'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);
    expect(find.text('Провести инвентаризацию №1?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Провести').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);
    final c = await tester.runAsync(() => f.db.select(f.db.inventoryCounts).getSingle());
    expect(c!.status, 'completed');
    await _dispose(tester, f);
  });

  testWidgets('phone 360: stocktake editor opens as a page, rapid scans all count', (tester) async {
    final f = (await tester.runAsync(_seed))!;
    await tester.runAsync(() => InventoryRepo(f.db, StockService(f.db)).createCount(scope: CountScope.all));
    await _pump(tester, f, const Size(360, 740));
    await _openTab(tester, 'Инвентаризация');
    await _settle(tester);
    await tester.tap(find.text('Инвентаризация №1'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Посчитано 0/2'), findsOneWidget);

    // Three scans fired back to back, as a hardware scanner does.
    final scan = find.widgetWithText(TextField, 'Скан: +1 к факту');
    for (var i = 0; i < 3; i++) {
      await tester.enterText(scan, '4780001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(tester);
    }
    final items = await tester.runAsync(() => f.db.select(f.db.inventoryCountItems).get());
    final milk = await tester.runAsync(() =>
        (f.db.select(f.db.products)..where((p) => p.barcode.equals('4780001'))).getSingle());
    expect(items!.firstWhere((i) => i.productId == milk!.id).countedQty, 3);
    expect(tester.takeException(), isNull);

    // Quick per-product dialogs from the stock list at phone width.
    await tester.pageBack();
    await _settle(tester);
    await _openTab(tester, 'Остатки');
    await _settle(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await _settle(tester);
    await tester.tap(find.byTooltip('Действия').first);
    await _settle(tester);
    await tester.tap(find.text('Списание').last);
    await _settle(tester);
    expect(find.text('Брак'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester, f);
  });
}
