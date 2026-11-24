import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../data/report_queries.dart';
import '../data/report_table.dart';
import '../report_providers.dart';
import '../widgets/kpi.dart';
import '../widgets/report_table_view.dart';

class StockTab extends ConsumerWidget {
  const StockTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final period = ref.watch(reportPeriodProvider);
    final withCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final value = ref.watch(stockValueProvider);
    final dead = ref.watch(deadStockProvider);
    final writeOffs = ref.watch(writeOffsProvider(period));

    return ListView(padding: const EdgeInsets.all(Gap.l), children: [
      AsyncView<List<StockValueRow>>(
        value: value,
        data: (list) {
          final cost = list.fold<int>(0, (s, r) => s + r.costValue);
          final retail = list.fold<int>(0, (s, r) => s + r.retailValue);
          final items = list.fold<int>(0, (s, r) => s + r.items);
          final table = RTable(
            title: l.repStockByCategory,
            columns: [
              RCol(l.commonCategory),
              RCol(l.repColPositions, numeric: true),
              RCol(l.repColQty, numeric: true),
              if (withCost) RCol(l.repColAtCost, numeric: true),
              RCol(l.repColAtRetail, numeric: true),
              if (withCost) RCol(l.repColPotentialProfit, numeric: true),
            ],
            rows: [
              for (final r in list)
                [
                  RCell(r.categoryName),
                  RCell.integer(r.items),
                  RCell.qty(r.qty),
                  if (withCost) RCell.money(r.costValue),
                  RCell.money(r.retailValue),
                  if (withCost) RCell.money(r.potentialProfit),
                ],
            ],
            totals: list.isEmpty
                ? null
                : [
                    RCell(l.commonTotal),
                    RCell.integer(items),
                    RCell.qty(list.fold<double>(0, (s, r) => s + r.qty)),
                    if (withCost) RCell.money(cost),
                    RCell.money(retail),
                    if (withCost) RCell.money(retail - cost),
                  ],
          );
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ResponsiveGrid(minTile: 160, maxColumns: 4, children: [
              KpiTile(
                  label: l.repPositionsInStock,
                  value: '$items',
                  icon: Icons.inventory_2_outlined,
                  hint: l.repCategoriesCount('${list.length}')),
              if (withCost)
                KpiTile(
                  label: l.repStockAtCost,
                  value: Money.format(cost),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.info,
                  tooltip: l.repStockAtCostTooltip,
                  hint: l.repStockAtCostHint,
                ),
              KpiTile(
                  label: l.repStockAtRetail,
                  value: Money.format(retail),
                  icon: Icons.sell_outlined,
                  hint: l.repStockAtRetailHint),
              if (withCost)
                KpiTile(
                  label: l.repPotentialProfit,
                  value: Money.format(retail - cost),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  hint: retail == 0
                      ? null
                      : l.repAvgMarkup(cost == 0 ? '—' : '${((retail - cost) * 100 / cost).toStringAsFixed(0)}%'),
                ),
            ]),
            const SizedBox(height: Gap.m),
            ReportTableCard(
                table: table,
                initialSort: 3,
                emptyText: l.repNoStock),
          ]);
        },
      ),
      const SizedBox(height: Gap.m),
      AsyncView<List<DeadStockRow>>(
        value: dead,
        data: (list) {
          final table = RTable(
            title: l.repDeadStockTitle('$deadStockDays'),
            columns: [
              RCol(l.commonProduct),
              RCol(l.commonStock, numeric: true),
              if (withCost) RCol(l.repColFrozen, numeric: true),
              RCol(l.repColLastSale),
            ],
            rows: [
              for (final r in list)
                [
                  RCell(r.name),
                  RCell.qty(r.qty, r.unit, l),
                  if (withCost) RCell.money(r.value),
                  RCell(r.lastSale == null ? l.repNeverSold : formatDate(r.lastSale!),
                      sort: r.lastSale?.millisecondsSinceEpoch ?? 0),
                ],
            ],
          );
          return ReportTableCard(
            table: table,
            initialSort: withCost ? 2 : 1,
            emptyText: l.repNoDeadStock,
            header: Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: Text(
                l.repDeadStockHint('$deadStockDays'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: Gap.m),
      AsyncView<List<WriteOffRow>>(
        value: writeOffs,
        data: (list) => ReportTableCard(
          table: RTable(
            title: l.repWriteOffsByReason,
            subtitle: period.labelIn(l),
            columns: [
              RCol(l.commonReason),
              RCol(l.repColOperations, numeric: true),
              RCol(l.repColQty, numeric: true),
              if (withCost) RCol(l.commonCost, numeric: true),
            ],
            rows: [
              for (final r in list)
                [
                  RCell(r.reason),
                  RCell.integer(r.count),
                  RCell.qty(r.qty),
                  if (withCost) RCell.money(r.cost),
                ],
            ],
            totals: list.isEmpty
                ? null
                : [
                    RCell(l.commonTotal),
                    RCell.integer(list.fold(0, (s, r) => s + r.count)),
                    RCell.qty(list.fold<double>(0, (s, r) => s + r.qty)),
                    if (withCost) RCell.money(list.fold(0, (s, r) => s + r.cost)),
                  ],
          ),
          initialSort: withCost ? 3 : 1,
          emptyText: l.repNoWriteOffs,
        ),
      ),
    ]);
  }
}
