// Settings → «Синхронизация» (D-025, spec §10, §11) with the in-memory
// FakeSyncServer behind syncTransportFactoryProvider. No real server.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/sync/conflict_text.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/features/auth/login_screen.dart';
import 'package:dreampos/features/settings/settings_providers.dart';
import 'package:dreampos/features/settings/settings_screen.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sync/sync_harness.dart' show testEmail, testPassword, testEndpoint;
import '../../helpers.dart';
import '../../support/fake_sync_server.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> settle(WidgetTester tester, [int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Runs [body] in the test zone, pumping until it completes (the services
  /// were created in the fake-async zone).
  Future<T> drive<T>(WidgetTester tester, Future<T> Function() body) async {
    T? out;
    Object? err;
    var done = false;
    body().then((v) {
      out = v;
      done = true;
    }, onError: (Object e) {
      err = e;
      done = true;
    });
    for (var i = 0; i < 200 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    if (err != null) throw err!;
    expect(done, isTrue, reason: 'operation did not complete');
    return out as T;
  }

  late FakeSyncServer server;

  Future<(Fixture, ProviderContainer)> pumpSection(
    WidgetTester tester, {
    Size size = const Size(1400, 1000),
    bool demo = false,
    Future<void> Function(Fixture f)? prepare,
    Locale? locale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    server = FakeSyncServer()..addUser(testEmail, testPassword);
    final f = (await tester.runAsync(() async {
      final f = await Fixture.create();
      await f.db.setSetting('store_name', 'Тестовый магазин');
      await f.db.setSetting('setup_done', '1');
      if (demo) await f.db.setSetting('demo_mode', '1');
      await prepare?.call(f);
      return f;
    }))!;
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(f.db),
        syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
        settingsDocumentsDirProvider.overrideWithValue(() async => Directory.systemTemp),
      ],
    );
    container.read(sessionProvider.notifier).login(f.owner);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: locale == null
            ? const MaterialApp(home: SettingsScreen())
            : MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const SettingsScreen(),
              ),
      ),
    );
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('nav-sync')));
    await settle(tester);
    return (f, container);
  }

  Future<void> dispose(WidgetTester tester, Fixture f, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(f.db.close);
  }

  Future<void> fillSignIn(WidgetTester tester, {String url = 'https://fake.example.test', String? password}) async {
    await tester.enterText(find.byKey(const ValueKey('sync-url')), url);
    await tester.enterText(find.byKey(const ValueKey('sync-anon-key')), testEndpoint.anonKey);
    await tester.enterText(find.byKey(const ValueKey('sync-email')), testEmail);
    await tester.enterText(find.byKey(const ValueKey('sync-password')), password ?? testPassword);
    await tester.pump();
  }

  Future<Map<String, String>> syncState(WidgetTester tester, AppDatabase db) => drive(
        tester,
        () async => {for (final r in await db.select(db.syncState).get()) r.key: r.value},
      );

  testWidgets('disconnected: validation, wrong password, create a test store, status card', (tester) async {
    final (f, c) = await pumpSection(tester);
    expect(find.text('Синхронизация выключена'), findsOneWidget);
    expect(find.text('Проверка целостности'), findsOneWidget);
    expect(find.text('Конфликтов нет'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sync-connect')));
    await settle(tester);
    expect(find.text('Подключение к облаку'), findsOneWidget);

    // Empty form -> required messages, nothing sent.
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    expect(find.text('Обязательное поле'), findsWidgets);

    // Plain http to a remote host is refused client-side.
    await fillSignIn(tester, url: 'http://example.test');
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    expect(find.text('Адрес сервера должен начинаться с https://.'), findsOneWidget);

    // Password field is obscured.
    final pw = tester.widget<EditableText>(
      find.descendant(of: find.byKey(const ValueKey('sync-password')), matching: find.byType(EditableText)),
    );
    expect(pw.obscureText, isTrue);

    // Wrong password -> inline error.
    await fillSignIn(tester, password: 'wrong');
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    expect(find.text('Неверный email или пароль, либо сессия истекла. Войдите снова.'), findsOneWidget);

    await fillSignIn(tester);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    expect(find.text('Вход выполнен: $testEmail'), findsOneWidget);
    // The fixture has a shift and sales data -> join is refused with the reason.
    expect(find.textContaining('В этой базе уже есть данные'), findsOneWidget);
    final join = tester.widget<RadioListTile<Object>>(find.byKey(const ValueKey('sync-mode-join')));
    expect(join.enabled, isFalse);
    expect(find.widgetWithText(TextFormField, 'Тестовый магазин'), findsOneWidget); // name prefilled

    // Double tap on «Создать и загрузить» creates one store only.
    await tester.tap(find.byKey(const ValueKey('sync-submit')));
    await tester.tap(find.byKey(const ValueKey('sync-submit')), warnIfMissed: false);
    await settle(tester, 12);
    expect(server.stores.length, 1);
    expect(server.stores.first.environment, StoreEnvironment.test);
    expect(find.text('Подключение к облаку'), findsNothing);
    expect(find.textContaining('Касса подключена к магазину «Тестовый магазин». Код кассы: A'), findsOneWidget);

    // Status card: state, store, environment badge, device code, pending, last sync.
    expect(find.text('Синхронизировано'), findsOneWidget);
    expect(find.text('Тестовый магазин'), findsWidgets);
    expect(find.text('Код кассы'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('номера чеков: A-15'), findsOneWidget);
    expect(find.text('Ожидают отправки'), findsOneWidget);
    expect(find.text('ещё не было'), findsNothing);
    expect(server.changesOf(server.stores.first.id), isNotEmpty);

    // The password is never persisted.
    final st = await syncState(tester, f.db);
    expect(st.values.any((v) => v.contains(testPassword)), isFalse);
    expect(st[SyncKeys.refreshToken], isNotNull);

    await dispose(tester, f, c);
  });

  testWidgets('demo database cannot pick a production store', (tester) async {
    final (f, c) = await pumpSection(tester, demo: true);
    await tester.tap(find.byKey(const ValueKey('sync-connect')));
    await settle(tester);
    await fillSignIn(tester);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    final prod = tester.widget<RadioListTile<StoreEnvironment>>(find.byKey(const ValueKey('sync-env-production')));
    expect(prod.enabled, isFalse);
    expect(find.text('Недоступно для демо-базы'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await settle(tester);
    expect(server.stores, isEmpty);
    await dispose(tester, f, c);
  });

  Future<void> connect(WidgetTester tester, Fixture f, ProviderContainer c) async {
    await drive(tester, () async {
      final s = c.read(syncServiceProvider);
      await s.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
      await s.createStoreAndUpload(name: 'Облачный магазин', environment: StoreEnvironment.test);
    });
    await settle(tester);
  }

  testWidgets('connected: sync now, offline error, disconnect keeps data and code', (tester) async {
    final (f, c) = await pumpSection(tester);
    await connect(tester, f, c);
    expect(find.text('Облачный магазин'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-now')), findsOneWidget);

    // A local write -> pending count after refresh.
    await drive(tester, () async {
      await f.product('Новый товар');
      await c.read(syncServiceProvider).refreshStatus();
    });
    await settle(tester);
    expect(
      find.descendant(of: find.byKey(const ValueKey('sync-pending')), matching: find.text('1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('sync-now')));
    await settle(tester);
    expect(find.textContaining('Синхронизация завершена: отправлено 1'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const ValueKey('sync-pending')), matching: find.text('0')),
      findsOneWidget,
    );

    // Offline -> error banner and phase «Нет связи».
    server.offline = true;
    await tester.tap(find.byKey(const ValueKey('sync-now')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-last-error')), findsOneWidget);
    expect(find.text('Нет связи'), findsOneWidget);
    server.offline = false;

    // Disconnect: confirm dialog says data is kept.
    await tester.tap(find.byKey(const ValueKey('sync-disconnect')));
    await settle(tester);
    expect(find.text('Отключить синхронизацию?'), findsOneWidget);
    expect(find.textContaining('Все данные на этой кассе сохранятся'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Отключить'));
    await settle(tester);
    expect(find.text('Синхронизация выключена'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // device code kept
    final st = await syncState(tester, f.db);
    expect(st[SyncKeys.connected], isNull);
    expect(st[SyncKeys.refreshToken], isNull);
    final products = await drive(tester, () => f.db.select(f.db.products).get());
    expect(products.map((p) => p.name), contains('Новый товар'));
    await dispose(tester, f, c);
  });

  testWidgets('disconnected register with data: rejoin only its own store; no production after a test store',
      (tester) async {
    final (f, c) = await pumpSection(tester);
    await connect(tester, f, c);
    server.seedStore('Чужой магазин', StoreEnvironment.production, ownerEmail: testEmail);
    await drive(tester, () => c.read(syncServiceProvider).disconnect());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sync-connect')));
    await settle(tester);
    await fillSignIn(tester);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);

    final join = tester.widget<RadioListTile<Object?>>(find.byKey(const ValueKey('sync-mode-join')));
    expect(join.enabled, isTrue);
    expect(find.textContaining('только к магазину «Облачный магазин»'), findsOneWidget);
    expect(find.text('Облачный магазин'), findsOneWidget);
    expect(find.text('Чужой магазин'), findsNothing, reason: 'two databases are never merged');

    await tester.tap(find.byKey(const ValueKey('sync-mode-create')));
    await settle(tester);
    final prod = tester.widget<RadioListTile<StoreEnvironment>>(find.byKey(const ValueKey('sync-env-production')));
    expect(prod.enabled, isFalse);
    expect(find.textContaining('Создать из неё рабочий магазин нельзя'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sync-mode-join')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sync-submit')));
    await settle(tester, 15);
    expect(await drive(tester, () => c.read(syncServiceProvider).isConnected()), isTrue);
    expect(find.text('Облачный магазин'), findsOneWidget);
    await dispose(tester, f, c);
  });

  testWidgets('expired session offers «Войти снова» with the endpoint fixed', (tester) async {
    final (f, c) = await pumpSection(tester);
    await connect(tester, f, c);
    server.revokeAllSessions();
    await tester.tap(find.byKey(const ValueKey('sync-now')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-sign-in-again')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in-again')));
    await settle(tester);
    final url = tester.widget<TextFormField>(find.byKey(const ValueKey('sync-url')));
    expect(url.enabled, isFalse);
    expect(find.text('https://fake.example.test'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('sync-password')), testPassword);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester, 12);
    expect(find.byKey(const ValueKey('sync-sign-in-again')), findsNothing);
    expect(find.text('Синхронизировано'), findsOneWidget);
    await dispose(tester, f, c);
  });

  testWidgets('integrity check: clean, then a broken cache; conflicts list', (tester) async {
    late String productId;
    final (f, c) = await pumpSection(tester, prepare: (f) async {
      productId = (await f.product('Чай зелёный', stock: 5)).id;
    });
    await tester.tap(find.byKey(const ValueKey('sync-integrity-run')));
    await settle(tester);
    // The fixture inserts stock directly (no movement), so the cache differs.
    expect(find.text('Найдено расхождений: 1'), findsOneWidget);
    expect(find.text('Остаток товара: Чай зелёный'), findsOneWidget);
    expect(find.text('сохранено 5 · по журналу 0'), findsOneWidget);

    await drive(tester, () => f.db.customStatement('UPDATE products SET stock_qty = 0 WHERE id = ?', [productId]));
    await tester.tap(find.byKey(const ValueKey('sync-integrity-run')));
    await settle(tester);
    expect(find.textContaining('Расхождений нет'), findsOneWidget);

    // Conflicts from sync_conflicts, newest first; mark as reviewed.
    await drive(tester, () async {
      await f.db.into(f.db.syncConflicts).insert(SyncConflictsCompanion.insert(
            kind: SyncConflictKind.negativeStock,
            entity: const Value('products'),
            entityId: Value(productId),
            details: const Value('Остаток товара «Чай зелёный» стал отрицательным (-2) после продаж на разных кассах.'),
          ));
      await f.db.into(f.db.syncConflicts).insert(SyncConflictsCompanion.insert(
            kind: SyncConflictKind.uniqueBarcode,
            details: const Value('Штрихкод 4600000000001 был назначен двум товарам.'),
          ));
    });
    await settle(tester);
    expect(find.text('Конфликтов нет'), findsNothing);
    expect(find.text('Отрицательный остаток'), findsOneWidget);
    expect(find.text('Совпадение штрихкода'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('sync-conflicts-mark-all')));
    await tester.tap(find.byKey(const ValueKey('sync-conflicts-mark-all')));
    await settle(tester);
    expect(find.text('Конфликтов нет'), findsOneWidget);
    await tester.ensureVisible(find.text('Показать просмотренные'));
    await tester.tap(find.text('Показать просмотренные'));
    await settle(tester);
    expect(find.text('Отрицательный остаток'), findsOneWidget);
    await dispose(tester, f, c);
  });

  testWidgets('conflict bodies follow the UI language; legacy text rows are shown as stored', (tester) async {
    const legacy = 'Штрихкод 4600000000001 был назначен двум товарам.';
    final payload = SyncConflictPayload.negativeStock(name: 'Чай зелёный', qty: -2, unit: 'pcs').encode();
    for (final lc in supportedLanguageCodes) {
      final (f, c) = await pumpSection(tester, locale: Locale(lc), prepare: (f) async {
        // Recorded while the UI was Russian.
        await f.db.into(f.db.syncConflicts).insert(SyncConflictsCompanion.insert(
              kind: SyncConflictKind.negativeStock,
              entity: const Value('products'),
              details: Value(payload),
            ));
        await f.db.into(f.db.syncConflicts).insert(SyncConflictsCompanion.insert(
              kind: SyncConflictKind.uniqueBarcode,
              details: const Value(legacy),
            ));
      });
      final l = L.of(lc);
      await tester.ensureVisible(find.byKey(const ValueKey('sync-conflicts')));
      await settle(tester);
      final body = l.syncConflictStockBody('Чай зелёный', Qty.format(-2, 'pcs', l));
      expect(find.text(l.syncConflictKindStock), findsOneWidget, reason: lc);
      expect(find.textContaining(body), findsOneWidget, reason: lc);
      expect(find.textContaining(legacy), findsOneWidget, reason: lc);
      expect(find.textContaining('"m"'), findsNothing, reason: lc);
      if (lc != 'ru') {
        expect(find.textContaining('Остаток товара'), findsNothing, reason: lc);
      }
      expect(tester.takeException(), isNull);
      await dispose(tester, f, c);
    }
  });

  testWidgets('phone width: section and connect dialog render without overflow', (tester) async {
    final (f, c) = await pumpSection(tester, size: const Size(390, 844));
    expect(find.text('Синхронизация выключена'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sync-connect')));
    await settle(tester);
    await fillSignIn(tester);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    expect(find.text('Создать магазин в облаке'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester, f, c);
  });

  testWidgets('login screen shows «Тестовый магазин» next to the demo badge', (tester) async {
    server = FakeSyncServer()..addUser(testEmail, testPassword);
    final f = (await tester.runAsync(() async {
      final f = await Fixture.create();
      await f.db.setSetting('demo_mode', '1');
      return f;
    }))!;
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(f.db),
      syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: LoginScreen())));
    await settle(tester);
    expect(find.text('Демо-режим'), findsOneWidget);
    expect(find.text('Тестовый магазин'), findsNothing); // sync off: unchanged
    await drive(tester, () async {
      final s = c.read(syncServiceProvider);
      await s.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
      await s.createStoreAndUpload(name: 'Учебный', environment: StoreEnvironment.test);
    });
    await settle(tester);
    expect(find.text('Демо-режим'), findsOneWidget);
    expect(find.text('Тестовый магазин'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(f.db.close);
  });
}
