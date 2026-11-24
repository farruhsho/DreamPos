// Offline, rule-based "AI analytics": turns aggregated figures into
// plain-language insight cards. Every rule is explainable (the explanation
// states the numbers and the threshold), so the owner can trust it.
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../l10n/l10n.dart';
import 'analytics.dart';
import 'period.dart';
import 'report_queries.dart';

enum InsightSeverity { critical, warning, info, positive }

class Insight {
  const Insight({
    required this.id,
    required this.severity,
    required this.title,
    required this.explanation,
    this.action,
    this.route,
  });

  /// Stable id of the rule (+ subject) — used in tests and as a widget key.
  final String id;
  final InsightSeverity severity;
  final String title;
  final String explanation;
  final String? action;
  final String? route;
}

/// Everything the rules need. Built by [loadInsightData] from SQL; kept as a
/// plain object so the rules are unit-testable without a database.
class InsightData {
  const InsightData({
    required this.now,
    this.week = const SalesSummary(),
    this.prevWeek = const SalesSummary(),
    this.month = const SalesSummary(),
    this.forecasts = const [],
    this.categories = const [],
    this.products = const [],
    this.weekProducts = const [],
    this.hours = const [],
    this.inactiveCustomers = 0,
    this.deadStock = const [],
    this.overdueDebtors = 0,
    this.overdueDebt = 0,
  });

  final DateTime now;
  /// Last 7 days (incl. today) and the 7 days before.
  final SalesSummary week;
  final SalesSummary prevWeek;
  /// Last 30 days.
  final SalesSummary month;
  final List<Forecast> forecasts;
  /// Last 30 days.
  final List<CategoryRow> categories;
  final List<ProductRow> products;
  /// Last 7 days.
  final List<ProductRow> weekProducts;
  /// Last 30 days.
  final List<HourCell> hours;
  final int inactiveCustomers;
  final List<DeadStockRow> deadStock;
  final int overdueDebtors;
  final int overdueDebt;
}

String _pct(double v) => '${v.abs().toStringAsFixed(v.abs() >= 10 ? 0 : 1).replaceAll('.', ',')}%';

/// Runs all rules. [withCost] = user may see cost/profit (Perm.viewCost).
/// Texts use [l] (default: the UI language, [L.current]).
List<Insight> buildInsights(InsightData d, {bool withCost = true, AppLocalizations? l}) {
  final t = l ?? L.current;
  final out = <Insight>[];

  // 1. Revenue trend week over week.
  if (d.prevWeek.net > 0 && d.week.net > 0) {
    final ch = (d.week.net - d.prevWeek.net) * 100 / d.prevWeek.net;
    final expl = t.repInsWeekExpl(Money.format(d.week.net), Money.format(d.prevWeek.net));
    if (ch >= 10) {
      out.add(Insight(
          id: 'revenue_up',
          severity: InsightSeverity.positive,
          title: t.repInsRevenueUpTitle(_pct(ch)),
          explanation: t.repInsRevenueUpExpl(expl)));
    } else if (ch <= -10) {
      out.add(Insight(
          id: 'revenue_down',
          severity: InsightSeverity.warning,
          title: t.repInsRevenueDownTitle(_pct(ch)),
          explanation: t.repInsRevenueDownExpl(expl),
          action: t.repInsActLaunchPromo,
          route: '/marketing'));
    }
  }

  // 2. Stockouts and stockout risk.
  final outWithDemand = d.forecasts.where((f) => f.hasDemand && f.outOfStock).toList();
  if (outWithDemand.isNotEmpty) {
    final names = outWithDemand.take(3).map((f) => t.repInsQuoted(f.row.name)).join(', ');
    out.add(Insight(
        id: 'out_of_stock',
        severity: InsightSeverity.critical,
        title: outWithDemand.length == 1
            ? t.repInsOutOfStockOne(outWithDemand.first.row.name)
            : t.repInsOutOfStockMany(t.commonProductsCount(outWithDemand.length)),
        explanation: t.repInsOutOfStockExpl(names),
        action: t.repInsActOrderSupplier,
        route: '/purchasing'));
  }
  final soon = d.forecasts
      .where((f) => f.atRisk && !f.outOfStock)
      .toList()
    ..sort((a, b) => a.daysOfCover!.compareTo(b.daysOfCover!));
  for (final f in soon.take(3)) {
    final days = math.max(1, f.daysOfCover!.floor());
    out.add(Insight(
        id: 'stockout_${f.row.id}',
        severity: days <= 3 ? InsightSeverity.critical : InsightSeverity.warning,
        title: t.repInsStockoutTitle(f.row.name, t.commonDaysCount(days)),
        explanation: t.repInsStockoutExpl(
            Qty.format(f.row.stock, f.row.unit, t),
            Qty.format(f.avgDaily, f.row.unit, t),
            t.commonDaysCount(f.windowDays),
            Qty.format(f.reorderQty, f.row.unit, t),
            t.commonDaysCount(f.horizonDays)),
        action: t.repInsActPurchase,
        route: '/purchasing'));
  }
  if (soon.length > 3) {
    out.add(Insight(
        id: 'stockout_more',
        severity: InsightSeverity.warning,
        title: soon.length - 3 == 1
            ? t.repInsStockoutMoreOne
            : t.repInsStockoutMoreMany(t.commonProductsCount(soon.length - 3)),
        explanation: t.repInsStockoutMoreExpl,
        action: t.repInsActPurchase,
        route: '/purchasing'));
  }

  // 3. Category profit concentration.
  if (withCost) {
    final profitable = d.categories.where((c) => c.profit > 0).toList();
    final totalProfit = profitable.fold<int>(0, (s, c) => s + c.profit);
    if (profitable.length >= 2 && totalProfit > 0) {
      profitable.sort((a, b) => b.profit.compareTo(a.profit));
      final top = profitable.first;
      final share = top.profit * 100 / totalProfit;
      if (share >= 40) {
        out.add(Insight(
            id: 'category_profit',
            severity: InsightSeverity.info,
            title: t.repInsCategoryTitle(top.name, _pct(share)),
            explanation:
                t.repInsCategoryExpl(Money.format(top.profit), Money.format(totalProfit)),
            action: t.repInsActOpenProducts,
            route: '/products'));
      }
    }
  }

  // 4. Low or negative margin products (only items with known cost).
  if (withCost) {
    final low = d.products
        .where((p) => p.revenue > 0 && p.cost > 0 && p.marginPct < 5)
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    for (final p in low.take(3)) {
      final loss = p.marginPct < 0;
      out.add(Insight(
          id: 'margin_${p.id}',
          severity: loss ? InsightSeverity.critical : InsightSeverity.warning,
          title: loss ? t.repInsLossTitle(p.name) : t.repInsLowMarginTitle(p.name),
          explanation: t.repInsMarginExpl(Money.format(p.revenue), Money.format(p.cost),
              p.marginPct.toStringAsFixed(1).replaceAll('.', ',')),
          action: t.repInsActChangePrice,
          route: '/products'));
    }
  }

  // 5. Inactive customers.
  if (d.inactiveCustomers >= 3) {
    out.add(Insight(
        id: 'inactive_customers',
        severity: InsightSeverity.info,
        title: t.repInsInactiveTitle(t.commonCustomersCount(d.inactiveCustomers)),
        explanation: t.repInsInactiveExpl,
        action: t.repInsActCreatePromo,
        route: '/marketing'));
  }

  // 6. Discounts eating revenue.
  if (d.month.subtotal > 0 && d.month.discountPct >= 10) {
    out.add(Insight(
        id: 'discounts',
        severity: InsightSeverity.warning,
        title: t.repInsDiscountsTitle(_pct(d.month.discountPct)),
        explanation:
            t.repInsDiscountsExpl(Money.format(d.month.discounts), Money.format(d.month.subtotal)),
        action: t.repInsActCheckPromos,
        route: '/marketing'));
  }

  // 7. Returns rate.
  if (d.month.gross > 0 && d.month.returnsCount >= 3 && d.month.returnsPct >= 5) {
    out.add(Insight(
        id: 'returns',
        severity: InsightSeverity.warning,
        title: t.repInsReturnsTitle(_pct(d.month.returnsPct)),
        explanation: t.repInsReturnsExpl(
            t.commonReturnsCount(d.month.returnsCount), Money.format(d.month.returnsTotal)),
        action: t.repInsActOpenReceipts,
        route: '/sales'));
  }

  // 8. Peak hours (staffing).
  final byHour = List<int>.filled(24, 0);
  for (final c in d.hours) {
    byHour[c.hour] += c.receipts;
  }
  final totalReceipts = byHour.fold<int>(0, (s, v) => s + v);
  if (totalReceipts >= 30) {
    var best = 0, bestSum = -1;
    for (var h = 0; h < 23; h++) {
      final s = byHour[h] + byHour[h + 1];
      if (s > bestSum) {
        bestSum = s;
        best = h;
      }
    }
    final share = bestSum * 100 / totalReceipts;
    if (share >= 25) {
      out.add(Insight(
          id: 'peak_hours',
          severity: InsightSeverity.info,
          title: t.repInsPeakTitle('$best', '${best + 2}'),
          explanation: t.repInsPeakExpl('$best', '${best + 2}', _pct(share)),
          action: t.repInsActStaff,
          route: '/staff'));
    }
  }

  // 9. Dead stock.
  if (d.deadStock.isNotEmpty) {
    final frozen = d.deadStock.fold<int>(0, (s, r) => s + r.value);
    out.add(Insight(
        id: 'dead_stock',
        severity: InsightSeverity.warning,
        title: t.repInsDeadTitle(t.commonProductsCount(d.deadStock.length)),
        explanation: withCost ? t.repInsDeadExplCost(Money.format(frozen)) : t.repInsDeadExpl,
        action: t.repInsActOpenInventory,
        route: '/inventory'));
  }

  // 10. Overdue debts.
  if (d.overdueDebtors > 0) {
    out.add(Insight(
        id: 'overdue_debts',
        severity: InsightSeverity.warning,
        title: t.repInsOverdueTitle(t.commonCustomersCount(d.overdueDebtors)),
        explanation: t.repInsOverdueExpl(Money.format(d.overdueDebt)),
        action: t.repInsActOpenCustomers,
        route: '/customers'));
  }

  // 11. Best seller of the week.
  final hits = d.weekProducts.where((p) => p.revenue > 0).toList();
  if (hits.length >= 3) {
    final top = hits.first;
    final total = hits.fold<int>(0, (s, p) => s + p.revenue);
    out.add(Insight(
        id: 'top_product',
        severity: InsightSeverity.positive,
        title: t.repInsTopTitle(top.name),
        explanation: t.repInsTopExpl(Money.format(top.revenue), _pct(top.revenue * 100 / total)),
        action: t.repInsActCheckStock,
        route: '/inventory'));
  }

  const order = {
    InsightSeverity.critical: 0,
    InsightSeverity.warning: 1,
    InsightSeverity.info: 2,
    InsightSeverity.positive: 3,
  };
  final indexed = out.asMap().entries.toList()
    ..sort((a, b) {
      final c = order[a.value.severity]!.compareTo(order[b.value.severity]!);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return [for (final e in indexed) e.value];
}

/// Collects [InsightData] from the database (all aggregation in SQL).
Future<InsightData> loadInsightData(AppDatabase db, {DateTime? now}) async {
  final n = now ?? DateTime.now();
  final tomorrow = DateTime(n.year, n.month, n.day + 1);
  final week = ReportPeriod(DateTime(n.year, n.month, n.day - 6), tomorrow);
  final prevWeek = ReportPeriod(DateTime(n.year, n.month, n.day - 13), week.start);
  final month = ReportPeriod(DateTime(n.year, n.month, n.day - 29), tomorrow);

  final inactive = await db.customSelect(
    'SELECT COUNT(*) AS n FROM customers WHERE deleted_at IS NULL AND visits > 0 '
    'AND last_visit_at IS NOT NULL AND last_visit_at < ?1',
    variables: [Variable.withDateTime(n.subtract(const Duration(days: 60)))],
  ).getSingle();
  final overdue = await loadOverdueDebtors(db, now: n);

  return InsightData(
    now: n,
    week: await salesSummaryQuery(db, week).getSingle(),
    prevWeek: await salesSummaryQuery(db, prevWeek).getSingle(),
    month: await salesSummaryQuery(db, month).getSingle(),
    forecasts: forecastAll(await demandQuery(db, now: n).get(), now: n),
    categories: await byCategoryQuery(db, month).get(),
    products: await byProductQuery(db, month).get(),
    weekProducts: await byProductQuery(db, week).get(),
    hours: await watchByHour(db, month).first,
    inactiveCustomers: qi(inactive, 'n'),
    deadStock: await deadStockQuery(db, now: n).get(),
    overdueDebtors: overdue.length,
    overdueDebt: overdue.fold<int>(0, (s, r) => s + r.overdue),
  );
}

class OverdueDebtor {
  const OverdueDebtor(this.customerId, this.name, this.debt, this.overdue, this.oldestDue);
  final String customerId;
  final String name;
  /// Total current debt.
  final int debt;
  /// Part of [debt] whose due date has passed.
  final int overdue;
  final DateTime oldestDue;
}

/// Customers whose debt is (partly) overdue.
///
/// Payments are applied FIFO (oldest credit sales are paid first), so the
/// current balance consists of the most recent credit sales; every unpaid part
/// of a sale whose due date has passed is overdue. Sales without a due date
/// never become overdue. Same rule as the Customers module uses.
Future<List<OverdueDebtor>> loadOverdueDebtors(AppDatabase db, {DateTime? now}) async {
  final at = now ?? DateTime.now();
  final rows = await db.customSelect(
    'SELECT c.id AS id, c.name AS name, c.debt_balance AS debt, l.amount AS amount, '
    'l.due_date AS due, l.created_at AS created '
    'FROM customer_ledger l JOIN customers c ON c.id = l.customer_id '
    "WHERE l.kind = 'debt_sale' AND l.amount > 0 AND l.deleted_at IS NULL "
    'AND c.deleted_at IS NULL AND c.debt_balance > 0 '
    'ORDER BY c.id, l.created_at DESC',
    readsFrom: {db.customerLedger, db.customers},
  ).get();
  final out = <OverdueDebtor>[];
  String? cur;
  var name = '';
  var debt = 0, remaining = 0, overdue = 0;
  DateTime? oldest;
  void flush() {
    final id = cur, o = oldest;
    if (id != null && overdue > 0 && o != null) out.add(OverdueDebtor(id, name, debt, overdue, o));
  }

  for (final r in rows) {
    final id = qs(r, 'id') ?? '';
    if (id != cur) {
      flush();
      cur = id;
      name = qs(r, 'name') ?? '';
      debt = qi(r, 'debt');
      remaining = debt;
      overdue = 0;
      oldest = null;
    }
    if (remaining <= 0) continue;
    final unpaid = math.min(remaining, qi(r, 'amount'));
    remaining -= unpaid;
    final due = r.readNullable<DateTime>('due');
    if (due != null && due.isBefore(at)) {
      overdue += unpaid;
      final o = oldest;
      if (o == null || due.isBefore(o)) oldest = due;
    }
  }
  flush();
  out.sort((a, b) => b.overdue.compareTo(a.overdue));
  return out;
}
