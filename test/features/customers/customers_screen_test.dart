import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/theme.dart';
import 'package:dreampos/features/customers/customers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    await f.customer('Анна Петрова', discount: 5, bonus: 1500);
    await f.customer('Борис Должников', debtLimit: 100000);
    await (f.db.update(f.db.customers)..where((c) => c.name.equals('Борис Должников')))
        .write(const CustomersCompanion(debtBalance: Value(25000)));
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
      child: MaterialApp(theme: buildTheme(Brightness.light), home: const CustomersScreen()),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await f.db.close();
  }

  testWidgets('narrow: list, summary, segment filter and detail page', (tester) async {
    await pump(tester, const Size(420, 900));
    expect(find.text('Анна Петрова'), findsOneWidget);
    expect(find.text('Борис Должников'), findsOneWidget);
    expect(find.text('Дебиторка'), findsOneWidget);
    expect(find.text('долг ${Money.format(25000)}'), findsOneWidget);

    await tester.tap(find.text('Должники 1'));
    await tester.pumpAndSettle();
    expect(find.text('Анна Петрова'), findsNothing);
    expect(find.text('Борис Должников'), findsOneWidget);

    await tester.tap(find.text('Борис Должников'));
    await tester.pumpAndSettle();
    expect(find.text('Карточка клиента'), findsOneWidget);
    expect(find.text('Принять оплату долга'), findsOneWidget);

    // accept the full debt in cash (shift is open), without printing
    await tester.tap(find.text('Принять оплату долга'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Вся сумма'));
    await tester.tap(find.text('Распечатать квитанцию'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Принять оплату'));
    await tester.pumpAndSettle();
    final c = await (f.db.select(f.db.customers)..where((t) => t.name.equals('Борис Должников'))).getSingle();
    expect(c.debtBalance, 0);
    expect(find.text('Принять оплату долга'), findsNothing, reason: 'button hidden once debt is paid');
    await dispose(tester);
  });

  testWidgets('wide: master-detail and new customer dialog validation', (tester) async {
    await pump(tester, const Size(1400, 900));
    expect(find.text('Выберите клиента'), findsOneWidget);
    await tester.tap(find.text('Анна Петрова'));
    await tester.pumpAndSettle();
    expect(find.text('Средний чек'), findsOneWidget);
    expect(find.text('Скидка 5%'), findsOneWidget);

    await tester.tap(find.text('Новый клиент'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();
    expect(find.text('Введите имя клиента'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Имя *'), 'Виктор');
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();
    expect(find.text('Клиент создан'), findsOneWidget);
    final rows = await f.db.select(f.db.customers).get();
    expect(rows.map((c) => c.name), contains('Виктор'));
    await dispose(tester);
  });

  testWidgets('360px phone: summary strip, card payment, reminder dialog', (tester) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pump(tester, const Size(360, 740));
    expect(tester.takeException(), isNull);
    expect(find.text('Дебиторка'), findsOneWidget);

    // editor fits at 360px and a double tap creates one customer
    await tester.tap(find.byTooltip('Новый клиент (Ctrl+N)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.widgetWithText(TextFormField, 'Имя *'), 'Двойной Клик');
    await tester.ensureVisible(find.text('Создать'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать'));
    await tester.tap(find.text('Создать'), warnIfMissed: false);
    await tester.pumpAndSettle();
    final created = await (f.db.select(f.db.customers)..where((t) => t.name.equals('Двойной Клик'))).get();
    expect(created, hasLength(1));
    // narrow layout opens the new customer's card as a page; go back
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Борис Должников'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Напоминание'));
    await tester.pumpAndSettle();
    expect(find.text('Напоминание о долге'), findsOneWidget);
    expect(find.textContaining('Здравствуйте, Борис Должников!'), findsOneWidget);
    await tester.tap(find.text('Копировать текст'));
    await tester.pumpAndSettle();
    expect(find.text('Напоминание о долге'), findsNothing);
    expect(clipboard, contains(Money.format(25000)));
    expect(tester.takeException(), isNull, reason: 'controller must outlive the dialog route');

    await tester.tap(find.text('Принять оплату долга'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'payment methods must fit at 360px');
    await tester.tap(find.text('Карта'));
    await tester.tap(find.text('Распечатать квитанцию'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Сумма оплаты *'), '300000');
    await tester.tap(find.text('Принять оплату'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не больше долга'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Сумма оплаты *'), Money.toInput(10000));
    await tester.tap(find.text('Принять оплату'));
    await tester.pumpAndSettle();
    final c = await (f.db.select(f.db.customers)..where((t) => t.name.equals('Борис Должников'))).getSingle();
    expect(c.debtBalance, 15000);
    final outbox = await f.db.select(f.db.syncOutbox).get();
    expect(outbox.where((o) => o.entity == 'customers' && o.entityId == c.id), isNotEmpty);
    await dispose(tester);
  });
}
