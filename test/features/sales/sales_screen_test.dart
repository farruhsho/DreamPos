import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/sales/sales_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

class _LoggedIn extends SessionNotifier {
  _LoggedIn(this.user);
  final User user;
  @override
  Session? build() => Session(user);
}

void main() {
  late Fixture f;
  late Sale sale;
  Future<void> seed() async {
    f = await Fixture.create();
    final p = await f.product('Наушники', price: 25000, stock: 5);
    final r = await SaleService(f.db).checkout(
      CheckoutRequest(
        lines: [CheckoutLine(productId: p.id, qty: 2, unitPrice: 25000)],
        payments: [PaymentInput('cash', 60000)],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ),
    );
    sale = r.sale;
  }

  setUp(seed);

  Future<void> pump(WidgetTester tester, Size size) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(f.db), sessionProvider.overrideWith(() => _LoggedIn(f.owner))],
        child: const MaterialApp(home: SalesScreen()),
      ),
    );
    await settle(tester);
  }

  Future<void> cleanup(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 2);
    await tester.runAsync(f.db.close);
  }

  testWidgets('wide: list, detail and full return through the wizard', (tester) async {
    await pump(tester, const Size(1400, 1000));

    expect(find.text('№${sale.number}'), findsOneWidget);
    expect(find.text('Выберите чек'), findsOneWidget);

    await tester.tap(find.text('№${sale.number}'));
    await settle(tester);
    expect(find.text('Чек №${sale.number}'), findsOneWidget);
    expect(find.text('Наушники'), findsOneWidget);
    expect(find.text('Сдача'), findsOneWidget);

    // open the return wizard
    await tester.tap(find.text('Возврат'));
    await settle(tester);
    expect(find.textContaining('Возврат по чеку'), findsOneWidget);
    await tester.tap(find.text('Вернуть всё'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('return-total'))).data, Money.format(50000));

    await tester.tap(find.text('Не подошёл'));
    await tester.pump();
    await tester.tap(find.text('Оформить возврат'));
    await settle(tester);
    // confirmation dialog
    await tester.tap(find.text('Оформить возврат').last);
    await settle(tester);
    expect(find.textContaining('оформлен'), findsOneWidget);
    await tester.tap(find.text('Готово'));
    await settle(tester);

    final rets = await tester.runAsync(() => f.db.select(f.db.returns).get());
    expect(rets!.single.total, 50000);
    expect(rets.single.reason, 'Не подошёл');
    expect(find.text('Возвращён'), findsWidgets);

    // returns tab
    await tester.tap(find.text('Возвраты').first);
    await settle(tester);
    expect(find.textContaining('Возврат №${rets.single.number}'), findsWidgets);

    await cleanup(tester);
  });

  testWidgets('narrow: tap opens detail page; void is offered in the same shift', (tester) async {
    await pump(tester, const Size(390, 800));

    await tester.tap(find.text('№${sale.number}'));
    await settle(tester);
    expect(find.text('Чек №${sale.number}'), findsOneWidget);
    final voidBtn = find.widgetWithText(OutlinedButton, 'Аннулировать');
    await tester.scrollUntilVisible(voidBtn, 100, scrollable: find.byType(Scrollable).last);
    expect(tester.widget<OutlinedButton>(voidBtn).onPressed, isNotNull);

    await cleanup(tester);
  });

  testWidgets('cashier: only the current shift, no return / void actions', (tester) async {
    final cashier = await tester.runAsync(
      () => AuthService(f.db).createUser(name: 'Кассир', role: Role.cashier, pin: '4826'),
    );
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(f.db), sessionProvider.overrideWith(() => _LoggedIn(cashier!))],
        child: const MaterialApp(home: SalesScreen()),
      ),
    );
    await settle(tester);

    expect(find.textContaining('Показаны чеки текущей смены'), findsOneWidget);
    expect(find.text('Период'), findsNothing, reason: 'period filter hidden for restricted users');
    await tester.tap(find.text('№${sale.number}'));
    await settle(tester);
    expect(find.text('Чек №${sale.number}'), findsOneWidget);
    expect(find.text('Копия чека'), findsOneWidget);
    expect(find.text('Возврат'), findsNothing);
    expect(find.text('Аннулировать'), findsNothing);

    await tester.tap(find.text('Возвраты').first);
    await settle(tester);
    expect(find.textContaining('возвраты текущей смены'), findsOneWidget);
    await cleanup(tester);
  });

  testWidgets('wizard validates quantity and keeps the submit disabled without a selection', (tester) async {
    await pump(tester, const Size(1400, 1000));
    await tester.tap(find.text('№${sale.number}'));
    await settle(tester);
    await tester.tap(find.text('Возврат'));
    await settle(tester);
    // single line is prefilled with the whole quantity
    expect(tester.widget<Text>(find.byKey(const Key('return-total'))).data, Money.format(50000));
    final item = await tester.runAsync(() => f.db.select(f.db.saleItems).getSingle());
    await tester.enterText(find.byKey(Key('qty-${item!.id}')), '3');
    await tester.pump();
    expect(find.text('Не больше 2'), findsOneWidget);
    await tester.enterText(find.byKey(Key('qty-${item.id}')), '1,5');
    await tester.pump();
    expect(find.text('Только целое'), findsOneWidget);
    await tester.enterText(find.byKey(Key('qty-${item.id}')), '1');
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('return-total'))).data, Money.format(25000));
    await tester.tap(find.text('Сбросить'));
    await tester.pump();
    final submit = find.ancestor(
      of: find.text('Оформить возврат'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(submit.first).onPressed, isNull);
    await cleanup(tester);
  });

  testWidgets('360px phone: detail page and full-screen return wizard render without overflow', (tester) async {
    await pump(tester, const Size(360, 740));
    await tester.tap(find.text('№${sale.number}'));
    await settle(tester);
    await tester.tap(find.text('Возврат'));
    await settle(tester);
    expect(find.text('Возврат по чеку №${sale.number}'), findsOneWidget);
    expect(find.byKey(const Key('return-total')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });

  testWidgets('empty state when there are no sales', (tester) async {
    await tester.runAsync(() async {
      await f.db.delete(f.db.salePayments).go();
      await f.db.delete(f.db.saleItems).go();
      await f.db.delete(f.db.sales).go();
    });
    await pump(tester, const Size(1200, 900));
    expect(find.text('Чеков не найдено'), findsOneWidget);
    await cleanup(tester);
  });
}

/// Lets drift streams (real async) deliver, then rebuilds.
Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}
