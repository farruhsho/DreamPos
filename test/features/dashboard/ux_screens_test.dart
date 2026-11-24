// Visual QA screenshots for dashboard, reports and notifications.
// Run: SCREENSHOTS=1 SCREENSHOTS_DIR=build/screens_dashboard flutter test test/features/dashboard/ux_screens_test.dart
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/notifications/notification_engine.dart';
import 'package:dreampos/features/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

const _reportTabs = [
  'Продажи',
  'Товары',
  'Сотрудники',
  'Оплаты',
  'Склад',
  'Прогноз спроса',
  'AI-аналитика',
];

void main() {
  testWidgets('dashboard / reports / notifications screens', (tester) async {
    final h = await UxHarness.start(tester);
    final errors = <String, List<String>>{};
    // Gift card advances for the payments report block (D-023).
    await tester.runAsync(() async {
      final shift = (await ShiftService(h.db).currentShift())!;
      final gifts = GiftCardService(h.db);
      await gifts.sell(GiftCardSaleRequest(
        code: 'UXGIFT0001',
        amount: 500000,
        payments: const [GiftSalePaymentInput('cash', 200000), GiftSalePaymentInput('card', 300000)],
        cashierId: h.owner.id,
        shiftId: shift.id,
      ));
      final v = await gifts.sell(GiftCardSaleRequest(
        code: 'UXGIFT0002',
        amount: 200000,
        payments: const [GiftSalePaymentInput('transfer', 200000)],
        cashierId: h.owner.id,
        shiftId: shift.id,
      ));
      await gifts.voidSale(v.saleId, reason: 'Ошибка кассира', userId: h.owner.id, shiftId: shift.id);
    });
    Future<void> shot(String name) async {
      final e = await h.shot(name);
      if (e.isNotEmpty) errors['${h.sizeName}_$name'] = e;
    }

    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await h.go('/dashboard');
      await h.settle();
      await shot('dashboard');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -700));
      await h.settle();
      await shot('dashboard_scrolled');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
      await h.settle();
      await shot('dashboard_bottom');

      await h.go('/reports');
      for (var i = 0; i < _reportTabs.length; i++) {
        final f = find.descendant(of: find.byType(TabBar), matching: find.text(_reportTabs[i]));
        await tester.ensureVisible(f.first);
        await h.settle(2);
        await tester.tap(f.first);
        await h.settle(10);
        await shot('reports_$i');
        final sc = find.descendant(of: find.byType(TabBarView), matching: find.byType(Scrollable));
        if (sc.evaluate().isNotEmpty) {
          await tester.drag(sc.first, const Offset(0, -700), warnIfMissed: false);
          await h.settle();
          await shot('reports_${i}_scrolled');
          if (_reportTabs[i] == 'Оплаты') {
            await tester.drag(sc.first, const Offset(0, -3000), warnIfMissed: false);
            await h.settle();
            await shot('reports_payments_gifts');
          }
        }
      }
      // back to first tab for next size
      final first = find.descendant(of: find.byType(TabBar), matching: find.text(_reportTabs.first));
      await tester.ensureVisible(first);
      await h.settle(2);
      await tester.tap(first);
      await h.settle();

      await tester.runAsync(() => runNotificationChecksDetailed(h.db));
      await h.go('/notifications');
      await shot('notifications');
      // all read + "unread" filter -> filtered empty state
      final ids = (await tester.runAsync(() => h.db.select(h.db.notifications).get()))!
          .map((n) => n.id)
          .toList();
      await tester.runAsync(() => setNotificationsRead(h.db, ids, read: true));
      await h.settle();
      await shot('notifications_read');
      await tester.tap(find.textContaining('Непрочитанные'));
      await h.settle();
      await shot('notifications_filter_empty');
      // nothing at all -> empty state
      await tester.runAsync(() => softDeleteNotifications(h.db, ids));
      await h.settle();
      await shot('notifications_empty');
      await tester.runAsync(() => softDeleteNotifications(h.db, ids, restore: true));
      await tester.runAsync(() => setNotificationsRead(h.db, ids, read: false));
      await h.go('/dashboard');
    }
    await h.finish();
    // ignore: avoid_print
    errors.forEach((k, v) => print('ERRORS $k: ${v.first.split('\n').first}'));
    expect(errors, isEmpty);
  }, skip: !screenshotsEnabled);

  // Known bug report: "RenderFlex overflowed by 67 pixels" on phone /dashboard.
  // Reproduce the exact path: the app started directly at phone width.
  testWidgets('phone dashboard from a cold start', (tester) async {
    final h = await UxHarness.start(tester, size: 'phone');
    await h.go('/dashboard');
    await h.settle();
    final e = await h.shot('dashboard_cold');
    await h.go('/reports');
    final f = find.descendant(of: find.byType(TabBar), matching: find.text('Прогноз спроса'));
    await tester.ensureVisible(f.first);
    await h.settle(2);
    await tester.tap(f.first);
    await h.settle(10);
    await tester.tap(find.text('Как считается прогноз'));
    await h.settle();
    final e2 = await h.shot('reports_forecast_help_open');
    await h.finish();
    expect([...e, ...e2], isEmpty);
  }, skip: !screenshotsEnabled);
}
