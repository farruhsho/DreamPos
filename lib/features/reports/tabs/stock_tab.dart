import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/report_queries.dart';
import '../data/report_table.dart';
import '../report_providers.dart';
import '../widgets/kpi.dart';
import '../widgets/report_table_view.dart';

class StockTab extends ConsumerWidget {
  const StockTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            title: 'Остатки по категориям (на сейчас)',
            columns: [
              const RCol('Категория'),
              const RCol('Позиций', numeric: true),
              const RCol('Кол-во', numeric: true),
              if (withCost) const RCol('По себестоимости', numeric: true),
              const RCol('По рознице', numeric: true),
              if (withCost) const RCol('Потенц. прибыль', numeric: true),
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
                    const RCell('Итого'),
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
                  label: 'Позиций в наличии',
                  value: '$items',
                  icon: Icons.inventory_2_outlined,
                  hint: 'категорий: ${list.length}'),
              if (withCost)
                KpiTile(
                  label: 'Склад по себестоимости',
                  value: Money.format(cost),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.info,
                  tooltip: 'Сколько денег вложено в товар на складе',
                  hint: 'вложено в товар',
                ),
              KpiTile(
                  label: 'Склад по розничным ценам',
                  value: Money.format(retail),
                  icon: Icons.sell_outlined,
                  hint: 'если продать всё по текущим ценам'),
              if (withCost)
                KpiTile(
                  label: 'Потенциальная прибыль',
                  value: Money.format(retail - cost),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  hint: retail == 0
                      ? null
                      : 'наценка в среднем ${cost == 0 ? '—' : '${((retail - cost) * 100 / cost).toStringAsFixed(0)}%'}',
                ),
            ]),
            const SizedBox(height: Gap.m),
            ReportTableCard(
                table: table,
                initialSort: 3,
                emptyText: 'На складе нет товаров с положительным остатком'),
          ]);
        },
      ),
      const SizedBox(height: Gap.m),
      AsyncView<List<DeadStockRow>>(
        value: dead,
        data: (list) {
          final table = RTable(
            title: 'Неликвид: нет продаж $deadStockDays дней',
            columns: [
              const RCol('Товар'),
              const RCol('Остаток', numeric: true),
              if (withCost) const RCol('Заморожено', numeric: true),
              const RCol('Последняя продажа'),
            ],
            rows: [
              for (final r in list)
                [
                  RCell(r.name),
                  RCell.qty(r.qty, r.unit),
                  if (withCost) RCell.money(r.value),
                  RCell(r.lastSale == null ? 'не продавался' : formatDate(r.lastSale!),
                      sort: r.lastSale?.millisecondsSinceEpoch ?? 0),
                ],
            ],
          );
          return ReportTableCard(
            table: table,
            initialSort: withCost ? 2 : 1,
            emptyText: 'Отлично — неликвидных товаров нет',
            header: Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: Text(
                'Товары с остатком, которые не продавались $deadStockDays дней. '
                'Сделайте уценку, акцию или верните поставщику.',
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
            title: 'Списания по причинам',
            subtitle: period.label,
            columns: [
              const RCol('Причина'),
              const RCol('Операций', numeric: true),
              const RCol('Кол-во', numeric: true),
              if (withCost) const RCol('Себестоимость', numeric: true),
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
                    const RCell('Итого'),
                    RCell.integer(list.fold(0, (s, r) => s + r.count)),
                    RCell.qty(list.fold<double>(0, (s, r) => s + r.qty)),
                    if (withCost) RCell.money(list.fold(0, (s, r) => s + r.cost)),
                  ],
          ),
          initialSort: withCost ? 3 : 1,
          emptyText: 'Списаний за период нет',
        ),
      ),
    ]);
  }
}
