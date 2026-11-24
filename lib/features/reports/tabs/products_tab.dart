import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/permissions.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/analytics.dart';
import '../data/report_queries.dart';
import '../data/report_table.dart';
import '../report_providers.dart';
import '../widgets/charts.dart';
import '../widgets/kpi.dart';
import '../widgets/report_table_view.dart';

int abcColor(AbcClass c) => switch (c) {
      AbcClass.a => AppColors.success.toARGB32(),
      AbcClass.b => AppColors.info.toARGB32(),
      AbcClass.c => AppColors.warning.toARGB32(),
    };

class ProductsTab extends ConsumerStatefulWidget {
  const ProductsTab({super.key});

  @override
  ConsumerState<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<ProductsTab> {
  bool _byCategory = false;
  AbcClass? _abc;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final withCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final switcher = Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('По товарам'), icon: Icon(Icons.inventory_2_outlined)),
          ButtonSegment(value: true, label: Text('По категориям'), icon: Icon(Icons.category_outlined)),
        ],
        selected: {_byCategory},
        onSelectionChanged: (s) => setState(() => _byCategory = s.first),
      ),
    );

    if (_byCategory) {
      final cats = ref.watch(byCategoryProvider(period));
      return AsyncView<List<CategoryRow>>(
        value: cats,
        data: (list) {
          final total = list.fold<int>(0, (s, c) => s + c.revenue);
          final table = RTable(
            title: 'Продажи по категориям',
            subtitle: period.label,
            columns: [
              const RCol('Категория'),
              const RCol('Товаров', numeric: true),
              const RCol('Кол-во', numeric: true),
              const RCol('Выручка', numeric: true),
              if (withCost) ...const [
                RCol('Себестоимость', numeric: true),
                RCol('Прибыль', numeric: true),
                RCol('Маржа', numeric: true),
              ],
              const RCol('Доля выручки', numeric: true),
            ],
            rows: [
              for (final c in list)
                [
                  RCell(c.name),
                  RCell.integer(c.products),
                  RCell.qty(c.qty),
                  RCell.money(c.revenue),
                  if (withCost) ...[
                    RCell.money(c.cost),
                    RCell.money(c.profit),
                    RCell.percent(c.marginPct),
                  ],
                  RCell.percent(total == 0 ? 0 : c.revenue * 100 / total),
                ],
            ],
          );
          return ListView(padding: const EdgeInsets.all(Gap.l), children: [
            switcher,
            const SizedBox(height: Gap.m),
            if (list.isNotEmpty)
              SectionCard(
                title: withCost ? 'Прибыль по категориям' : 'Выручка по категориям',
                child: ShareBars(items: [
                  for (final c in list.take(10))
                    ShareItem(c.name, withCost ? c.profit : c.revenue,
                        trailing: Money.format(withCost ? c.profit : c.revenue)),
                ]),
              ),
            if (list.isNotEmpty) const SizedBox(height: Gap.m),
            ReportTableCard(key: const ValueKey('categories-table'), table: table, initialSort: 3),
          ]);
        },
      );
    }

    final products = ref.watch(byProductProvider(period));
    return AsyncView<List<ProductRow>>(
      value: products,
      data: (list) {
        final abc = abcClassify(list.map((p) => MapEntry(p.id, p.revenue)));
        final total = list.fold<int>(0, (s, p) => s + p.revenue);
        final counts = {for (final c in AbcClass.values) c: 0};
        final revenueBy = {for (final c in AbcClass.values) c: 0};
        for (final p in list) {
          final c = abc[p.id]!;
          counts[c] = counts[c]! + 1;
          revenueBy[c] = revenueBy[c]! + p.revenue;
        }
        final q = _q.toLowerCase();
        final filtered = list
            .where((p) => (_abc == null || abc[p.id] == _abc) &&
                (q.isEmpty || p.name.toLowerCase().contains(q)))
            .toList();
        final table = RTable(
          title: 'Продажи по товарам',
          subtitle: period.label,
          columns: [
            const RCol('Товар'),
            const RCol('Категория'),
            const RCol('Кол-во', numeric: true),
            const RCol('Выручка', numeric: true),
            if (withCost) ...const [
              RCol('Себестоимость', numeric: true),
              RCol('Прибыль', numeric: true),
              RCol('Маржа', numeric: true),
            ],
            const RCol('Доля', numeric: true),
            const RCol('ABC', tooltip: 'A — 80% выручки, B — следующие 15%, C — последние 5%'),
          ],
          rows: [
            for (final p in filtered)
              [
                RCell(p.name),
                RCell(p.categoryName ?? '—'),
                RCell.qty(p.qty, p.unit),
                RCell.money(p.revenue),
                if (withCost) ...[
                  RCell.money(p.cost),
                  RCell(Money.format(p.profit),
                      sort: p.profit,
                      csv: Money.toInput(p.profit).replaceAll('.', ','),
                      colorValue: p.profit < 0 ? AppColors.danger.toARGB32() : null),
                  RCell('${p.marginPct.toStringAsFixed(1).replaceAll('.', ',')}%',
                      sort: p.marginPct,
                      csv: p.marginPct.toStringAsFixed(1).replaceAll('.', ','),
                      colorValue: p.revenue > 0 && p.marginPct < 5 ? AppColors.danger.toARGB32() : null),
                ],
                RCell.percent(total == 0 ? 0 : p.revenue * 100 / total),
                RCell(abc[p.id]!.label, sort: abc[p.id]!.index, chipColor: abcColor(abc[p.id]!)),
              ],
          ],
        );
        return ListView(padding: const EdgeInsets.all(Gap.l), children: [
          switcher,
          const SizedBox(height: Gap.m),
          ResponsiveGrid(minTile: 220, maxColumns: 3, children: [
            for (final c in AbcClass.values)
              KpiTile(
                label: 'Класс ${c.label} — ${c.hint}',
                value: '${counts[c]} тов.',
                icon: Icons.label_important_outline,
                color: Color(abcColor(c)),
                hint: '${Money.format(revenueBy[c]!)} · '
                    '${(total == 0 ? 0 : revenueBy[c]! * 100 / total).toStringAsFixed(0)}% выручки',
                onTap: () => setState(() => _abc = _abc == c ? null : c),
              ),
          ]),
          const SizedBox(height: Gap.m),
          ReportTableCard(
            key: const ValueKey('products-table'),
            table: table,
            initialSort: 3,
            emptyText: list.isEmpty ? 'Нет продаж за период' : 'Ничего не найдено',
            header: Padding(
              padding: const EdgeInsets.only(bottom: Gap.m),
              child: Wrap(spacing: Gap.s, runSpacing: Gap.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(
                  width: 260,
                  child: SearchField(hint: 'Поиск товара', onChanged: (v) => setState(() => _q = v)),
                ),
                ChoiceChip(
                  label: const Text('Все'),
                  selected: _abc == null,
                  onSelected: (_) => setState(() => _abc = null),
                ),
                for (final c in AbcClass.values)
                  ChoiceChip(
                    label: Text('${c.label} (${counts[c]})'),
                    tooltip: c.hint,
                    selected: _abc == c,
                    onSelected: (_) => setState(() => _abc = _abc == c ? null : c),
                  ),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}
