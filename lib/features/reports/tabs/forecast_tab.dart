import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
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
          title: 'Прогноз спроса и заказ на $_horizon дн.',
          subtitle: 'на ${formatDateTime(DateTime.now())}',
          columns: [
            const RCol('Товар'),
            const RCol('Остаток', numeric: true),
            const RCol('Продаж в день', numeric: true, tooltip: 'Среднее за 28 дней (для новых — за дни с момента создания, не меньше 7)'),
            const RCol('Тренд 7 дн.', numeric: true, tooltip: 'Темп продаж последних 7 дней относительно среднего'),
            const RCol('Хватит на', numeric: true),
            const RCol('Закончится'),
            const RCol('Заказать', numeric: true),
            if (withCost) const RCol('Сумма заказа', numeric: true),
            const RCol('Статус'),
          ],
          rows: [
            for (final f in shown)
              [
                RCell(f.row.name),
                RCell.qty(f.row.stock, f.row.unit),
                RCell(f.hasDemand ? '${_num(f.avgDaily, f.avgDaily < 1 ? 2 : 1)} ${Qty.unitLabel(f.row.unit)}' : '—',
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
                RCell(f.daysOfCover == null ? '∞' : '${_num(f.daysOfCover!, f.daysOfCover! < 10 ? 1 : 0)} дн.',
                    sort: f.daysOfCover ?? 1e9, csv: f.daysOfCover == null ? '' : _num(f.daysOfCover!)),
                RCell(f.stockoutDate == null ? '—' : f.outOfStock ? 'уже нет' : formatDate(f.stockoutDate!),
                    sort: f.stockoutDate?.millisecondsSinceEpoch ?? 1 << 52),
                RCell.qty(f.reorderQty, f.row.unit),
                if (withCost) RCell.money(f.reorderCost),
                f.outOfStock && f.hasDemand
                    ? RCell('Нет в наличии', sort: 0, chipColor: AppColors.danger.toARGB32())
                    : f.atRisk
                        ? RCell('Риск', sort: 1, chipColor: AppColors.warning.toARGB32())
                        : f.hasDemand
                            ? RCell('Норма', sort: 2, chipColor: AppColors.success.toARGB32())
                            : RCell('Нет продаж', sort: 3, chipColor: t.colorScheme.outline.toARGB32()),
              ],
          ],
        );

        return ListView(padding: const EdgeInsets.all(Gap.l), children: [
          ResponsiveGrid(minTile: 160, maxColumns: 4, children: [
            KpiTile(
              label: 'Закончатся за 7 дней',
              value: '${risk.length - out}',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
            KpiTile(
              label: 'Нет в наличии, но покупают',
              value: '$out',
              icon: Icons.remove_shopping_cart_outlined,
              color: AppColors.danger,
            ),
            KpiTile(
              label: 'Позиций к заказу',
              value: '${toOrder.length}',
              icon: Icons.add_shopping_cart,
            ),
            if (withCost)
              KpiTile(
                label: 'Сумма заказа (по себестоимости)',
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
              title: Text('Как считается прогноз', style: t.textTheme.titleSmall),
              childrenPadding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
              expandedAlignment: Alignment.centerLeft,
              children: [
                Text(
                  '• Продаж в день = продано за последние 28 дней (за вычетом возвратов) ÷ 28. '
                  'Для новых товаров — за дни с момента добавления, но не меньше 7.\n'
                  '• Хватит на = остаток ÷ продаж в день.\n'
                  '• Заказать = продаж в день × $_horizon дн. + минимальный остаток − текущий остаток.\n'
                  '• «Риск» — товар закончится в ближайшие $forecastRiskDays дней.',
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
                ? 'Нечего заказывать — запасов хватает на $_horizon дн.'
                : 'Нет товаров с учётом остатков',
            header: Padding(
              padding: const EdgeInsets.only(bottom: Gap.m),
              child: Wrap(spacing: Gap.m, runSpacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7 дн.')),
                    ButtonSegment(value: 14, label: Text('14 дн.')),
                    ButtonSegment(value: 30, label: Text('30 дн.')),
                  ],
                  selected: {_horizon},
                  onSelectionChanged: (s) => setState(() => _horizon = s.first),
                ),
                FilterChip(
                  label: const Text('Только требующие заказа'),
                  selected: _onlyAction,
                  onSelected: (v) => setState(() => _onlyAction = v),
                ),
                if (canBuy && toOrder.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/purchasing'),
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Перейти к закупкам'),
                  ),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}
