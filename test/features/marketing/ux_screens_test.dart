import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ux/harness.dart';

void main() {
  for (final size in uxSizes.keys) {
    testWidgets('marketing screens $size', skip: !screenshotsEnabled, (tester) async {
      final h = await UxHarness.start(tester, size: size);
      final l = L.of(h.locale);
      final errors = <String>[];
      Future<void> shot(String n) async => errors.addAll(await h.shot(n));
      Future<void> pop(Finder inside) async {
        Navigator.of(tester.element(inside.last)).pop();
        await h.settle();
      }

      await h.go('/marketing');
      await shot('marketing_promotions');

      await tester.tap(find.text(l.mktNewPromo).first);
      await h.settle();
      await shot('marketing_promo_editor');
      await pop(find.text(l.mktPromoEnabled));

      await tester.tap(find.text(l.mktTestOnReceipt).first);
      await h.settle();
      await shot('marketing_simulator');
      await tester.tap(find.text(l.mktSimAddProduct).first);
      await h.settle();
      await shot('marketing_simulator_pick');
      await tester.tap(find.text('Вода минеральная 1.5л').last);
      await h.settle();
      await tester.enterText(find.widgetWithText(TextField, l.mktSimQtyShort).first, '3');
      await h.settle();
      await shot('marketing_simulator_cart');
      await pop(find.text(l.mktSimTitle));

      await tester.tap(find.text(l.mktTabGiftCards).first);
      await h.settle();
      await shot('marketing_gift_cards_empty');

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
        await tester.runAsync(
          () => h.db
              .into(h.db.giftCards)
              .insert(
                GiftCardsCompanion.insert(
                  id: 'ux-gift-$i',
                  code: code,
                  initialAmount: initial,
                  balance: balance,
                  status: Value(status),
                  expiresAt: Value(expires),
                  customerId: Value(cust),
                  createdAt: Value(now.subtract(Duration(days: i * 9))),
                  updatedAt: Value(now),
                ),
              ),
        );
      }
      await h.settle();
      await shot('marketing_gift_cards');
      // D-023: the shared «Продажа сертификата» dialog, success, detail, list.
      await tester.tap(find.text(l.mktIssue).first);
      await h.settle();
      await shot('marketing_gift_issue');
      await tester.tap(find.widgetWithText(ChoiceChip, l.mktPayMixed));
      await h.settle();
      await tester.enterText(find.byKey(const Key('gift-sale-amount')), '100000');
      await tester.enterText(find.byKey(const Key('gift-sale-card')), '30000');
      await tester.enterText(find.byKey(const Key('gift-sale-tendered')), '80000');
      FocusManager.instance.primaryFocus?.unfocus();
      await h.settle();
      await tester.ensureVisible(find.byKey(const Key('gift-sale-submit')));
      await h.settle();
      await shot('marketing_gift_issue_split');
      await tester.tap(find.byKey(const Key('gift-sale-submit')));
      await h.settle(10);
      await shot('marketing_gift_sale_success');
      await tester.tap(find.text(l.commonDone));
      await h.settle();

      final sold = (await tester.runAsync(() async {
        final s = await h.db.select(h.db.giftCardSales).getSingle();
        return (h.db.select(h.db.giftCards)..where((g) => g.id.equals(s.giftCardId))).getSingle();
      }))!;
      await tester.tap(find.text(sold.code).first);
      await h.settle();
      await shot('marketing_gift_detail');
      await pop(find.text(l.mktSaleDocument));
      await tester.tap(find.text('GCB4T8N2LP').first);
      await h.settle();
      await shot('marketing_gift_detail_legacy');
      await pop(find.text(l.mktSaleDocument));

      await tester.tap(find.text(l.mktCheckBalance).first);
      await h.settle();
      await shot('marketing_gift_balance');
      await pop(find.text(l.mktGiftBalanceTitle));

      await tester.tap(find.text(l.mktGiftSalesSegment).first);
      await h.settle();
      await shot('marketing_gift_sales');
      await tester.tap(find.widgetWithText(ChoiceChip, l.mktSaleVoidedStatus));
      await h.settle();
      await shot('marketing_gift_sales_voided_empty');
      await tester.tap(find.text(l.mktTabGiftCards).last);
      await h.settle();

      await tester.tap(find.text(l.mktTabLoyalty).first);
      await h.settle();
      await shot('marketing_loyalty');

      await tester.tap(find.text(l.mktTabMailing).first);
      await h.settle();
      await shot('marketing_mailing');
      await tester.tap(find.textContaining(RegExp('^${RegExp.escape(l.custSegDebtors)} \\d')).first);
      await h.settle();
      await shot('marketing_mailing_debtors');
      await h.finish();
      expect(errors, isEmpty);
    });
  }
}
