import 'dart:math';

import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/customer_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/marketing/marketing_repo.dart';
import 'package:dreampos/features/marketing/promotion_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  group('gift code generator', () {
    test('12 chars from the unambiguous alphabet', () {
      final r = Random(7);
      final codes = <String>{};
      for (var i = 0; i < 2000; i++) {
        final c = generateGiftCode(r);
        expect(c, hasLength(giftCodeLength));
        expect(c.split('').every(giftCodeAlphabet.contains), isTrue);
        codes.add(c);
      }
      expect(codes.length, 2000, reason: 'no collisions in a sample');
      for (final ch in ['0', 'O', '1', 'I', 'L']) {
        expect(giftCodeAlphabet.contains(ch), isFalse, reason: '$ch is ambiguous');
      }
    });

    test('normalisation', () {
      expect(normalizeGiftCode(' abcd-efgh jkmn '), 'ABCDEFGHJKMN');
    });
  });

  group('repo', () {
    late Fixture f;
    late MarketingRepo repo;
    setUp(() async {
      f = await Fixture.create();
      repo = MarketingRepo(f.db);
    });
    tearDown(() => f.db.close());

    test('cash gift card sale is a pay-in of the open shift', () async {
      final before = await ShiftService(f.db).report(f.shift.id);
      final g = await repo.issueGiftCard(
          code: 'abcd-2345-wxyz', amount: 50000, method: 'cash', userId: f.owner.id, shiftId: f.shift.id);
      expect(g.code, 'ABCD2345WXYZ');
      expect(g.balance, 50000);
      expect(g.status, 'active');
      final after = await ShiftService(f.db).report(f.shift.id);
      expect(after.expectedCash - before.expectedCash, 50000);
      final mv = await f.db.select(f.db.cashMovements).get();
      expect(mv.single.reason, 'Продажа сертификата ABCD2345WXYZ');
      expect((await f.db.select(f.db.auditLog).get()).map((a) => a.action), contains('gift_card.issue'));
      // duplicate code rejected, nothing written
      expect(
          () => repo.issueGiftCard(
              code: 'ABCD2345WXYZ', amount: 1000, method: 'card', userId: f.owner.id, shiftId: f.shift.id),
          throwsA(isA<BusinessException>()));
      expect(await f.db.select(f.db.giftCards).get(), hasLength(1));
    });

    test('card payment does not touch the drawer; cash needs a shift', () async {
      await repo.issueGiftCard(code: 'CARDPAY123', amount: 1000, method: 'card', userId: f.owner.id);
      expect(await f.db.select(f.db.cashMovements).get(), isEmpty);
      expect(() => repo.issueGiftCard(code: 'NOSHIFT123', amount: 1000, method: 'cash', userId: f.owner.id),
          throwsA(isA<BusinessException>()));
      expect(() => repo.issueGiftCard(code: 'ZERO123456', amount: 0, method: 'card', userId: f.owner.id),
          throwsA(isA<BusinessException>()));
    });

    test('issued card is accepted by checkout; block/unblock', () async {
      final g = await repo.generateUniqueGiftCode();
      final card = await repo.issueGiftCard(code: g, amount: 5000, method: 'transfer', userId: f.owner.id);
      final p = await f.product('Товар', price: 3000);
      await SaleService(f.db).checkout(CheckoutRequest(
        lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 3000)],
        payments: [PaymentInput('gift_card', 3000, reference: g)],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ));
      expect((await repo.giftByCode(g))!.balance, 2000);
      await repo.setGiftBlocked(card, true, userId: f.owner.id, reason: 'утерян');
      final blocked = (await repo.giftByCode(g))!;
      expect(giftStatusOf(blocked, DateTime.now()), GiftStatus.blocked);
      await repo.setGiftBlocked(blocked, false, userId: f.owner.id);
      expect((await repo.giftByCode(g))!.status, 'active');
    });

    test('effective status: expired and used', () async {
      final g = await repo.issueGiftCard(
          code: 'EXPIRE1234', amount: 1000, method: 'free', userId: f.owner.id, expiresAt: DateTime.now().add(const Duration(days: 1)));
      expect(giftStatusOf(g, DateTime.now()), GiftStatus.active);
      expect(giftStatusOf(g, DateTime.now().add(const Duration(days: 2))), GiftStatus.expired);
      expect(giftStatusOf(g.copyWith(balance: 0), DateTime.now()), GiftStatus.used);
    });

    test('saved promotions are applied by the real checkout engine', () async {
      await repo.savePromotion(
          PromoDraft(name: 'Код', type: 'promo_code', code: 'vip', percentMode: false, amount: 1500),
          userId: f.owner.id);
      final rules = await SaleService(f.db).activePromotions();
      expect(rules.single.code, 'VIP');
      final p = await f.product('Товар', price: 10000);
      final quote = await SaleService(f.db).quote(CheckoutRequest(
        lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 10000)],
        payments: const [],
        cashierId: f.owner.id,
        promoCode: 'VIP',
      ));
      expect(quote.discountTotal, 1500);
    });

    test('promo code unique among active promotions', () async {
      final id = await repo.savePromotion(
          PromoDraft(name: 'A', type: 'promo_code', code: 'SALE', percent: 10), userId: f.owner.id);
      expect(
          () => repo.savePromotion(PromoDraft(name: 'B', type: 'promo_code', code: 'sale', percent: 5),
              userId: f.owner.id),
          throwsA(isA<BusinessException>()));
      // a disabled duplicate is allowed, but cannot be enabled while the first is active
      final id2 = await repo.savePromotion(
          PromoDraft(name: 'B', type: 'promo_code', code: 'SALE', percent: 5, isActive: false),
          userId: f.owner.id);
      final p2 = await (f.db.select(f.db.promotions)..where((p) => p.id.equals(id2))).getSingle();
      expect(() => repo.setPromotionActive(p2, true, userId: f.owner.id), throwsA(isA<BusinessException>()));
      final p1 = await (f.db.select(f.db.promotions)..where((p) => p.id.equals(id))).getSingle();
      await repo.deletePromotion(p1, userId: f.owner.id);
      await repo.setPromotionActive(p2, true, userId: f.owner.id);
      expect((await SaleService(f.db).activePromotions()).single.id, id2);
    });

    test('loyalty stats: liability and 30-day flows', () async {
      final c = await f.customer('Клиент');
      await CustomerService(f.db).adjustBonus(customerId: c.id, delta: 700, userId: f.owner.id, reason: 'тест');
      final st = await loadLoyaltyStats(f.db);
      expect(st.liability, 700);
      expect(st.holders, 1);
      expect(st.adjusted30, 700);
      expect(st.earned30, 0);
    });
  });
}
