import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../data/analytics.dart';
import '../data/report_table.dart';
import '../report_providers.dart';
import '../widgets/kpi.dart';
import '../widgets/report_table_view.dart';

String _num(double v, [int digits = 1]) => v.toStringAsFixed(digits).replaceAll('.', ',');

class ForecastTab extends ConsumerStatefulWidget {
  const ForecastTab({super.key});

  @override
  ConsumerState<ForecastTab> createState() => _ForecastTabState();
}

class _ForecastTabState extends ConsumerState<ForecastTab> {
  int _horizon = 14;
  bool _onlyAction = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final withCost = session?.can(Perm.viewCost) ?? false;
    final canBuy = session?.can(Perm.purchasing) ?? false;
    final data = ref.watch(forecastProvider(_horizon));
    final t = Theme.of(context);

    return AsyncView<List<Forecast>>(
      value: data,
      onRetry: () => ref.invalidate(forecastProvider(_horizon)),
      data: (all) {
        final withDemand = all.where((f) => f.hasDemand).toList();
        final risk = withDemand.where((f) => f.atRisk).toList();
        final out = withDemand.where((f) => f.outOfStock).length;
        final toOrder = all.where((f) => f.reorderQty > 0).toList();
        final orderCost = toOrder.fold<int>(0, (s, f) => s + f.reorderCost);
        final shown = _onlyAction ? all.where((f) => f.atRisk || f.reorderQty > 0).toList() : all;

        final table = RTable(
          title: l.repForecastTitle('$_horizon'),
          subtitle: l.repAsOf(formatDateTime(DateTime.now())),
          columns: [
            RCol(l.commonProduct),
            RCol(l.commonStock, numeric: true),
            RCol(l.repColSalesPerDay, numeric: true, tooltip: l.repColSalesPerDayTooltip),
            RCol(l.repColTrend7, numeric: true, tooltip: l.repColTrend7Tooltip),
            RCol(l.repColCover, numeric: true),
            RCol(l.repColRunsOut),
            RCol(l.repColToOrder, numeric: true),
            if (withCost) RCol(l.repColOrderSum, numeric: true),
            RCol(l.commonStatus),
          ],
          rows: [
            for (final f in shown)
              [
                RCell(f.row.name),
                RCell.qty(f.row.stock, f.row.unit, l),
                RCell(f.hasDemand ? '${_num(f.avgDaily, f.avgDaily < 1 ? 2 : 1)} ${Qty.unitLabel(f.row.unit, l)}' : '—',
                    sort: f.avgDaily, csv: _num(f.avgDaily, 3)),
                RCell(
                  f.hasDemand ? '${f.trendPct >= 0 ? '+' : '−'}${_num(f.trendPct.abs(), 0)}%' : '—',
                  sort: f.trendPct,
                  colorValue: !f.hasDemand || f.trendPct.abs() < 10
                      ? null
                      : f.trendPct > 0
                          ? AppColors.success.toARGB32()
                          : AppColors.danger.toARGB32(),
                ),
                RCell(f.daysOfCover == null ? '∞' : l.repDaysShort(_num(f.daysOfCover!, f.daysOfCover! < 10 ? 1 : 0)),
                    sort: f.daysOfCover ?? 1e9, csv: f.daysOfCover == null ? '' : _num(f.daysOfCover!)),
                RCell(f.stockoutDate == null ? '—' : f.outOfStock ? l.repAlreadyOut : formatDate(f.stockoutDate!),
                    sort: f.stockoutDate?.millisecondsSinceEpoch ?? 1 << 52),
                RCell.qty(f.reorderQty, f.row.unit, l),
                if (withCost) RCell.money(f.reorderCost),
                f.outOfStock && f.hasDemand
                    ? RCell(l.repOutOfStock, sort: 0, chipColor: AppColors.danger.toARGB32())
                    : f.atRisk
                        ? RCell(l.repRisk, sort: 1, chipColor: AppColors.warning.toARGB32())
                        : f.hasDemand
                            ? RCell(l.repNormal, sort: 2, chipColor: AppColors.success.toARGB32())
                            : RCell(l.repNoSalesShort, sort: 3, chipColor: t.colorScheme.outline.toARGB32()),
              ],
          ],
        );

        return ListView(padding: const EdgeInsets.all(Gap.l), children: [
          ResponsiveGrid(minTile: 160, maxColumns: 4, children: [
            KpiTile(
              label: l.repRunOutIn7,
              value: '${risk.length - out}',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
            KpiTile(
              label: l.repOutButWanted,
              value: '$out',
              icon: Icons.remove_shopping_cart_outlined,
              color: AppColors.danger,
            ),
            KpiTile(
              label: l.repItemsToOrder,
              value: '${toOrder.length}',
              icon: Icons.add_shopping_cart,
            ),
            if (withCost)
              KpiTile(
                label: l.repOrderSumAtCost,
                value: Money.format(orderCost),
                icon: Icons.payments_outlined,
                color: AppColors.info,
              ),
          ]),
          const SizedBox(height: Gap.m),
          // Formula help: open on wide screens, collapsed on phones where it
          // would push the table a whole screen down.
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: ValueKey('forecast-help-${context.isCompact}'),
              initiallyExpanded: !context.isCompact,
              shape: const Border(),
              collapsedShape: const Border(),
              leading: Icon(Icons.lightbulb_outline, color: t.colorScheme.primary),
              title: Text(l.repForecastHow, style: t.textTheme.titleSmall),
              childrenPadding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
              expandedAlignment: Alignment.centerLeft,
              children: [
                Text(
                  l.repForecastHelp('$_horizon', '$forecastRiskDays'),
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.m),
          ReportTableCard(
            table: table,
            initialSort: 4,
            initialAscending: true,
            emptyText: _onlyAction
                ? l.repNothingToOrder('$_horizon')
                : l.repNoTrackedProducts,
            header: Padding(
              padding: const EdgeInsets.only(bottom: Gap.m),
              child: Wrap(spacing: Gap.m, runSpacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 7, label: Text(l.repDaysShort('7'))),
                    ButtonSegment(value: 14, label: Text(l.repDaysShort('14'))),
                    ButtonSegment(value: 30, label: Text(l.repDaysShort('30'))),
                  ],
                  selected: {_horizon},
                  onSelectionChanged: (s) => setState(() => _horizon = s.first),
                ),
                FilterChip(
                  label: Text(l.repOnlyToOrder),
                  selected: _onlyAction,
                  onSelected: (v) => setState(() => _onlyAction = v),
                ),
                if (canBuy && toOrder.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/purchasing'),
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: Text(l.repGoToPurchasing),
                  ),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}
