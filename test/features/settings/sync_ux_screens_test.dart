// UX screenshots of the sync UI (D-025, spec §11): settings section
// (disconnected, connect dialog, connected idle, error, conflicts), the shell
// indicator, the login «Тестовый магазин» badge and the setup wizard's join
// step, at 390/1024/1440. Uses the in-memory FakeSyncServer.
//
//   SCREENSHOTS=1 SCREENSHOTS_LOCALE=uz SCREENSHOTS_DIR=build/screens_sync_uz \
//     flutter test test/features/settings/sync_ux_screens_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:dreampos/app/app.dart';
import 'package:dreampos/app/router.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/sync/conflict_text.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sync/sync_harness.dart' show testEmail, testPassword, testEndpoint;
import '../../helpers.dart';
import '../../support/fake_sync_server.dart';
import '../../ux/harness.dart' show loadUxFonts, screenshotsEnabled, screenshotsLocale, seedDemoStore, uxSizes;

class _Ux {
  _Ux(this.tester, this.db, this.container, this.dir, this.locale);
  final WidgetTester tester;
  final AppDatabase db;
  final ProviderContainer container;
  final Directory dir;
  final String locale;
  final key = GlobalKey();
  String size = 'desktop';
  final errors = <String>[];

  static Future<_Ux> start(WidgetTester tester, AppDatabase db, FakeSyncServer server, {User? login}) async {
    await tester.runAsync(loadUxFonts);
    final lang = screenshotsLocale;
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      uiLocaleProvider.overrideWith(() => UiLocaleNotifier(lang)),
      syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
    ]);
    final dir = Directory(Platform.environment['SCREENSHOTS_DIR'] ?? 'build/screens')..createSync(recursive: true);
    final h = _Ux(tester, db, c, dir, lang);
    h.setSize('desktop');
    if (login != null) c.read(sessionProvider.notifier).login(login);
    await tester.pumpWidget(RepaintBoundary(
      key: h.key,
      child: UncontrolledProviderScope(container: c, child: const DreamPosApp()),
    ));
    await h.settle();
    return h;
  }

  void setSize(String name) {
    size = name;
    tester.view.physicalSize = uxSizes[name]!;
    tester.view.devicePixelRatio = 1;
  }

  Future<void> settle([int rounds = 8]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  /// Runs [body] in the test zone, pumping until it completes.
  Future<T> drive<T>(Future<T> Function() body) async {
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
    for (var i = 0; i < 400 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    if (err != null) throw err!;
    expect(done, isTrue, reason: 'operation did not complete');
    return out as T;
  }

  Future<void> go(String route) async {
    container.read(routerProvider).go(route);
    await settle(10);
  }

  Future<void> shot(String name) async {
    final suffix = locale == 'ru' ? '' : '_$locale';
    final file = '${dir.path}/${size}_$name$suffix.png';
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File(file).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    final errs = <String>[];
    Object? e;
    while ((e = tester.takeException()) != null) {
      errs.add(e.toString());
    }
    final errFile = File('$file.errors.txt');
    if (errs.isNotEmpty) {
      errFile.writeAsStringSync(errs.join('\n\n'));
      errors.add('$file: ${errs.first}');
    } else if (errFile.existsSync()) {
      errFile.deleteSync();
    }
  }

  Future<void> tap(Finder f) async {
    await tester.ensureVisible(f.first);
    await settle(2);
    await tester.tap(f.first);
    await settle();
  }

  Future<void> closeDialogs() async {
    while (find.byType(Dialog).evaluate().isNotEmpty) {
      await Navigator.of(tester.element(find.byType(Dialog).last)).maybePop();
      await settle(3);
    }
  }

  void hideSnack() {
    final s = find.byType(Scaffold);
    if (s.evaluate().isNotEmpty) ScaffoldMessenger.of(tester.element(s.first)).removeCurrentSnackBar();
  }

  Future<void> finish() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    L.reset();
  }
}

Future<void> _fillSignIn(WidgetTester tester) async {
  await tester.enterText(find.byKey(const ValueKey('sync-url')), testEndpoint.url);
  await tester.enterText(find.byKey(const ValueKey('sync-anon-key')), testEndpoint.anonKey);
  await tester.enterText(find.byKey(const ValueKey('sync-email')), testEmail);
  await tester.enterText(find.byKey(const ValueKey('sync-password')), testPassword);
  await tester.pump();
}

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('sync settings ux screens', skip: !screenshotsEnabled, timeout: const Timeout(Duration(minutes: 8)),
      (tester) async {
    SharedPreferences.setMockInitialValues({'ui_locale': screenshotsLocale});
    L.reset();
    final server = FakeSyncServer()..addUser(testEmail, testPassword);
    final db = memoryDb();
    final owner = (await tester.runAsync(() => seedDemoStore(db)))!;
    final h = await _Ux.start(tester, db, server, login: owner);

    Future<void> openSection() async {
      if (h.size == 'phone') {
        await h.go('/settings');
        await h.tap(find.byKey(const ValueKey('nav-sync')));
      } else {
        await h.go('/settings');
        await h.tap(find.byKey(const ValueKey('nav-sync')));
      }
      await h.settle(6);
    }

    Future<void> leaveSection() async {
      if (h.size == 'phone') {
        await Navigator.of(h.tester.element(find.byType(Scaffold).last)).maybePop();
        await h.settle();
      }
    }

    // 1) Disconnected + connect dialog (sign-in and choose steps).
    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await openSection();
      await h.shot('sync_disconnected');
      await h.tap(find.byKey(const ValueKey('sync-connect')));
      await h.shot('sync_connect_dialog');
      await h.tap(find.byKey(const ValueKey('sync-sign-in'))); // validation messages
      await h.shot('sync_connect_validation');
      await _fillSignIn(tester);
      await h.tap(find.byKey(const ValueKey('sync-sign-in')));
      await h.settle(6);
      await h.shot('sync_connect_choose');
      await h.closeDialogs();
      await leaveSection();
    }

    // 2) Connected (demo DB -> test store).
    await h.drive(() async {
      final s = h.container.read(syncServiceProvider);
      await s.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
      await s.createStoreAndUpload(name: 'Магазин «Ташкент Маркет»', environment: StoreEnvironment.test);
    });
    await h.settle();
    h.hideSnack();
    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await openSection();
      await h.shot('sync_connected');
      await leaveSection();
    }

    // 3) Error (server unreachable) and session expired.
    server.offline = true;
    try {
      await h.drive(() => h.container.read(syncServiceProvider).syncNow());
    } on SyncException {
      // expected
    }
    await h.settle();
    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await openSection();
      await h.shot('sync_offline');
      await leaveSection();
    }
    server.offline = false;
    server.revokeAllSessions();
    try {
      await h.drive(() => h.container.read(syncServiceProvider).syncNow());
    } on SyncException {
      // expected
    }
    await h.settle();
    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await openSection();
      await h.shot('sync_error');
      await leaveSection();
    }

    // 4) Conflicts + integrity mismatch.
    await h.drive(() async {
      final p = await (db.select(db.products)..limit(1)).getSingle();
      final c = await (db.select(db.customers)..limit(1)).getSingle();
      await db.customStatement('UPDATE products SET stock_qty = stock_qty + 3 WHERE id = ?', [p.id]);
      // Language-neutral payloads (rendered in the screenshot language).
      for (final payload in [
        SyncConflictPayload.negativeStock(name: p.name, qty: -2, unit: p.unit),
        SyncConflictPayload.uniqueBarcode(code: '4780000000017', winner: p.name, loser: 'Чай чёрный'),
        SyncConflictPayload.negativeBonus(name: c.name, balance: -150000),
        SyncConflictPayload.overReturn(number: 12, code: 'B', refunded: 2500000, total: 2000000),
      ]) {
        await db.into(db.syncConflicts).insert(SyncConflictsCompanion.insert(
              kind: payload.message,
              entity: const Value('products'),
              entityId: Value(p.id),
              details: Value(payload.encode()),
            ));
      }
    });
    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await openSection();
      await h.tap(find.byKey(const ValueKey('sync-integrity-run')));
      await h.settle(6);
      await tester.ensureVisible(find.byKey(const ValueKey('sync-conflicts')));
      await h.settle(3);
      await h.shot('sync_conflicts');
      await leaveSection();
    }

    // 5) Shell indicator on the POS screen and the login test-store badge.
    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await h.go('/dashboard');
      await h.shot('sync_shell_indicator');
    }
    h.container.read(sessionProvider.notifier).logout();
    await h.settle(8);
    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await h.settle(3);
      await h.shot('sync_login_test_store');
    }
    await h.finish();
    expect(h.errors, isEmpty);
  });

  testWidgets('setup wizard join ux screens', skip: !screenshotsEnabled, timeout: const Timeout(Duration(minutes: 5)),
      (tester) async {
    SharedPreferences.setMockInitialValues({'ui_locale': screenshotsLocale});
    L.reset();
    final server = FakeSyncServer()..addUser(testEmail, testPassword);
    // The cloud store, made on register A.
    await tester.runAsync(() async {
      final a = memoryDb();
      await AuthService(a).createUser(name: 'Фаррух', role: Role.owner, pin: '2580');
      await a.setSetting('store_name', 'Магазин «Ташкент Маркет»');
      final s = SyncService(a, transportFactory: (_) => server.client());
      await s.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
      await s.createStoreAndUpload(name: 'Магазин «Ташкент Маркет»', environment: StoreEnvironment.test);
      final other = server.seedStore('Филиал «Чиланзар»', StoreEnvironment.production, ownerEmail: testEmail);
      expect(other.id, isNotEmpty);
      s.dispose();
      await a.close();
    });
    final db = memoryDb();
    final h = await _Ux.start(tester, db, server);
    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await h.settle(4);
      await h.shot('setup_step1_join_offer');
      await h.tap(find.byKey(const ValueKey('setup-join')));
      await h.shot('setup_join_sign_in');
      await _fillSignIn(tester);
      await h.tap(find.byKey(const ValueKey('sync-sign-in')));
      await h.settle(6);
      await tester.ensureVisible(find.byKey(const ValueKey('setup-join-submit')));
      await h.settle(2);
      await h.shot('setup_join_pick_store');
      await h.tap(find.byKey(const ValueKey('setup-join-back')));
    }
    await h.finish();
    expect(h.errors, isEmpty);
    await tester.runAsync(db.close);
  });
}
