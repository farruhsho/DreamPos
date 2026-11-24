// POS action «Продать сертификат» (D-023): opens the shared marketing dialog,
// sells a certificate as an advance and leaves the basket alone.
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/pos/cart_controller.dart';
import 'package:dreampos/features/pos/pos_screen.dart';
import 'package:flutter/material.dart';
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pumpPos(
    WidgetTester tester,
    Fixture f, {
    Size size = const Size(1400, 900),
    User? user,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(f.db),
        sessionProvider.overrideWith(() => _TestSession(user ?? f.owner)),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PosScreen()),
      ),
    );
    await _settle(tester);
    return container;
  }

  Future<void> tearDownWidgets(WidgetTester tester, Fixture f, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => f.db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openMenuItem(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Действия с чеком').first);
    await _settle(tester);
  }

  testWidgets('menu → dialog → cash sale with change; basket untouched', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final p = (await tester.runAsync(() => f.product('Хлеб', price: 4000)))!;
    final c = await pumpPos(tester, f);
    c.read(cartProvider.notifier).addProduct(p);
    await _settle(tester);

    await openMenuItem(tester);
    await tester.tap(find.text('Продать сертификат'));
    await _settle(tester);
    expect(find.text('Продажа сертификата'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('gift-sale-amount')), '100000');
    await tester.enterText(find.byKey(const Key('gift-sale-tendered')), '120000');
    await _settle(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await _settle(tester);
    await tester.ensureVisible(find.byKey(const Key('gift-sale-submit')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('gift-sale-submit')));
    await _settle(tester);
    await _settle(tester);

    expect(find.text('Сертификат продан'), findsOneWidget);
    expect(find.text(Money.format(Money.parse('20000')!)), findsOneWidget);
    await tester.tap(find.text('Готово'));
    await _settle(tester);

    final sales = (await tester.runAsync(() => f.db.select(f.db.giftCardSales).get()))!;
    expect(sales.single.amount, Money.parse('100000'));
    expect(sales.single.changeDue, Money.parse('20000'));
    expect(sales.single.shiftId, f.shift.id);
    expect((await tester.runAsync(() => f.db.select(f.db.sales).get()))!, isEmpty);
    expect(c.read(cartProvider).lines, hasLength(1), reason: 'the basket stays as it was');
    await tearDownWidgets(tester, f, c);
  });

  testWidgets('no shift: item stays tappable with a reason and offers to open one', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    await tester.runAsync(() => ShiftService(f.db).close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 10000));
    final c = await pumpPos(tester, f);
    await openMenuItem(tester);
    final item = tester.widget<PopupMenuItem<String>>(
      find.ancestor(of: find.text('Продать сертификат'), matching: find.byType(PopupMenuItem<String>)),
    );
    expect(item.enabled, isTrue);
    expect(find.text('Нужна открытая смена'), findsOneWidget);
    await tester.tap(find.text('Продать сертификат'));
    await _settle(tester);
    expect(find.text('Откройте смену, чтобы продать сертификат.'), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Открыть смену')), findsOneWidget);
    expect(find.text('Продажа сертификата'), findsNothing);
    await tester.tap(find.text('Отмена'));
    await _settle(tester);
    await tearDownWidgets(tester, f, c);
  });

  testWidgets('menu item disabled with a reason without Perm.sell', (tester) async {
    final f2 = (await tester.runAsync(Fixture.create))!;
    expect(Role.values.where((r) => !r.can(Perm.sell)), isNotEmpty, reason: 'some role cannot sell');
    final noSell = Role.values.firstWhere((r) => !r.can(Perm.sell));
    final u = (await tester.runAsync(() => AuthService(f2.db).createUser(name: 'X', role: noSell, pin: '1470')))!;
    final c2 = await pumpPos(tester, f2, user: u);
    await openMenuItem(tester);
    final item2 = tester.widget<PopupMenuItem<String>>(
      find.ancestor(of: find.text('Продать сертификат'), matching: find.byType(PopupMenuItem<String>)),
    );
    expect(item2.enabled, isFalse);
    expect(find.text('Нет права продавать'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await _settle(tester);
    await tearDownWidgets(tester, f2, c2);
  });

  testWidgets('phone: cart page menu opens the dialog', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final c = await pumpPos(tester, f, size: const Size(390, 844));
    await tester.tap(find.byKey(const Key('pos-open-cart')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('pos-cart-menu')));
    await _settle(tester);
    await tester.tap(find.text('Продать сертификат'));
    await _settle(tester);
    expect(find.text('Продажа сертификата'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Закрыть').last);
    await _settle(tester);
    await tearDownWidgets(tester, f, c);
  });
}
