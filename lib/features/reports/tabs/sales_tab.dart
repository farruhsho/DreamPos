import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../data/period.dart';
import '../data/report_queries.dart';
import '../data/report_table.dart';
import '../report_providers.dart';
import '../widgets/charts.dart';
import '../widgets/kpi.dart';
import '../widgets/report_table_view.dart';

String shortDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

String pctText(double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')}%';

class SalesTab extends ConsumerWidget {
  const SalesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final period = ref.watch(reportPeriodProvider);
    final cost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final summary = ref.watch(summaryProvider(period));
    final prev = ref.watch(summaryProvider(period.previous)).value;

    return AsyncView<SalesSummary>(
      value: summary,
      onRetry: () => ref.invalidate(summaryProvider(period)),
      data: (s) => ListView(padding: const EdgeInsets.all(Gap.l), children: [
        if (s.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.m),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.repNoSalesInPeriod),
                subtitle: Text(l.repPickAnotherPeriod),
              ),
            ),
          ),
        _SummaryGrid(s: s, prev: prev, withCost: cost),
        const SizedBox(height: Gap.m),
        _ByDaySection(period: period, withCost: cost),
        const SizedBox(height: Gap.m),
        _ByHourSection(period: period),
      ]),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.s, required this.prev, required this.withCost});
  final SalesSummary s;
  final SalesSummary? prev;
  final bool withCost;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? pl(int? v) => v == null ? null : l.repPrevPeriod(Money.format(v));
    return ResponsiveGrid(minTile: 160, maxColumns: 4, children: [
      KpiTile(
        label: l.repNetRevenue,
        value: Money.format(s.net),
        icon: Icons.payments_outlined,
        current: s.net,
        previous: prev?.net,
        previousLabel: pl(prev?.net),
        tooltip: l.repNetRevenueTooltip,
      ),
      KpiTile(
        label: l.repTabSales,
        value: Money.format(s.gross),
        icon: Icons.shopping_bag_outlined,
        current: s.gross,
        previous: prev?.gross,
        previousLabel: pl(prev?.gross),
      ),
      KpiTile(
        label: l.repReturns,
        value: Money.format(s.returnsTotal),
        icon: Icons.assignment_return_outlined,
        color: AppColors.warning,
        current: s.returnsTotal,
        previous: prev?.returnsTotal,
        inverse: true,
        hint: l.repReturnsHint('${s.returnsCount}', pctText(s.returnsPct)),
      ),
      KpiTile(
        label: l.repDiscounts,
        value: Money.format(s.discounts),
        icon: Icons.percent,
        color: AppColors.info,
        current: s.discounts,
        previous: prev?.discounts,
        inverse: true,
        hint: l.repDiscountsHint(pctText(s.discountPct)),
      ),
      KpiTile(
        label: l.repReceipts,
        value: '${s.receipts}',
        icon: Icons.receipt_long_outlined,
        current: s.receipts,
        previous: prev?.receipts,
        hint: s.voids > 0 ? l.repVoidedCount('${s.voids}') : l.repNoVoids,
      ),
      KpiTile(
        label: l.repAvgCheck,
        value: Money.format(s.avgCheck),
        icon: Icons.functions,
        current: s.avgCheck,
        previous: prev?.avgCheck,
        previousLabel: pl(prev?.avgCheck),
      ),
      if (withCost) ...[
        KpiTile(
          label: l.repGrossProfit,
          value: Money.format(s.profit),
          icon: Icons.trending_up,
          color: AppColors.success,
          current: s.profit,
          previous: prev?.profit,
          previousLabel: pl(prev?.profit),
          tooltip: l.repGrossProfitTooltip,
        ),
        KpiTile(
          label: l.repMargin,
          value: pctText(s.marginPct),
          icon: Icons.pie_chart_outline,
          color: AppColors.success,
          hint: l.repCostHint(Money.format(s.netCost)),
        ),
      ],
    ]);
  }
}

class _ByDaySection extends ConsumerWidget {
  const _ByDaySection({required this.period, required this.withCost});
  final ReportPeriod period;
  final bool withCost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final days = ref.watch(byDayProvider(period));
    return AsyncView<List<DayPoint>>(
      value: days,
      data: (list) {
        final today = dayKey(DateTime.now());
        final rowsDesc = list.reversed.where((d) => d.receipts > 0 || d.returns > 0).toList();
        final total = list.fold<DayPoint>(
            DayPoint(period.start),
            (a, d) => DayPoint(period.start,
                gross: a.gross + d.gross,
                returns: a.returns + d.returns,
                cost: a.cost + d.cost,
                receipts: a.receipts + d.receipts,
                discounts: a.discounts + d.discounts));
        final table = RTable(
          title: l.repSalesByDay,
          subtitle: period.labelIn(l),
          columns: [
            RCol(l.commonDate),
            RCol(l.repReceipts, numeric: true),
            RCol(l.repTabSales, numeric: true),
            RCol(l.repReturns, numeric: true),
            RCol(l.repDiscounts, numeric: true),
            RCol(l.repNetRevenue, numeric: true),
            RCol(l.repAvgCheck, numeric: true),
            if (withCost) RCol(l.repProfit, numeric: true),
          ],
          rows: [
            for (final d in rowsDesc)
              [
                RCell(formatDate(d.day), sort: d.day.millisecondsSinceEpoch),
                RCell.integer(d.receipts),
                RCell.money(d.gross),
                RCell.money(d.returns),
                RCell.money(d.discounts),
                RCell.money(d.net),
                RCell.money(d.avgCheck),
                if (withCost) RCell.money(d.profit),
              ],
          ],
          totals: [
            RCell(l.commonTotal),
            RCell.integer(total.receipts),
            RCell.money(total.gross),
            RCell.money(total.returns),
            RCell.money(total.discounts),
            RCell.money(total.net),
            RCell.money(total.avgCheck),
            if (withCost) RCell.money(total.profit),
          ],
        );
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (list.length > 1)
            SectionCard(
              title: l.repNetRevenueByDay,
              child: SimpleBarChart(
                height: 180,
                formatAxis: (v) => Money.format(v),
                data: [
                  for (final d in list)
                    BarDatum(
                      label: shortDay(d.day),
                      value: d.net,
                      highlight: dayKey(d.day) == today,
                      tooltip: '${formatDate(d.day)}\n'
                          '${l.repTipNetRevenue(Money.format(d.net))}\n'
                          '${l.repTipReceipts('${d.receipts}')}'
                          '${d.returns > 0 ? '\n${l.repTipReturns(Money.format(d.returns))}' : ''}',
                    ),
                ],
              ),
            ),
          if (list.length > 1) const SizedBox(height: Gap.m),
          ReportTableCard(table: table, initialSort: 0),
        ]);
      },
    );
  }
}

class _ByHourSection extends ConsumerWidget {
  const _ByHourSection({required this.period});
  final ReportPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cells = ref.watch(byHourProvider(period));
    return AsyncView<List<HourCell>>(
      value: cells,
      data: (list) {
        final grid = List.generate(7, (_) => List<int>.filled(24, 0));
        final byHourN = List<int>.filled(24, 0);
        final byHourRev = List<int>.filled(24, 0);
        for (final c in list) {
          grid[c.weekday - 1][c.hour] += c.receipts;
          byHourN[c.hour] += c.receipts;
          byHourRev[c.hour] += c.revenue;
        }
        final total = byHourN.fold<int>(0, (s, v) => s + v);
        var first = byHourN.indexWhere((v) => v > 0);
        var last = byHourN.lastIndexWhere((v) => v > 0);
        if (first < 0) {
          first = 8;
          last = 21;
        }
        final peak = total == 0 ? -1 : byHourN.indexOf(byHourN.reduce((a, b) => a > b ? a : b));
        final days = period.dayCount;
        final table = RTable(
          title: l.repSalesByHour,
          subtitle: period.labelIn(l),
          columns: [
            RCol(l.repHour),
            RCol(l.repReceipts, numeric: true),
            RCol(l.repReceiptsPerDay, numeric: true, tooltip: l.repReceiptsPerDayTooltip),
            RCol(l.repTabSales, numeric: true),
            RCol(l.repReceiptsShare, numeric: true),
          ],
          rows: [
            for (var h = 0; h < 24; h++)
              if (byHourN[h] > 0)
                [
                  RCell('${h.toString().padLeft(2, '0')}:00–${(h + 1).toString().padLeft(2, '0')}:00', sort: h),
                  RCell.integer(byHourN[h]),
                  RCell((byHourN[h] / days).toStringAsFixed(1).replaceAll('.', ','),
                      sort: byHourN[h] / days),
                  RCell.money(byHourRev[h]),
                  RCell.percent(total == 0 ? 0 : byHourN[h] * 100 / total),
                ],
          ],
        );
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionCard(
            title: l.repLoadByHour,
            trailing: peak >= 0
                ? StatusChip(l.repPeak('$peak', '${peak + 1}'), color: AppColors.warning)
                : null,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                l.repLoadByHourHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: Gap.m),
              SimpleBarChart(
                height: 120,
                data: [
                  for (var h = first; h <= last; h++)
                    BarDatum(
                      label: '$h',
                      value: byHourN[h],
                      highlight: h == peak,
                      tooltip: '$h:00–${h + 1}:00\n'
                          '${l.repTipReceiptsPerDay('${byHourN[h]}', (byHourN[h] / days).toStringAsFixed(1).replaceAll('.', ','))}\n'
                          '${l.repTipSales(Money.format(byHourRev[h]))}',
                    ),
                ],
              ),
              const SizedBox(height: Gap.l),
              Text(l.repByWeekday, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Gap.s),
              HourHeatmap(
                values: grid,
                tooltip: (wd, h, v) =>
                    '${weekdayShortIn(l)[wd - 1]}, $h:00–${h + 1}:00 — ${l.repTipReceiptsLower('$v')}',
              ),
            ]),
          ),
          const SizedBox(height: Gap.m),
          ReportTableCard(table: table, initialSort: 0, initialAscending: true),
        ]);
      },
    );
  }
}
