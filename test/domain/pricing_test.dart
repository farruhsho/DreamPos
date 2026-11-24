import 'package:dreampos/domain/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

PricingLine line(String k, int price, {double qty = 1, String? cat, int manual = 0, double vat = 0, bool noDisc = false}) =>
    PricingLine(key: k, productId: 'p$k', categoryId: cat, qty: qty, unitPrice: price,
        manualDiscount: manual, vatPercent: vat, noDiscount: noDisc);

void main() {
  test('no discounts: total = gross', () {
    final r = PricingEngine.price(lines: [line('1', 1000, qty: 3), line('2', 250)]);
    expect(r.subtotal, 3250);
    expect(r.total, 3250);
    expect(r.discountTotal, 0);
  });

  test('best automatic discount wins, no stacking', () {
    final r = PricingEngine.price(
      lines: [line('1', 1000, cat: 'c')],
      promotions: const [PromoRule(id: 'a', name: 'Cat 10', type: 'percent_category', value: 10, targetId: 'c')],
      customerDiscountPercent: 15,
    );
    expect(r.lines.single.autoDiscount, 150);
    expect(r.lines.single.autoReason, 'Скидка клиента');
  });

  test('buy 2 get 1 on 7 units gives 2 free', () {
    final r = PricingEngine.price(
      lines: [PricingLine(key: '1', productId: 'w', qty: 7, unitPrice: 500)],
      promotions: const [PromoRule(id: 'b', name: '2+1', type: 'buy_x_get_y', value: 0, targetId: 'w', buyQty: 2, getQty: 1)],
    );
    expect(r.discountTotal, 1000);
  });

  test('manual line discount is capped to remaining amount', () {
    final r = PricingEngine.price(lines: [line('1', 1000, manual: 5000)]);
    expect(r.total, 0);
    expect(r.lines.single.manualDiscount, 1000);
  });

  test('order discount allocation sums exactly and never goes negative', () {
    final r = PricingEngine.price(
      lines: [line('1', 333), line('2', 333), line('3', 334)],
      manualOrderDiscountAmount: 100,
    );
    expect(r.total, 900);
    expect(r.lines.map((l) => l.orderDiscount).reduce((a, b) => a + b), 100);
    expect(r.lines.every((l) => l.total >= 0), isTrue);
  });

  test('order discount larger than total is clamped', () {
    final r = PricingEngine.price(lines: [line('1', 500)], manualOrderDiscountAmount: 9999);
    expect(r.total, 0);
  });

  test('noDiscount lines are excluded from all discounts', () {
    final r = PricingEngine.price(
      lines: [line('gift', 5000, noDisc: true), line('2', 1000)],
      customerDiscountPercent: 10,
      manualOrderDiscountPercent: 10,
    );
    expect(r.byKey('gift')!.total, 5000);
    expect(r.byKey('2')!.total, 810);
  });

  test('promo code: valid, case-insensitive, min order, invalid', () {
    const promos = [PromoRule(id: 'p', name: 'W5', type: 'promo_code', value: 5, code: 'WELCOME', minOrderTotal: 1000)];
    expect(PricingEngine.price(lines: [line('1', 2000)], promotions: promos, promoCode: 'welcome').total, 1900);
    final low = PricingEngine.price(lines: [line('1', 500)], promotions: promos, promoCode: 'WELCOME');
    expect(low.promoCodeValid, isFalse);
    expect(low.total, 500);
    expect(PricingEngine.price(lines: [line('1', 2000)], promotions: promos, promoCode: 'NOPE').promoCodeValid, isFalse);
    expect(PricingEngine.price(lines: [line('1', 2000)], promotions: promos).promoCodeValid, isNull);
  });

  test('order promotion requires min total; best single order promo applies', () {
    const promos = [
      PromoRule(id: 'a', name: '5%', type: 'percent_order', value: 5, minOrderTotal: 1000),
      PromoRule(id: 'b', name: '-200', type: 'amount_order', value: 200, minOrderTotal: 3000),
    ];
    expect(PricingEngine.price(lines: [line('1', 999)], promotions: promos).total, 999);
    expect(PricingEngine.price(lines: [line('1', 2000)], promotions: promos).total, 1900);
    expect(PricingEngine.price(lines: [line('1', 5000)], promotions: promos).total, 4750);
  });

  test('VAT is extracted from inclusive price', () {
    final r = PricingEngine.price(lines: [line('1', 11200, vat: 12)]);
    expect(r.vatTotal, 1200);
  });

  test('allocateProportionally is exact', () {
    expect(allocateProportionally(10, [1, 1, 1]).reduce((a, b) => a + b), 10);
    expect(allocateProportionally(0, [5, 5]), [0, 0]);
    expect(allocateProportionally(7, [0, 0]), [0, 0]);
  });

  test('cash rounding rounds down but never below one step', () {
    expect(PricingEngine.price(lines: [line('1', 12500)], cashRoundingStep: 1000).total, 12000);
    expect(PricingEngine.price(lines: [line('1', 500)], cashRoundingStep: 1000).total, 500);
    expect(PricingEngine.price(lines: [line('1', 12000)], cashRoundingStep: 1000).roundingDiscount, 0);
  });
}
