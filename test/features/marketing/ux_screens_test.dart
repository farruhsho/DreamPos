import 'package:dreampos/core/db/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

void main() {
  for (final size in uxSizes.keys) {
    testWidgets('marketing screens $size', skip: !screenshotsEnabled, (tester) async {
      final h = await UxHarness.start(tester, size: size);
      Future<void> pop(Finder inside) async {
        Navigator.of(tester.element(inside.last)).pop();
        await h.settle();
      }

      await h.go('/marketing');
      await h.shot('marketing_promotions');

      await tester.tap(find.text('Новая акция').first);
      await h.settle();
      await h.shot('marketing_promo_editor');
      await pop(find.text('Акция включена'));

      await tester.tap(find.text('Проверить на чеке').first);
      await h.settle();
      await h.shot('marketing_simulator');
      await tester.tap(find.text('Добавить товар').first);
      await h.settle();
      await h.shot('marketing_simulator_pick');
      await tester.tap(find.text('Вода минеральная 1.5л').last);
      await h.settle();
      await tester.enterText(find.widgetWithText(TextField, 'Кол-во').first, '3');
      await h.settle();
      await h.shot('marketing_simulator_cart');
      await pop(find.text('Проверка акций на чеке'));

      await tester.tap(find.text('Сертификаты').first);
      await h.settle();
      await h.shot('marketing_gift_cards_empty');

      // Populated list: active, partly spent, used, blocked, expired.
      final customers = await tester.runAsync(() => h.db.select(h.db.customers).get());
      final now = DateTime.now();
      var i = 0;
      for (final (code, initial, balance, status, expires, cust) in [
        ('GC7K2M9QXA', 500000, 500000, 'active', DateTime(now.year + 1, now.month, 1), customers![0].id),
        ('GCB4T8N2LP', 300000, 120000, 'active', null, null),
        ('GCZ9R3W5HE', 200000, 0, 'used', DateTime(now.year + 1, 1, 1), customers[1].id),
        ('GCQ1D6V7YU', 1000000, 1000000, 'blocked', null, null),
        ('GCM5S2F8JK', 250000, 250000, 'active', DateTime(now.year - 1, 1, 1), null),
      ]) {
        i++;
        await tester.runAsync(() => h.db.into(h.db.giftCards).insert(GiftCardsCompanion.insert(
              id: 'ux-gift-$i',
              code: code,
              initialAmount: initial,
              balance: balance,
              status: Value(status),
              expiresAt: Value(expires),
              customerId: Value(cust),
              createdAt: Value(now.subtract(Duration(days: i * 9))),
              updatedAt: Value(now),
            )));
      }
      await h.settle();
      await h.shot('marketing_gift_cards');
      await tester.tap(find.text('Выпустить').first);
      await h.settle();
      await h.shot('marketing_gift_issue');
      await pop(find.text('Выпуск сертификата'));
      await tester.tap(find.text('Проверить баланс').first);
      await h.settle();
      await h.shot('marketing_gift_balance');
      await pop(find.text('Баланс сертификата'));

      await tester.tap(find.text('Лояльность').first);
      await h.settle();
      await h.shot('marketing_loyalty');

      await tester.tap(find.text('Рассылки').first);
      await h.settle();
      await h.shot('marketing_mailing');
      await tester.tap(find.textContaining(RegExp(r'^Должники \d')).first);
      await h.settle();
      await h.shot('marketing_mailing_debtors');
      await h.finish();
    });
  }
}
