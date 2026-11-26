// «Создать аккаунт владельца» (registering the cloud owner account from the
// app): the register form in Settings → «Синхронизация» and in the setup
// wizard's join step, against the in-memory FakeSyncServer. No real server,
// no real account.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:dreampos/app/app.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/features/settings/settings_providers.dart';
import 'package:dreampos/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sync/sync_harness.dart' show testEmail, testPassword, testEndpoint;
import '../../helpers.dart';
import '../../support/fake_sync_server.dart';

const _newEmail = 'boss@example.test';
const _newPassword = 'Owner-pass-2026';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Future<void> settle(WidgetTester tester, [int n = 8]) async {
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

  late FakeSyncServer server;

  Future<(Fixture, ProviderContainer)> pumpSettings(
    WidgetTester tester, {
    Future<void> Function(Fixture f)? prepare,
    Role role = Role.owner,
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    server = FakeSyncServer()..addUser(testEmail, testPassword);
    late User user;
    final f = (await tester.runAsync(() async {
      final f = await Fixture.create();
      await f.db.setSetting('store_name', 'Тестовый магазин');
      await f.db.setSetting('setup_done', '1');
      await prepare?.call(f);
      user = role == Role.owner
          ? f.owner
          : await AuthService(f.db).createUser(name: 'Кассир', role: role, pin: '1357');
      return f;
    }))!;
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(f.db),
      syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
      settingsDocumentsDirProvider.overrideWithValue(() async => Directory.systemTemp),
    ]);
    container.read(sessionProvider.notifier).login(user);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await settle(tester);
    if (role == Role.owner) {
      await tester.tap(find.byKey(const ValueKey('nav-sync')));
      await settle(tester);
    }
    return (f, container);
  }

  Future<void> dispose(WidgetTester tester, AppDatabase db, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(db.close);
  }

  Future<Map<String, String>> syncState(WidgetTester tester, AppDatabase db) =>
      drive(tester, () async => {for (final r in await db.select(db.syncState).get()) r.key: r.value});

  Future<void> openRegister(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('sync-connect')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sync-auth-sign-up')));
    await settle(tester);
  }

  Future<void> fillRegister(WidgetTester tester,
      {String email = _newEmail, String password = _newPassword, String? repeat}) async {
    await tester.enterText(find.byKey(const ValueKey('sync-project-id')), testEndpoint.projectId);
    await tester.enterText(find.byKey(const ValueKey('sync-api-key')), testEndpoint.apiKey);
    await tester.enterText(find.byKey(const ValueKey('sync-email')), email);
    await tester.enterText(find.byKey(const ValueKey('sync-password')), password);
    await tester.enterText(find.byKey(const ValueKey('sync-password-repeat')), repeat ?? password);
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('sync-sign-up')));
    await tester.tap(find.byKey(const ValueKey('sync-sign-up')));
    await settle(tester);
  }

  testWidgets('settings: switch to «Создать аккаунт владельца», validation and mismatch', (tester) async {
    final (f, c) = await pumpSettings(tester);
    await tester.tap(find.byKey(const ValueKey('sync-connect')));
    await settle(tester);
    // Sign-in is the default; the switch offers both.
    expect(find.text('Войти'), findsWidgets);
    expect(find.text('Создать аккаунт владельца'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-password-repeat')), findsNothing);
    expect(find.byKey(const ValueKey('sync-sign-in')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sync-auth-sign-up')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-password-repeat')), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-sign-up')), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-sign-in')), findsNothing);
    expect(find.textContaining('новый аккаунт владельца магазина'), findsOneWidget);
    expect(find.text('Не менее 8 символов. Пароль не сохраняется на кассе.'), findsOneWidget);

    // Empty form -> required messages, nothing sent.
    await submit(tester);
    expect(find.text('Обязательное поле'), findsNWidgets(5));
    expect(server.signUpCalls, 0);

    // Bad e-mail, short password, mismatching repetition.
    await fillRegister(tester, email: 'boss@', password: 'short', repeat: 'other');
    await submit(tester);
    expect(find.text('Неверный email'), findsOneWidget);
    expect(find.text('Не менее 8 символов'), findsOneWidget);
    expect(find.text('Пароли не совпадают'), findsOneWidget);
    expect(server.signUpCalls, 0);

    // Long enough but different.
    await fillRegister(tester, repeat: '${_newPassword}x');
    await submit(tester);
    expect(find.text('Пароли не совпадают'), findsOneWidget);
    expect(find.text('Не менее 8 символов'), findsNothing);
    expect(server.signUpCalls, 0);

    // Both password fields are obscured; show/hide toggles both.
    bool obscured(String key) => tester
        .widget<EditableText>(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText)))
        .obscureText;
    expect(obscured('sync-password'), isTrue);
    expect(obscured('sync-password-repeat'), isTrue);
    await tester.tap(find.byTooltip('Показать пароль'));
    await tester.pump();
    expect(obscured('sync-password'), isFalse);
    expect(obscured('sync-password-repeat'), isFalse);
    await tester.tap(find.byTooltip('Скрыть пароль'));
    await tester.pump();
    expect(obscured('sync-password'), isTrue);

    // Back to sign-in: the repetition goes away, typed fields stay.
    await tester.tap(find.byKey(const ValueKey('sync-auth-sign-in')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-password-repeat')), findsNothing);
    expect(find.widgetWithText(TextFormField, testEndpoint.projectId), findsOneWidget);
    await dispose(tester, f.db, c);
  });

  testWidgets('settings: register -> «Аккаунт создан» -> create the cloud store (double tap: one account)',
      (tester) async {
    final (f, c) = await pumpSettings(tester);
    await openRegister(tester);
    await fillRegister(tester);
    final gate = Completer<void>();
    server.signUpGate = gate.future;
    await tester.ensureVisible(find.byKey(const ValueKey('sync-sign-up')));
    await tester.tap(find.byKey(const ValueKey('sync-sign-up')));
    await tester.tap(find.byKey(const ValueKey('sync-sign-up')), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    // Loading: button disabled with a spinner, fields and switch locked.
    expect(tester.widget<ButtonStyleButton>(find.byKey(const ValueKey('sync-sign-up'))).enabled, isFalse);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('sync-sign-up')), matching: find.byType(CircularProgressIndicator)),
        findsOneWidget);
    expect(tester.widget<TextFormField>(find.byKey(const ValueKey('sync-email'))).enabled, isFalse);
    await tester.tap(find.byKey(const ValueKey('sync-sign-up')), warnIfMissed: false);
    gate.complete();
    server.signUpGate = null;
    await settle(tester);
    expect(server.signUpCalls, 1);

    // Next step exactly like after sign-in, with «Создать магазин» chosen.
    expect(find.text('Аккаунт создан: $_newEmail'), findsOneWidget);
    // A new account has no stores: «Создать магазин в облаке» is preselected
    // (its form with the store name is shown).
    expect(find.byKey(const ValueKey('sync-store-name')), findsOneWidget);
    final st = await syncState(tester, f.db);
    expect(st[SyncKeys.email], _newEmail);
    expect(st[SyncKeys.projectId], testEndpoint.projectId);
    expect(st[SyncKeys.refreshToken], isNotNull);
    expect(st.values.any((v) => v.contains(_newPassword)), isFalse);

    await tester.ensureVisible(find.byKey(const ValueKey('sync-submit')));
    await tester.tap(find.byKey(const ValueKey('sync-submit')));
    await settle(tester, 12);
    expect(server.stores.length, 1);
    expect(server.stores.first.members[server.userIdOf(_newEmail)], 'owner');
    expect(find.textContaining('Касса подключена к магазину «Тестовый магазин». Код кассы: A'), findsOneWidget);
    await dispose(tester, f.db, c);
  });

  testWidgets('settings: EMAIL_EXISTS and sign-up disabled are shown inline; fields kept', (tester) async {
    final (f, c) = await pumpSettings(tester);
    await openRegister(tester);
    await fillRegister(tester, email: testEmail);
    await submit(tester);
    expect(find.text('Аккаунт с этим email уже есть. Войдите с ним («Войти») или укажите другой email.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('sync-sign-up')), findsOneWidget, reason: 'still on the form');
    expect(find.widgetWithText(TextFormField, testEmail), findsOneWidget);

    server.signUpDisabled = true;
    await fillRegister(tester);
    await submit(tester);
    expect(find.textContaining('отключена регистрация новых аккаунтов'), findsOneWidget);
    expect(find.textContaining('Аккаунт с этим email уже есть'), findsNothing);
    expect(server.passwordOf(_newEmail), isNull);
    final st = await syncState(tester, f.db);
    expect(st[SyncKeys.refreshToken], isNull);
    await dispose(tester, f.db, c);
  });

  testWidgets('settings: project id and key are prefilled from an earlier sign-in', (tester) async {
    final (f, c) = await pumpSettings(tester, prepare: (f) async {
      for (final e in {SyncKeys.projectId: testEndpoint.projectId, SyncKeys.apiKey: testEndpoint.apiKey}.entries) {
        await f.db.into(f.db.syncState).insert(SyncStateCompanion.insert(key: e.key, value: e.value));
      }
    });
    await openRegister(tester);
    expect(find.widgetWithText(TextFormField, testEndpoint.projectId), findsOneWidget);
    expect(find.widgetWithText(TextFormField, testEndpoint.apiKey), findsOneWidget);
    await dispose(tester, f.db, c);
  });

  testWidgets('settings: a session-expired re-sign-in offers no registration', (tester) async {
    final (f, c) = await pumpSettings(tester);
    await drive(tester, () async {
      final s = c.read(syncServiceProvider);
      await s.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
      await s.createStoreAndUpload(name: 'Облачный магазин', environment: StoreEnvironment.test);
    });
    server.revokeAllSessions();
    try {
      await drive(tester, () => c.read(syncServiceProvider).syncNow());
    } on SyncException {
      // expected
    }
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in-again')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-sign-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-auth-mode')), findsNothing);
    expect(find.text('Создать аккаунт владельца'), findsNothing);
    await dispose(tester, f.db, c);
  });

  testWidgets('settings without Perm.manageSettings: no sync section at all', (tester) async {
    final (f, c) = await pumpSettings(tester, role: Role.cashier);
    expect(find.byKey(const ValueKey('nav-sync')), findsNothing);
    expect(find.byKey(const ValueKey('sync-connect')), findsNothing);
    await dispose(tester, f.db, c);
  });

  testWidgets('setup wizard: «Нет аккаунта? Зарегистрироваться» registers the owner account', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    server = FakeSyncServer()..addUser(testEmail, testPassword);
    final db = memoryDb();
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const DreamPosApp()));
    await settle(tester, 10);
    await tester.ensureVisible(find.byKey(const ValueKey('setup-join')));
    await tester.tap(find.byKey(const ValueKey('setup-join')));
    await settle(tester);
    expect(find.text('Нет аккаунта? Зарегистрироваться'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-auth-mode')), findsNothing, reason: 'the wizard uses the link');

    expect(find.byKey(const ValueKey('setup-join-intro')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('sync-auth-to-sign-up')));
    await tester.tap(find.byKey(const ValueKey('sync-auth-to-sign-up')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-password-repeat')), findsOneWidget);
    expect(find.text('Уже есть аккаунт? Войти'), findsOneWidget);
    // One intro that matches what the wizard does next (no «выберите магазин»,
    // no «или подключитесь к существующему»).
    expect(find.byKey(const ValueKey('setup-join-intro')), findsNothing);
    expect(find.textContaining('Затем создайте на этой кассе новый магазин'), findsOneWidget);
    expect(find.textContaining('подключитесь к существующему'), findsNothing);

    await fillRegister(tester, repeat: 'different-pass');
    await submit(tester);
    expect(find.text('Пароли не совпадают'), findsOneWidget);
    expect(server.signUpCalls, 0);

    await fillRegister(tester, email: testEmail);
    await submit(tester);
    expect(find.textContaining('Аккаунт с этим email уже есть'), findsOneWidget);

    await fillRegister(tester);
    // While the account is being created there is no way back (it would be
    // created and stored behind the closed panel).
    final gate = Completer<void>();
    server.signUpGate = gate.future;
    await tester.ensureVisible(find.byKey(const ValueKey('sync-sign-up')));
    await tester.tap(find.byKey(const ValueKey('sync-sign-up')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<ButtonStyleButton>(find.byKey(const ValueKey('setup-join-back'))).enabled, isFalse);
    gate.complete();
    server.signUpGate = null;
    await settle(tester);
    expect(find.text('Аккаунт создан: $_newEmail'), findsOneWidget);
    expect(find.byKey(const ValueKey('setup-join-new-account')), findsOneWidget);
    // No dead end: no «Выберите магазин», no grey «Подключить»; the way on is
    // the primary «Создать новый магазин».
    expect(find.text('Выберите магазин'), findsNothing);
    expect(find.byKey(const ValueKey('setup-join-intro')), findsNothing, reason: '«…выберите магазин» intro');
    expect(find.byKey(const ValueKey('setup-join-submit')), findsNothing);
    expect(find.byKey(const ValueKey('setup-join-back')), findsNothing);
    final next = find.byKey(const ValueKey('setup-join-new-store'));
    expect(next, findsOneWidget);
    expect(find.descendant(of: next, matching: find.text('Создать новый магазин')), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(next).enabled, isTrue);
    expect(find.ancestor(of: find.text('Создать новый магазин'), matching: find.byWidgetPredicate((w) => w is FilledButton)),
        findsOneWidget);
    expect(find.byKey(const ValueKey('sync-sign-up-disable-hint')), findsOneWidget);
    final st = await syncState(tester, db);
    expect(st[SyncKeys.email], _newEmail);
    expect(st.values.any((v) => v.contains(_newPassword)), isFalse);
    await tester.ensureVisible(next);
    await tester.tap(next);
    await settle(tester);
    expect(find.byKey(const ValueKey('setup-join-panel')), findsNothing, reason: 'on to the new local store');

    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(db.close);
  });

  bool focused(WidgetTester tester, String key) => tester
      .widget<EditableText>(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText)))
      .focusNode
      .hasFocus;

  testWidgets('settings: the dialog cannot be closed while the account is being created', (tester) async {
    final (f, c) = await pumpSettings(tester);
    await openRegister(tester);
    await fillRegister(tester);
    final gate = Completer<void>();
    server.signUpGate = gate.future;
    await tester.ensureVisible(find.byKey(const ValueKey('sync-sign-up')));
    await tester.tap(find.byKey(const ValueKey('sync-sign-up')));
    await tester.pump(const Duration(milliseconds: 50));
    final close = find.byKey(const ValueKey('sync-connect-close'));
    expect(tester.widget<IconButton>(close).onPressed, isNull);
    await tester.tap(close, warnIfMissed: false);
    // Back / Escape go through the route's pop: refused as well.
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('sync-sign-up')), findsOneWidget, reason: 'dialog still open');
    gate.complete();
    server.signUpGate = null;
    await settle(tester);
    expect(find.text('Аккаунт создан: $_newEmail'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-sign-up-disable-hint')), findsOneWidget);
    expect(find.textContaining('Enable create (sign-up)'), findsOneWidget);
    expect(tester.widget<IconButton>(close).onPressed, isNotNull);
    await dispose(tester, f.db, c);
  });

  testWidgets('settings: keyboard flow: autofocus, Enter moves on, Enter in the password never reveals it',
      (tester) async {
    final (f, c) = await pumpSettings(tester);
    await openRegister(tester);
    // The first empty field has the focus.
    expect(focused(tester, 'sync-project-id'), isTrue);
    await tester.enterText(find.byKey(const ValueKey('sync-project-id')), testEndpoint.projectId);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(focused(tester, 'sync-api-key'), isTrue);
    await tester.enterText(find.byKey(const ValueKey('sync-api-key')), testEndpoint.apiKey);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(focused(tester, 'sync-email'), isTrue);
    await tester.enterText(find.byKey(const ValueKey('sync-email')), _newEmail);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(focused(tester, 'sync-password'), isTrue);
    await tester.enterText(find.byKey(const ValueKey('sync-password')), _newPassword);
    // Enter twice: straight to the repetition, the password stays hidden.
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(focused(tester, 'sync-password-repeat'), isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final pw = tester.widget<EditableText>(
        find.descendant(of: find.byKey(const ValueKey('sync-password')), matching: find.byType(EditableText)));
    expect(pw.obscureText, isTrue);
    expect(find.byTooltip('Показать пароль'), findsOneWidget);
    // Enter in the repetition submits.
    await tester.enterText(find.byKey(const ValueKey('sync-password-repeat')), _newPassword);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(server.signUpCalls, 1);
    expect(find.text('Аккаунт создан: $_newEmail'), findsOneWidget);
    await dispose(tester, f.db, c);
  });

  testWidgets('settings: prefilled endpoint -> the e-mail has the focus', (tester) async {
    final (f, c) = await pumpSettings(tester, prepare: (f) async {
      for (final e in {SyncKeys.projectId: testEndpoint.projectId, SyncKeys.apiKey: testEndpoint.apiKey}.entries) {
        await f.db.into(f.db.syncState).insert(SyncStateCompanion.insert(key: e.key, value: e.value));
      }
    });
    await tester.tap(find.byKey(const ValueKey('sync-connect')));
    await settle(tester);
    expect(focused(tester, 'sync-email'), isTrue);
    await dispose(tester, f.db, c);
  });

  testWidgets('settings: a field turns red only after it was edited', (tester) async {
    final (f, c) = await pumpSettings(tester);
    await openRegister(tester);
    await tester.enterText(find.byKey(const ValueKey('sync-project-id')), testEndpoint.projectId);
    await tester.pump();
    expect(find.text('Обязательное поле'), findsNothing, reason: 'untouched fields stay quiet');
    await tester.enterText(find.byKey(const ValueKey('sync-password')), _newPassword);
    await tester.pump();
    expect(find.text('Обязательное поле'), findsNothing);
    expect(find.text('Пароли не совпадают'), findsNothing, reason: 'the repetition was not reached yet');
    await tester.enterText(find.byKey(const ValueKey('sync-password-repeat')), 'x');
    await tester.pump();
    expect(find.text('Пароли не совпадают'), findsOneWidget);
    // Switching modes does not flag anything either.
    await tester.tap(find.byKey(const ValueKey('sync-auth-sign-in')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sync-auth-sign-up')));
    await settle(tester);
    expect(find.text('Обязательное поле'), findsNothing);
    expect(find.text('Пароли не совпадают'), findsNothing);
    // Submitting still checks every field.
    await submit(tester);
    expect(find.text('Обязательное поле'), findsNWidgets(3));
    expect(server.signUpCalls, 0);
    await dispose(tester, f.db, c);
  });

  testWidgets('settings: one intro in register mode; «email exists» offers «Войти с этим email»', (tester) async {
    final (f, c) = await pumpSettings(tester);
    await tester.tap(find.byKey(const ValueKey('sync-connect')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-sign-in-intro')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sync-auth-sign-up')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-sign-in-intro')), findsNothing);
    expect(find.byKey(const ValueKey('sync-sign-up-intro')), findsOneWidget);

    await fillRegister(tester, email: testEmail);
    await submit(tester);
    final action = find.byKey(const ValueKey('sync-email-exists-sign-in'));
    expect(action, findsOneWidget);
    expect(find.descendant(of: action, matching: find.text('Войти с этим email')), findsOneWidget);
    await tester.ensureVisible(action);
    await tester.tap(action);
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-sign-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-password-repeat')), findsNothing);
    expect(find.byKey(const ValueKey('sync-sign-in-intro')), findsOneWidget);
    expect(find.widgetWithText(TextFormField, testEmail), findsOneWidget, reason: 'e-mail kept');
    expect(find.byKey(const ValueKey('sync-error')), findsNothing);
    expect(focused(tester, 'sync-password'), isTrue);
    await tester.enterText(find.byKey(const ValueKey('sync-password')), testPassword);
    await tester.tap(find.byKey(const ValueKey('sync-sign-in')));
    await settle(tester);
    expect(find.byKey(const ValueKey('sync-signed-in-as')), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-sign-up-disable-hint')), findsNothing, reason: 'signed in, not created');
    await dispose(tester, f.db, c);
  });
}
