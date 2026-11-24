// Offline, rule-based "AI analytics": turns aggregated figures into
// plain-Russian insight cards. Every rule is explainable (the explanation
// states the numbers and the threshold), so the owner can trust it.
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/money.dart';
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

String _days(int n) {
  final m10 = n % 10, m100 = n % 100;
  final w = (m10 == 1 && m100 != 11)
      ? 'день'
      : (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14))
          ? 'дня'
          : 'дней';
  return '$n $w';
}

String _items(int n) {
  final m10 = n % 10, m100 = n % 100;
  final w = (m10 == 1 && m100 != 11)
      ? 'товар'
      : (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14))
          ? 'товара'
          : 'товаров';
  return '$n $w';
}

String _returns(int n) {
  final m10 = n % 10, m100 = n % 100;
  final w = (m10 == 1 && m100 != 11)
      ? 'возврат'
      : (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14))
          ? 'возврата'
          : 'возвратов';
  return '$n $w';
}

String _clients(int n) {
  final m10 = n % 10, m100 = n % 100;
  final w = (m10 == 1 && m100 != 11)
      ? 'клиент'
      : (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14))
          ? 'клиента'
          : 'клиентов';
  return '$n $w';
}

/// Runs all rules. [withCost] = user may see cost/profit (Perm.viewCost).
List<Insight> buildInsights(InsightData d, {bool withCost = true}) {
  final out = <Insight>[];

  // 1. Revenue trend week over week.
  if (d.prevWeek.net > 0 && d.week.net > 0) {
    final ch = (d.week.net - d.prevWeek.net) * 100 / d.prevWeek.net;
    final expl = 'За последние 7 дней: ${Money.format(d.week.net)}, '
        'за 7 дней до этого: ${Money.format(d.prevWeek.net)} (чистая выручка с учётом возвратов).';
    if (ch >= 10) {
      out.add(Insight(
          id: 'revenue_up',
          severity: InsightSeverity.positive,
          title: 'Выручка за неделю выросла на ${_pct(ch)}',
          explanation: '$expl Отличный результат — проверьте, хватит ли остатков ходовых товаров.'));
    } else if (ch <= -10) {
      out.add(Insight(
          id: 'revenue_down',
          severity: InsightSeverity.warning,
          title: 'Выручка за неделю упала на ${_pct(ch)}',
          explanation: '$expl Проверьте наличие ходовых товаров и запустите акцию.',
          action: 'Запустить акцию',
          route: '/marketing'));
    }
  }

  // 2. Stockouts and stockout risk.
  final outWithDemand = d.forecasts.where((f) => f.hasDemand && f.outOfStock).toList();
  if (outWithDemand.isNotEmpty) {
    final names = outWithDemand.take(3).map((f) => '«${f.row.name}»').join(', ');
    out.add(Insight(
        id: 'out_of_stock',
        severity: InsightSeverity.critical,
        title: outWithDemand.length == 1
            ? 'Закончился ходовой товар ${outWithDemand.first.row.name}'
            : '${_items(outWithDemand.length)} с продажами закончились',
        explanation: '$names — остаток 0, а за последние 4 недели их покупали. '
            'Каждый день без товара — потерянная выручка.',
        action: 'Заказать у поставщика',
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
        title: 'Товар ${f.row.name} закончится через ${_days(days)}',
        explanation: 'Остаток ${Qty.format(f.row.stock, f.row.unit)}, продаётся в среднем '
            '${Qty.format(f.avgDaily, f.row.unit)} в день (за ${_days(f.windowDays)}). '
            'Рекомендуем заказать ${Qty.format(f.reorderQty, f.row.unit)} на ${_days(f.horizonDays)}.',
        action: 'Оформить закупку',
        route: '/purchasing'));
  }
  if (soon.length > 3) {
    out.add(Insight(
        id: 'stockout_more',
        severity: InsightSeverity.warning,
        title: soon.length - 3 == 1
            ? 'Ещё 1 товар закончится в течение недели'
            : 'Ещё ${_items(soon.length - 3)} закончатся в течение недели',
        explanation: 'См. вкладку «Прогноз спроса» — там рекомендуемое количество к заказу.',
        action: 'Оформить закупку',
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
            title: 'Категория «${top.name}» даёт ${_pct(share)} прибыли',
            explanation: 'За 30 дней: ${Money.format(top.profit)} из ${Money.format(totalProfit)} '
                'валовой прибыли. Держите эту категорию в наличии и на видном месте.',
            action: 'Открыть товары',
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
          title: loss
              ? 'Товар ${p.name} продаётся в убыток'
              : 'Маржа товара ${p.name} ниже 5%',
          explanation: 'За 30 дней: выручка ${Money.format(p.revenue)}, себестоимость '
              '${Money.format(p.cost)}, маржа ${p.marginPct.toStringAsFixed(1).replaceAll('.', ',')}%. '
              'Поднимите цену или пересмотрите закупочную цену и скидки.',
          action: 'Изменить цену',
          route: '/products'));
    }
  }

  // 5. Inactive customers.
  if (d.inactiveCustomers >= 3) {
    out.add(Insight(
        id: 'inactive_customers',
        severity: InsightSeverity.info,
        title: '${_clients(d.inactiveCustomers)} не приходили 60 дней — запустите акцию',
        explanation: 'Эти клиенты раньше покупали, но не возвращались больше 60 дней. '
            'Персональная скидка или бонусы часто возвращают 10–20% из них.',
        action: 'Создать акцию',
        route: '/marketing'));
  }

  // 6. Discounts eating revenue.
  if (d.month.subtotal > 0 && d.month.discountPct >= 10) {
    out.add(Insight(
        id: 'discounts',
        severity: InsightSeverity.warning,
        title: 'Скидки съели ${_pct(d.month.discountPct)} выручки',
        explanation: 'За 30 дней скидки составили ${Money.format(d.month.discounts)} '
            'от ${Money.format(d.month.subtotal)} до скидок. Проверьте акции и ручные скидки кассиров '
            '(вкладка «Сотрудники»).',
        action: 'Проверить акции',
        route: '/marketing'));
  }

  // 7. Returns rate.
  if (d.month.gross > 0 && d.month.returnsCount >= 3 && d.month.returnsPct >= 5) {
    out.add(Insight(
        id: 'returns',
        severity: InsightSeverity.warning,
        title: 'Возвраты — ${_pct(d.month.returnsPct)} от продаж',
        explanation: 'За 30 дней ${_returns(d.month.returnsCount)} на ${Money.format(d.month.returnsTotal)}. '
            'Норма для розницы — до 3–5%. Проверьте качество товара и причины возвратов.',
        action: 'Открыть чеки',
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
          title: 'Пиковые часы $best–${best + 2} — поставьте второго кассира',
          explanation: 'С $best:00 до ${best + 2}:00 приходится ${_pct(share)} всех чеков за 30 дней. '
              'Второй кассир в это время сократит очереди и потерянные продажи.',
          action: 'Сотрудники',
          route: '/staff'));
    }
  }

  // 9. Dead stock.
  if (d.deadStock.isNotEmpty) {
    final frozen = d.deadStock.fold<int>(0, (s, r) => s + r.value);
    out.add(Insight(
        id: 'dead_stock',
        severity: InsightSeverity.warning,
        title: '${_items(d.deadStock.length)} не продавались 60 дней',
        explanation: withCost
            ? 'В них заморожено ${Money.format(frozen)} по себестоимости. '
                'Сделайте уценку или акцию, чтобы освободить деньги.'
            : 'Сделайте уценку или акцию, чтобы освободить деньги и место на полке.',
        action: 'Открыть склад',
        route: '/inventory'));
  }

  // 10. Overdue debts.
  if (d.overdueDebtors > 0) {
    out.add(Insight(
        id: 'overdue_debts',
        severity: InsightSeverity.warning,
        title: 'Просроченные долги: ${_clients(d.overdueDebtors)}',
        explanation: 'Просрочено ${Money.format(d.overdueDebt)} — срок оплаты этих долгов прошёл. '
            'Напомните клиентам и не продавайте им в долг до погашения.',
        action: 'Открыть клиентов',
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
        title: 'Хит недели — ${top.name}',
        explanation: 'Выручка ${Money.format(top.revenue)} за 7 дней '
            '(${_pct(top.revenue * 100 / total)} всех продаж). Следите, чтобы он не заканчивался.',
        action: 'Проверить остатки',
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
