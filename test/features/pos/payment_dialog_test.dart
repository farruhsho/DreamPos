// Widget tests of the payment dialog alone (it does not depend on printing,
// so it compiles even while the printing packages are broken).
import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/widgets/widgets.dart';
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
      WidgetTester tester, Fixture f, CartState cart, int total, {Customer? customer}) async {
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
                      cart: cart,
                      total: total,
                      cashierId: f.owner.id,
                      shiftId: f.shift.id,
                      customer: customer),
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

  CartState cartOf(Product p, double qty, {Customer? customer}) {
    final c = ProviderContainer();
    c.read(cartProvider.notifier).addProduct(p, qty: qty);
    if (customer != null) c.read(cartProvider.notifier).setCustomer(customer);
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
          id: newId(), code: 'GC100', initialAmount: 10000, balance: 10000));
      await f.db.into(f.db.giftCards).insert(GiftCardsCompanion.insert(
          id: newId(), code: 'GCOLD', initialAmount: 10000, balance: 0, status: const Value('used')));
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
        (f.db.select(f.db.giftCards)..where((g) => g.code.equals('GC100'))).getSingle()))!;
    expect(card.balance, 0);
    expect(card.status, 'used');
    await finish(tester, f, c);
  });

  String text(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('cash rounding: cash-only shows and charges the rounded total', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() async {
      await f.db.setSetting('cash_rounding', '1000');
      return f.product('Сахар', price: 12500);
    }))!;
    final (c, results) = await pumpDialog(tester, f, cartOf(p, 1), 12500);

    expect(text(tester, 'pay-total'), contains(Money.format(12000, withSymbol: false)));
    expect(text(tester, 'pay-rounding'), 'Округление: −${Money.format(500)}');
    // cash is prefilled with the rounded amount: no change, nothing missing
    expect(tester.widget<TextFormField>(find.byKey(const Key('pay-cash'))).controller!.text,
        Money.toInput(12000));
    expect(text(tester, 'pay-change'), contains('0'));

    await tester.tap(find.byKey(const Key('pay-confirm')));
    await _settle(tester);
    expect(results.single!.sale.total, 12000);
    expect(results.single!.changeDue, 0);
    await finish(tester, f, c);
  });

  testWidgets('cash rounding: mixed payment uses the exact total', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() async {
      await f.db.setSetting('cash_rounding', '1000');
      return f.product('Сахар', price: 12500);
    }))!;
    final (c, results) = await pumpDialog(tester, f, cartOf(p, 1), 12500);
    expect(find.byKey(const Key('pay-rounding')), findsOneWidget);

    await tester.tap(find.text('Смешанная оплата'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Карта'), '5000');
    await tester.pump();
    expect(text(tester, 'pay-total'), contains(Money.format(12500, withSymbol: false)));
    expect(find.byKey(const Key('pay-rounding')), findsNothing);
    // the rest in cash follows the exact total
    expect(tester.widget<TextFormField>(find.byKey(const Key('pay-cash'))).controller!.text,
        Money.toInput(7500));

    // card removed again -> back to the rounded cash total
    await tester.enterText(find.widgetWithText(TextField, 'Карта'), '');
    await tester.pump();
    expect(text(tester, 'pay-total'), contains(Money.format(12000, withSymbol: false)));
    await tester.enterText(find.widgetWithText(TextField, 'Карта'), '5000');
    await tester.pump();

    await tester.tap(find.byKey(const Key('pay-confirm')));
    await _settle(tester);
    expect(results.single!.sale.total, 12500);
    final pays = (await tester.runAsync(() => f.db.select(f.db.salePayments).get()))!;
    expect({for (final p in pays) p.method: p.amount}, {'card': 5000, 'cash': 7500});
    await finish(tester, f, c);
  });

  testWidgets('cash rounding: change and quick tenders use the rounded total', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() async {
      await f.db.setSetting('cash_rounding', '1000');
      await f.db.setSetting('pos_banknotes', '5000,10000');
      return f.product('Сахар', price: 12500);
    }))!;
    final (c, results) = await pumpDialog(tester, f, cartOf(p, 1), 12500);

    // tenders are built from the rounded 12000: 15000 and 20000 (not 12500-based)
    expect(find.widgetWithText(ChoiceChip, Money.format(15000, withSymbol: false)), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, Money.format(20000, withSymbol: false)), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, Money.format(20000, withSymbol: false)));
    await tester.pump();
    expect(text(tester, 'pay-change'), Money.format(8000));

    await tester.tap(find.byKey(const Key('pay-confirm')));
    await _settle(tester);
    expect(results.single!.sale.total, 12000);
    expect(results.single!.changeDue, 8000);
    final pays = (await tester.runAsync(() => f.db.select(f.db.salePayments).get()))!;
    expect({for (final p in pays) p.method: p.amount}, {'cash': 12000});
    await finish(tester, f, c);
  });

  testWidgets('cash rounding off: no rounding line, exact total', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() => f.product('Сахар', price: 12500)))!;
    final (c, results) = await pumpDialog(tester, f, cartOf(p, 1), 12500);
    expect(find.byKey(const Key('pay-rounding')), findsNothing);
    expect(text(tester, 'pay-total'), contains(Money.format(12500, withSymbol: false)));
    await tester.tap(find.byKey(const Key('pay-confirm')));
    await _settle(tester);
    expect(results.single!.sale.total, 12500);
    await finish(tester, f, c);
  });

  testWidgets('quick tenders follow the pos_banknotes setting', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() async {
      await f.db.setSetting('pos_banknotes', '3000,7000');
      return f.product('Мука', price: 12500);
    }))!;
    final (c, _) = await pumpDialog(tester, f, cartOf(p, 1), 12500);
    // 12500 rounded up to 7000s and 3000s: 14000 and 15000
    expect(find.widgetWithText(ChoiceChip, Money.format(14000, withSymbol: false)), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, Money.format(15000, withSymbol: false)), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, Money.format(20000, withSymbol: false)), findsNothing);
    await finish(tester, f, c);
  });

  testWidgets('debt: due date picker (default +14 days) is sent with the sale', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final (p, cust) = (await tester.runAsync(() async =>
        (await f.product('Ковёр', price: 50000), await f.customer('Анвар', debtLimit: 100000))))!;
    final (c, results) = await pumpDialog(tester, f, cartOf(p, 1, customer: cust), 50000, customer: cust);

    await tester.tap(find.text('Смешанная оплата'));
    await tester.pump();
    expect(find.byKey(const Key('pay-debt-due')), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'В долг'), '20000');
    await tester.pump();
    expect(find.byKey(const Key('pay-debt-due')), findsOneWidget);
    final now = DateTime.now();
    final d14 = DateTime(now.year, now.month, now.day + 14);
    expect(find.text('до ${formatDate(d14)}'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '14 дн.')).selected, isTrue);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '30 дн.'));
    await tester.tap(find.widgetWithText(ChoiceChip, '30 дн.'));
    await tester.pump();
    final d30 = DateTime(now.year, now.month, now.day + 30);
    expect(find.text('до ${formatDate(d30)}'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pay-confirm')));
    await _settle(tester);
    final errs = find.byKey(const Key('pay-error'));
    expect(errs.evaluate().isEmpty ? null : tester.widget<Text>(errs).data, isNull);
    expect(results.single, isNotNull);
    final ledger = (await tester.runAsync(() => f.db.select(f.db.customerLedger).get()))!;
    final debt = ledger.singleWhere((l) => l.kind == 'debt_sale');
    expect(debt.dueDate, d30);
    await finish(tester, f, c);
  });
}
