import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/services/sale_service.dart' show paymentMethodLabel;
import '../data/report_queries.dart';
import '../data/report_table.dart';
import '../report_providers.dart';
import '../widgets/charts.dart';
import '../widgets/kpi.dart';
import '../widgets/report_table_view.dart';

class StaffTab extends ConsumerStatefulWidget {
  const StaffTab({super.key});

  @override
  ConsumerState<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends ConsumerState<StaffTab> {
  StaffGrouping _g = StaffGrouping.cashier;

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final rows = ref.watch(byStaffProvider((period, _g)));
    return AsyncView<List<StaffRow>>(
      value: rows,
      data: (list) {
        final total = list.fold<StaffRow>(
            const StaffRow(userId: null, name: 'Итого'),
            (a, r) => StaffRow(
                userId: null,
                name: 'Итого',
                receipts: a.receipts + r.receipts,
                revenue: a.revenue + r.revenue,
                discounts: a.discounts + r.discounts,
                returnsTotal: a.returnsTotal + r.returnsTotal,
                returnsCount: a.returnsCount + r.returnsCount,
                voids: a.voids + r.voids));
        List<RCell> cells(StaffRow r) => [
              RCell(r.name),
              RCell.integer(r.receipts),
              RCell.money(r.revenue),
              RCell.money(r.avgCheck),
              RCell(
                '${Money.format(r.discounts)}'
                '${r.revenue + r.discounts > 0 ? ' (${(r.discounts * 100 / (r.revenue + r.discounts)).toStringAsFixed(1).replaceAll('.', ',')}%)' : ''}',
                sort: r.discounts,
                csv: Money.toInput(r.discounts).replaceAll('.', ','),
              ),
              RCell('${Money.format(r.returnsTotal)} (${r.returnsCount})',
                  sort: r.returnsTotal, csv: Money.toInput(r.returnsTotal).replaceAll('.', ',')),
              RCell.integer(r.voids),
              RCell.money(r.net),
            ];
        final table = RTable(
          title: _g == StaffGrouping.cashier ? 'Продажи по кассирам' : 'Продажи по продавцам',
          subtitle: period.label,
          columns: const [
            RCol('Сотрудник'),
            RCol('Чеков', numeric: true),
            RCol('Продажи', numeric: true),
            RCol('Средний чек', numeric: true),
            RCol('Скидки', numeric: true, tooltip: 'Сумма скидок в чеках сотрудника и доля от суммы до скидок'),
            RCol('Возвраты', numeric: true, tooltip: 'Возвраты по чекам этого сотрудника, оформленные в периоде'),
            RCol('Аннулир.', numeric: true, tooltip: 'Аннулированные чеки'),
            RCol('Чистая выручка', numeric: true),
          ],
          rows: [for (final r in list) cells(r)],
          totals: list.isEmpty ? null : cells(total),
        );
        return ListView(padding: const EdgeInsets.all(Gap.l), children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<StaffGrouping>(
              segments: const [
                ButtonSegment(
                    value: StaffGrouping.cashier,
                    label: Text('Кассиры'),
                    icon: Icon(Icons.point_of_sale_outlined)),
                ButtonSegment(
                    value: StaffGrouping.seller,
                    label: Text('Продавцы'),
                    icon: Icon(Icons.support_agent_outlined)),
              ],
              selected: {_g},
              onSelectionChanged: (s) => setState(() => _g = s.first),
            ),
          ),
          const SizedBox(height: Gap.m),
          if (list.isNotEmpty) ...[
            SectionCard(
              title: 'Чистая выручка по сотрудникам',
              child: ShareBars(relativeToMax: true, items: [
                for (final r in list.take(10))
                  ShareItem(r.name, r.net, trailing: Money.format(r.net)),
              ]),
            ),
            const SizedBox(height: Gap.m),
          ],
          ReportTableCard(table: table, initialSort: 2),
        ]);
      },
    );
  }
}

class PaymentsTab extends ConsumerWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final pays = ref.watch(paymentsProvider(period));
    final debts = ref.watch(debtsProvider(period));
    return AsyncView<List<PaymentRow>>(
      value: pays,
      data: (list) {
        final totalNet = list.fold<int>(0, (s, r) => s + r.net);
        final table = RTable(
          title: 'Оплаты по способам',
          subtitle: period.label,
          columns: const [
            RCol('Способ оплаты'),
            RCol('Чеков', numeric: true),
            RCol('Получено', numeric: true),
            RCol('Возвращено', numeric: true),
            RCol('Итого', numeric: true),
            RCol('Доля', numeric: true),
          ],
          rows: [
            for (final r in list)
              [
                RCell(paymentMethodLabel(r.method)),
                RCell.integer(r.receipts),
                RCell.money(r.paid),
                RCell.money(r.refunded),
                RCell.money(r.net),
                RCell.percent(totalNet == 0 ? 0 : r.net * 100 / totalNet),
              ],
          ],
          totals: list.isEmpty
              ? null
              : [
                  const RCell('Итого'),
                  RCell.integer(list.fold(0, (s, r) => s + r.receipts)),
                  RCell.money(list.fold(0, (s, r) => s + r.paid)),
                  RCell.money(list.fold(0, (s, r) => s + r.refunded)),
                  RCell.money(totalNet),
                  const RCell('100%'),
                ],
        );
        return ListView(padding: const EdgeInsets.all(Gap.l), children: [
          TwoPane(
            left: SectionCard(
              title: 'Структура оплат',
              child: list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: Gap.l),
                      child: Center(child: Text('Нет оплат за период')),
                    )
                  : ShareBars(items: [
                      for (final r in list)
                        ShareItem(paymentMethodLabel(r.method), r.net,
                            trailing:
                                '${Money.format(r.net)} · ${(totalNet == 0 ? 0 : r.net * 100 / totalNet).toStringAsFixed(0)}%',
                            color: paymentMethodColor(r.method)),
                    ]),
            ),
            right: AsyncView<DebtSummary>(
              value: debts,
              data: (d) => SectionCard(
                title: 'Долги клиентов',
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ResponsiveGrid(minTile: 160, maxColumns: 2, children: [
                    KpiTile(
                      label: 'Выдано в долг',
                      value: Money.format(d.issued),
                      icon: Icons.call_made,
                      color: AppColors.warning,
                    ),
                    KpiTile(
                      label: 'Погашено',
                      value: Money.format(d.collected),
                      icon: Icons.call_received,
                      color: AppColors.success,
                    ),
                  ]),
                  const SizedBox(height: Gap.m),
                  _line(context, 'Корректировки (возвраты, аннулирования)', Money.format(d.adjusted)),
                  _line(context, 'Изменение долга за период', Money.format(d.netChange)),
                  const Divider(height: Gap.l),
                  _line(context, 'Текущий долг клиентов (${d.debtors})', Money.format(d.outstanding),
                      bold: true),
                ]),
              ),
            ),
          ),
          const SizedBox(height: Gap.m),
          ReportTableCard(table: table, initialSort: 4),
        ]);
      },
    );
  }

  Widget _line(BuildContext context, String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ]),
      );
}
