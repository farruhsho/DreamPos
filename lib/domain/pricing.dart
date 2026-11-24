// Pure pricing engine: no Flutter, no DB. Fully unit-tested.
//
// Discount policy (see DECISIONS.md D-008):
//  1. Per line, the automatic discount is the BEST of: product/category
//     promotion, buy-X-get-Y, customer personal discount. They do not stack.
//  2. Manual line discount (cashier) is added on top, capped to line amount.
//  3. Order-level discounts (order promotion, promo code, manual order
//     discount) are allocated proportionally across lines so that every line
//     total is exact — required for correct partial returns.
//  4. Prices are VAT-inclusive; VAT is extracted per line.
import 'dart:math';

class PricingLine {
  PricingLine({
    required this.key,
    required this.productId,
    required this.qty,
    required this.unitPrice,
    this.categoryId,
    this.vatPercent = 0,
    this.manualDiscount = 0,
    this.noDiscount = false,
  });

  final String key;
  final String productId;
  final String? categoryId;
  final double qty;
  final int unitPrice;
  final double vatPercent;
  final int manualDiscount;
  /// e.g. gift cards being sold: excluded from all discounts.
  final bool noDiscount;

  int get gross => (unitPrice * qty).round();
}

class PromoRule {
  const PromoRule({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.targetId,
    this.code,
    this.minOrderTotal = 0,
    this.buyQty = 0,
    this.getQty = 0,
  });

  final String id;
  final String name;
  /// percent_order | amount_order | percent_category | percent_product |
  /// buy_x_get_y | promo_code
  final String type;
  final double value;
  final String? targetId;
  final String? code;
  final int minOrderTotal;
  final int buyQty;
  final int getQty;
}

class PricedLine {
  PricedLine({
    required this.line,
    required this.autoDiscount,
    required this.manualDiscount,
    required this.orderDiscount,
    this.autoReason,
  });

  final PricingLine line;
  final int autoDiscount;
  final int manualDiscount;
  int orderDiscount;
  final String? autoReason;

  int get discount => autoDiscount + manualDiscount + orderDiscount;
  int get total => line.gross - discount;
  int get vat => line.vatPercent <= 0
      ? 0
      : (total * line.vatPercent / (100 + line.vatPercent)).round();
}

class PricingResult {
  PricingResult({
    required this.lines,
    required this.appliedPromotions,
    required this.promoCodeValid,
  });

  final List<PricedLine> lines;
  final List<String> appliedPromotions;
  /// null when no code was entered.
  final bool? promoCodeValid;

  int get subtotal => lines.fold(0, (s, l) => s + l.line.gross);
  int get discountTotal => lines.fold(0, (s, l) => s + l.discount);
  int get total => lines.fold(0, (s, l) => s + l.total);
  int get vatTotal => lines.fold(0, (s, l) => s + l.vat);

  PricedLine? byKey(String key) {
    for (final l in lines) {
      if (l.line.key == key) return l;
    }
    return null;
  }
}

class PricingEngine {
  static PricingResult price({
    required List<PricingLine> lines,
    List<PromoRule> promotions = const [],
    double customerDiscountPercent = 0,
    String? promoCode,
    double manualOrderDiscountPercent = 0,
    int manualOrderDiscountAmount = 0,
  }) {
    final applied = <String>{};

    // ---- 1. per-line automatic discount (best wins)
    final priced = <PricedLine>[];
    for (final l in lines) {
      if (l.noDiscount || l.gross <= 0) {
        priced.add(PricedLine(
            line: l, autoDiscount: 0, manualDiscount: 0, orderDiscount: 0));
        continue;
      }
      var best = 0;
      String? reason;
      void consider(int d, String r) {
        if (d > best) {
          best = d;
          reason = r;
        }
      }

      if (customerDiscountPercent > 0) {
        consider(_pct(l.gross, customerDiscountPercent), 'Скидка клиента');
      }
      for (final p in promotions) {
        switch (p.type) {
          case 'percent_product':
            if (p.targetId == l.productId) consider(_pct(l.gross, p.value), p.name);
          case 'percent_category':
            if (p.targetId != null && p.targetId == l.categoryId) {
              consider(_pct(l.gross, p.value), p.name);
            }
          case 'buy_x_get_y':
            if (p.targetId == l.productId && p.buyQty > 0 && p.getQty > 0) {
              final group = p.buyQty + p.getQty;
              final free = (l.qty ~/ group) * p.getQty;
              if (free > 0) consider(l.unitPrice * free, p.name);
            }
        }
      }
      best = min(best, l.gross);
      final manual = min(max(0, l.manualDiscount), l.gross - best);
      if (best > 0 && reason != null) applied.add(reason!);
      priced.add(PricedLine(
        line: l,
        autoDiscount: best,
        manualDiscount: manual,
        orderDiscount: 0,
        autoReason: reason,
      ));
    }

    int net() => priced.fold(0, (s, l) => s + l.total);

    // ---- 2. order level promotions (best single one) + promo code
    bool? codeValid;
    var orderDiscount = 0;
    final netAfterLines = net();
    // percent-based order discounts apply only to discountable lines
    final discountableNet = priced
        .where((p) => !p.line.noDiscount)
        .fold(0, (s, l) => s + l.total);
    PromoRule? bestOrder;
    var bestOrderValue = 0;
    for (final p in promotions) {
      final isCode = p.type == 'promo_code';
      final isOrder = p.type == 'percent_order' || p.type == 'amount_order';
      if (!isCode && !isOrder) continue;
      if (isCode) {
        if (promoCode == null || promoCode.trim().isEmpty) continue;
        if ((p.code ?? '').toUpperCase() != promoCode.trim().toUpperCase()) continue;
        codeValid = netAfterLines >= p.minOrderTotal;
        if (codeValid != true) continue;
      } else if (netAfterLines < p.minOrderTotal) {
        continue;
      }
      // promo_code: value <= 100 → percent, otherwise fixed amount (minor).
      final v = (p.type == 'amount_order' || (isCode && p.value > 100))
          ? p.value.round()
          : _pct(discountableNet, p.value);
      if (v > bestOrderValue) {
        bestOrderValue = v;
        bestOrder = p;
      }
    }
    if (promoCode != null && promoCode.trim().isNotEmpty) codeValid ??= false;
    if (bestOrder != null) {
      orderDiscount += bestOrderValue;
      applied.add(bestOrder.name);
    }

    // ---- 3. manual order discount
    if (manualOrderDiscountPercent > 0) {
      orderDiscount += _pct(discountableNet - orderDiscount, manualOrderDiscountPercent);
    }
    if (manualOrderDiscountAmount > 0) orderDiscount += manualOrderDiscountAmount;

    // allocate only over discountable lines
    final eligible = priced.where((p) => !p.line.noDiscount && p.total > 0).toList();
    final eligibleNet = eligible.fold(0, (s, l) => s + l.total);
    orderDiscount = min(orderDiscount, eligibleNet);
    if (orderDiscount > 0 && eligibleNet > 0) {
      var allocated = 0;
      for (final p in eligible) {
        final share = (orderDiscount * p.total / eligibleNet).floor();
        p.orderDiscount = share;
        allocated += share;
      }
      // remainder (rounding) goes to lines with largest remaining total
      var rest = orderDiscount - allocated;
      eligible.sort((a, b) => b.total.compareTo(a.total));
      var i = 0;
      while (rest > 0 && eligible.isNotEmpty) {
        final p = eligible[i % eligible.length];
        if (p.total > 0) {
          p.orderDiscount += 1;
          rest--;
        }
        i++;
        if (i > eligible.length * 1000) break;
      }
    }

    return PricingResult(
      lines: priced,
      appliedPromotions: applied.toList(),
      promoCodeValid: codeValid,
    );
  }

  static int _pct(int amount, double pct) =>
      pct <= 0 ? 0 : min(amount, (amount * pct / 100).round());
}

/// Splits [amount] proportionally to [weights] with exact integer total.
List<int> allocateProportionally(int amount, List<int> weights) {
  final sum = weights.fold(0, (a, b) => a + b);
  if (sum <= 0 || amount == 0) return List.filled(weights.length, 0);
  final res = [for (final w in weights) (amount * w / sum).floor()];
  var rest = amount - res.fold(0, (a, b) => a + b);
  final order = List.generate(weights.length, (i) => i)
    ..sort((a, b) => weights[b].compareTo(weights[a]));
  var i = 0;
  while (rest > 0) {
    res[order[i % order.length]]++;
    rest--;
    i++;
  }
  return res;
}
