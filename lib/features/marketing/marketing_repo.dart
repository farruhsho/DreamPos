// Marketing data access: promotions & gift cards (reference data, written via
// drift with updatedAt + markDirty), gift card sales via GiftCardService
// (D-023), loyalty stats.
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../domain/errors.dart';
import '../../domain/services/sale_service.dart' show normalizeGiftCode;
import '../../domain/services/gift_card_service.dart';
import '../../l10n/l10n.dart';
import 'promotion_logic.dart';

// Single source of truth lives in the domain (checkout uses the same rule).
export '../../domain/services/sale_service.dart' show normalizeGiftCode;

// ------------------------------------------------------------------ gift codes

/// No 0/O, 1/I/L — easy to read aloud and type.
const giftCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const giftCodeLength = 12;

String generateGiftCode([Random? random]) {
  final r = random ?? Random.secure();
  return String.fromCharCodes(
      List.generate(giftCodeLength, (_) => giftCodeAlphabet.codeUnitAt(r.nextInt(giftCodeAlphabet.length))));
}

/// Uppercases and strips spaces/dashes (codes are stored without them).

enum GiftStatus {
  active,
  used,
  expired,
  blocked;

  String labelIn(AppLocalizations l) => switch (this) {
        GiftStatus.active => l.mktGiftActive,
        GiftStatus.used => l.mktGiftUsed,
        GiftStatus.expired => l.mktGiftExpired,
        GiftStatus.blocked => l.mktGiftBlocked,
      };

  String get label => labelIn(L.current);
}

/// Effective status: an active card past its expiry is shown as expired.
GiftStatus giftStatusOf(GiftCard g, DateTime now) {
  switch (g.status) {
    case 'blocked':
      return GiftStatus.blocked;
    case 'used':
      return GiftStatus.used;
    case 'expired':
      return GiftStatus.expired;
  }
  if (g.expiresAt != null && now.isAfter(g.expiresAt!)) return GiftStatus.expired;
  if (g.balance <= 0) return GiftStatus.used;
  return GiftStatus.active;
}

/// Methods a certificate can be sold for (see [giftSaleMethods]).
Map<String, String> giftPaymentMethodsIn(AppLocalizations l) => {
      'cash': l.payCash,
      'card': l.payCard,
      'transfer': l.payTransfer,
    };

/// [giftPaymentMethodsIn] in the current UI language.
Map<String, String> get giftPaymentMethods => giftPaymentMethodsIn(L.current);

class MarketingRepo {
  MarketingRepo(this.db, [GiftCardService? gifts]) : gifts = gifts ?? GiftCardService(db);
  final AppDatabase db;
  final GiftCardService gifts;

  // ---------------------------------------------------------------- promos

  Future<bool> isPromoCodeTaken(String code, {String? exceptId}) async {
    final c = normalizePromoCode(code);
    if (c.isEmpty) return false;
    final rows = await (db.select(db.promotions)
          ..where((p) => p.deletedAt.isNull() & p.isActive.equals(true) & p.type.equals('promo_code')))
        .get();
    final now = DateTime.now();
    return rows.any((p) =>
        p.id != exceptId &&
        normalizePromoCode(p.code ?? '') == c &&
        statusOf(p, now) != PromoStatus.finished);
  }

  Future<String> savePromotion(PromoDraft d, {required String userId}) async {
    return db.transaction(() async {
      final taken = d.type == 'promo_code' && d.isActive && await isPromoCodeTaken(d.code ?? '', exceptId: d.id);
      final err = validatePromo(d, codeTaken: taken);
      if (err != null) throw BusinessException(err);
      final now = DateTime.now();
      final comp = PromotionsCompanion(
        name: Value(d.name.trim()),
        type: Value(d.type),
        value: Value(d.storedValue),
        targetId: Value(promoTypeHasTarget(d.type) ? d.targetId : null),
        code: Value(d.type == 'promo_code' ? normalizePromoCode(d.code!) : null),
        minOrderTotal: Value(promoTypeHasMinOrder(d.type) ? d.minOrderTotal : 0),
        buyQty: Value(d.type == 'buy_x_get_y' ? d.buyQty : 0),
        getQty: Value(d.type == 'buy_x_get_y' ? d.getQty : 0),
        startsAt: Value(d.startsAt),
        endsAt: Value(d.endsAt),
        isActive: Value(d.isActive),
        updatedAt: Value(now),
      );
      final String id;
      if (d.id == null) {
        id = newId();
        await db.into(db.promotions).insert(comp.copyWith(id: Value(id), createdAt: Value(now)));
        await db.audit('promotion.create', userId: userId, entity: 'promotion', entityId: id,
            details: '${d.type}; ${d.storedValue}; ${d.name.trim()}');
      } else {
        id = d.id!;
        await (db.update(db.promotions)..where((p) => p.id.equals(id))).write(comp);
        await db.audit('promotion.update', userId: userId, entity: 'promotion', entityId: id,
            details: '${d.type}; ${d.storedValue}; active=${d.isActive}');
      }
      await db.markDirty('promotions', id);
      return id;
    });
  }

  Future<void> setPromotionActive(Promotion p, bool active, {required String userId}) async {
    if (active && p.type == 'promo_code' && await isPromoCodeTaken(p.code ?? '', exceptId: p.id)) {
      throw BusinessException(L.current.mktErrCodeTaken('${p.code}'));
    }
    await (db.update(db.promotions)..where((t) => t.id.equals(p.id)))
        .write(PromotionsCompanion(isActive: Value(active), updatedAt: Value(DateTime.now())));
    await db.markDirty('promotions', p.id);
    await db.audit(active ? 'promotion.enable' : 'promotion.disable',
        userId: userId, entity: 'promotion', entityId: p.id, details: p.name);
  }

  Future<void> deletePromotion(Promotion p, {required String userId}) async {
    final now = DateTime.now();
    await (db.update(db.promotions)..where((t) => t.id.equals(p.id)))
        .write(PromotionsCompanion(deletedAt: Value(now), isActive: const Value(false), updatedAt: Value(now)));
    await db.markDirty('promotions', p.id, op: 'delete');
    await db.audit('promotion.delete', userId: userId, entity: 'promotion', entityId: p.id, details: p.name);
  }

  // ---------------------------------------------------------------- gift cards

  Future<GiftCard?> giftByCode(String code) => (db.select(db.giftCards)
        ..where((g) => g.code.equals(normalizeGiftCode(code)) & g.deletedAt.isNull()))
      .getSingleOrNull();

  Future<bool> isGiftCodeTaken(String code) async =>
      (await (db.select(db.giftCards)..where((g) => g.code.equals(normalizeGiftCode(code)))).get())
          .isNotEmpty;

  Future<String> generateUniqueGiftCode({Random? random}) async {
    for (var i = 0; i < 20; i++) {
      final c = generateGiftCode(random);
      if (!await isGiftCodeTaken(c)) return c;
    }
    throw BusinessException(L.current.mktErrUniqueCode);
  }

  /// Sells a certificate with a single payment — delegates to
  /// [GiftCardService.sell] (numbered document, D-023). An open shift is
  /// required for every method.
  Future<GiftCard> issueGiftCard({
    required String code,
    required int amount,
    required String method,
    required String userId,
    DateTime? expiresAt,
    String? customerId,
    String? shiftId,
  }) async {
    final res = await gifts.sell(GiftCardSaleRequest(
      code: code,
      amount: amount,
      payments: [GiftSalePaymentInput(method, amount)],
      cashierId: userId,
      shiftId: shiftId,
      customerId: customerId,
      expiresAt: expiresAt,
    ));
    return res.giftCard;
  }

  Future<void> setGiftBlocked(GiftCard g, bool blocked, {required String userId, String? reason}) async {
    if (!blocked && g.soldSaleId != null) {
      final sale = await (db.select(db.giftCardSales)..where((s) => s.id.equals(g.soldSaleId!))).getSingleOrNull();
      if (sale?.status == GiftSaleStatus.voided) {
        throw BusinessException(L.current.mktErrUnblockVoided);
      }
    }
    final status = blocked ? 'blocked' : (g.balance > 0 ? 'active' : 'used');
    await (db.update(db.giftCards)..where((t) => t.id.equals(g.id)))
        .write(GiftCardsCompanion(status: Value(status), updatedAt: Value(DateTime.now())));
    await db.markDirty('gift_cards', g.id);
    await db.audit(blocked ? 'gift_card.block' : 'gift_card.unblock',
        userId: userId, entity: 'gift_card', entityId: g.id, details: '${g.code}; ${reason ?? ''}');
  }
}

final marketingRepoProvider = Provider((ref) => MarketingRepo(ref.watch(databaseProvider)));

final promotionsProvider = StreamProvider<List<Promotion>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.promotions)
        ..where((p) => p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
      .watch();
});

final giftCardsProvider = StreamProvider<List<GiftCard>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.giftCards)
        ..where((g) => g.deletedAt.isNull())
        ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
      .watch();
});

final categoriesListProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)]))
      .watch();
});

/// Names of products referenced by promotions (id -> name).
final promoProductNamesProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(databaseProvider);
  final ids = (ref.watch(promotionsProvider).value ?? const <Promotion>[])
      .where((p) => p.type == 'percent_product' || p.type == 'buy_x_get_y')
      .map((p) => p.targetId)
      .whereType<String>()
      .toSet();
  if (ids.isEmpty) return Stream.value(const {});
  return (db.select(db.products)..where((p) => p.id.isIn(ids)))
      .watch()
      .map((rows) => {for (final p in rows) p.id: p.name});
});

/// Customer names for gift cards (id -> name).
final customerNamesProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.selectOnly(db.customers)..addColumns([db.customers.id, db.customers.name]);
  return q.watch().map((rows) => {
        for (final r in rows) r.read(db.customers.id)!: r.read(db.customers.name)!,
      });
});

class LoyaltyStats {
  const LoyaltyStats({
    required this.liability,
    required this.holders,
    required this.earned30,
    required this.spent30,
    required this.adjusted30,
  });
  final int liability;
  final int holders;
  final int earned30;
  final int spent30;
  final int adjusted30;
}

Future<LoyaltyStats> loadLoyaltyStats(AppDatabase db, {DateTime? now}) async {
  final since = (now ?? DateTime.now()).subtract(const Duration(days: 30));
  final sum = db.customers.bonusBalance.sum();
  final cnt = db.customers.id.count();
  final liab = await (db.selectOnly(db.customers)
        ..addColumns([sum])
        ..where(db.customers.deletedAt.isNull()))
      .getSingle();
  final holders = await (db.selectOnly(db.customers)
        ..addColumns([cnt])
        ..where(db.customers.deletedAt.isNull() & db.customers.bonusBalance.isBiggerThanValue(0)))
      .getSingle();
  final l = db.customerLedger;
  final lsum = l.amount.sum();
  final rows = await (db.selectOnly(l)
        ..addColumns([l.kind, lsum])
        ..where(l.createdAt.isBiggerOrEqualValue(since) & l.kind.isIn(['bonus_earn', 'bonus_spend', 'bonus_adjust']))
        ..groupBy([l.kind]))
      .get();
  final by = {for (final r in rows) r.read(l.kind)!: r.read(lsum) ?? 0};
  return LoyaltyStats(
    liability: liab.read(sum) ?? 0,
    holders: holders.read(cnt) ?? 0,
    earned30: by['bonus_earn'] ?? 0,
    spent30: -(by['bonus_spend'] ?? 0),
    adjusted30: by['bonus_adjust'] ?? 0,
  );
}

/// Recomputed whenever customers or the ledger change.
final loyaltyStatsProvider = StreamProvider<LoyaltyStats>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect('SELECT 1', readsFrom: {db.customers, db.customerLedger})
      .watch()
      .asyncMap((_) => loadLoyaltyStats(db));
});
