import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/theme.dart';
import 'package:dreampos/features/marketing/marketing_repo.dart';
import 'package:dreampos/features/marketing/marketing_screen.dart';
import 'package:dreampos/features/marketing/promotion_logic.dart';
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

  setUp(() async {
    f = await Fixture.create();
    final repo = MarketingRepo(f.db);
    await repo.savePromotion(PromoDraft(name: 'Чёрная пятница', type: 'percent_order', percent: 15),
        userId: f.owner.id);
    await repo.savePromotion(
        PromoDraft(name: 'Будущая акция', type: 'percent_order', percent: 5, startDay: DateTime.now().add(const Duration(days: 10))),
        userId: f.owner.id);
    await repo.issueGiftCard(code: 'GIFTTEST2345', amount: 100000, method: 'card', userId: f.owner.id);
    final c = await f.customer('Должник Иван');
    await (f.db.update(f.db.customers)..where((t) => t.id.equals(c.id))).write(
        const CustomersCompanion(debtBalance: Value(5000), phone: Value('+998901112233')));
    await f.db.setSetting('loyalty_enabled', '1');
    await f.db.setSetting('loyalty_earn_percent', '3');
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(f.db),
        sessionProvider.overrideWith(() => _LoggedIn(f.owner)),
      ],
      child: MaterialApp(theme: buildTheme(Brightness.light), home: const MarketingScreen()),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await f.db.close();
  }

  testWidgets('tabs render live data on desktop', (tester) async {
    await pump(tester, const Size(1400, 900));
    expect(find.text('Чёрная пятница'), findsOneWidget);
    expect(find.text('Активна'), findsOneWidget);
    expect(find.text('Запланирована'), findsOneWidget);

    await tester.tap(find.text('Сертификаты'));
    await tester.pumpAndSettle();
    expect(find.text('GIFTTEST2345'), findsOneWidget);

    await tester.tap(find.text('Лояльность'));
    await tester.pumpAndSettle();
    expect(find.text('Включена'), findsOneWidget);
    expect(find.textContaining('3% от оплаченной суммы'), findsOneWidget);

    await tester.tap(find.text('Рассылки'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(RegExp(r'^Должники \d')));
    await tester.pumpAndSettle();
    expect(find.text('Должник Иван'), findsOneWidget);
    expect(find.text('Копировать телефоны (1)'), findsOneWidget);
    await dispose(tester);
  });

  testWidgets('promotion editor validates on phone width', (tester) async {
    await pump(tester, const Size(400, 860));
    await tester.tap(find.text('Новая акция'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();
    expect(find.text('Введите название акции'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Название *'), 'Тест');
    await tester.enterText(find.widgetWithText(TextFormField, 'Скидка *'), '150');
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();
    expect(find.textContaining('не больше 100'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextFormField, 'Скидка *'), '7');
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();
    expect(find.text('Акция сохранена'), findsOneWidget);
    expect((await f.db.select(f.db.promotions).get()).where((p) => p.name == 'Тест'), hasLength(1));
    await dispose(tester);
  });

  testWidgets('phone width: every tab, gift issue dialog and simulator', (tester) async {
    await pump(tester, const Size(380, 800));
    await tester.tap(find.text('Проверить на чеке'));
    await tester.pumpAndSettle();
    expect(find.text('Тестовый чек пуст'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    Future<void> openTab(String tab) async {
      await tester.ensureVisible(find.text(tab));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }

    for (final tab in ['Сертификаты', 'Лояльность', 'Рассылки']) {
      await openTab(tab);
    }
    expect(find.textContaining(RegExp(r'^Именинники \d')), findsOneWidget);
    await openTab('Сертификаты');
    await tester.tap(find.text('Выпустить'));
    await tester.pumpAndSettle();
    expect(find.text('Выпуск сертификата'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Номинал *'), '20000');
    await tester.tap(find.text('Выпустить сертификат'));
    await tester.pumpAndSettle();
    expect(find.text('Распечатать сертификат?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    final cards = await f.db.select(f.db.giftCards).get();
    expect(cards, hasLength(2));
    final cash = await f.db.select(f.db.cashMovements).get();
    expect(cash.single.amount, Money.parse('20000'));
    await dispose(tester);
  });

  testWidgets('360px: promo code editor (%/сумма toggle) saves; simulator line fits', (tester) async {
    await pump(tester, const Size(360, 740));
    await tester.tap(find.text('Новая акция'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Название *'), 'Код');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Промокод').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'toggle row must not overflow at 360px');
    await tester.enterText(find.widgetWithText(TextFormField, 'Промокод *'), 'sale 10');
    await tester.ensureVisible(find.textContaining('сумма,'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('сумма,'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Сумма скидки *'), '5000');
    await tester.ensureVisible(find.text('Создать'));
    await tester.pumpAndSettle();
    // double tap must create only one promotion
    await tester.tap(find.text('Создать'));
    await tester.tap(find.text('Создать'), warnIfMissed: false);
    await tester.pumpAndSettle();
    final saved = (await f.db.select(f.db.promotions).get()).where((p) => p.name == 'Код').toList();
    expect(saved, hasLength(1));
    expect(saved.single.code, 'SALE10');
    expect(saved.single.value, Money.parse('5000')!.toDouble());

    final product = await f.product('Очень длинное название товара для проверки', price: 10000);
    expect(product.id, isNotEmpty);
    await tester.tap(find.text('Проверить на чеке'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить товар'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Очень длинное название товара для проверки').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('К оплате'), findsOneWidget);
    // percent_order 15% is active: 10000 -> 8500
    expect(find.text(Money.format(8500)), findsWidgets);
    await tester.enterText(find.widgetWithText(TextField, 'Скидка клиента'), '150');
    await tester.pumpAndSettle();
    expect(find.text('От 0 до 100'), findsOneWidget);
    await tester.tap(find.byTooltip('Убрать'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Тестовый чек пуст'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await dispose(tester);
  });
}
