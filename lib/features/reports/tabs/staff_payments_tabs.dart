import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/services/sale_service.dart' show paymentMethodLabel;
import '../../../l10n/l10n.dart';
import '../data/gift_sales_report.dart';
import '../data/period.dart';
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
    final l = context.l10n;
    final period = ref.watch(reportPeriodProvider);
    final rows = ref.watch(byStaffProvider((period, _g)));
    return AsyncView<List<StaffRow>>(
      value: rows,
      data: (list) {
        final total = list.fold<StaffRow>(
            StaffRow(userId: null, name: l.commonTotal),
            (a, r) => StaffRow(
                userId: null,
                name: l.commonTotal,
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
          title: _g == StaffGrouping.cashier ? l.repSalesByCashier : l.repSalesBySeller,
          subtitle: period.labelIn(l),
          columns: [
            RCol(l.commonEmployee),
            RCol(l.repReceipts, numeric: true),
            RCol(l.repTabSales, numeric: true),
            RCol(l.repAvgCheck, numeric: true),
            RCol(l.repDiscounts, numeric: true, tooltip: l.repStaffDiscountsTooltip),
            RCol(l.repReturns, numeric: true, tooltip: l.repStaffReturnsTooltip),
            RCol(l.repColVoidedShort, numeric: true, tooltip: l.repVoidedReceipts),
            RCol(l.repNetRevenue, numeric: true),
          ],
          rows: [for (final r in list) cells(r)],
          totals: list.isEmpty ? null : cells(total),
        );
        return ListView(padding: const EdgeInsets.all(Gap.l), children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<StaffGrouping>(
              segments: [
                ButtonSegment(
                    value: StaffGrouping.cashier,
                    label: Text(l.repCashiers),
                    icon: const Icon(Icons.point_of_sale_outlined)),
                ButtonSegment(
                    value: StaffGrouping.seller,
                    label: Text(l.repSellers),
                    icon: const Icon(Icons.support_agent_outlined)),
              ],
              selected: {_g},
              onSelectionChanged: (s) => setState(() => _g = s.first),
            ),
          ),
          const SizedBox(height: Gap.m),
          if (list.isNotEmpty) ...[
            SectionCard(
              title: l.repNetRevenueByStaff,
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
    final l = context.l10n;
    final period = ref.watch(reportPeriodProvider);
    final pays = ref.watch(paymentsProvider(period));
    final debts = ref.watch(debtsProvider(period));
    return AsyncView<List<PaymentRow>>(
      value: pays,
      data: (list) {
        final totalNet = list.fold<int>(0, (s, r) => s + r.net);
        final table = RTable(
          title: l.repPaymentsByMethod,
          subtitle: period.labelIn(l),
          columns: [
            RCol(l.commonPaymentMethod),
            RCol(l.repReceipts, numeric: true),
            RCol(l.repColReceived, numeric: true),
            RCol(l.repColRefunded, numeric: true),
            RCol(l.commonTotal, numeric: true),
            RCol(l.repColShare, numeric: true),
          ],
          rows: [
            for (final r in list)
              [
                RCell(paymentMethodLabel(r.method, l)),
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
                  RCell(l.commonTotal),
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
              title: l.repPaymentsStructure,
              child: list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Gap.l),
                      child: Center(child: Text(l.repNoPayments)),
                    )
                  : ShareBars(items: [
                      for (final r in list)
                        ShareItem(paymentMethodLabel(r.method, l), r.net,
                            trailing:
                                '${Money.format(r.net)} · ${(totalNet == 0 ? 0 : r.net * 100 / totalNet).toStringAsFixed(0)}%',
                            color: paymentMethodColor(r.method)),
                    ]),
            ),
            right: AsyncView<DebtSummary>(
              value: debts,
              data: (d) => SectionCard(
                title: l.repCustomerDebts,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ResponsiveGrid(minTile: 160, maxColumns: 2, children: [
                    KpiTile(
                      label: l.repDebtIssued,
                      value: Money.format(d.issued),
                      icon: Icons.call_made,
                      color: AppColors.warning,
                    ),
                    KpiTile(
                      label: l.repDebtCollected,
                      value: Money.format(d.collected),
                      icon: Icons.call_received,
                      color: AppColors.success,
                    ),
                  ]),
                  const SizedBox(height: Gap.m),
                  _line(context, l.repDebtAdjusted, Money.format(d.adjusted)),
                  _line(context, l.repDebtChange, Money.format(d.netChange)),
                  const Divider(height: Gap.l),
                  _line(context, l.repDebtOutstanding('${d.debtors}'), Money.format(d.outstanding),
                      bold: true),
                ]),
              ),
            ),
          ),
          const SizedBox(height: Gap.m),
          ReportTableCard(table: table, initialSort: 4),
          _GiftSalesBlock(period: period),
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

/// «Продажа сертификатов (аванс, не выручка)»: separate from revenue and from
/// the payments table above; hidden when the period has no gift card sales.
class _GiftSalesBlock extends ConsumerWidget {
  const _GiftSalesBlock({required this.period});
  final ReportPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final gifts = ref.watch(giftSalesReportProvider(period));
    return gifts.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(top: Gap.m),
        child: SectionCard(
          title: l.repGiftSalesTitle,
          child: ErrorView(error: e, onRetry: () => ref.invalidate(giftSalesReportProvider(period))),
        ),
      ),
      data: (g) {
        if (g.isEmpty) return const SizedBox.shrink();
        final t = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: Gap.m),
          child: ReportTableCard(
            key: const ValueKey('gift-sales-report'),
            table: giftSalesTable(g, period, l),
            pageSize: 10,
            header: Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Gap.xs),
                  Expanded(
                    child: Text(
                      l.repGiftSalesHint,
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
