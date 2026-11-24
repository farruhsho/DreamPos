import 'dart:io';

import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/settings/sections/devices_section.dart' show buildTestReceiptPdf;
import 'package:dreampos/features/settings/settings_providers.dart';
import 'package:dreampos/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<(Fixture, ProviderContainer)> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(1400, 900),
    Role role = Role.owner,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (f, user) = (await tester.runAsync(() async {
      final f = await Fixture.create();
      await f.db.setSetting('store_name', 'Тестовый магазин');
      await f.db.setSetting('setup_done', '1');
      var user = f.owner;
      if (role != Role.owner) {
        user = await AuthService(f.db).createUser(name: 'Кассир', role: role, pin: '1357');
      }
      return (f, user);
    }))!;
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(f.db),
        settingsDocumentsDirProvider.overrideWithValue(() async => Directory.systemTemp),
        settingsDbPathProvider.overrideWithValue(
          () async =>
              '${Directory.systemTemp.path}${Platform.pathSeparator}dreampos_settings_widget_test.sqlite',
        ),
      ],
    );
    container.read(sessionProvider.notifier).login(user);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    // let drift streams deliver
    await settle(tester);
    return (f, container);
  }

  Future<void> dispose(WidgetTester tester, Fixture f, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(f.db.close);
  }

  testWidgets('wide layout: sections, store form saves with audit', (tester) async {
    final (f, c) = await pumpScreen(tester);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-backup')), findsOneWidget);
    // Store section is open with the current store name
    expect(find.widgetWithText(TextFormField, 'Тестовый магазин'), findsOneWidget);
    expect(find.text('Образец чека'), findsOneWidget);

    // Empty name -> validation error, nothing saved
    await tester.enterText(find.widgetWithText(TextFormField, 'Тестовый магазин'), '');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Сохранить'));
    await settle(tester);
    expect(find.textContaining('Название магазина обязательно'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Новый магазин');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Сохранить'));
    await settle(tester);
    expect(c.read(settingsProvider).value?['store_name'], 'Новый магазин');
    final audit = (await tester.runAsync(() => f.db.select(f.db.auditLog).get()))!;
    expect(audit.any((a) => a.action == 'settings.change' && a.entityId == 'store_name'), isTrue);

    await dispose(tester, f, c);
  });

  testWidgets('currency is locked after the first sale', (tester) async {
    final (f, c) = await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('nav-currency')));
    await settle(tester);
    expect(find.text('Валюта учёта'), findsOneWidget);
    expect(find.textContaining('Валюта зафиксирована'), findsNothing);

    await tester.runAsync(() async {
      final p = await f.product('Milk', price: 1500, stock: 5);
      await SaleService(f.db).checkout(
        CheckoutRequest(
          lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 1500)],
          payments: [PaymentInput('cash', 1500)],
          cashierId: f.owner.id,
          shiftId: f.shift.id,
        ),
      );
    });
    await settle(tester);
    expect(find.textContaining('Валюта зафиксирована'), findsOneWidget);
    final usd = tester.widget<ListTile>(find.byKey(const ValueKey('currency-USD')));
    expect(usd.enabled, isFalse);

    await dispose(tester, f, c);
  });

  testWidgets('other sections render', (tester) async {
    final (f, c) = await pumpScreen(tester);
    for (final (key, text) in [
      ('nav-sales', 'Продавать только при открытой смене'),
      ('nav-loyalty', 'Бонусная программа включена'),
      ('nav-devices', 'Напечатать тестовый чек'),
      ('nav-appearance', 'Тёмная'),
      ('nav-data', 'Экспорт'),
      ('nav-about', 'Связаться с поддержкой'),
    ]) {
      await tester.tap(find.byKey(ValueKey(key)));
      await settle(tester);
      expect(find.textContaining(text), findsWidgets, reason: key);
    }
    await dispose(tester, f, c);
  });

  testWidgets('narrow layout pushes a section page', (tester) async {
    final (f, c) = await pumpScreen(tester, size: const Size(390, 800));
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('nav-appearance')));
    await settle(tester);
    expect(find.text('Авто'), findsOneWidget);
    await tester.tap(find.text('Тёмная'));
    await settle(tester);
    expect(c.read(settingsProvider).value?['theme_mode'], 'dark');
    await dispose(tester, f, c);
  });

  testWidgets('every section fits a 360px phone without overflow', (tester) async {
    // Very tall viewport so every card of each section is laid out at 360px.
    final (f, c) = await pumpScreen(tester, size: const Size(360, 3000));
    for (final key in const [
      'nav-store',
      'nav-currency',
      'nav-sales',
      'nav-loyalty',
      'nav-devices',
      'nav-appearance',
      'nav-backup',
      'nav-data',
      'nav-about',
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(key)),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(ValueKey(key)));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: key);
      await tester.pageBack();
      await settle(tester);
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: 'back from $key');
    }
    await dispose(tester, f, c);
  });

  testWidgets('narrow: unsaved edits ask before leaving the page', (tester) async {
    final (f, c) = await pumpScreen(tester, size: const Size(360, 740));
    await tester.tap(find.byKey(const ValueKey('nav-store')));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Черновик');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pageBack();
    await settle(tester);
    expect(find.text('Отменить изменения?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await settle(tester);
    expect(find.widgetWithText(TextFormField, 'Черновик'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.text('Не сохранять'));
    await settle(tester);
    expect(find.byKey(const ValueKey('nav-store')), findsOneWidget);
    expect(c.read(settingsProvider).value?['store_name'], 'Тестовый магазин');
    await dispose(tester, f, c);
  });

  testWidgets('cashier has no access', (tester) async {
    final (f, c) = await pumpScreen(tester, role: Role.cashier);
    expect(find.text('Нет доступа'), findsOneWidget);
    await dispose(tester, f, c);
  });

  testWidgets('test receipt pdf builds', (tester) async {
    final bytes = await tester.runAsync(() => buildTestReceiptPdf({'receipt_width_mm': '58'}));
    expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
  });
}
