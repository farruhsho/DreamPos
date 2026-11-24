import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/features/staff/staff_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

class _FixedSession extends SessionNotifier {
  _FixedSession(this.user);
  final User user;
  @override
  Session? build() => Session(user);
}

Widget _app(AppDatabase db, User user) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(db), sessionProvider.overrideWith(() => _FixedSession(user))],
  child: const MaterialApp(home: StaffScreen()),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('staff screen: list, clock in, tabs', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);
    await AuthService(f.db).createUser(name: 'Алина', role: Role.cashier, pin: '4826');

    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Алина'), findsOneWidget);
    expect(find.text('Кассир'), findsWidgets);
    expect(find.text('Журнал действий'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('clock_in')));
    await _settle(tester);
    final ws = await f.db.select(f.db.workSessions).get();
    expect(ws.single.userId, f.owner.id);
    expect(find.byKey(const ValueKey('clock_out')), findsOneWidget);

    await tester.tap(find.text('Роли и права'));
    await _settle(tester);
    expect(find.text('Управление сотрудниками'), findsOneWidget);

    await tester.tap(find.text('Мотивация'));
    await _settle(tester);
    expect(find.text('Комиссия к выплате'), findsOneWidget);

    await tester.tap(find.text('Журнал действий'));
    await _settle(tester);
    expect(find.text('Приход на работу'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('creates a user from the form on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);
    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('add_user')));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('user_name')), 'Бобур');
    await tester.enterText(find.byKey(const ValueKey('user_pin')), '4826');
    await tester.enterText(find.byKey(const ValueKey('user_pin2')), '4827');
    await tester.tap(find.byKey(const ValueKey('user_save')));
    await _settle(tester);
    expect(find.text('PIN не совпадает'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('user_pin2')), '4826');
    await tester.tap(find.byKey(const ValueKey('user_save')));
    await _settle(tester);
    final users = await f.db.select(f.db.users).get();
    expect(users.map((u) => u.name), contains('Бобур'));
    expect(find.text('Бобур'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('non-staff role sees no access', (tester) async {
    final f = await Fixture.create();
    addTearDown(f.db.close);
    final c = await AuthService(f.db).createUser(name: 'C', role: Role.cashier, pin: '4826');
    await tester.pumpWidget(_app(f.db, c));
    await _settle(tester);
    expect(find.text('Нет доступа'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('editing yourself refreshes the session', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);
    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    await tester.tap(find.text('Owner'));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('user_name')), 'Хозяин');
    await tester.tap(find.byKey(const ValueKey('user_save')));
    await _settle(tester);

    final container = ProviderScope.containerOf(tester.element(find.byType(StaffScreen)));
    expect(container.read(sessionProvider)!.user.name, 'Хозяин');
    expect(find.text('Хозяин'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('time tab on a phone: add a manual session', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);
    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    await tester.tap(find.text('Рабочее время'));
    await _settle(tester);
    expect(find.text('Нет отметок за период'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add_session')));
    await _settle(tester);
    // pick the employee
    await tester.tap(find.text('Сотрудник *'));
    await _settle(tester);
    await tester.tap(find.text('Owner').last);
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('session_save')));
    await _settle(tester);

    final ws = await f.db.select(f.db.workSessions).get();
    expect(ws, hasLength(1));
    expect(ws.single.endedAt, isNotNull);
    expect(find.text('Нет отметок за период'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('small phone 360x640: every tab renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);
    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    for (final tab in ['Рабочее время', 'Мотивация', 'Роли и права', 'Журнал действий', 'Сотрудники']) {
      final t = find.widgetWithText(Tab, tab);
      await tester.ensureVisible(t);
      await _settle(tester);
      await tester.tap(t);
      await _settle(tester);
    }
    await tester.tap(find.byKey(const ValueKey('add_user')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('user_save')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });
}
