import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/features/pos/cart_controller.dart';
import 'package:dreampos/features/pos/pos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers.dart';

class _TestSession extends SessionNotifier {
  _TestSession(this.user);
  final User user;
  @override
  Session? build() => Session(user);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

final _containers = <Fixture, ProviderContainer>{};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(ProviderContainer, Fixture)> pumpPos(WidgetTester tester, Fixture f,
      {Size size = const Size(1400, 900), User? user}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(f.db),
      sessionProvider.overrideWith(() => _TestSession(user ?? f.owner)),
    ]);
    _containers[f] = container;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PosScreen()),
    ));
    await _settle(tester);
    return (container, f);
  }

  Future<void> tearDownWidgets(WidgetTester tester, Fixture f) async {
    await tester.pumpWidget(const SizedBox());
    _containers.remove(f)?.dispose();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => f.db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('scan -> cart -> pay cash -> stock decreased', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() async {
      final p = await f.product('Хлеб белый', price: 4000, stock: 10);
      await (f.db.update(f.db.products)..where((t) => t.id.equals(p.id)))
          .write(const ProductsCompanion(barcode: Value('4780000000011')));
      return p;
    }))!;
    final (container, _) = await pumpPos(tester, f);

    expect(find.text('Хлеб белый'), findsOneWidget); // product tile
    expect(find.text('Чек пуст'), findsOneWidget);

    // scanner: "2*" multiplier + code + Enter
    await tester.enterText(find.byKey(const Key('pos-search')), '2*4780000000011');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);
    expect(container.read(cartProvider).lines.single.qty, 2);
    expect(find.byKey(Key('qty-${p.id}')), findsOneWidget);

    // unknown code -> error, cart unchanged
    await tester.enterText(find.byKey(const Key('pos-search')), '999999999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);
    expect(find.textContaining('не найден'), findsWidgets);
    expect(container.read(cartProvider).lines, hasLength(1));

    // let the error toast disappear, then pay
    await tester.pump(const Duration(seconds: 6));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('pos-pay')));
    await _settle(tester);
    expect(find.byKey(const Key('pay-total')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pay-cash')), '10000');
    await tester.pump();
    expect(
        tester.widget<Text>(find.byKey(const Key('pay-change'))).data, contains(Money.format(2000, withSymbol: false)));
    await tester.tap(find.byKey(const Key('pay-confirm')));
    await _settle(tester);

    expect(find.byKey(const Key('success-change')), findsOneWidget);
    expect(container.read(cartProvider).isEmpty, isTrue);
    final after = (await tester.runAsync(() => f.reload(p)))!;
    expect(after.stockQty, 8);

    await tester.tap(find.text('Новая продажа (Enter)'));
    await _settle(tester);
    expect(find.byKey(const Key('success-change')), findsNothing);

    await tearDownWidgets(tester, f);
  });

  testWidgets('no open shift shows banner and opens a shift', (tester) async {
    final f = (await tester.runAsync(() async {
      final db = memoryDb();
      final fx = Fixture(db);
      fx.owner = await AuthService(db).createUser(name: 'Owner', role: Role.owner, pin: '2580');
      await fx.product('Вода', price: 3000);
      return fx;
    }))!;
    final (container, _) = await pumpPos(tester, f);
    expect(find.byKey(const Key('pos-open-shift')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pos-open-shift')));
    await _settle(tester);
    await tester.tap(find.text('Открыть смену').last);
    await _settle(tester);
    expect(find.byKey(const Key('pos-open-shift')), findsNothing);
    final shift = await tester.runAsync(() => container.read(shiftServiceProvider).currentShift());
    expect(shift, isNotNull);

    await tearDownWidgets(tester, f);
  });

  testWidgets('narrow layout shows bottom bar with total', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    await tester.runAsync(() => f.product('Сок', price: 7000));
    await pumpPos(tester, f, size: const Size(380, 800));

    expect(find.byKey(const Key('pos-open-cart')), findsOneWidget);
    await tester.tap(find.text('Сок'));
    await _settle(tester);
    expect(tester.widget<Text>(find.byKey(const Key('bottom-total'))).data, contains(Money.format(7000, withSymbol: false)));

    await tester.tap(find.byKey(const Key('pos-open-cart')));
    await _settle(tester);
    expect(find.byKey(const Key('pos-pay')), findsOneWidget);

    await tearDownWidgets(tester, f);
  });

  testWidgets('discount above cashier limit needs manager PIN, then sells', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final (cashier, p) = (await tester.runAsync(() async {
      final auth = AuthService(f.db);
      final cashier = await auth.createUser(
          name: 'Кассир', role: Role.cashier, pin: '1357', maxDiscountPercent: 5);
      await auth.createUser(name: 'Менеджер', role: Role.manager, pin: '2468', maxDiscountPercent: 20);
      return (cashier, await f.product('Пальто', price: 100000, stock: 2));
    }))!;
    final (container, _) = await pumpPos(tester, f, user: cashier);

    await tester.tap(find.text('Пальто'));
    await _settle(tester);
    await tester.tap(find.byTooltip('Скидка на позицию'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Скидка, %'), '10');
    await tester.pump();
    expect(find.textContaining('потребуется PIN менеджера'), findsOneWidget);
    await tester.tap(find.text('Применить'));
    await _settle(tester);

    // manager PIN pad
    expect(find.text('Подтверждение менеджера'), findsOneWidget);
    for (final d in ['2', '4', '6', '8']) {
      await tester.tap(find.widgetWithText(OutlinedButton, d));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await _settle(tester);
    expect(find.text('Подтверждение менеджера'), findsNothing);
    final cart = container.read(cartProvider);
    expect(cart.lines.single.manualDiscount, 10000);
    expect(cart.approverId, isNotNull);

    await tester.tap(find.byKey(const Key('pos-pay')));
    await _settle(tester);
    expect(tester.widget<Text>(find.byKey(const Key('pay-total'))).data,
        contains(Money.format(90000, withSymbol: false)));
    await tester.tap(find.byKey(const Key('pay-confirm')));
    await _settle(tester);
    expect(find.byKey(const Key('success-change')), findsOneWidget);
    final sale = (await tester.runAsync(() => f.db.select(f.db.sales).getSingle()))!;
    expect(sale.total, 90000);
    expect(sale.cashierId, cashier.id);

    await tester.tap(find.text('Новая продажа (Enter)'));
    await _settle(tester);
    await tearDownWidgets(tester, f);
  });

  Future<void> sellOne(WidgetTester tester, String name) async {
    await tester.tap(find.text(name).first);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('pos-pay')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('pay-confirm')));
    await _settle(tester);
    expect(find.byKey(const Key('success-change')), findsOneWidget);
  }

  Future<void> typeKeys(WidgetTester tester, String s) async {
    for (final ch in s.split('')) {
      await tester.sendKeyEvent(LogicalKeyboardKey(ch.codeUnitAt(0)), character: ch);
    }
  }

  testWidgets('scan while the sale-success dialog is open starts the next sale', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() async {
      final p = await f.product('Хлеб белый', price: 4000, stock: 10);
      await (f.db.update(f.db.products)..where((t) => t.id.equals(p.id)))
          .write(const ProductsCompanion(barcode: Value('4780000000011')));
      return p;
    }))!;
    final (container, _) = await pumpPos(tester, f);
    await sellOne(tester, 'Хлеб белый');

    // scanner: digits + Enter arrive while the dialog is still open
    await typeKeys(tester, '4780000000011');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.byKey(const Key('success-change')), findsNothing);
    expect(container.read(cartProvider).lines.single.productId, p.id);
    expect(tester.widget<TextField>(find.byKey(const Key('pos-search'))).controller!.text, isEmpty);
    await tearDownWidgets(tester, f);
  });

  testWidgets('Enter alone closes the success dialog; typed digits go to the search field',
      (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    await tester.runAsync(() => f.product('Вода', price: 3000));
    final (container, _) = await pumpPos(tester, f);

    await sellOne(tester, 'Вода');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.byKey(const Key('success-change')), findsNothing);
    expect(container.read(cartProvider).isEmpty, isTrue);

    await sellOne(tester, 'Вода');
    await typeKeys(tester, '478');
    await tester.tap(find.text('Новая продажа (Enter)'));
    await _settle(tester);
    expect(find.byKey(const Key('success-change')), findsNothing);
    final search = find.byKey(const Key('pos-search'));
    expect(tester.widget<TextField>(search).controller!.text, '478');
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
    expect(container.read(cartProvider).isEmpty, isTrue);
    await tearDownWidgets(tester, f);
  });

  testWidgets('register bound to the device is used for the shift and the sale', (tester) async {
    final (f, regId) = (await tester.runAsync(() async {
      final db = memoryDb();
      final fx = Fixture(db);
      fx.owner = await AuthService(db).createUser(name: 'Owner', role: Role.owner, pin: '2580');
      await fx.product('Вода', price: 3000);
      final id = newId();
      await db.into(db.registers).insert(RegistersCompanion.insert(id: id, name: 'Касса 1'));
      return (fx, id);
    }))!;
    SharedPreferences.setMockInitialValues({'register_id': regId});
    final (container, _) = await pumpPos(tester, f);

    await tester.tap(find.byKey(const Key('pos-open-shift')));
    await _settle(tester);
    await tester.tap(find.text('Открыть смену').last);
    await _settle(tester);
    final shift = (await tester.runAsync(() => container.read(shiftServiceProvider).currentShift()))!;
    expect(shift.registerId, regId);

    // let the "shift opened" toast disappear (it covers the pay button)
    await tester.pump(const Duration(seconds: 6));
    await _settle(tester);
    await sellOne(tester, 'Вода');
    final sale = (await tester.runAsync(() => f.db.select(f.db.sales).getSingle()))!;
    expect(sale.registerId, regId);
    await tester.tap(find.text('Новая продажа (Enter)'));
    await _settle(tester);
    await tearDownWidgets(tester, f);
  });
}
