// Pure promotion rules: type metadata, value encoding (as PricingEngine
// expects), validation and status computation.
import '../../core/db/database.dart';
import '../../core/money.dart';

const promoTypes = [
  'percent_order',
  'amount_order',
  'percent_category',
  'percent_product',
  'buy_x_get_y',
  'promo_code',
];

String promoTypeLabel(String t) => switch (t) {
      'percent_order' => 'Скидка % на чек',
      'amount_order' => 'Скидка суммой на чек',
      'percent_category' => 'Скидка % на категорию',
      'percent_product' => 'Скидка % на товар',
      'buy_x_get_y' => 'Купи X — получи Y',
      'promo_code' => 'Промокод',
      _ => t,
    };

String promoTypeHelp(String t) => switch (t) {
      'percent_order' =>
        'Процент от суммы чека после скидок по позициям. Можно задать минимальную сумму чека. '
            'Из скидок на чек применяется только одна — самая выгодная.',
      'amount_order' =>
        'Фиксированная сумма скидки на чек (например, 10 000 при покупке от 100 000). '
            'Распределяется по позициям пропорционально — возвраты считаются точно.',
      'percent_category' =>
        'Процент на все товары выбранной категории. Не суммируется с другими скидками на позицию '
            'и персональной скидкой клиента — берётся лучшая.',
      'percent_product' =>
        'Процент на один товар. Не суммируется с другими скидками на позицию — берётся лучшая.',
      'buy_x_get_y' =>
        'При покупке X штук товара ещё Y штук бесплатно. Например, «2+1»: каждая третья единица '
            'бесплатно. Работает на одну позицию товара.',
      'promo_code' =>
        'Скидка на чек по коду, который кассир вводит на кассе. Можно задать процент или сумму '
            'и минимальную сумму чека. Конкурирует с другими скидками на чек — применяется лучшая.',
      _ => '',
    };

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
  active('Активна'),
  scheduled('Запланирована'),
  finished('Завершена'),
  disabled('Выключена');

  const PromoStatus(this.label);
  final String label;
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
String? validatePromo(PromoDraft d, {bool codeTaken = false}) {
  if (d.name.trim().isEmpty) return 'Введите название акции';
  if (!promoTypes.contains(d.type)) return 'Выберите тип акции';
  if (d.type != 'buy_x_get_y') {
    if (d.usesPercent) {
      final p = d.percent;
      if (p == null) return 'Укажите процент скидки';
      if (p <= 0 || p > 100) return 'Процент скидки должен быть больше 0 и не больше 100';
    } else {
      final a = d.amount;
      if (a == null || a <= 0) return 'Укажите сумму скидки';
      if (d.type == 'promo_code' && a < promoCodeMinAmount) {
        return 'Сумма скидки по промокоду должна быть не меньше ${Money.format(promoCodeMinAmount)}';
      }
      if (d.minOrderTotal > 0 && a > d.minOrderTotal) {
        return 'Скидка не может быть больше минимальной суммы чека';
      }
    }
  }
  if (promoTypeHasTarget(d.type) && (d.targetId == null || d.targetId!.isEmpty)) {
    return d.type == 'percent_category' ? 'Выберите категорию' : 'Выберите товар';
  }
  if (d.type == 'buy_x_get_y') {
    if (d.buyQty < 1) return '«Купи» — минимум 1 шт.';
    if (d.getQty < 1) return '«Получи» — минимум 1 шт.';
    if (d.buyQty > 1000 || d.getQty > 1000) return 'Слишком большое количество';
  }
  if (d.type == 'promo_code') {
    final c = normalizePromoCode(d.code ?? '');
    if (c.isEmpty) return 'Введите промокод';
    if (c.length < 3) return 'Промокод — минимум 3 символа';
    if (c.length > 32) return 'Промокод слишком длинный';
    if (!RegExp(r'^[A-ZА-ЯЁ0-9_-]+$').hasMatch(c)) {
      return 'Промокод: только буквы, цифры, «-» и «_»';
    }
    if (codeTaken) return 'Промокод $c уже используется в другой активной акции';
  }
  if (d.minOrderTotal < 0) return 'Минимальная сумма не может быть отрицательной';
  if (d.startsAt != null && d.endsAt != null && !d.endsAt!.isAfter(d.startsAt!)) {
    return 'Дата окончания должна быть не раньше даты начала';
  }
  return null;
}

String _pct(double p) => p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1);

/// Human description, e.g. "−10% на чек от 100 000 сум".
String describePromo(Promotion p, {String? targetName}) {
  final isPct = promoValueIsPercent(p.type, p.value);
  final v = isPct ? '−${_pct(p.value)}%' : '−${Money.format(p.value.round())}';
  final min = p.minOrderTotal > 0 ? ' от ${Money.format(p.minOrderTotal)}' : '';
  final target = targetName ?? '…';
  return switch (p.type) {
    'percent_order' || 'amount_order' => '$v на чек$min',
    'percent_category' => '$v на категорию «$target»',
    'percent_product' => '$v на «$target»',
    'buy_x_get_y' => '${p.buyQty}+${p.getQty}: купи ${p.buyQty}, ещё ${p.getQty} бесплатно — «$target»',
    'promo_code' => 'Код ${p.code ?? ''}: $v на чек$min',
    _ => p.type,
  };
}

String formatPeriod(DateTime? startsAt, DateTime? endsAt) {
  String d(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}.${x.month.toString().padLeft(2, '0')}.${x.year}';
  final lastDay = endsAt?.subtract(const Duration(days: 1));
  if (startsAt == null && lastDay == null) return 'Бессрочно';
  if (startsAt == null) return 'по ${d(lastDay!)}';
  if (lastDay == null) return 'с ${d(startsAt)}';
  return '${d(startsAt)} — ${d(lastDay)}';
}
