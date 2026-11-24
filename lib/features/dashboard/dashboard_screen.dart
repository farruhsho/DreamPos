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
    final session = ref.watch(sessionProvider);
    final progress = ref.watch(storeProgressProvider);
    final name = session?.user.name;
    return PageScaffold(
      title: 'Обзор',
      subtitle: 'Сегодня, ${formatDate(_now)}${name == null ? '' : ' · $name'}',
      padding: EdgeInsets.zero,
      actions: [
        if (session?.can(Perm.viewReports) ?? false)
          IconButton(
            tooltip: 'Отчёты',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.go('/reports'),
          ),
        if (session?.can(Perm.sell) ?? false)
          Padding(
            padding: const EdgeInsets.only(left: Gap.s),
            child: FilledButton.icon(
              onPressed: () => context.go('/pos'),
              icon: const Icon(Icons.point_of_sale, size: 18),
              label: const Text('Касса'),
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
    final session = ref.watch(sessionProvider);
    final shift = ref.watch(currentShiftProvider).value;
    final steps = [
      (
        done: progress.products > 0,
        title: 'Добавьте товары',
        text: progress.products > 0
            ? 'В каталоге ${progress.products} тов. Можно добавить ещё или загрузить остатки.'
            : 'Заведите товары с ценами и остатками — вручную или сканером штрихкодов.',
        icon: Icons.inventory_2_outlined,
        route: '/products',
        button: 'К товарам',
      ),
      (
        done: progress.shifts > 0,
        title: 'Откройте смену',
        text: shift != null
            ? 'Смена №${shift.number} открыта — можно продавать.'
            : 'Укажите сумму размена в кассе, чтобы вечером сверить наличные.',
        icon: Icons.schedule_outlined,
        route: '/shifts',
        button: 'Открыть смену',
      ),
      (
        done: progress.sales > 0,
        title: 'Сделайте первую продажу',
        text: 'Отсканируйте товар или выберите его в кассе и примите оплату.',
        icon: Icons.point_of_sale_outlined,
        route: '/pos',
        button: 'Перейти в кассу',
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
            Text('Добро пожаловать в DreamPOS!',
                textAlign: TextAlign.center, style: t.textTheme.headlineSmall),
            const SizedBox(height: Gap.s),
            Text(
              'Три шага — и здесь появятся выручка, прибыль, лучшие товары и подсказки.',
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
            Text('Выполнено ${progress.stepsDone} из 3',
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
    return onPressed == null ? Tooltip(message: 'Нет доступа к разделу', child: b) : b;
  }
}

// ------------------------------------------------------------------ main body

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.medium;
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

    return ListView(padding: const EdgeInsets.all(Gap.l), children: [
      kpis,
      const SizedBox(height: Gap.m),
      if (wide) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: chart),
          const SizedBox(width: Gap.m),
          Expanded(child: side),
        ]),
        const SizedBox(height: Gap.m),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: top),
          const SizedBox(width: Gap.m),
          Expanded(child: pays),
          const SizedBox(width: Gap.m),
          const Expanded(child: recent),
        ]),
      ] else ...[
        side,
        const SizedBox(height: Gap.m),
        chart,
        const SizedBox(height: Gap.m),
        top,
        const SizedBox(height: Gap.m),
        pays,
        const SizedBox(height: Gap.m),
        recent,
      ],
    ]);
  }
}

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
    final withCost = ref.watch(sessionProvider)?.can(Perm.viewCost) ?? false;
    final today = ref.watch(summaryProvider(_today(now)));
    final yest = ref.watch(summaryProvider(_yesterdaySoFar(now))).value;
    return AsyncView<SalesSummary>(
      value: today,
      data: (s) {
        String? y(int? v) => v == null ? null : 'вчера к этому часу: ${Money.format(v)}';
        return ResponsiveGrid(minTile: 160, maxColumns: 5, children: [
          KpiTile(
            key: const ValueKey('kpi-revenue'),
            label: 'Выручка сегодня',
            value: Money.format(s.net),
            icon: Icons.payments_outlined,
            current: s.net,
            previous: yest?.net,
            previousLabel: y(yest?.net),
            tooltip: 'Продажи минус возвраты (аннулированные чеки не учитываются)',
          ),
          KpiTile(
            label: 'Чеков',
            value: '${s.receipts}',
            icon: Icons.receipt_long_outlined,
            current: s.receipts,
            previous: yest?.receipts,
            previousLabel: yest == null ? null : 'вчера к этому часу: ${yest.receipts}',
          ),
          KpiTile(
            label: 'Средний чек',
            value: Money.format(s.avgCheck),
            icon: Icons.functions,
            current: s.avgCheck,
            previous: yest?.avgCheck,
            previousLabel: y(yest?.avgCheck),
          ),
          if (withCost)
            KpiTile(
              label: 'Валовая прибыль',
              value: Money.format(s.profit),
              icon: Icons.trending_up,
              color: AppColors.success,
              current: s.profit,
              previous: yest?.profit,
              previousLabel: s.net == 0
                  ? y(yest?.profit)
                  : 'маржа ${s.marginPct.toStringAsFixed(1).replaceAll('.', ',')}%',
            ),
          KpiTile(
            label: 'Возвраты',
            value: Money.format(s.returnsTotal),
            icon: Icons.assignment_return_outlined,
            color: AppColors.warning,
            current: s.returnsTotal,
            previous: yest?.returnsTotal,
            inverse: true,
            previousLabel: '${s.returnsCount} шт.'
                '${s.voids > 0 ? ' · аннулировано чеков: ${s.voids}' : ''}',
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
    final days = ref.watch(byDayProvider(p));
    final session = ref.watch(sessionProvider);
    return SectionCard(
      title: 'Выручка за 14 дней',
      trailing: TextButton(
        onPressed: _nav(context, session, '/reports'),
        child: const Text('Подробнее'),
      ),
      child: AsyncView<List<DayPoint>>(
        value: days,
        data: (list) {
          final total = list.fold<int>(0, (s, d) => s + d.net);
          final active = list.where((d) => d.receipts > 0).length;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              'Итого ${Money.format(total)} · в среднем ${Money.format(active == 0 ? 0 : total ~/ active)} в торговый день',
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
                    tooltip: '${weekdayShort[d.day.weekday - 1]}, ${formatDate(d.day)}\n'
                        'Выручка: ${Money.format(d.net)}\nЧеков: ${d.receipts}',
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
              title: const Text('Смена закрыта'),
              subtitle: const Text('Продажи невозможны, пока смена не открыта'),
              trailing: FilledButton.tonal(
                  onPressed: _nav(context, session, '/shifts'), child: const Text('Открыть')),
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
                      child: Text('Смена №${s.number} открыта',
                          style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                  StatusChip(long ? 'Долго открыта' : 'Идёт',
                      color: long ? AppColors.warning : AppColors.success),
                ]),
                const SizedBox(height: Gap.s),
                Text(
                  'С ${formatTime(s.openedAt)}'
                  '${dayKey(s.openedAt) != dayKey(now) ? ' (${formatDate(s.openedAt)})' : ''}'
                  ' · ${dur.inHours} ч ${dur.inMinutes % 60} мин'
                  '${totals?.cashier == null ? '' : ' · ${totals!.cashier}'}',
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
                if (totals != null) ...[
                  const SizedBox(height: Gap.s),
                  Text('Чеков: ${totals.receipts} · выручка ${Money.format(totals.revenue)}'),
                ],
                if (long) ...[
                  const SizedBox(height: Gap.s),
                  Text('Смена открыта больше 16 часов — закройте её и сверьте кассу.',
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
    final session = ref.watch(sessionProvider);
    final stock = ref.watch(stockAlertsProvider).value;
    final debt = ref.watch(debtTotalProvider).value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _AlertTile(
        key: const ValueKey('alert-stock'),
        icon: Icons.inventory_outlined,
        color: (stock?.total ?? 0) > 0 ? AppColors.danger : AppColors.success,
        title: stock == null
            ? 'Остатки…'
            : stock.total == 0
                ? 'Остатков достаточно'
                : 'Заканчиваются: ${stock.low} · нет в наличии: ${stock.out}',
        subtitle: 'Товары с остатком ниже минимального',
        onTap: _nav(context, session, '/inventory'),
      ),
      const SizedBox(height: Gap.m),
      _AlertTile(
        key: const ValueKey('alert-debt'),
        icon: Icons.account_balance_wallet_outlined,
        color: (debt?.total ?? 0) > 0 ? AppColors.warning : AppColors.success,
        title: debt == null
            ? 'Долги…'
            : debt.total == 0
                ? 'Долгов нет'
                : 'Долг клиентов: ${Money.format(debt.total)}',
        subtitle: debt == null || debt.total == 0 ? 'Все клиенты рассчитались' : 'Должников: ${debt.customers}',
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
            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(subtitle),
            trailing: onTap == null ? null : const Icon(Icons.chevron_right),
          ),
        );
    return onTap == null ? Tooltip(message: 'Нет доступа к разделу', child: card) : card;
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
    final rows = ref.watch(byProductProvider(p));
    return SectionCard(
      title: 'Топ-5 товаров',
      trailing: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: false, label: Text('Сегодня')),
          ButtonSegment(value: true, label: Text('7 дн.')),
        ],
        selected: {_week},
        onSelectionChanged: (s) => setState(() => _week = s.first),
      ),
      child: AsyncView<List<ProductRow>>(
        value: rows,
        data: (list) {
          final top = list.where((r) => r.revenue > 0).take(5).toList();
          if (top.isEmpty) {
            return const _Muted('Продаж пока нет');
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
    final rows = ref.watch(paymentsProvider(_today(now)));
    return SectionCard(
      title: 'Оплаты сегодня',
      child: AsyncView<List<PaymentRow>>(
        value: rows,
        data: (list) {
          final items = list.where((r) => r.net != 0).toList();
          final total = items.fold<int>(0, (s, r) => s + r.net);
          if (items.isEmpty) return const _Muted('Оплат сегодня ещё не было');
          return ShareBars(items: [
            for (final r in items)
              ShareItem(paymentMethodLabel(r.method), r.net,
                  trailing:
                      '${Money.format(r.net)} · ${total == 0 ? 0 : (r.net * 100 / total).round()}%',
                  color: _methodColor(r.method)),
          ]);
        },
      ),
    );
  }

  Color? _methodColor(String m) => switch (m) {
        'cash' => AppColors.success,
        'card' => AppColors.info,
        'transfer' => AppColors.brand,
        'debt' => AppColors.warning,
        _ => null,
      };
}

class _RecentReceipts extends ConsumerWidget {
  const _RecentReceipts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final rows = ref.watch(recentSalesProvider);
    final t = Theme.of(context);
    return SectionCard(
      title: 'Последние чеки',
      trailing: TextButton(onPressed: _nav(context, session, '/sales'), child: const Text('Все')),
      child: AsyncView<List<RecentSale>>(
        value: rows,
        data: (list) {
          if (list.isEmpty) return const _Muted('Чеков пока нет');
          return Column(children: [
            for (final r in list)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: _nav(context, session, '/sales'),
                title: Text('Чек №${r.sale.number}',
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
                    if (_statusLabel(r.sale.status) case final st?)
                      Text(st.$1, style: TextStyle(fontSize: 11, color: st.$2)),
                  ],
                ),
              ),
          ]);
        },
      ),
    );
  }

  (String, Color)? _statusLabel(String s) => switch (s) {
        'voided' => ('аннулирован', AppColors.danger),
        'returned' => ('возврат', AppColors.warning),
        'partially_returned' => ('частичный возврат', AppColors.warning),
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
