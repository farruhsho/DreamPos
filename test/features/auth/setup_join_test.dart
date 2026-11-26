// Setup wizard → «Подключиться к существующему магазину» (D-025, spec §10)
// against the in-memory FakeSyncServer: sign in, pick the store, join, pull
// everything, land on the PIN login with the store's users.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:dreampos/app/app.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sync/sync_harness.dart' show testEmail, testPassword, testEndpoint;
import '../../helpers.dart';
import '../../support/fake_sync_server.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Future<void> settle(WidgetTester tester, [int n = 10]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

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

  /// A store created on another register (A) with an owner and settings.
  Future<String> seedCloudStore(FakeSyncServer server) async {
    final db = memoryDb();
    await AuthService(db).createUser(name: 'Хозяин', role: Role.owner, pin: '2580');
    await db.setSetting('store_name', 'Облачный магазин');
    await db.setSetting('currency_code', 'UZS');
    final svc = SyncService(db, transportFactory: (_) => server.client());
    await svc.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
    final info = await svc.createStoreAndUpload(name: 'Облачный магазин', environment: StoreEnvironment.test);
    svc.dispose();
    await db.close();
    return info.id;
  }

  Future<void> fillSignIn(WidgetTester tester, {String? password}) async {
    await tester.enterText(find.byKey(const ValueKey('sync-project-id')), testEndpoint.projectId);
    await tester.enterText(find.byKey(const ValueKey('sync-api-key')), testEndpoint.apiKey);
    await tester.enterText(find.byKey(const ValueKey('sync-email')), testEmail);
    await tester.enterText(find.byKey(const ValueKey('sync-password')), password ?? testPassword);
    await tester.pump();
  }

  testWidgets('fresh install joins an existing store and lands on the PIN login', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final server = FakeSyncServer()..addUser(testEmail, testPassword);
    await tester.runAsync(() => seedCloudStore(server));
    final db = memoryDb();
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const DreamPosApp()));
    await settle(tester);
    expect(find.text('Добро пожаловать в DreamPOS'), findsOneWidget);
    expect(find.text('Подключиться к существующему магазину'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('setup-join')));
    await tester.tap(find.byKey(const ValueKey('setup-join')));
    await settle(tester);
    expect(find.text('Подключение к магазину'), findsOneWidget);

    // Back to creating a store and in again.
    await tester.ensureVisible(find.byKey(const ValueKey('setup-join-back')));
    await tester.tap(find.byKey(const ValueKey('setup-join-back')));
    await settle(tester);
    expect(find.text('Подключение к магазину'), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('setup-join')));
    await tester.tap(find.byKey(const ValueKey('setup-join')));
    await settle(tester);

    // Wrong password first.
    await fillSignIn(tester, password: 'nope');
    await tester.ensureVisible(find.byKey(const ValueKey('sync-sign-in')));
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    expect(find.text('Неверный email или пароль, либо сессия истекла. Войдите снова.'), findsOneWidget);

    await fillSignIn(tester);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    expect(find.text('Вход выполнен: $testEmail'), findsOneWidget);
    expect(find.text('Облачный магазин'), findsOneWidget);
    expect(find.text('Тестовый магазин'), findsOneWidget); // env badge of the store

    await tester.ensureVisible(find.byKey(const ValueKey('setup-join-submit')));
    await tester.tap(find.byKey(const ValueKey('setup-join-submit')));
    await settle(tester, 20);

    // Login screen of the joined store: name from the cloud, test badge.
    expect(find.text('Введите PIN-код'), findsOneWidget);
    expect(find.text('Облачный магазин'), findsOneWidget);
    expect(find.text('Тестовый магазин'), findsOneWidget);
    final users = await drive(tester, () => db.select(db.users).get());
    expect(users.map((u) => u.name), ['Хозяин']);
    expect(await drive(tester, () => db.getSetting('setup_done')), '1');
    expect(await drive(tester, db.deviceCode), 'B');

    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(db.close);
  });

  Future<void> pumpApp(WidgetTester tester, ProviderContainer c) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const DreamPosApp()));
    await settle(tester);
  }

  Future<void> close(WidgetTester tester, ProviderContainer c, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(db.close);
  }

  testWidgets('a join interrupted before the download finished resumes after a restart', (tester) async {
    final server = FakeSyncServer()..addUser(testEmail, testPassword);
    await tester.runAsync(() => seedCloudStore(server));
    final db = memoryDb();
    var c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
    ]);
    c.read(syncServiceProvider).debugBeforeApply = (i, change) async {
      if (change.entity == 'settings') throw StateError('connection lost');
    };
    await pumpApp(tester, c);
    await tester.ensureVisible(find.byKey(const ValueKey('setup-join')));
    await tester.tap(find.byKey(const ValueKey('setup-join')));
    await settle(tester);
    await fillSignIn(tester);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('setup-join-submit')));
    await tester.tap(find.byKey(const ValueKey('setup-join-submit')));
    await settle(tester, 20);
    expect(find.text('Повторить загрузку'), findsOneWidget);

    // The app is closed and started again: the wizard must not offer a local
    // store on this connected database, only the interrupted download.
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const DreamPosApp()));
    await settle(tester);
    expect(find.text('Добро пожаловать в DreamPOS'), findsOneWidget);
    expect(find.text('Касса подключена, но загрузка данных не завершилась. Проверьте связь и повторите.'), findsOneWidget);
    expect(find.text('Повторить загрузку'), findsOneWidget);
    expect(find.byKey(const ValueKey('setup-join')), findsNothing);
    expect(find.text('Далее'), findsNothing, reason: 'no local store wizard on a connected database');

    await tester.ensureVisible(find.byKey(const ValueKey('setup-join-submit')));
    await tester.tap(find.byKey(const ValueKey('setup-join-submit')));
    await settle(tester, 20);
    expect(find.text('Введите PIN-код'), findsOneWidget);
    expect(await drive(tester, () => db.getSetting('setup_done')), '1');
    final users = await drive(tester, () => db.select(db.users).get());
    expect(users.map((u) => u.name), ['Хозяин'], reason: 'no second owner');
    await close(tester, c, db);
  });

  testWidgets('join offer is hidden without a transport in this build', (tester) async {
    final db = memoryDb();
    final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    await pumpApp(tester, c);
    expect(find.text('Добро пожаловать в DreamPOS'), findsOneWidget);
    expect(find.text('Подключиться к существующему магазину'), findsNothing);
    await close(tester, c, db);
  });

  testWidgets('join offer is hidden for a database with business data', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    final server = FakeSyncServer();
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(f.db),
      syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
    ]);
    await pumpApp(tester, c);
    expect(find.text('Добро пожаловать в DreamPOS'), findsOneWidget);
    expect(find.text('Подключиться к существующему магазину'), findsNothing);
    await close(tester, c, f.db);
  });
}
