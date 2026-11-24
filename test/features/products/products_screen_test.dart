import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/features/products/price_labels.dart';
import 'package:dreampos/features/products/product_logic.dart';
import 'package:dreampos/features/products/products_repo.dart';
import 'package:dreampos/features/products/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

class _TestSession extends SessionNotifier {
  _TestSession(this.user);
  final User user;
  @override
  Session? build() => Session(user);
}

Widget _app(AppDatabase db, User user) => ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sessionProvider.overrideWith(() => _TestSession(user)),
      ],
      child: const MaterialApp(home: ProductsScreen()),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('empty catalog shows empty state with create/import actions', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = memoryDb();
    addTearDown(db.close);
    final owner = await AuthService(db).createUser(name: 'Owner', role: Role.owner, pin: '2580');

    await tester.pumpWidget(_app(db, owner));
    await _settle(tester);
    expect(find.text('Каталог пуст'), findsOneWidget);
    expect(find.text('Импорт CSV'), findsOneWidget);
    expect(find.text('Новый товар'), findsWidgets);
    await _dispose(tester);
  });

  testWidgets('lists products, opens detail on wide screen, creates a product', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = memoryDb();
    addTearDown(db.close);
    final owner = await AuthService(db).createUser(name: 'Owner', role: Role.owner, pin: '2580');
    final repo = ProductsRepo(db);
    final cat = await repo.saveCategory(name: 'Молочные', color: categoryPalette[1]);
    await repo.saveProduct(
        ProductDraft(name: 'Молоко 1 л', price: 12000, costPrice: 9000, categoryId: cat, initialStock: 0),
        userId: owner.id);
    await repo.saveProduct(ProductDraft(name: 'Хлеб', price: 3000, costPrice: 2000, initialStock: 5),
        userId: owner.id);

    await tester.pumpWidget(_app(db, owner));
    await _settle(tester);
    expect(find.text('Молоко 1 л'), findsOneWidget);
    expect(find.text('Хлеб'), findsOneWidget);
    expect(find.text('Себест.'), findsOneWidget, reason: 'owner sees cost column');

    // Open detail (master-detail on wide screens)
    await tester.tap(find.text('Хлеб'));
    await _settle(tester);
    expect(find.text('Характеристики'), findsOneWidget);
    expect(find.text('Движение товара'), findsOneWidget);
    expect(find.text('Начальный остаток'), findsOneWidget);

    // Create a new product through the editor dialog
    await tester.tap(find.text('Новый товар').first);
    await _settle(tester);
    expect(find.text('Основное'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Название *'), 'Кефир');
    await tester.enterText(find.widgetWithText(TextFormField, 'Розничная цена *'), '8000');
    await tester.tap(find.text('Создать товар'));
    await _settle(tester);
    expect(find.text('Основное'), findsNothing, reason: 'dialog closed');
    final all = await repo.listProducts(const ProductQuery(limit: 0));
    expect(all.map((p) => p.name), contains('Кефир'));
    expect(find.text('Кефир'), findsWidgets);
    await _dispose(tester);
  });

  testWidgets('cashier on phone: no cost column, no create button; search filters', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = memoryDb();
    addTearDown(db.close);
    final cashier = await AuthService(db).createUser(name: 'Cashier', role: Role.cashier, pin: '1357');
    final repo = ProductsRepo(db);
    await repo.saveProduct(ProductDraft(name: 'Молоко', price: 12000, costPrice: 9000));
    await repo.saveProduct(ProductDraft(name: 'Хлеб', price: 3000));

    await tester.pumpWidget(_app(db, cashier));
    await _settle(tester);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Себест.'), findsNothing);
    expect(find.text('Молоко'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'хлеб');
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);
    expect(find.text('Молоко'), findsNothing);
    expect(find.text('Хлеб'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('import via paste, bulk price change, categories manager', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = memoryDb();
    addTearDown(db.close);
    final owner = await AuthService(db).createUser(name: 'Owner', role: Role.owner, pin: '2580');
    final repo = ProductsRepo(db);

    await tester.pumpWidget(_app(db, owner));
    await _settle(tester);

    // --- import
    await tester.tap(find.byTooltip('Ещё').first);
    await _settle(tester);
    await tester.tap(find.text('Импорт из CSV'));
    await _settle(tester);
    final paste = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)).first;
    await tester.enterText(paste, 'name;barcode;category;price;unit;stock\nМолоко;111;Молочные;10000;шт;5\nКефир;222;Молочные;8050;шт;\n;333;;1;;');
    await tester.tap(find.text('Проверить'));
    await _settle(tester);
    expect(find.text('Новых: 2'), findsOneWidget);
    expect(find.text('Ошибка'), findsOneWidget);
    await tester.tap(find.text('Импортировать 2'));
    await _settle(tester);
    var all = await repo.listProducts(const ProductQuery(limit: 0));
    expect(all.map((p) => p.name).toSet(), {'Молоко', 'Кефир'});
    expect(all.firstWhere((p) => p.name == 'Молоко').stockQty, 5);
    expect(find.text('Молоко'), findsOneWidget);

    // --- bulk price +10% rounded to 100
    await tester.longPress(find.text('Молоко'));
    await _settle(tester);
    await tester.tap(find.byType(Checkbox).first); // header: select all
    await _settle(tester);
    expect(find.text('Выбрано: 2'), findsOneWidget);
    await tester.tap(find.text('Цены, %'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Изменение, %'), '10');
    await _settle(tester);
    expect(find.text('Применить к 2'), findsOneWidget);
    await tester.tap(find.text('Применить к 2'));
    await _settle(tester);
    await tester.tap(find.text('Изменить цены'));
    await _settle(tester);
    all = await repo.listProducts(const ProductQuery(limit: 0));
    expect({for (final p in all) p.name: p.price}, {'Молоко': 11000, 'Кефир': 8900});

    // --- categories manager lists the imported category
    await tester.tap(find.text('Категории'));
    await _settle(tester);
    expect(find.text('Молочные'), findsWidgets);
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Товаров: 2')), findsOneWidget);
    await tester.tap(find.byTooltip('Закрыть'));
    await _settle(tester);
    await _dispose(tester);
  });

  testWidgets('scanner Enter by SKU opens detail; storekeeper edits without price right', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = memoryDb();
    addTearDown(db.close);
    final keeper = await AuthService(db).createUser(name: 'Keeper', role: Role.storekeeper, pin: '4680');
    final repo = ProductsRepo(db);
    await repo.saveProduct(ProductDraft(name: 'Гвозди', price: 5000, costPrice: 3000, sku: 'GV-7'));
    await repo.saveProduct(ProductDraft(name: 'Шурупы', price: 7000));

    await tester.pumpWidget(_app(db, keeper));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).first, 'GV-7');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);
    expect(find.text('Характеристики'), findsOneWidget, reason: 'detail opened by exact SKU');

    await tester.tap(find.text('Изменить'));
    await _settle(tester);
    expect(find.text('Нет права менять цены'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Розничная цена *'), findsNothing);
    await tester.enterText(find.widgetWithText(TextFormField, 'Название *'), 'Гвозди 100 мм');
    await tester.tap(find.text('Сохранить'));
    await _settle(tester);
    final p = (await repo.listProducts(const ProductQuery(search: 'GV-7'))).single;
    expect(p.name, 'Гвозди 100 мм');
    expect(p.price, 5000);
    await _dispose(tester);
  });

  testWidgets('phone: editor opens as a full page; closing with changes asks first',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = memoryDb();
    addTearDown(db.close);
    final owner = await AuthService(db).createUser(name: 'Owner', role: Role.owner, pin: '2580');
    await ProductsRepo(db).saveProduct(
        ProductDraft(name: 'Очень длинное название товара для проверки переноса строк', price: 1234500,
            costPrice: 1000000, barcode: '4006381333931', sku: 'LONG-SKU-0001', initialStock: 3),
        userId: owner.id);

    await tester.pumpWidget(_app(db, owner));
    await _settle(tester);
    expect(tester.takeException(), isNull, reason: 'list fits 360px');
    await tester.tap(find.byType(FloatingActionButton));
    await _settle(tester);
    expect(find.text('Новый товар'), findsWidgets);
    expect(find.text('Создать товар'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'editor fits 360px');
    await tester.enterText(find.widgetWithText(TextFormField, 'Название *'), 'Черновик');
    await _settle(tester);
    await tester.tap(find.byTooltip('Закрыть'));
    await _settle(tester);
    expect(find.text('Закрыть без сохранения?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await _settle(tester);
    expect(find.text('Создать товар'), findsOneWidget, reason: 'editor still open');
    await tester.tap(find.byTooltip('Закрыть'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Закрыть'));
    await _settle(tester); // confirm dialog closes
    await _settle(tester); // page route pop transition
    expect(find.text('Создать товар'), findsNothing, reason: 'discarded');

    // Detail opens as its own page on phones.
    await tester.tap(find.textContaining('Очень длинное'));
    await _settle(tester);
    expect(find.text('Характеристики'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'detail fits 360px');
    await _dispose(tester);
  });

  testWidgets('price labels PDF is generated with bundled fonts', (tester) async {
    final f = await Fixture.create();
    addTearDown(f.db.close);
    final a = await f.product('Молоко', price: 12000);
    final withCode = a.copyWith(barcode: Value(Ean13.internal(7)));
    final b = await f.product('Хлеб', price: 3000);
    final bytes = await tester.runAsync(() => buildPriceLabelsPdf([withCode, b],
        copies: 13, layout: LabelLayout.medium, storeName: 'Магазин'));
    expect(bytes, isNotNull);
    expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
    expect(labelBarcode(Ean13.internal(7)), isNotNull);
    expect(labelBarcode('ABC-1'), isNotNull);
    expect(labelBarcode('Код'), isNull);
  });
}
