import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
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
    final period = ref.watch(reportPeriodProvider);
    final cost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final summary = ref.watch(summaryProvider(period));
    final prev = ref.watch(summaryProvider(period.previous)).value;

    return AsyncView<SalesSummary>(
      value: summary,
      onRetry: () => ref.invalidate(summaryProvider(period)),
      data: (s) => ListView(padding: const EdgeInsets.all(Gap.l), children: [
        if (s.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: Gap.m),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('За выбранный период продаж нет'),
                subtitle: Text('Выберите другой период вверху экрана.'),
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
    String? pl(int? v) => v == null ? null : 'пред. период: ${Money.format(v)}';
    return ResponsiveGrid(minTile: 160, maxColumns: 4, children: [
      KpiTile(
        label: 'Чистая выручка',
        value: Money.format(s.net),
        icon: Icons.payments_outlined,
        current: s.net,
        previous: prev?.net,
        previousLabel: pl(prev?.net),
        tooltip: 'Продажи минус возвраты за период (аннулированные чеки не учитываются)',
      ),
      KpiTile(
        label: 'Продажи',
        value: Money.format(s.gross),
        icon: Icons.shopping_bag_outlined,
        current: s.gross,
        previous: prev?.gross,
        previousLabel: pl(prev?.gross),
      ),
      KpiTile(
        label: 'Возвраты',
        value: Money.format(s.returnsTotal),
        icon: Icons.assignment_return_outlined,
        color: AppColors.warning,
        current: s.returnsTotal,
        previous: prev?.returnsTotal,
        inverse: true,
        hint: '${s.returnsCount} шт. · ${pctText(s.returnsPct)} от продаж',
      ),
      KpiTile(
        label: 'Скидки',
        value: Money.format(s.discounts),
        icon: Icons.percent,
        color: AppColors.info,
        current: s.discounts,
        previous: prev?.discounts,
        inverse: true,
        hint: '${pctText(s.discountPct)} от суммы до скидок',
      ),
      KpiTile(
        label: 'Чеков',
        value: '${s.receipts}',
        icon: Icons.receipt_long_outlined,
        current: s.receipts,
        previous: prev?.receipts,
        hint: s.voids > 0 ? 'аннулировано: ${s.voids}' : 'аннулирований нет',
      ),
      KpiTile(
        label: 'Средний чек',
        value: Money.format(s.avgCheck),
        icon: Icons.functions,
        current: s.avgCheck,
        previous: prev?.avgCheck,
        previousLabel: pl(prev?.avgCheck),
      ),
      if (withCost) ...[
        KpiTile(
          label: 'Валовая прибыль',
          value: Money.format(s.profit),
          icon: Icons.trending_up,
          color: AppColors.success,
          current: s.profit,
          previous: prev?.profit,
          previousLabel: pl(prev?.profit),
          tooltip: 'Чистая выручка минус себестоимость проданного (с учётом возвратов на склад)',
        ),
        KpiTile(
          label: 'Маржа',
          value: pctText(s.marginPct),
          icon: Icons.pie_chart_outline,
          color: AppColors.success,
          hint: 'себестоимость: ${Money.format(s.netCost)}',
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
          title: 'Продажи по дням',
          subtitle: period.label,
          columns: [
            const RCol('Дата'),
            const RCol('Чеков', numeric: true),
            const RCol('Продажи', numeric: true),
            const RCol('Возвраты', numeric: true),
            const RCol('Скидки', numeric: true),
            const RCol('Чистая выручка', numeric: true),
            const RCol('Средний чек', numeric: true),
            if (withCost) const RCol('Прибыль', numeric: true),
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
            const RCell('Итого'),
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
              title: 'Чистая выручка по дням',
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
                          'Чистая выручка: ${Money.format(d.net)}\n'
                          'Чеков: ${d.receipts}'
                          '${d.returns > 0 ? '\nВозвраты: ${Money.format(d.returns)}' : ''}',
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
          title: 'Продажи по часам',
          subtitle: period.label,
          columns: const [
            RCol('Час'),
            RCol('Чеков', numeric: true),
            RCol('Чеков в день', numeric: true, tooltip: 'Среднее количество чеков в этот час за день'),
            RCol('Продажи', numeric: true),
            RCol('Доля чеков', numeric: true),
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
            title: 'Загрузка по часам',
            trailing: peak >= 0
                ? StatusChip('Пик: $peak:00–${peak + 1}:00', color: AppColors.warning)
                : null,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                'Сколько чеков пробивается в каждый час — помогает планировать смены и второго кассира.',
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
                      tooltip: '$h:00–${h + 1}:00\nЧеков: ${byHourN[h]}'
                          ' (≈${(byHourN[h] / days).toStringAsFixed(1).replaceAll('.', ',')} в день)\n'
                          'Продажи: ${Money.format(byHourRev[h])}',
                    ),
                ],
              ),
              const SizedBox(height: Gap.l),
              Text('По дням недели', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Gap.s),
              HourHeatmap(
                values: grid,
                tooltip: (wd, h, v) => '${weekdayShort[wd - 1]}, $h:00–${h + 1}:00 — чеков: $v',
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
