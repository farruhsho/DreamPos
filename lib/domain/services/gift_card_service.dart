// Gift card sale documents (D-023). Selling a certificate is an advance
// received (liability), not revenue: nothing here touches `sales`,
// `sale_payments` or `cash_movements`. Cash is accounted for by
// ShiftService.report (giftSalesByMethod / giftRefundsByMethod).
import 'package:drift/drift.dart';

import '../../l10n/l10n.dart';
import '../../core/db/database.dart';
import '../errors.dart';
import 'sale_service.dart' show normalizeGiftCode;

/// Methods a certificate can be paid with. Bonus, debt and gift_card are not
/// money received and are refused.
const giftSaleMethods = ['cash', 'card', 'transfer'];

/// Gift card sale status values.
abstract final class GiftSaleStatus {
  static const completed = 'completed';
  static const voided = 'voided';
}

class GiftSalePaymentInput {
  const GiftSalePaymentInput(this.method, this.amount, {this.reference});
  final String method;

  /// Minor units, > 0. For cash: the part of the nominal paid in cash (net of
  /// change); what the buyer handed over goes to [GiftCardSaleRequest.cashTendered].
  final int amount;

  /// Card slip / transfer id.
  final String? reference;
}

class GiftCardSaleRequest {
  const GiftCardSaleRequest({
    required this.code,
    required this.amount,
    required this.payments,
    required this.cashierId,
    required this.shiftId,
    this.registerId,
    this.customerId,
    this.expiresAt,
    this.note,
    this.cashTendered,
    this.now,
  });

  final String code;

  /// Nominal, minor units.
  final int amount;
  final List<GiftSalePaymentInput> payments;
  final String cashierId;

  /// Always required (a till operation); nullable only so the service owns
  /// the user-facing message.
  final String? shiftId;

  /// Defaults to the shift's register.
  final String? registerId;
  final String? customerId;
  final DateTime? expiresAt;
  final String? note;

  /// Cash handed over by the buyer; ≥ the cash payment. The difference is
  /// change. Null = exact cash.
  final int? cashTendered;

  /// Test clock.
  final DateTime? now;
}

class GiftSaleResult {
  const GiftSaleResult({
    required this.saleId,
    required this.number,
    required this.giftCard,
    required this.changeDue,
  });
  final String saleId;
  final int number;
  final GiftCard giftCard;
  final int changeDue;
}

/// Gift card sale payments / refunds by method for a period.
class GiftSalesByMethod {
  const GiftSalesByMethod({
    this.sold = const {},
    this.refunded = const {},
    this.soldCount = 0,
    this.voidedCount = 0,
  });

  /// Payments of every sale document created in the period (incl. ones voided
  /// later), by method.
  final Map<String, int> sold;

  /// Refunds of sales voided in the period, by original method.
  final Map<String, int> refunded;
  final int soldCount;
  final int voidedCount;

  int get soldTotal => sold.values.fold(0, (s, v) => s + v);
  int get refundedTotal => refunded.values.fold(0, (s, v) => s + v);
  int get netTotal => soldTotal - refundedTotal;

  /// sold − refunded per method (methods with both zero are omitted).
  Map<String, int> get net {
    final out = <String, int>{};
    for (final m in {...sold.keys, ...refunded.keys}) {
      final v = (sold[m] ?? 0) - (refunded[m] ?? 0);
      if (v != 0 || (sold[m] ?? 0) != 0) out[m] = v;
    }
    return out;
  }

  bool get isEmpty => soldCount == 0 && voidedCount == 0;
}

/// Cash-basis gift card advance figures for `[from, to)` — the same rule as
/// the shift report: a sale counts when it was made, a void when it was
/// voided. Never part of revenue. For the payments report.
Future<GiftSalesByMethod> giftSalesByMethod(AppDatabase db, DateTime from, DateTime to) async {
  final s = db.giftCardSales;
  final sold = await (db.select(s)
        ..where((g) =>
            g.deletedAt.isNull() & g.createdAt.isBiggerOrEqualValue(from) & g.createdAt.isSmallerThanValue(to)))
      .get();
  final voided = await (db.select(s)
        ..where((g) =>
            g.deletedAt.isNull() &
            g.status.equals(GiftSaleStatus.voided) &
            g.voidedAt.isBiggerOrEqualValue(from) &
            g.voidedAt.isSmallerThanValue(to)))
      .get();
  return GiftSalesByMethod(
    sold: await _byMethod(db, sold.map((x) => x.id)),
    refunded: await _byMethod(db, voided.map((x) => x.id)),
    soldCount: sold.length,
    voidedCount: voided.length,
  );
}

Future<Map<String, int>> _byMethod(AppDatabase db, Iterable<String> saleIds) async {
  final ids = saleIds.toList();
  final out = <String, int>{};
  if (ids.isEmpty) return out;
  final pays = await (db.select(db.giftCardSalePayments)
        ..where((p) => p.saleId.isIn(ids) & p.deletedAt.isNull()))
      .get();
  for (final p in pays) {
    out[p.method] = (out[p.method] ?? 0) + p.amount;
  }
  return out;
}

/// The only writer of `gift_card_sales` / `gift_card_sale_payments`.
class GiftCardService {
  GiftCardService(this.db);
  final AppDatabase db;

  /// Validates and normalises a certificate code; throws on a bad one.
  static String validateCode(String raw) {
    final c = normalizeGiftCode(raw);
    if (c.length < 6) throw BusinessException(L.current.errGiftCodeTooShort);
    if (c.length > 32) throw BusinessException(L.current.errGiftCodeTooLong);
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(c)) {
      throw BusinessException(L.current.errGiftCodeChars);
    }
    return c;
  }

  /// Sells a certificate: card + numbered document + payments, one transaction.
  Future<GiftSaleResult> sell(GiftCardSaleRequest r) async {
    final now = r.now ?? DateTime.now();
    final code = validateCode(r.code);
    if (r.amount <= 0) throw BusinessException(L.current.errFaceValuePositive);
    if (r.expiresAt != null && r.expiresAt!.isBefore(now)) {
      throw BusinessException(L.current.errExpiryPassed);
    }
    if (r.shiftId == null) throw BusinessException(L.current.errOpenShiftToSellGift);
    if (r.payments.isEmpty) throw BusinessException(L.current.errChoosePaymentMethod);
    for (final p in r.payments) {
      if (!giftSaleMethods.contains(p.method)) {
        throw BusinessException(L.current.errGiftPaymentMethods);
      }
      if (p.amount <= 0) throw BusinessException(L.current.errPaymentMustBePositive);
    }
    final paid = r.payments.fold<int>(0, (s, p) => s + p.amount);
    if (paid != r.amount) {
      throw BusinessException(L.current.errGiftPaymentsMismatch);
    }
    final cashPart = r.payments.where((p) => p.method == 'cash').fold<int>(0, (s, p) => s + p.amount);
    var change = 0;
    if (r.cashTendered != null) {
      if (cashPart == 0) {
        if (r.cashTendered! > 0) throw BusinessException(L.current.errCashNotInPayment);
      } else {
        if (r.cashTendered! < cashPart) throw BusinessException(L.current.errCashTenderedLess);
        change = r.cashTendered! - cashPart;
      }
    }
    final note = (r.note ?? '').trim().isEmpty ? null : r.note!.trim();

    return db.transaction(() async {
      final shift = await (db.select(db.shifts)..where((s) => s.id.equals(r.shiftId!))).getSingleOrNull();
      if (shift == null || shift.status != 'open') {
        throw BusinessException(L.current.errOpenShiftToSellGift);
      }
      final taken = await (db.select(db.giftCards)..where((g) => g.code.equals(code))).get();
      if (taken.isNotEmpty) throw BusinessException(L.current.errGiftCodeExists(code));
      if (r.customerId != null) {
        final c = await (db.select(db.customers)..where((c) => c.id.equals(r.customerId!))).getSingleOrNull();
        if (c == null || c.deletedAt != null) throw BusinessException(L.current.commonCustomerNotFound);
      }

      final cardId = newId();
      final saleId = newId();
      final number = await db.nextNumber('gift_sale');
      await db.into(db.giftCards).insert(GiftCardsCompanion.insert(
            id: cardId,
            code: code,
            initialAmount: r.amount,
            balance: r.amount,
            expiresAt: Value(r.expiresAt),
            customerId: Value(r.customerId),
            soldSaleId: Value(saleId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));
      await db.markDirty('gift_cards', cardId);
      await db.into(db.giftCardSales).insert(GiftCardSalesCompanion.insert(
            id: saleId,
            number: number,
            giftCardId: cardId,
            amount: r.amount,
            shiftId: Value(shift.id),
            registerId: Value(r.registerId ?? shift.registerId),
            cashierId: Value(r.cashierId),
            customerId: Value(r.customerId),
            changeDue: Value(change),
            note: Value(note),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));
      await db.markDirty('gift_card_sales', saleId);
      for (final p in r.payments) {
        final pid = newId();
        final ref = (p.reference ?? '').trim();
        await db.into(db.giftCardSalePayments).insert(GiftCardSalePaymentsCompanion.insert(
              id: pid,
              saleId: saleId,
              method: p.method,
              amount: p.amount,
              reference: Value(ref.isEmpty ? null : ref),
              createdAt: Value(now),
              updatedAt: Value(now),
            ));
        await db.markDirty('gift_card_sale_payments', pid);
      }
      await db.audit('gift_card.sell',
          userId: r.cashierId,
          entity: 'gift_card_sale',
          entityId: saleId,
          details: '№$number; $code; ${r.amount}; '
              '${r.payments.map((p) => '${p.method}=${p.amount}').join(',')}'
              '${change > 0 ? '; change=$change' : ''}');
      final card = await (db.select(db.giftCards)..where((g) => g.id.equals(cardId))).getSingle();
      return GiftSaleResult(saleId: saleId, number: number, giftCard: card, changeDue: change);
    });
  }

  /// Why [sale] cannot be voided now, or null when it can (shift aside).
  /// Used by the UI to disable the button with a tooltip.
  Future<String?> voidBlockReason(String giftSaleId) async {
    final sale = await (db.select(db.giftCardSales)..where((s) => s.id.equals(giftSaleId))).getSingleOrNull();
    if (sale == null || sale.deletedAt != null) return L.current.errDocumentNotFound;
    if (sale.status != GiftSaleStatus.completed) return L.current.errGiftSaleAlreadyVoided;
    final card = await (db.select(db.giftCards)..where((g) => g.id.equals(sale.giftCardId))).getSingleOrNull();
    if (card == null) return L.current.errGiftNotFound;
    if (await _isUsed(card)) return L.current.errGiftUsedCannotVoid;
    return null;
  }

  Future<bool> _isUsed(GiftCard card) async {
    if (card.balance != card.initialAmount || card.status == 'used') return true;
    final pays = await (db.select(db.salePayments)
          ..where((p) => p.method.equals('gift_card') & p.reference.equals(card.code))
          ..limit(1))
        .get();
    return pays.isNotEmpty;
  }

  /// Voids a gift card sale: the money goes back by the original methods in
  /// [shiftId]; the card is blocked with balance 0 (kept, not deleted).
  Future<void> voidSale(
    String giftSaleId, {
    required String reason,
    required String userId,
    required String? shiftId,
    DateTime? now,
  }) async {
    final why = reason.trim();
    if (why.isEmpty) throw BusinessException(L.current.errVoidReasonRequired);
    if (shiftId == null) throw BusinessException(L.current.errOpenShiftToVoid);
    final at = now ?? DateTime.now();
    await db.transaction(() async {
      final shift = await (db.select(db.shifts)..where((s) => s.id.equals(shiftId))).getSingleOrNull();
      if (shift == null || shift.status != 'open') {
        throw BusinessException(L.current.errOpenShiftToVoid);
      }
      final sale = await (db.select(db.giftCardSales)..where((s) => s.id.equals(giftSaleId))).getSingleOrNull();
      if (sale == null || sale.deletedAt != null) throw BusinessException(L.current.errDocumentNotFound);
      if (sale.status != GiftSaleStatus.completed) {
        throw BusinessException(L.current.errGiftSaleNumberVoided('${sale.number}'));
      }
      final card = await (db.select(db.giftCards)..where((g) => g.id.equals(sale.giftCardId))).getSingle();
      if (await _isUsed(card)) {
        throw BusinessException(L.current.errGiftUsedCannotVoid);
      }
      await (db.update(db.giftCardSales)..where((s) => s.id.equals(sale.id))).write(GiftCardSalesCompanion(
            status: const Value(GiftSaleStatus.voided),
            voidedAt: Value(at),
            voidedBy: Value(userId),
            voidShiftId: Value(shiftId),
            voidReason: Value(why),
            updatedAt: Value(at),
          ));
      await db.markDirty('gift_card_sales', sale.id);
      await (db.update(db.giftCards)..where((g) => g.id.equals(card.id))).write(GiftCardsCompanion(
            status: const Value('blocked'),
            balance: const Value(0),
            updatedAt: Value(at),
          ));
      await db.markDirty('gift_cards', card.id);
      final refunds = await _byMethod(db, [sale.id]);
      await db.audit('gift_card.void_sale',
          userId: userId,
          entity: 'gift_card_sale',
          entityId: sale.id,
          details: '№${sale.number}; ${card.code}; ${sale.amount}; '
              '${refunds.entries.map((e) => '${e.key}=${e.value}').join(',')}; $why');
    });
  }
}
