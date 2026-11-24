import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/features/notifications/notification_engine.dart';
import 'package:dreampos/features/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../reports/pump_helpers.dart';

void main() {
  testWidgets('empty state offers a manual check', (tester) async {
    final f = (await tester.runAsync(Fixture.create))!;
    await pumpScreen(tester, f.db, f.owner, const NotificationsScreen());
    expect(find.text('Уведомлений нет'), findsOneWidget);
    await unmount(tester);
    await tester.runAsync(f.db.close);
  });

  for (final size in const [Size(1300, 900), Size(390, 800)]) {
    testWidgets('lists, filters and marks notifications read (${size.width.toInt()}px)',
        (tester) async {
      final f = (await tester.runAsync(() async {
        final f = await Fixture.create();
        final p = await f.product('Молоко', stock: 1);
        await (f.db.update(f.db.products)..where((t) => t.id.equals(p.id)))
            .write(const ProductsCompanion(minStock: Value(5)));
        final c = await f.customer('Анна');
        final today = DateTime.now();
        await (f.db.update(f.db.customers)..where((t) => t.id.equals(c.id)))
            .write(CustomersCompanion(birthday: Value(DateTime(1995, today.month, today.day))));
        await runNotificationChecks(f.db);
        return f;
      }))!;
      await pumpScreen(tester, f.db, f.owner, const NotificationsScreen(), size: size);

      expect(find.text('Сегодня'), findsOneWidget);
      expect(find.text('Мало товара: Молоко'), findsOneWidget);
      expect(find.text('День рождения: Анна'), findsOneWidget);
      expect(find.text('Непрочитанных: 2'), findsOneWidget);

      // filter by kind
      // on phones the filter chips scroll horizontally
      await tester.ensureVisible(find.textContaining('Дни рождения ('));
      await tester.pump();
      await tester.tap(find.textContaining('Дни рождения ('));
      await settle(tester);
      expect(find.text('Мало товара: Молоко'), findsNothing);
      expect(find.text('День рождения: Анна'), findsOneWidget);
      await tester.ensureVisible(find.textContaining('Все ('));
      await tester.pump();
      await tester.tap(find.textContaining('Все ('));
      await settle(tester);

      // mark all read
      await tester.tap(find.byTooltip('Прочитать все'));
      await settle(tester);
      expect(find.text('Все прочитаны'), findsOneWidget);
      final rows = (await tester.runAsync(() => f.db.select(f.db.notifications).get()))!;
      expect(rows.every((n) => n.isRead), isTrue);

      await unmount(tester);
      await tester.runAsync(f.db.close);
    });
  }

  testWidgets('swipe soft-deletes a notification and "Отменить" restores it', (tester) async {
    final f = (await tester.runAsync(() async {
      final f = await Fixture.create();
      final p = await f.product('Кефир', stock: 1);
      await (f.db.update(f.db.products)..where((t) => t.id.equals(p.id)))
          .write(const ProductsCompanion(minStock: Value(5)));
      await runNotificationChecks(f.db);
      return f;
    }))!;
    await pumpScreen(tester, f.db, f.owner, const NotificationsScreen());
    expect(find.text('Мало товара: Кефир'), findsOneWidget);

    await tester.drag(find.text('Мало товара: Кефир'), const Offset(-900, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Мало товара: Кефир'), findsNothing);
    expect(find.text('Уведомление удалено'), findsOneWidget);
    var rows = (await tester.runAsync(() => f.db.select(f.db.notifications).get()))!;
    expect(rows.single.deletedAt, isNotNull, reason: 'soft delete, not hard delete');

    await tester.tap(find.text('Отменить'));
    await settle(tester);
    rows = (await tester.runAsync(() => f.db.select(f.db.notifications).get()))!;
    expect(rows.single.deletedAt, isNull);
    expect(find.text('Мало товара: Кефир'), findsOneWidget);

    await unmount(tester);
    await tester.runAsync(f.db.close);
  });
}
