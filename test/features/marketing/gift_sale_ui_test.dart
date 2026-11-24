// UI of gift card sales (D-023): the shared «Продажа сертификата» dialog,
// card detail with the sale document / void, the «Продажи» list.
import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/theme.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/marketing/gift_sale_dialog.dart';
import 'package:dreampos/features/marketing/gift_sales_list.dart';
import 'package:dreampos/features/marketing/gift_sales_logic.dart';
import 'package:dreampos/features/marketing/marketing_repo.dart';
import 'package:dreampos/features/marketing/marketing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers.dart';

class _LoggedIn extends SessionNotifier {
  _LoggedIn(this.user);
  final User user;
  @override
  Session? build() => Session(user);
}

int m(int major) => Money.parse('$major')!;

void main() {
  late Fixture f;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    f = await Fixture.create();
    await MarketingRepo(
      f.db,
    ).issueGiftCard(code: 'GIFTTEST2345', amount: m(100000), method: 'card', userId: f.owner.id, shiftId: f.shift.id);
  });

  Future<void> pump(WidgetTester tester, {Size size = const Size(1400, 900), User? user}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(f.db),
          sessionProvider.overrideWith(() => _LoggedIn(user ?? f.owner)),
        ],
        child: MaterialApp(theme: buildTheme(Brightness.light), home: const MarketingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сертификаты').first);
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await f.db.close();
  }

  Future<void> openIssue(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('gift-issue')));
    await tester.pumpAndSettle();
    expect(find.text('Продажа сертификата'), findsOneWidget);
  }

  Future<void> submit(WidgetTester tester) async {
    // a focused field scrolls itself back into view on every layout
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('gift-sale-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gift-sale-submit')));
    await tester.pumpAndSettle();
  }

  test('quick nominals: setting or defaults', () {
    expect(giftQuickNominals(null), [m(50000), m(100000), m(200000), m(500000)]);
    expect(giftQuickNominals('25 000, 75000;x'), [m(25000), m(75000)]);
    expect(giftQuickNominals(' , '), hasLength(4));
  });

  testWidgets('split sale with change: success dialog and document', (tester) async {
    await pump(tester);
    await openIssue(tester);
    // quick nominal
    await tester.tap(find.widgetWithText(ChoiceChip, Money.format(m(200000))));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Смешанная'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('gift-sale-card')), '50000');
    await tester.pumpAndSettle();
    expect(find.text(Money.format(m(150000))), findsOneWidget); // cash part
    await tester.enterText(find.byKey(const Key('gift-sale-tendered')), '160000');
    await tester.pumpAndSettle();
    expect(find.text('Сдача'), findsOneWidget);
    await submit(tester);

    expect(find.text('Сертификат продан'), findsOneWidget);
    expect(find.text('Продажа сертификата №2'), findsOneWidget);
    expect(find.byKey(const Key('gift-success-print')), findsOneWidget);
    expect(find.text(Money.format(m(10000))), findsOneWidget);
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();

    final sales = await f.db.select(f.db.giftCardSales).get();
    final sale = sales.firstWhere((s) => s.number == 2);
    expect(sale.amount, m(200000));
    expect(sale.changeDue, m(10000));
    final pays = await (f.db.select(f.db.giftCardSalePayments)..where((p) => p.saleId.equals(sale.id))).get();
    expect({for (final p in pays) p.method: p.amount}, {'cash': m(150000), 'card': m(50000)});
    expect(await f.db.select(f.db.cashMovements).get(), isEmpty);
    await dispose(tester);
  });

  testWidgets('validation: tendered below cash; card above nominal; double tap sells once', (tester) async {
    await pump(tester);
    await openIssue(tester);
    await tester.enterText(find.byKey(const Key('gift-sale-amount')), '100000');
    await tester.enterText(find.byKey(const Key('gift-sale-tendered')), '50000');
    await tester.pumpAndSettle();
    expect(find.textContaining('Получено меньше'), findsOneWidget);
    await submit(tester);
    expect(find.text('Сертификат продан'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Смешанная'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('gift-sale-card')), '150000');
    await tester.pumpAndSettle();
    expect(find.textContaining('больше номинала'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Карта'));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('gift-sale-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gift-sale-submit')));
    await tester.tap(find.byKey(const Key('gift-sale-submit')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Сертификат продан'), findsOneWidget);
    expect(await f.db.select(f.db.giftCardSales).get(), hasLength(2));
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    await dispose(tester);
  });

  testWidgets('duplicate code shows a field error', (tester) async {
    await pump(tester);
    await openIssue(tester);
    await tester.enterText(find.byKey(const Key('gift-sale-amount')), '100000');
    await tester.enterText(find.byKey(const Key('gift-sale-code')), 'GIFTTEST2345');
    await submit(tester);
    expect(find.text('Такой код уже существует'), findsOneWidget);
    expect(await f.db.select(f.db.giftCardSales).get(), hasLength(1));
    await dispose(tester);
  });

  testWidgets('issue is disabled without an open shift', (tester) async {
    await ShiftService(f.db).close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 10000);
    await pump(tester);
    final btn = tester.widget<ButtonStyleButton>(find.byKey(const Key('gift-issue')));
    expect(btn.onPressed, isNull);
    expect(find.byTooltip('Откройте смену, чтобы продать сертификат'), findsOneWidget);
    await dispose(tester);
  });

  testWidgets('card detail: document, void with reason and confirmation', (tester) async {
    await pump(tester);
    await tester.tap(find.text('GIFTTEST2345'));
    await tester.pumpAndSettle();
    expect(find.text('Документ продажи'), findsOneWidget);
    expect(find.text('Продажа №1'), findsOneWidget);
    expect(find.text('Проведена'), findsOneWidget);
    expect(find.byKey(const Key('gift-sale-reprint')), findsOneWidget);

    await tester.tap(find.byKey(const Key('gift-sale-void')));
    await tester.pumpAndSettle();
    // empty reason is refused
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Обязательное поле'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Причина *'), 'Передумал');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Аннулировать продажу №1?'), findsOneWidget);
    await tester.tap(find.text('Аннулировать'));
    await tester.pumpAndSettle();

    expect(find.text('Аннулирована'), findsOneWidget);
    expect(find.byKey(const Key('gift-sale-void')), findsNothing);
    final sale = (await f.db.select(f.db.giftCardSales).get()).single;
    expect(sale.status, GiftSaleStatus.voided);
    expect(sale.voidReason, 'Передумал');
    final card = (await f.db.select(f.db.giftCards).get()).single;
    expect(card.status, 'blocked');
    await dispose(tester);
  });

  testWidgets('void disabled with a tooltip when the card was used', (tester) async {
    await (f.db.update(f.db.giftCards)).write(GiftCardsCompanion(balance: Value(m(40000))));
    await pump(tester);
    await tester.tap(find.text('GIFTTEST2345'));
    await tester.pumpAndSettle();
    final btn = tester.widget<ButtonStyleButton>(find.byKey(const Key('gift-sale-void')));
    expect(btn.onPressed, isNull);
    expect(find.textContaining('уже использован'), findsWidgets);
    await dispose(tester);
  });

  testWidgets('void disabled without Perm.voidSale', (tester) async {
    final cashier = await AuthService(f.db).createUser(name: 'Кассир', role: Role.cashier, pin: '1357');
    expect(Role.cashier.can(Perm.voidSale), isFalse);
    await pump(tester, user: cashier);
    await tester.tap(find.text('GIFTTEST2345'));
    await tester.pumpAndSettle();
    final btn = tester.widget<ButtonStyleButton>(find.byKey(const Key('gift-sale-void')));
    expect(btn.onPressed, isNull);
    expect(find.text('Нет права аннулировать продажи'), findsOneWidget);
    await dispose(tester);
  });

  testWidgets('«Продажи» list with status filter; phone width', (tester) async {
    final svc = GiftCardService(f.db);
    final r = await svc.sell(
      GiftCardSaleRequest(
        code: 'SECOND2345',
        amount: m(50000),
        payments: [GiftSalePaymentInput('cash', m(50000))],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ),
    );
    await svc.voidSale(r.saleId, reason: 'Ошибка', userId: f.owner.id, shiftId: f.shift.id);
    await pump(tester, size: const Size(390, 844));
    await tester.tap(find.text('Продажи'));
    await tester.pumpAndSettle();
    expect(find.text('№1'), findsOneWidget);
    expect(find.text('№2'), findsOneWidget);
    expect(find.textContaining('аннулировано: 1'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Аннулирована'));
    await tester.pumpAndSettle();
    expect(find.text('№1'), findsNothing);
    expect(find.text('№2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('№2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Аннулирована '), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('sale dialog fits 390px', (tester) async {
    await pump(tester, size: const Size(390, 844));
    await openIssue(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Смешанная'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const Key('gift-sale-amount')), '100000');
    await tester.enterText(find.byKey(const Key('gift-sale-transfer')), '100000');
    await submit(tester);
    expect(find.text('Сертификат продан'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    await dispose(tester);
  });

  testWidgets('empty list without a shift: the blocked call to action says why', (tester) async {
    await (f.db.update(f.db.giftCards)).write(GiftCardsCompanion(deletedAt: Value(DateTime.now())));
    await ShiftService(f.db).close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 10000);
    await pump(tester, size: const Size(390, 844));
    expect(find.text('Сертификатов пока нет'), findsOneWidget);
    final btn = tester.widget<ButtonStyleButton>(find.byKey(const Key('gift-issue-empty')));
    expect(btn.onPressed, isNull);
    // visible text, not only a tooltip (touch devices)
    expect(find.text('Откройте смену, чтобы продать сертификат'), findsOneWidget);
    await dispose(tester);
  });

  testWidgets('«Продажи» period filter follows the calendar day', (tester) async {
    final svc = GiftCardService(f.db);
    await svc.sell(
      GiftCardSaleRequest(
        code: 'SECOND2345',
        amount: m(50000),
        payments: [GiftSalePaymentInput('cash', m(50000))],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ),
    );
    // №1 yesterday evening, №2 this morning
    await (f.db.update(
      f.db.giftCardSales,
    )..where((s) => s.number.equals(1))).write(GiftCardSalesCompanion(createdAt: Value(DateTime(2026, 3, 9, 10))));
    await (f.db.update(
      f.db.giftCardSales,
    )..where((s) => s.number.equals(2))).write(GiftCardSalesCompanion(createdAt: Value(DateTime(2026, 3, 10, 8))));
    var now = DateTime(2026, 3, 9, 23, 59);
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(f.db), sessionProvider.overrideWith(() => _LoggedIn(f.owner))],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(body: GiftSalesList(clock: () => now)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Сегодня'));
    await tester.pumpAndSettle();
    expect(find.text('№1'), findsOneWidget);

    // the screen stays open past midnight: «Сегодня» must drop yesterday
    now = DateTime(2026, 3, 10, 9);
    await tester.pump(const Duration(minutes: 2)); // the midnight timer fires
    await tester.pumpAndSettle();
    expect(find.text('№1'), findsNothing);
    expect(find.text('№2'), findsOneWidget);
    await dispose(tester);
  });
}
