import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:dreampos/features/purchasing/purchasing_screen.dart';
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
  final repo = PurchasingRepo(f.db, StockService(f.db));
  final sid = await repo.saveSupplier(const SupplierInput(name: 'Молочный завод', phone: '+998901234567'));
  await (f.db.update(f.db.suppliers)..where((s) => s.id.equals(sid))).write(const SuppliersCompanion(balance: Value(50000)));
  final milk = await f.product('Молоко 1л', price: 12000, cost: 9000, stock: 1);
  await (f.db.update(f.db.products)..where((p) => p.id.equals(milk.id)))
      .write(ProductsCompanion(minStock: const Value(10), supplierId: Value(sid)));
  await repo.saveDraftOrder(supplierId: sid, lines: [PoLineInput(productId: milk.id, qty: 20, unitCost: 9000)]);
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
    child: const MaterialApp(home: PurchasingScreen()),
  ));
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester, Fixture f) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
  await f.db.close();
}

void main() {
  testWidgets('desktop: suppliers master-detail, orders, reorder, prices', (tester) async {
    final f = (await tester.runAsync(_seed))!;
    await _pump(tester, f, const Size(1440, 900));

    expect(find.text('Закупки'), findsOneWidget);
    expect(find.text('Молочный завод'), findsOneWidget);
    expect(find.text('Выберите поставщика'), findsOneWidget);

    await tester.tap(find.text('Молочный завод'));
    await _settle(tester);
    expect(find.text('Наш долг поставщику'), findsOneWidget);
    expect(find.text('Оплатить'), findsOneWidget);

    // Payment dialog: overpay asks for confirmation.
    await tester.tap(find.text('Оплатить'));
    await _settle(tester);
    expect(find.text('Оплата поставщику'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Сумма *'), '20000');
    await tester.tap(find.text('Оплатить').last);
    await _settle(tester);
    final s = await tester.runAsync(() => f.db.select(f.db.suppliers).getSingle());
    expect(s!.balance, 30000);

    await tester.tap(_tab('Заказы'));
    await _settle(tester);
    expect(find.textContaining('№1 · Молочный завод'), findsOneWidget);
    await tester.tap(find.textContaining('№1 · Молочный завод'));
    await _settle(tester);
    expect(find.text('Заказ №1'), findsOneWidget);
    expect(find.text('Отметить заказанным'), findsOneWidget);
    await tester.tap(find.text('Отметить заказанным'));
    await _settle(tester);
    final o = await tester.runAsync(() => f.db.select(f.db.purchaseOrders).getSingle());
    expect(o!.status, 'ordered');

    await tester.tap(_tab('Автозаказ'));
    await _settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await _settle(tester);
    // Stock 1 + 20 on order >= min 10 -> nothing to order.
    expect(find.text('Заказывать нечего'), findsOneWidget);

    await tester.tap(_tab('Закупочные цены'));
    await _settle(tester);
    expect(find.text('Приходов за период нет'), findsOneWidget);

    await _dispose(tester, f);
  });

  testWidgets('phone width renders all tabs', (tester) async {
    final f = (await tester.runAsync(_seed))!;
    await _pump(tester, f, const Size(380, 800));
    expect(find.text('Молочный завод'), findsOneWidget);
    for (final tab in ['Заказы', 'Автозаказ', 'Закупочные цены', 'Поставщики']) {
      await _openTab(tester, tab);
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: tab);
    }
    await _dispose(tester, f);
  });

  testWidgets('phone 360: supplier page, payment dialog, reorder without supplier, receiving', (tester) async {
    final f = (await tester.runAsync(() async {
      final f = await _seed();
      // A low-stock product without a supplier -> «Без поставщика» group.
      final salt = await f.product('Соль поваренная йодированная мелкого помола 1 кг', cost: 300, stock: 0);
      await (f.db.update(f.db.products)..where((p) => p.id.equals(salt.id)))
          .write(const ProductsCompanion(minStock: Value(12)));
      final o = await f.db.select(f.db.purchaseOrders).getSingle();
      await PurchasingRepo(f.db, StockService(f.db)).markOrdered(o.id);
      return f;
    }))!;
    await _pump(tester, f, const Size(360, 740));

    await tester.tap(find.text('Молочный завод'));
    await _settle(tester);
    expect(find.text('Наш долг поставщику'), findsOneWidget);
    await tester.tap(find.text('Оплатить'));
    await _settle(tester);
    await tester.tap(find.text('Наличные'));
    await _settle(tester);
    expect(find.textContaining('выплата из кассы смены'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Закрыть'));
    await _settle(tester);
    await tester.pageBack();
    await _settle(tester);

    await _openTab(tester, 'Заказы');
    await _settle(tester);
    await tester.tap(find.textContaining('№1 · Молочный завод'));
    await _settle(tester);
    await tester.tap(find.text('Принять товар'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);
    expect(find.text('Приёмка по заказу №1'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Принято'), '5');
    await _settle(tester);
    await tester.tap(find.text('Принять').last);
    await _settle(tester);
    expect(find.text('Принять товар?'), findsOneWidget);
    await tester.tap(find.text('Принять').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);
    final item = await tester.runAsync(() => f.db.select(f.db.purchaseOrderItems).getSingle());
    expect(item!.receivedQty, 5);
    final sup = await tester.runAsync(() => f.db.select(f.db.suppliers).getSingle());
    expect(sup!.balance, 50000 + 5 * 9000);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await _settle(tester);

    await _openTab(tester, 'Автозаказ');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await _settle(tester);
    expect(find.text('Без поставщика'), findsOneWidget);
    expect(find.text('Заказать у поставщика'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester, f);
  });
}
