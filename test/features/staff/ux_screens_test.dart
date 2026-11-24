import 'package:dreampos/core/db/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

/// Runs a DB seeding step in the app's zone, pumping until it completes.
Future<void> inApp(UxHarness h, Future<void> Function() op) async {
  var done = false;
  Object? error;
  op().then(
    (_) => done = true,
    onError: (Object e) {
      error = e;
      done = true;
    },
  );
  for (var i = 0; i < 200 && !done; i++) {
    await h.settle(1);
  }
  if (error != null) throw error!;
  expect(done, isTrue, reason: 'seeding did not complete');
}

void main() {
  testWidgets('staff screens', (tester) async {
    final h = await UxHarness.start(tester);
    // Direct inserts: drift transactions inside runAsync dead-lock against
    // the app's fake-async stream queries.
    await h.go('/staff');
    await inApp(h, () async {
      final users = await h.db.select(h.db.users).get();
      final now = DateTime.now();
      var n = 0;
      for (final u in users) {
        for (var d = 6; d >= 1; d--) {
          final day = DateTime(now.year, now.month, now.day - d);
          await h.db
              .into(h.db.workSessions)
              .insert(
                WorkSessionsCompanion.insert(
                  id: 'ws${n++}',
                  userId: u.id,
                  startedAt: day.add(const Duration(hours: 9)),
                  endedAt: Value(day.add(Duration(hours: 17, minutes: 10 * d))),
                ),
              );
        }
      }
      await h.db
          .into(h.db.workSessions)
          .insert(
            WorkSessionsCompanion.insert(
              id: 'ws_open',
              userId: h.owner.id,
              startedAt: now.subtract(const Duration(hours: 3)),
            ),
          );
    });
    final errs = <String>[];
    Future<void> tab(String label) async {
      await tester.tap(find.text(label).hitTestable().last);
      await h.settle();
    }

    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await h.go('/staff');
      await h.settle();
      errs.addAll(await h.shot('staff_users'));

      await tester.tap(find.byKey(const ValueKey('add_user')));
      await h.settle();
      errs.addAll(await h.shot('staff_user_new'));
      await tester.tap(find.text('Отмена').last);
      await h.settle();

      await tester.tap(find.text('Кассир Нигора').hitTestable().first);
      await h.settle();
      errs.addAll(await h.shot('staff_user_edit'));
      await tester.tap(find.text('Отмена').last);
      await h.settle();

      await tab('Рабочее время');
      errs.addAll(await h.shot('staff_time'));
      await tester.tap(find.byKey(const ValueKey('add_session')));
      await h.settle();
      errs.addAll(await h.shot('staff_time_add'));
      await tester.tap(find.text('Отмена').last);
      await h.settle();

      await tab('Мотивация');
      errs.addAll(await h.shot('staff_motivation'));

      await tab('Роли и права');
      errs.addAll(await h.shot('staff_roles'));

      await tab('Журнал действий');
      errs.addAll(await h.shot('staff_audit'));

      await h.go('/');
    }
    await h.finish();
    expect(errs, isEmpty);
  }, skip: !screenshotsEnabled);
}
