// Pure promotion rules: type metadata, value encoding (as PricingEngine
// expects), validation and status computation.
import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../l10n/l10n.dart';

const promoTypes = [
  'percent_order',
  'amount_order',
  'percent_category',
  'percent_product',
  'buy_x_get_y',
  'promo_code',
];

String promoTypeLabel(String t, [AppLocalizations? l]) {
  final s = l ?? L.current;
  return switch (t) {
    'percent_order' => s.mktTypePercentOrder,
    'amount_order' => s.mktTypeAmountOrder,
    'percent_category' => s.mktTypePercentCategory,
    'percent_product' => s.mktTypePercentProduct,
    'buy_x_get_y' => s.mktTypeBuyXGetY,
    'promo_code' => s.mktTypePromoCode,
    _ => t,
  };
}

String promoTypeHelp(String t, [AppLocalizations? l]) {
  final s = l ?? L.current;
  return switch (t) {
    'percent_order' => s.mktHelpPercentOrder,
    'amount_order' => s.mktHelpAmountOrder,
    'percent_category' => s.mktHelpPercentCategory,
    'percent_product' => s.mktHelpPercentProduct,
    'buy_x_get_y' => s.mktHelpBuyXGetY,
    'promo_code' => s.mktHelpPromoCode,
    _ => '',
  };
}

/// Types whose value is always a percent.
bool promoTypeIsPercent(String t) =>
    t == 'percent_order' || t == 'percent_category' || t == 'percent_product';

/// Whether a stored promotion value means percent (engine semantics).
/// promo_code: value <= 100 → percent, otherwise amount in minor units.
bool promoValueIsPercent(String type, double value) => switch (type) {
      'amount_order' || 'buy_x_get_y' => false,
      'promo_code' => value <= 100,
      _ => true,
    };

bool promoTypeHasTarget(String t) =>
    t == 'percent_category' || t == 'percent_product' || t == 'buy_x_get_y';

bool promoTypeHasMinOrder(String t) =>
    t == 'percent_order' || t == 'amount_order' || t == 'promo_code';

/// Smallest amount (minor units) a promo_code amount discount may have so
/// that the engine does not read it as a percent.
const promoCodeMinAmount = 101;

String normalizePromoCode(String s) =>
    s.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

// ------------------------------------------------------------------ status

enum PromoStatus {
  active,
  scheduled,
  finished,
  disabled;

  String labelIn(AppLocalizations l) => switch (this) {
        PromoStatus.active => l.mktStatusActive,
        PromoStatus.scheduled => l.mktStatusScheduled,
        PromoStatus.finished => l.mktStatusFinished,
        PromoStatus.disabled => l.mktStatusDisabled,
      };

  String get label => labelIn(L.current);
}

/// endsAt is exclusive (the engine applies a promo while now < endsAt).
PromoStatus promoStatus({
  required bool isActive,
  DateTime? startsAt,
  DateTime? endsAt,
  required DateTime now,
}) {
  if (!isActive) return PromoStatus.disabled;
  if (endsAt != null && !now.isBefore(endsAt)) return PromoStatus.finished;
  if (startsAt != null && now.isBefore(startsAt)) return PromoStatus.scheduled;
  return PromoStatus.active;
}

PromoStatus statusOf(Promotion p, DateTime now) =>
    promoStatus(isActive: p.isActive, startsAt: p.startsAt, endsAt: p.endsAt, now: now);

// ------------------------------------------------------------------ draft

/// Editable promotion. [percentMode] matters for promo_code only.
class PromoDraft {
  PromoDraft({
    this.id,
    this.name = '',
    this.type = 'percent_order',
    this.percent,
    this.amount,
    this.percentMode = true,
    this.targetId,
    this.code,
    this.minOrderTotal = 0,
    this.buyQty = 2,
    this.getQty = 1,
    this.startDay,
    this.endDay,
    this.isActive = true,
  });

  factory PromoDraft.from(Promotion p) {
    final isPct = promoValueIsPercent(p.type, p.value);
    return PromoDraft(
      id: p.id,
      name: p.name,
      type: p.type,
      percent: isPct ? p.value : null,
      amount: isPct ? null : p.value.round(),
      percentMode: isPct,
      targetId: p.targetId,
      code: p.code,
      minOrderTotal: p.minOrderTotal,
      buyQty: p.buyQty == 0 ? 2 : p.buyQty,
      getQty: p.getQty == 0 ? 1 : p.getQty,
      startDay: p.startsAt,
      endDay: p.endsAt?.subtract(const Duration(days: 1)),
      isActive: p.isActive,
    );
  }

  String? id;
  String name;
  String type;
  double? percent;
  int? amount;
  bool percentMode;
  String? targetId;
  String? code;
  int minOrderTotal;
  int buyQty;
  int getQty;
  /// First day (inclusive).
  DateTime? startDay;
  /// Last day (inclusive). Stored as the next midnight (exclusive).
  DateTime? endDay;
  bool isActive;

  bool get usesPercent => switch (type) {
        'amount_order' || 'buy_x_get_y' => false,
        'promo_code' => percentMode,
        _ => true,
      };

  DateTime? get startsAt => startDay == null ? null : DateTime(startDay!.year, startDay!.month, startDay!.day);
  DateTime? get endsAt => endDay == null ? null : DateTime(endDay!.year, endDay!.month, endDay!.day + 1);

  /// Value as stored in `promotions.value` (engine semantics).
  double get storedValue {
    if (type == 'buy_x_get_y') return 0;
    return usesPercent ? (percent ?? 0) : (amount ?? 0).toDouble();
  }
}

/// Returns a user-facing error, or null when the draft is valid.
/// [codeTaken] — whether another active promotion already uses this code.
String? validatePromo(PromoDraft d, {bool codeTaken = false, AppLocalizations? l}) {
  final s = l ?? L.current;
  if (d.name.trim().isEmpty) return s.mktErrEnterName;
  if (!promoTypes.contains(d.type)) return s.mktErrSelectType;
  if (d.type != 'buy_x_get_y') {
    if (d.usesPercent) {
      final p = d.percent;
      if (p == null) return s.mktErrEnterPercent;
      if (p <= 0 || p > 100) return s.mktErrPercentRange;
    } else {
      final a = d.amount;
      if (a == null || a <= 0) return s.mktErrEnterAmount;
      if (d.type == 'promo_code' && a < promoCodeMinAmount) {
        return s.mktErrPromoCodeMinAmount(Money.format(promoCodeMinAmount));
      }
      if (d.minOrderTotal > 0 && a > d.minOrderTotal) {
        return s.mktErrDiscountAboveMin;
      }
    }
  }
  if (promoTypeHasTarget(d.type) && (d.targetId == null || d.targetId!.isEmpty)) {
    return d.type == 'percent_category' ? s.mktErrSelectCategory : s.mktErrSelectProduct;
  }
  if (d.type == 'buy_x_get_y') {
    if (d.buyQty < 1) return s.mktErrBuyMin;
    if (d.getQty < 1) return s.mktErrGetMin;
    if (d.buyQty > 1000 || d.getQty > 1000) return s.mktErrQtyTooLarge;
  }
  if (d.type == 'promo_code') {
    final c = normalizePromoCode(d.code ?? '');
    if (c.isEmpty) return s.mktErrEnterCode;
    if (c.length < 3) return s.mktErrCodeTooShort;
    if (c.length > 32) return s.mktErrCodeTooLong;
    if (!RegExp(r'^[A-ZА-ЯЁ0-9_-]+$').hasMatch(c)) { // l10n-ignore: allowed code characters
      return s.mktErrCodeChars;
    }
    if (codeTaken) return s.mktErrCodeTaken(c);
  }
  if (d.minOrderTotal < 0) return s.mktErrMinNegative;
  if (d.startsAt != null && d.endsAt != null && !d.endsAt!.isAfter(d.startsAt!)) {
    return s.mktErrEndBeforeStart;
  }
  return null;
}

String _pct(double p) => p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1);

/// Human description, e.g. "−10% на чек от 100 000 сум".
String describePromo(Promotion p, {String? targetName, AppLocalizations? l}) {
  final s = l ?? L.current;
  final isPct = promoValueIsPercent(p.type, p.value);
  final v = isPct ? '−${_pct(p.value)}%' : '−${Money.format(p.value.round())}';
  final min = p.minOrderTotal > 0 ? s.mktDescMinOrder(Money.format(p.minOrderTotal)) : '';
  final target = targetName ?? '…';
  return switch (p.type) {
    'percent_order' || 'amount_order' => s.mktDescOrder(v, min),
    'percent_category' => s.mktDescCategory(v, target),
    'percent_product' => s.mktDescProduct(v, target),
    'buy_x_get_y' => s.mktDescBuyXGetY('${p.buyQty}', '${p.getQty}', target),
    'promo_code' => s.mktDescPromoCode(p.code ?? '', v, min),
    _ => p.type,
  };
}

String formatPeriod(DateTime? startsAt, DateTime? endsAt, [AppLocalizations? l]) {
  final s = l ?? L.current;
  String d(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}.${x.month.toString().padLeft(2, '0')}.${x.year}';
  final lastDay = endsAt?.subtract(const Duration(days: 1));
  if (startsAt == null && lastDay == null) return s.mktPeriodUnlimited;
  if (startsAt == null) return s.mktPeriodUntil(d(lastDay!));
  if (lastDay == null) return s.mktPeriodFrom(d(startsAt));
  return '${d(startsAt)} — ${d(lastDay)}';
}
