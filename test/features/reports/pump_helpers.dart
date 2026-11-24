import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class LoggedInSession extends SessionNotifier {
  LoggedInSession(this.user);
  final User user;
  @override
  Session? build() => Session(user);
}

/// Pumps [screen] with an in-memory database and a logged-in [user].
Future<void> pumpScreen(WidgetTester tester, AppDatabase db, User user, Widget screen,
    {Size size = const Size(1400, 900)}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sessionProvider.overrideWith(() => LoggedInSession(user)),
    ],
    child: MaterialApp(theme: buildTheme(Brightness.light), home: screen),
  ));
  await settle(tester);
}

/// Lets drift streams (real async) deliver, then rebuilds.
Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Unmounts the tree so stream subscriptions/timers are disposed before the DB closes.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await settle(tester, rounds: 2);
}
