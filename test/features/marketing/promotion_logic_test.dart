import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/features/marketing/promotion_logic.dart';
import 'package:flutter_test/flutter_test.dart';

Promotion promo({
  String type = 'percent_order',
  double value = 10,
  String? code,
  int minOrder = 0,
  int buy = 0,
  int get = 0,
  DateTime? startsAt,
  DateTime? endsAt,
  bool active = true,
}) =>
    Promotion(
      id: 'p',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      name: 'Акция',
      type: type,
      value: value,
      code: code,
      minOrderTotal: minOrder,
      buyQty: buy,
      getQty: get,
      startsAt: startsAt,
      endsAt: endsAt,
      isActive: active,
    );

void main() {
  group('status', () {
    final now = DateTime(2026, 11, 24, 12);
    PromoStatus st({bool active = true, DateTime? s, DateTime? e}) =>
        promoStatus(isActive: active, startsAt: s, endsAt: e, now: now);

    test('computed from active flag and period', () {
      expect(st(), PromoStatus.active);
      expect(st(active: false), PromoStatus.disabled);
      expect(st(s: DateTime(2026, 11, 25)), PromoStatus.scheduled);
      expect(st(s: DateTime(2026, 11, 24)), PromoStatus.active, reason: 'start is inclusive');
      expect(st(e: DateTime(2026, 11, 24)), PromoStatus.finished, reason: 'end is exclusive');
      expect(st(e: DateTime(2026, 11, 25)), PromoStatus.active);
      expect(st(active: false, e: DateTime(2020)), PromoStatus.disabled);
    });

    test('draft end day is inclusive: stored as next midnight', () {
      final d = PromoDraft(startDay: DateTime(2026, 11, 24, 15), endDay: DateTime(2026, 11, 30, 9));
      expect(d.startsAt, DateTime(2026, 11, 24));
      expect(d.endsAt, DateTime(2026, 12, 1));
      final back = PromoDraft.from(promo(startsAt: d.startsAt, endsAt: d.endsAt));
      expect(back.endDay, DateTime(2026, 11, 30));
      expect(formatPeriod(d.startsAt, d.endsAt), '24.11.2026 — 30.11.2026');
      expect(formatPeriod(null, null), 'Бессрочно');
    });
  });

  group('validation', () {
    PromoDraft ok() => PromoDraft(name: 'Скидка', type: 'percent_order', percent: 10);

    test('valid percent promo', () => expect(validatePromo(ok()), isNull));

    test('name and percent range', () {
      expect(validatePromo(ok()..name = ' '), isNotNull);
      expect(validatePromo(ok()..percent = 0), contains('больше 0'));
      expect(validatePromo(ok()..percent = 100.5), contains('не больше 100'));
      expect(validatePromo(ok()..percent = 100), isNull);
      expect(validatePromo(ok()..percent = null), isNotNull);
    });

    test('amount order: positive, not above min order', () {
      final d = PromoDraft(name: 'A', type: 'amount_order', amount: 5000, minOrderTotal: 100000);
      expect(validatePromo(d), isNull);
      expect(validatePromo(d..amount = 0), isNotNull);
      expect(validatePromo(d..amount = 200000), contains('минимальной суммы'));
    });

    test('targets required for category/product/buy_x_get_y', () {
      expect(validatePromo(PromoDraft(name: 'A', type: 'percent_category', percent: 5)), 'Выберите категорию');
      expect(validatePromo(PromoDraft(name: 'A', type: 'percent_product', percent: 5)), 'Выберите товар');
      final bx = PromoDraft(name: 'A', type: 'buy_x_get_y', targetId: 'x', buyQty: 2, getQty: 1);
      expect(validatePromo(bx), isNull);
      expect(validatePromo(bx..getQty = 0), isNotNull);
      expect(bx.storedValue, 0);
    });

    test('promo code: format, uniqueness, percent or amount', () {
      final d = PromoDraft(name: 'A', type: 'promo_code', code: 'sale10', percent: 10);
      expect(validatePromo(d), isNull);
      expect(validatePromo(d, codeTaken: true), contains('уже используется'));
      expect(validatePromo(d..code = 'a b!'), isNotNull);
      d
        ..code = 'SALE'
        ..percentMode = false
        ..amount = 50;
      expect(validatePromo(d), contains('не меньше'), reason: 'small amounts would be read as percent');
      d.amount = 10000;
      expect(validatePromo(d), isNull);
      expect(d.storedValue, 10000);
      expect(promoValueIsPercent('promo_code', d.storedValue), isFalse);
      d.percentMode = true;
      expect(d.storedValue, 10);
      expect(promoValueIsPercent('promo_code', d.storedValue), isTrue);
    });

    test('end must not be before start', () {
      final d = ok()
        ..startDay = DateTime(2026, 12, 10)
        ..endDay = DateTime(2026, 12, 9);
      expect(validatePromo(d), contains('Дата окончания'));
      d.endDay = DateTime(2026, 12, 10);
      expect(validatePromo(d), isNull, reason: 'one-day promotion');
    });
  });

  test('round trip from stored promo_code amount', () {
    final d = PromoDraft.from(promo(type: 'promo_code', value: 25000, code: 'X'));
    expect(d.percentMode, isFalse);
    expect(d.amount, 25000);
  });

  test('description', () {
    expect(describePromo(promo(value: 10, minOrder: 100000)), '−10% на чек от ${Money.format(100000)}');
    expect(describePromo(promo(type: 'buy_x_get_y', buy: 2, get: 1, value: 0), targetName: 'Сок'),
        contains('2+1'));
    expect(describePromo(promo(type: 'promo_code', value: 5000, code: 'GIFT')),
        'Код GIFT: −${Money.format(5000)} на чек');
  });
}
