import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/services/sale_service.dart' show paymentMethodLabel;
import '../reports/data/period.dart';
import '../reports/data/report_queries.dart';
import '../reports/report_providers.dart';
import '../reports/tabs/insights_tab.dart' show canOpenRoute;
import '../reports/widgets/charts.dart';
import '../reports/widgets/kpi.dart';
import 'dashboard_providers.dart';
import '../../l10n/l10n.dart';

/// Обзор — home screen for the owner/manager: today's KPIs vs yesterday,
/// 14-day revenue, top products, payment split, alerts and recent receipts.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _now = DateTime.now();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Keeps "today" / "yesterday at this time" correct while the screen is open.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final progress = ref.watch(storeProgressProvider);
    final name = session?.user.name;
    return PageScaffold(
      title: l.dashTitle,
      subtitle: l.dashTodayDate(formatDate(_now)) + (name == null ? '' : ' · $name'),
      padding: EdgeInsets.zero,
      actions: [
        if (session?.can(Perm.viewReports) ?? false)
          IconButton(
            tooltip: l.dashReports,
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.go('/reports'),
          ),
        if (session?.can(Perm.sell) ?? false)
          Padding(
            padding: const EdgeInsets.only(left: Gap.s),
            child: FilledButton.icon(
              onPressed: () => context.go('/pos'),
              icon: const Icon(Icons.point_of_sale, size: 18),
              label: Text(l.dashPos),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
          ),
      ],
      body: AsyncView<StoreProgress>(
        value: progress,
        onRetry: () => ref.invalidate(storeProgressProvider),
        data: (p) => p.isNew ? _Onboarding(progress: p) : _DashboardBody(now: _now),
      ),
    );
  }
}

/// Navigates if the user may open [route]; returns null (disabled) otherwise.
VoidCallback? _nav(BuildContext context, Session? s, String route) =>
    canOpenRoute(s, route) ? () => context.go(route) : null;

// ------------------------------------------------------------------ onboarding

class _Onboarding extends ConsumerWidget {
  const _Onboarding({required this.progress});
  final StoreProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final shift = ref.watch(currentShiftProvider).value;
    final steps = [
      (
        done: progress.products > 0,
        title: l.dashOnbProductsTitle,
        text: progress.products > 0
            ? l.dashOnbProductsDone('${progress.products}')
            : l.dashOnbProductsText,
        icon: Icons.inventory_2_outlined,
        route: '/products',
        button: l.dashOnbProductsButton,
      ),
      (
        done: progress.shifts > 0,
        title: l.dashOnbShiftTitle,
        text: shift != null
            ? l.dashOnbShiftDone('${shift.number}')
            : l.dashOnbShiftText,
        icon: Icons.schedule_outlined,
        route: '/shifts',
        button: l.dashOnbShiftButton,
      ),
      (
        done: progress.sales > 0,
        title: l.dashOnbSaleTitle,
        text: l.dashOnbSaleText,
        icon: Icons.point_of_sale_outlined,
        route: '/pos',
        button: l.dashOnbSaleButton,
      ),
    ];
    final next = steps.indexWhere((s) => !s.done);
    return ListView(padding: const EdgeInsets.all(Gap.l), children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: Gap.l),
            Icon(Icons.rocket_launch_outlined, size: 48, color: t.colorScheme.primary),
            const SizedBox(height: Gap.m),
            Text(l.dashWelcome,
                textAlign: TextAlign.center, style: t.textTheme.headlineSmall),
            const SizedBox(height: Gap.s),
            Text(
              l.dashWelcomeText,
              textAlign: TextAlign.center,
              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: Gap.l),
            LinearProgressIndicator(
              value: progress.stepsDone / 3,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: Gap.xs),
            Text(l.dashStepsDone('${progress.stepsDone}', '3'),
                textAlign: TextAlign.end, style: t.textTheme.labelSmall),
            const SizedBox(height: Gap.m),
            for (var i = 0; i < steps.length; i++) ...[
              Card(
                key: ValueKey('onboarding-step-$i'),
                child: Padding(
                  padding: const EdgeInsets.all(Gap.l),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: steps[i].done
                          ? AppColors.success.withValues(alpha: 0.15)
                          : t.colorScheme.primaryContainer,
                      child: steps[i].done
                          ? const Icon(Icons.check, color: AppColors.success)
                          : Text('${i + 1}',
                              style: TextStyle(
                                  color: t.colorScheme.primary, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: Gap.l),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(steps[i].title,
                            style: t.textTheme.titleMedium?.copyWith(
                                decoration: steps[i].done ? TextDecoration.lineThrough : null)),
                        const SizedBox(height: 2),
                        Text(steps[i].text,
                            style: t.textTheme.bodySmall
                                ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                      ]),
                    ),
                    const SizedBox(width: Gap.m),
                    _StepButton(
                      label: steps[i].button,
                      primary: i == next,
                      onPressed: _nav(context, session, steps[i].route),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: Gap.m),
            ],
          ]),
        ),
      ),
    ]);
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.primary, required this.onPressed});
  final String label;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final Widget b = narrow
        ? IconButton.filledTonal(
            onPressed: onPressed, icon: const Icon(Icons.arrow_forward), tooltip: label)
        : primary
            ? FilledButton(onPressed: onPressed, child: Text(label))
            : OutlinedButton(onPressed: onPressed, child: Text(label));
    return onPressed == null ? Tooltip(message: context.l10n.dashNoAccess, child: b) : b;
  }
}

// ------------------------------------------------------------------ main body

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = _Kpis(now: now);
    final chart = _RevenueChart(now: now);
    final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _ShiftCard(now: now),
      const SizedBox(height: Gap.m),
      const _Alerts(),
    ]);
    final top = _TopProducts(now: now);
    final pays = _PaymentSplit(now: now);
    const recent = _RecentReceipts();
    const gapV = SizedBox(height: Gap.m);
    const gapH = SizedBox(width: Gap.m);

    return LayoutBuilder(builder: (context, c) {
      // content width (without the navigation rail), not the window width
      final w = c.maxWidth;
      final List<Widget> sections;
      if (w >= 1150) {
        sections = [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: chart),
            gapH,
            Expanded(child: side),
          ]),
          gapV,
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: top),
            gapH,
            Expanded(child: pays),
            gapH,
            const Expanded(child: recent),
          ]),
        ];
      } else if (w >= 720) {
        // tablet: three narrow columns would truncate product names
        sections = [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: chart),
            gapH,
            Expanded(flex: 2, child: side),
          ]),
          gapV,
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: top),
            gapH,
            Expanded(child: pays),
          ]),
          gapV,
          recent,
        ];
      } else {
        sections = [side, gapV, chart, gapV, top, gapV, pays, gapV, recent];
      }
      return ListView(padding: const EdgeInsets.all(Gap.l), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [kpis, gapV, ...sections],
            ),
          ),
        ),
      ]);
    });
  }
}

/// Single-column (phone) layout: cards are stacked, so header controls can
/// keep full 48px touch targets instead of compact ones.
bool _isPhone(BuildContext context) => MediaQuery.sizeOf(context).width < 720;

/// Compact text button for [SectionCard] headers (keeps header heights even
/// side by side); a full-size touch target on phones.
Widget _headerLink(BuildContext context, String label, VoidCallback? onPressed) => TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize:
            _isPhone(context) ? MaterialTapTargetSize.padded : MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );

ReportPeriod _today(DateTime now) => ReportPeriod.preset(PeriodPreset.today, now: now);

/// Yesterday from midnight until "now minus one day" (rounded to 5 minutes
/// so the stream key doesn't change every minute).
ReportPeriod _yesterdaySoFar(DateTime now) {
  final y = DateTime(now.year, now.month, now.day - 1);
  final cut = DateTime(now.year, now.month, now.day - 1, now.hour, now.minute - now.minute % 5);
  return ReportPeriod(y, cut.isAfter(y) ? cut : y.add(const Duration(minutes: 5)));
}

class _Kpis extends ConsumerWidget {
  const _Kpis({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final withCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final today = ref.watch(summaryProvider(_today(now)));
    final yest = ref.watch(summaryProvider(_yesterdaySoFar(now))).value;
    return AsyncView<SalesSummary>(
      value: today,
      data: (s) {
        String? y(int? v) => v == null ? null : l.dashYesterdaySoFar(Money.format(v));
        return ResponsiveGrid(minTile: 160, maxColumns: 5, stretchLast: true, children: [
          KpiTile(
            key: const ValueKey('kpi-revenue'),
            label: l.dashRevenueToday,
            value: Money.format(s.net),
            icon: Icons.payments_outlined,
            current: s.net,
            previous: yest?.net,
            previousLabel: y(yest?.net),
            tooltip: l.dashRevenueTooltip,
          ),
          KpiTile(
            label: l.dashReceipts,
            value: '${s.receipts}',
            icon: Icons.receipt_long_outlined,
            current: s.receipts,
            previous: yest?.receipts,
            previousLabel: yest == null ? null : l.dashYesterdaySoFar('${yest.receipts}'),
          ),
          KpiTile(
            label: l.dashAvgCheck,
            value: Money.format(s.avgCheck),
            icon: Icons.functions,
            current: s.avgCheck,
            previous: yest?.avgCheck,
            previousLabel: y(yest?.avgCheck),
          ),
          if (withCost)
            KpiTile(
              label: l.dashGrossProfit,
              value: Money.format(s.profit),
              icon: Icons.trending_up,
              color: AppColors.success,
              current: s.profit,
              previous: yest?.profit,
              previousLabel: s.net == 0
                  ? y(yest?.profit)
                  : l.dashMargin(s.marginPct.toStringAsFixed(1).replaceAll('.', ',')),
            ),
          KpiTile(
            label: l.dashReturns,
            value: Money.format(s.returnsTotal),
            icon: Icons.assignment_return_outlined,
            color: AppColors.warning,
            current: s.returnsTotal,
            previous: yest?.returnsTotal,
            inverse: true,
            previousLabel: l.dashPcs('${s.returnsCount}') + (s.voids > 0 ? l.dashVoidedSuffix('${s.voids}') : ''),
          ),
        ]);
      },
    );
  }
}

class _RevenueChart extends ConsumerWidget {
  const _RevenueChart({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ReportPeriod(DateTime(now.year, now.month, now.day - 13),
        DateTime(now.year, now.month, now.day + 1));
    final l = context.l10n;
    final days = ref.watch(byDayProvider(p));
    final session = ref.watch(sessionProvider);
    return SectionCard(
      title: l.dashRevenue14,
      trailing: _headerLink(context, l.commonDetails, _nav(context, session, '/reports')),
      child: AsyncView<List<DayPoint>>(
        value: days,
        data: (list) {
          final total = list.fold<int>(0, (s, d) => s + d.net);
          final active = list.where((d) => d.receipts > 0).length;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              l.dashRevenueSummary(Money.format(total), Money.format(active == 0 ? 0 : total ~/ active)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: Gap.m),
            SimpleBarChart(
              height: 170,
              formatAxis: (v) => Money.format(v),
              data: [
                for (final d in list)
                  BarDatum(
                    label: '${d.day.day}',
                    value: d.net,
                    highlight: dayKey(d.day) == dayKey(now),
                    tooltip: '${weekdayShortIn(l)[d.day.weekday - 1]}, ${formatDate(d.day)}\n'
                        '${l.dashBarTooltip(Money.format(d.net), '${d.receipts}')}',
                  ),
              ],
            ),
          ]);
        },
      ),
    );
  }
}

class _ShiftCard extends ConsumerWidget {
  const _ShiftCard({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final shift = ref.watch(currentShiftProvider);
    return AsyncView<Shift?>(
      value: shift,
      data: (s) {
        if (s == null) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0x22B45309),
                  child: Icon(Icons.lock_clock, color: AppColors.warning)),
              title: Text(l.dashShiftClosed),
              subtitle: Text(l.dashShiftClosedText),
              trailing: FilledButton.tonal(
                  onPressed: _nav(context, session, '/shifts'), child: Text(l.commonOpen)),
            ),
          );
        }
        final dur = now.difference(s.openedAt);
        final long = dur.inHours >= 16;
        final totals = ref.watch(shiftTotalsProvider(s.id)).value;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _nav(context, session, '/shifts'),
            child: Padding(
              padding: const EdgeInsets.all(Gap.l),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.schedule, color: long ? AppColors.warning : AppColors.success),
                  const SizedBox(width: Gap.s),
                  Expanded(
                      child: Text(l.dashShiftOpen('${s.number}'),
                          style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                  StatusChip(long ? l.dashShiftLong : l.dashShiftRunning,
                      color: long ? AppColors.warning : AppColors.success),
                ]),
                const SizedBox(height: Gap.s),
                Text(
                  '${l.dashShiftSince(formatTime(s.openedAt))}'
                  '${dayKey(s.openedAt) != dayKey(now) ? ' (${formatDate(s.openedAt)})' : ''}'
                  ' · ${l.dashDuration('${dur.inHours}', '${dur.inMinutes % 60}')}'
                  '${totals?.cashier == null ? '' : ' · ${totals!.cashier}'}',
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
                if (totals != null) ...[
                  const SizedBox(height: Gap.s),
                  Text(l.dashShiftTotals('${totals.receipts}', Money.format(totals.revenue))),
                ],
                if (long) ...[
                  const SizedBox(height: Gap.s),
                  Text(l.dashShiftLongText,
                      style: t.textTheme.bodySmall?.copyWith(color: AppColors.warning)),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _Alerts extends ConsumerWidget {
  const _Alerts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final stock = ref.watch(stockAlertsProvider).value;
    final debt = ref.watch(debtTotalProvider).value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _AlertTile(
        key: const ValueKey('alert-stock'),
        icon: Icons.inventory_outlined,
        color: (stock?.total ?? 0) > 0 ? AppColors.danger : AppColors.success,
        title: stock == null
            ? l.dashStockLoading
            : stock.total == 0
                ? l.dashStockOk
                : l.dashStockLow('${stock.low}', '${stock.out}'),
        subtitle: l.dashStockSubtitle,
        onTap: _nav(context, session, '/inventory'),
      ),
      const SizedBox(height: Gap.m),
      _AlertTile(
        key: const ValueKey('alert-debt'),
        icon: Icons.account_balance_wallet_outlined,
        color: (debt?.total ?? 0) > 0 ? AppColors.warning : AppColors.success,
        title: debt == null
            ? l.dashDebtLoading
            : debt.total == 0
                ? l.dashDebtNone
                : l.dashDebtTotal(Money.format(debt.total)),
        subtitle: debt == null || debt.total == 0 ? l.dashDebtAllPaid : l.dashDebtors('${debt.customers}'),
        onTap: _nav(context, session, '/customers'),
      ),
    ]);
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: onTap,
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            // same weight as the other card titles (shift card, sections)
            title: Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle),
            trailing: onTap == null ? null : const Icon(Icons.chevron_right),
          ),
        );
    return onTap == null ? Tooltip(message: context.l10n.dashNoAccess, child: card) : card;
  }
}

class _TopProducts extends ConsumerStatefulWidget {
  const _TopProducts({required this.now});
  final DateTime now;

  @override
  ConsumerState<_TopProducts> createState() => _TopProductsState();
}

class _TopProductsState extends ConsumerState<_TopProducts> {
  bool _week = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.now;
    final p = _week
        ? ReportPeriod(DateTime(n.year, n.month, n.day - 6), DateTime(n.year, n.month, n.day + 1))
        : _today(n);
    final l = context.l10n;
    final rows = ref.watch(byProductProvider(p));
    return SectionCard(
      title: l.dashTop5,
      trailing: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize:
              _isPhone(context) ? MaterialTapTargetSize.padded : MaterialTapTargetSize.shrinkWrap,
        ),
        segments: [
          ButtonSegment(value: false, label: Text(l.commonToday)),
          ButtonSegment(value: true, label: Text(l.dash7Days)),
        ],
        selected: {_week},
        onSelectionChanged: (s) => setState(() => _week = s.first),
      ),
      child: AsyncView<List<ProductRow>>(
        value: rows,
        data: (list) {
          final top = list.where((r) => r.revenue > 0).take(5).toList();
          if (top.isEmpty) {
            return _Muted(l.dashNoSales);
          }
          return ShareBars(relativeToMax: true, items: [
            for (final r in top)
              ShareItem(r.name, r.revenue,
                  trailing: '${Qty.format(r.qty, r.unit)} · ${Money.format(r.revenue)}'),
          ]);
        },
      ),
    );
  }
}

class _PaymentSplit extends ConsumerWidget {
  const _PaymentSplit({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final rows = ref.watch(paymentsProvider(_today(now)));
    return SectionCard(
      title: l.dashPaymentsToday,
      child: AsyncView<List<PaymentRow>>(
        value: rows,
        data: (list) {
          final items = list.where((r) => r.net != 0).toList();
          final total = items.fold<int>(0, (s, r) => s + r.net);
          if (items.isEmpty) return _Muted(l.dashNoPaymentsToday);
          return ShareBars(items: [
            for (final r in items)
              ShareItem(paymentMethodLabel(r.method, l), r.net,
                  trailing:
                      '${Money.format(r.net)} · ${total == 0 ? 0 : (r.net * 100 / total).round()}%',
                  color: paymentMethodColor(r.method)),
          ]);
        },
      ),
    );
  }
}

class _RecentReceipts extends ConsumerWidget {
  const _RecentReceipts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final rows = ref.watch(recentSalesProvider);
    final t = Theme.of(context);
    final l = context.l10n;
    return SectionCard(
      title: l.dashRecentReceipts,
      trailing: _headerLink(context, l.dashAllReceipts, _nav(context, session, '/sales')),
      child: AsyncView<List<RecentSale>>(
        value: rows,
        data: (list) {
          if (list.isEmpty) return _Muted(l.dashNoReceipts);
          return Column(children: [
            for (final r in list)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: _nav(context, session, '/sales'),
                title: Text(l.dashReceiptNumber('${r.sale.number}'),
                    style: r.sale.status == 'voided'
                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                        : null),
                subtitle: Text(
                  [
                    dayKey(r.sale.createdAt) == dayKey(DateTime.now())
                        ? formatTime(r.sale.createdAt)
                        : formatDateTime(r.sale.createdAt),
                    ?r.customer,
                    ?r.cashier,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Money.format(r.sale.total),
                        style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (_statusLabel(l, r.sale.status) case final st?)
                      Text(st.$1, style: TextStyle(fontSize: 11, color: st.$2)),
                  ],
                ),
              ),
          ]);
        },
      ),
    );
  }

  (String, Color)? _statusLabel(AppLocalizations l, String s) => switch (s) {
        'voided' => (l.dashStatusVoided, AppColors.danger),
        'returned' => (l.dashStatusReturned, AppColors.warning),
        'partially_returned' => (l.dashStatusPartReturned, AppColors.warning),
        _ => null,
      };
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.l),
        child: Center(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
}
