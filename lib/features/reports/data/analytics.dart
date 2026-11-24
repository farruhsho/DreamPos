// Pure, explainable analytics: ABC classification and demand forecast.
import 'dart:math' as math;

import '../../../core/money.dart';
import 'report_queries.dart';

// ------------------------------------------------------------------ ABC

enum AbcClass {
  a('A', 'Основная выручка (первые 80%)'),
  b('B', 'Средний вклад (следующие 15%)'),
  c('C', 'Малый вклад (последние 5%)');

  const AbcClass(this.label, this.hint);
  final String label;
  final String hint;
}

/// ABC analysis by value (revenue).
///
/// Items are sorted by value descending; an item belongs to:
///  * A while the cumulative share of items ABOVE it is < 80%,
///  * B while that share is < 95%,
///  * C otherwise.
/// The "share above" rule guarantees the top seller is always A, and an item
/// that crosses the 80% line is still A (it makes the 80%). Items with zero or
/// negative value are always C.
Map<String, AbcClass> abcClassify(Iterable<MapEntry<String, int>> values,
    {double aShare = 0.80, double bShare = 0.95}) {
  final sorted = values.toList()..sort((x, y) => y.value.compareTo(x.value));
  final total = sorted.fold<int>(0, (s, e) => s + math.max(0, e.value));
  final out = <String, AbcClass>{};
  var cum = 0;
  for (final e in sorted) {
    if (e.value <= 0 || total == 0) {
      out[e.key] = AbcClass.c;
      continue;
    }
    final before = cum / total;
    out[e.key] = before < aShare - 1e-12
        ? AbcClass.a
        : before < bShare - 1e-12
            ? AbcClass.b
            : AbcClass.c;
    cum += e.value;
  }
  return out;
}

// ------------------------------------------------------------------ forecast

const forecastWindowDays = 28;
const forecastMinWindowDays = 7;
const forecastRiskDays = 7;

class Forecast {
  const Forecast({
    required this.row,
    required this.windowDays,
    required this.avgDaily,
    required this.recentDaily,
    required this.daysOfCover,
    required this.stockoutDate,
    required this.reorderQty,
    required this.horizonDays,
  });

  final DemandRow row;
  /// Days the average was computed over (28, or product age for new items, min 7).
  final int windowDays;
  /// Average daily demand over [windowDays].
  final double avgDaily;
  /// Average daily demand over the last 7 days (trend hint).
  final double recentDaily;
  /// Days the current stock lasts; null when there is no demand.
  final double? daysOfCover;
  final DateTime? stockoutDate;
  /// Recommended purchase to cover [horizonDays] + keep min stock.
  final double reorderQty;
  final int horizonDays;

  bool get hasDemand => avgDaily > 0;
  bool get outOfStock => row.stock <= 0;
  /// Will run out within [forecastRiskDays].
  bool get atRisk => hasDemand && (daysOfCover ?? double.infinity) <= forecastRiskDays;
  /// Recent 7-day pace vs. the window average, in percent (+ = growing).
  double get trendPct => avgDaily == 0 ? 0 : (recentDaily - avgDaily) * 100 / avgDaily;
  int get reorderCost => (reorderQty * row.costPrice).round();
}

/// Simple moving-average forecast:
///   avg = net units sold in the last 28 days / window days
///   (window = product age in days for new products, clamped to 7…28),
///   cover = stock / avg, stockout = now + cover,
///   reorder = avg × horizon + min stock − stock (rounded up; ≥ 0).
Forecast computeForecast(DemandRow r, {required DateTime now, int horizonDays = 14}) {
  final age = now.difference(r.createdAt).inDays;
  final window = age.clamp(forecastMinWindowDays, forecastWindowDays);
  final sold = math.max(0.0, r.sold28);
  final avg = sold / window;
  final recent = math.max(0.0, r.sold7) / forecastMinWindowDays;
  final stock = math.max(0.0, r.stock);
  final cover = avg > 0 ? stock / avg : null;
  final stockout = cover == null
      ? null
      : now.add(Duration(minutes: (cover * 24 * 60).round()));
  var need = avg * horizonDays + r.minStock - r.stock;
  if (need <= 1e-9) {
    need = 0;
  } else if (Qty.isFractional(r.unit)) {
    need = (need * 10).ceilToDouble() / 10;
  } else {
    need = (need - 1e-9).ceilToDouble();
  }
  return Forecast(
    row: r,
    windowDays: window,
    avgDaily: avg,
    recentDaily: recent,
    daysOfCover: cover,
    stockoutDate: stockout,
    reorderQty: need,
    horizonDays: horizonDays,
  );
}

/// Forecasts sorted by urgency: at-risk first (soonest stockout), then the rest.
List<Forecast> forecastAll(List<DemandRow> rows, {required DateTime now, int horizonDays = 14}) {
  final list = [for (final r in rows) computeForecast(r, now: now, horizonDays: horizonDays)];
  list.sort((a, b) {
    final ca = a.daysOfCover ?? double.infinity;
    final cb = b.daysOfCover ?? double.infinity;
    final c = ca.compareTo(cb);
    if (c != 0) return c;
    return b.avgDaily.compareTo(a.avgDaily);
  });
  return list;
}
