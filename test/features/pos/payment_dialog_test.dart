// Widget tests of the payment dialog alone (it does not depend on printing,
// so it compiles even while the printing packages are broken).
import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/pos/cart_controller.dart';
import 'package:dreampos/features/pos/widgets/payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  Future<(ProviderContainer, List<CheckoutResult?>)> pumpDialog(
      WidgetTester tester, Fixture f, CartState cart, int total) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(f.db)]);
    final results = <CheckoutResult?>[];
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () async {
                results.add(await showDialog<CheckoutResult>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => PaymentDialog(
                      cart: cart, total: total, cashierId: f.owner.id, shiftId: f.shift.id),
                ));
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await _settle(tester);
    return (container, results);
  }

  Future<void> finish(WidgetTester tester, Fixture f, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => f.db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await tester.pump(const Duration(seconds: 1));
  }

  CartState cartOf(Product p, double qty) {
    final c = ProviderContainer();
    c.read(cartProvider.notifier).addProduct(p, qty: qty);
    final s = c.read(cartProvider);
    c.dispose();
    return s;
  }

  testWidgets('card in one tap, Enter confirms once; stock decreases', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() => f.product('Наушники', price: 25000, stock: 3)))!;
    final (c, results) = await pumpDialog(tester, f, cartOf(p, 2), 50000);

    expect(find.byKey(const Key('pay-total')), findsOneWidget);
    await tester.tap(find.text('Картой'));
    await tester.pump();
    // nothing is left to pay in cash
    expect(tester.widget<Text>(find.byKey(const Key('pay-change'))).data, contains('0'));

    // Enter twice quickly (focus is back in the cash field): exactly one sale
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);

    expect(results.single, isNotNull);
    final sales = (await tester.runAsync(() => f.db.select(f.db.sales).get()))!;
    expect(sales, hasLength(1));
    final pays = (await tester.runAsync(() => f.db.select(f.db.salePayments).get()))!;
    expect(pays.single.method, 'card');
    expect(pays.single.amount, 50000);
    expect((await tester.runAsync(() => f.reload(p)))!.stockQty, 1);
    await finish(tester, f, c);
  });

  testWidgets('not enough cash keeps the dialog open with a clear message', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() => f.product('Чай', price: 7000)))!;
    final (c, results) = await pumpDialog(tester, f, cartOf(p, 1), 7000);

    await tester.enterText(find.byKey(const Key('pay-cash')), '5000');
    await tester.pump();
    expect(find.textContaining('Не хватает'), findsWidgets);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('pay-confirm'))).onPressed, isNull);
    expect(results, isEmpty);
    await finish(tester, f, c);
  });

  testWidgets('gift card: code is validated, balance shown, card is charged', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() async {
      await f.db.into(f.db.giftCards).insert(GiftCardsCompanion.insert(
          id: newId(), code: 'GC-100', initialAmount: 10000, balance: 10000));
      await f.db.into(f.db.giftCards).insert(GiftCardsCompanion.insert(
          id: newId(), code: 'GC-OLD', initialAmount: 10000, balance: 0, status: const Value('used')));
      return f.product('Книга', price: 15000);
    }))!;
    final (c, results) = await pumpDialog(tester, f, cartOf(p, 1), 15000);

    await tester.tap(find.text('Смешанная оплата'));
    await tester.pump();
    final codeField = find.widgetWithText(TextField, 'Код сертификата');

    await tester.enterText(codeField, 'GC-OLD');
    await tester.tap(find.text('Проверить'));
    await _settle(tester);
    expect(find.textContaining('не активен'), findsOneWidget);

    await tester.enterText(codeField, 'GC-100');
    await tester.tap(find.text('Проверить'));
    await _settle(tester);
    expect(find.textContaining('Баланс'), findsWidgets);
    // the rest (5000) remains in cash, prefilled
    await tester.tap(find.byKey(const Key('pay-confirm')));
    await _settle(tester);

    expect(results.single, isNotNull);
    final card = (await tester.runAsync(() =>
        (f.db.select(f.db.giftCards)..where((g) => g.code.equals('GC-100'))).getSingle()))!;
    expect(card.balance, 0);
    expect(card.status, 'used');
    await finish(tester, f, c);
  });
}
