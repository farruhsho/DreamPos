import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/features/shifts/shifts_view.dart';
import 'package:dreampos/domain/services/shift_service.dart';
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
  overrides: [
    databaseProvider.overrideWithValue(db),
    sessionProvider.overrideWith(() => _FixedSession(user)),
  ],
  child: const MaterialApp(home: ShiftsView()),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('closed shift: opens a new shift from the screen', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);
    await ShiftService(f.db).close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 10000);

    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    expect(find.text('Смена закрыта'), findsWidgets);
    expect(find.byKey(const ValueKey('open_shift')), findsOneWidget);
    // suggested opening float from the previous shift
    expect(find.text('10000'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open_shift')));
    await _settle(tester);

    final open = await ShiftService(f.db).currentShift();
    expect(open, isNotNull);
    expect(open!.openingCash, 10000);
    expect(find.byKey(const ValueKey('close_shift')), findsOneWidget);
    expect(find.textContaining('X-отчёт'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('open shift on a phone: X-report, cash ops and history tab', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);

    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    expect(find.byKey(const ValueKey('close_shift')), findsOneWidget);
    expect(find.byKey(const ValueKey('cash_pay_in')), findsOneWidget);
    expect(find.text('Внесений и выплат ещё не было'), findsOneWidget);

    // pay-in through the dialog
    await tester.ensureVisible(find.byKey(const ValueKey('cash_pay_in')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('cash_pay_in')));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('cash_amount')), '5000');
    await tester.tap(find.byKey(const ValueKey('cash_submit')));
    await _settle(tester);
    final moves = await f.db.select(f.db.cashMovements).get();
    expect(moves.single.amount, 5000);

    await tester.tap(find.text('История смен'));
    await _settle(tester);
    expect(find.text('Смена №${f.shift.number}'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('close shift dialog requires a note on shortage', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);
    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('close_shift')));
    await _settle(tester);
    expect(find.text('По купюрам'), findsOneWidget);
    // 5000 counted vs 10000 expected
    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('den_5000')), matching: find.byType(TextField)),
      '1',
    );
    await _settle(tester);
    expect(find.text('Недостача'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close_submit')));
    await _settle(tester);
    expect(find.text('Укажите причину расхождения'), findsOneWidget);
    expect((await ShiftService(f.db).currentShift()), isNotNull);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('closing a shift by total shows the Z-report afterwards', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);
    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('close_shift')));
    await _settle(tester);
    await tester.tap(find.text('Общей суммой'));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('close_total')), '10000');
    await _settle(tester);
    expect(find.text('Расхождение'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close_submit')));
    await _settle(tester);
    // confirmation dialog
    await tester.tap(find.widgetWithText(FilledButton, 'Закрыть смену').last);
    await _settle(tester);

    final s = await (f.db.select(f.db.shifts)..where((t) => t.id.equals(f.shift.id))).getSingle();
    expect(s.status, 'closed');
    expect(s.countedCash, 10000);
    // Z-report dialog is shown even though the open-shift dashboard was replaced
    expect(find.textContaining('Z-отчёт'), findsWidgets);
    expect(find.byKey(const ValueKey('open_shift')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('small phone 360x640: dashboard, close dialog, expense dialog, history', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final f = await Fixture.create();
    addTearDown(f.db.close);
    await tester.pumpWidget(_app(f.db, f.owner));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('close_shift')));
    await _settle(tester);
    expect(find.text('По купюрам'), findsOneWidget);
    await tester.tap(find.byTooltip('Закрыть'));
    await _settle(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('cash_expense')),
      200,
      scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first,
    );
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('cash_expense')));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('cash_amount')), '2000');
    await tester.tap(find.text('Аренда'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('cash_submit')));
    await _settle(tester);
    final m = await f.db.select(f.db.cashMovements).getSingle();
    expect(m.kind, 'expense');
    expect(m.expenseCategory, 'Аренда');

    await tester.tap(find.text('История смен'));
    await _settle(tester);
    await tester.tap(find.text('Смена №${f.shift.number}').first);
    await _settle(tester);
    expect(find.textContaining('X-отчёт'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });
}
