// Visual QA screenshots for the POS (run with SCREENSHOTS=1).
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/features/pos/cart_controller.dart';
import 'package:dreampos/features/pos/parked_carts.dart';
import 'package:dreampos/features/pos/widgets/product_area.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ux/harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('pos screens', skip: !screenshotsEnabled, (tester) async {
    final h = await UxHarness.start(tester);
    // finders follow the screenshot language (SCREENSHOTS_LOCALE)
    final l = L.of(h.locale);
    final errors = <String>[];
    Future<void> shot(String n) async => errors.addAll(await h.shot('pos_$n'));
    Future<void> tap(Finder f) async {
      await tester.tap(f.first, warnIfMissed: false);
      await h.settle();
    }

    await tester.runAsync(() => h.db.setSetting('cash_rounding', '1000'));
    final cart = h.container.read(cartProvider.notifier);
    final customers = (await tester.runAsync(() => h.db.select(h.db.customers).get()))!;
    final Customer cust = customers.firstWhere((c) => c.debtLimit > 0, orElse: () => customers.first);

    for (final size in ['desktop', 'tablet', 'phone']) {
      h.setSize(size);
      cart.clear();
      await h.go('/pos');
      await shot('empty');

      // add 4 lines by tapping tiles
      for (var i = 0; i < 4; i++) {
        await tap(find.byType(ProductTile).at(i * 2));
      }
      await shot('cart');

      if (size == 'phone') {
        await tap(find.byKey(const Key('pos-open-cart')));
        await shot('cart_sheet');
        await tap(find.byKey(const Key('pos-cart-menu')));
        await shot('cart_menu');
        await tester.tapAt(const Offset(10, 820));
        await h.settle();
        // «Продать сертификат» from the cart page menu (D-023)
        await tap(find.byKey(const Key('pos-cart-menu')));
        await tap(find.text(l.posSellGiftCard));
        await shot('gift_sale');
        await tap(find.byTooltip(l.commonClose).last);
      } else {
        await tap(find.byTooltip(l.posCartActions));
        await tap(find.text(l.posSellGiftCard));
        await shot('gift_sale');
        await tap(find.byTooltip(l.commonClose).last);
      }

      // line discount
      await tap(find.byTooltip(l.posLineDiscount));
      await shot('discount_dialog');
      await tester.enterText(find.byType(TextFormField).last, '10');
      await h.settle();
      await tap(find.text(l.commonApply));

      cart.setCustomer(cust);
      await h.settle();
      await shot('cart_customer');

      await tap(find.byKey(const Key('pos-pay')));
      await shot('pay_simple');
      await tap(find.text(l.posMixed));
      await tester.enterText(find.widgetWithText(TextField, l.payCard), '50000');
      await h.settle();
      await shot('pay_split');
      final debtField = find.widgetWithText(TextField, l.payDebt);
      if (debtField.evaluate().isNotEmpty) {
        await tester.enterText(find.widgetWithText(TextField, l.payCard), '');
        await tester.enterText(debtField, '20000');
        await h.settle();
        await tester.ensureVisible(find.byKey(const Key('pay-debt-due')));
        await h.settle();
        await shot('pay_debt');
      }
      await tap(find.byTooltip(l.posCloseEsc));

      // parked list
      await tester.runAsync(
        () => h.container
            .read(parkedCartsProvider.notifier)
            .park(h.container.read(cartProvider), note: 'Азиз, вернётся через 5 минут', cashierName: 'Фаррух'),
      );
      await tester.runAsync(
        () =>
            h.container.read(parkedCartsProvider.notifier).park(h.container.read(cartProvider), cashierName: 'Фаррух'),
      );
      await h.settle();
      await tap(find.byTooltip(size == 'phone' ? l.posParkedReceipts : l.posParkedTooltip));
      await shot('parked');
      await tap(find.byTooltip(l.commonClose));
      for (final p in [...?h.container.read(parkedCartsProvider).value]) {
        await tester.runAsync(() => h.container.read(parkedCartsProvider.notifier).remove(p.id));
      }
      if (size == 'phone') {
        await tap(find.byType(BackButton));
      }
    }
    await h.finish();
    expect(errors, isEmpty);
  });
}
