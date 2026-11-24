import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/shifts/z_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

/// Scrolls the vertical list of the current tab until [f] is on screen
/// (ensureVisible would also scroll the horizontal TabBarView).
Future<void> reveal(WidgetTester tester, Finder f) async {
  final lists = find.byType(ListView);
  if (lists.evaluate().isEmpty) return;
  await tester.drag(lists.first, const Offset(0, 5000));
  await tester.pump();
  await tester.dragUntilVisible(f, lists.first, const Offset(0, -150));
  await tester.pump();
}

void main() {
  testWidgets('shifts screens', (tester) async {
    final h = await UxHarness.start(tester);
    final shift = (await tester.runAsync(() => ShiftService(h.db).currentShift()))!;
    await tester.runAsync(() async {
      final svc = ShiftService(h.db);
      await svc.cashMovement(
        shiftId: shift.id,
        kind: 'pay_in',
        amount: 200000,
        userId: h.owner.id,
        reason: 'Размен из сейфа',
      );
      await svc.cashMovement(
        shiftId: shift.id,
        kind: 'expense',
        amount: 45000,
        userId: h.owner.id,
        expenseCategory: 'Хозтовары',
        reason: 'Пакеты и скотч',
      );
      await svc.cashMovement(shiftId: shift.id, kind: 'collection', amount: 300000, userId: h.owner.id);
      // Gift card sales for the «Сертификаты» section (D-023).
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
        payments: const [GiftSalePaymentInput('cash', 200000)],
        cashierId: h.owner.id,
        shiftId: shift.id,
      ));
      await gifts.voidSale(v.saleId, reason: 'Ошибка кассира', userId: h.owner.id, shiftId: shift.id);
    });
    final errs = <String>[];
    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      await h.go('/shifts');
      await h.settle();
      errs.addAll(await h.shot('shifts_current'));
      if (size == 'phone') {
        await tester.drag(find.byType(ListView).first, const Offset(0, -900));
        await h.settle();
        errs.addAll(await h.shot('shifts_current_scrolled'));
        await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
        await h.settle();
        errs.addAll(await h.shot('shifts_current_scrolled2'));
        await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
        await h.settle();
      }

      await reveal(tester, find.byKey(const ValueKey('cash_expense')));
      await h.settle();
      await tester.tap(find.byKey(const ValueKey('cash_expense')));
      await h.settle();
      errs.addAll(await h.shot('shifts_cash_expense'));
      await tester.tap(find.text('Отмена').last);
      await h.settle();
      await reveal(tester, find.byKey(const ValueKey('cash_pay_in')));
      await h.settle();
      await tester.tap(find.byKey(const ValueKey('cash_pay_in')));
      await h.settle();
      errs.addAll(await h.shot('shifts_cash_pay_in'));
      await tester.tap(find.text('Отмена').last);
      await h.settle();

      await reveal(tester, find.byKey(const ValueKey('close_shift')));
      await h.settle();
      await tester.tap(find.byKey(const ValueKey('close_shift')));
      await h.settle();
      errs.addAll(await h.shot('shifts_close'));
      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('den_100000')), matching: find.byType(TextField)),
        '3',
      );
      await h.settle();
      errs.addAll(await h.shot('shifts_close_counted'));
      await tester.tap(find.text('Отмена').last);
      await h.settle();

      await tester.tap(find.text('История смен'));
      await h.settle();
      errs.addAll(await h.shot('shifts_history'));
      await tester.tap(find.text('Смена №1').hitTestable().last);
      await h.settle();
      errs.addAll(await h.shot('shifts_history_selected'));
      if (size == 'phone') {
        // Desktop and tablet show the report in the master-detail pane.
        Navigator.of(tester.element(find.byType(ZReportPanel))).pop();
        await h.settle();
      }
      await tester.tap(find.text('Текущая смена'));
      await h.settle();
    }
    await h.finish();
    expect(errs, isEmpty);
  }, skip: !screenshotsEnabled);
}
