import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/pos/cart_controller.dart';
import 'package:dreampos/features/pos/pos_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late Fixture f;
  late ProviderContainer c;

  setUp(() async {
    f = await Fixture.create();
    c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(f.db)]);
  });
  tearDown(() async {
    c.dispose();
    await f.db.close();
  });

  test('add product -> checkout cash -> stock decreased, change computed', () async {
    final p = await f.product('Хлеб', price: 4000, stock: 10);
    final ctl = c.read(cartProvider.notifier);
    ctl.addProduct(p);
    ctl.addProduct(p, qty: 2);

    final quote = await c.read(cartQuoteProvider.future);
    expect(quote!.total, 12000);

    final res = await c.read(saleServiceProvider).checkout(c.read(cartProvider).toRequest(
          cashierId: f.owner.id,
          shiftId: f.shift.id,
          payments: [PaymentInput('cash', 20000)],
        ));
    expect(res.changeDue, 8000);
    expect(res.sale.total, 12000);
    expect((await f.reload(p)).stockQty, 7);
  });

  test('live quote reflects manual and customer discounts', () async {
    final p = await f.product('Сыр', price: 10000);
    final cust = await f.customer('Анна', discount: 5);
    final ctl = c.read(cartProvider.notifier);
    ctl.addProduct(p, qty: 2);
    expect((await c.read(cartQuoteProvider.future))!.total, 20000);

    ctl.setCustomer(cust);
    final q2 = (await c.read(cartQuoteProvider.future))!;
    expect(q2.total, 19000);
    expect(q2.appliedPromotions, contains('Скидка клиента'));

    ctl.setLineDiscount(c.read(cartProvider).lines.single.key, amount: 1000);
    expect((await c.read(cartQuoteProvider.future))!.total, 18000);

    ctl.setOrderDiscount(percent: 10);
    expect((await c.read(cartQuoteProvider.future))!.total, 16200);
  });

  test('promo code validity is reported', () async {
    final p = await f.product('Кофе', price: 10000);
    await f.db.into(f.db.promotions).insert(PromotionsCompanion.insert(
          id: newId(),
          name: 'Весна',
          type: 'promo_code',
          value: 10,
          code: const Value('SPRING'),
        ));
    final ctl = c.read(cartProvider.notifier);
    ctl.addProduct(p);
    ctl.setPromoCode('spring');
    final q = (await c.read(cartQuoteProvider.future))!;
    expect(q.promoCodeValid, isTrue);
    expect(q.total, 9000);
    ctl.setPromoCode('WRONG');
    expect((await c.read(cartQuoteProvider.future))!.promoCodeValid, isFalse);
  });

  test('selling beyond stock is blocked by the service', () async {
    final p = await f.product('Молоко', price: 1000, stock: 1);
    final ctl = c.read(cartProvider.notifier);
    ctl.addProduct(p, qty: 3);
    await expectLater(
      c.read(saleServiceProvider).checkout(c.read(cartProvider).toRequest(
            cashierId: f.owner.id,
            shiftId: f.shift.id,
            payments: [PaymentInput('cash', 3000)],
          )),
      throwsA(isA<BusinessException>()),
    );
    expect((await f.reload(p)).stockQty, 1);
  });

  test('cumulative manual discount: measured like checkout; approver is sent', () async {
    final auth = AuthService(f.db);
    final cashier = await auth.createUser(
        name: 'Кассир', role: Role.cashier, pin: '1357', maxDiscountPercent: 5);
    final manager = await auth.createUser(
        name: 'Менеджер', role: Role.manager, pin: '2468', maxDiscountPercent: 20);
    final p = await f.product('Куртка', price: 10000, stock: 5);
    final ctl = c.read(cartProvider.notifier);
    ctl.addProduct(p);
    // each discount alone is within 5%, together they are not
    ctl.setLineDiscount(c.read(cartProvider).lines.single.key, percent: 4);
    ctl.setOrderDiscount(percent: 4);
    final pct = await cartManualDiscountPercent(c.read(saleServiceProvider), c.read(cartProvider));
    expect(pct, closeTo(7.84, 0.01));
    expect(withinDiscountLimit(pct, cashier.maxDiscountPercent), isFalse);

    CheckoutRequest req() => c.read(cartProvider).toRequest(
          cashierId: cashier.id,
          shiftId: f.shift.id,
          payments: [PaymentInput('cash', 10000)],
        );
    // the service refuses without approval ...
    await expectLater(c.read(saleServiceProvider).checkout(req()),
        throwsA(isA<BusinessException>().having((e) => e.code, 'code', 'discount_limit')));
    // ... and accepts once the manager approval is attached to the cart
    ctl.setApprover(manager.id);
    final res = await c.read(saleServiceProvider).checkout(req());
    expect(res.sale.total, 10000 - 400 - 384);
    expect((await f.reload(p)).stockQty, 4);
    final audit = await (f.db.select(f.db.auditLog)
          ..where((a) => a.action.equals('discount.override')))
        .get();
    expect(audit.single.userId, manager.id);
  });

  test('no manual discounts -> 0%, nothing to approve', () async {
    final p = await f.product('Чай', price: 5000);
    c.read(cartProvider.notifier).addProduct(p);
    expect(await cartManualDiscountPercent(c.read(saleServiceProvider), c.read(cartProvider)), 0);
  });
}
