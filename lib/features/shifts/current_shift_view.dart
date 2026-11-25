import '../../core/doc_number.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'cash_operation_dialog.dart';
import 'close_shift_dialog.dart';
import 'shift_logic.dart';
import 'shift_providers.dart';
import 'z_report.dart';

class CurrentShiftView extends ConsumerWidget {
  const CurrentShiftView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(currentShiftProvider);
    return AsyncView(
      value: shift,
      onRetry: () => ref.invalidate(currentShiftProvider),
      data: (s) => s == null ? const OpenShiftPanel() : OpenShiftDashboard(shift: s),
    );
  }
}

// ------------------------------------------------------------ open

class OpenShiftPanel extends ConsumerStatefulWidget {
  const OpenShiftPanel({super.key});

  @override
  ConsumerState<OpenShiftPanel> createState() => _OpenShiftPanelState();
}

class _OpenShiftPanelState extends ConsumerState<OpenShiftPanel> {
  final _form = GlobalKey<FormState>();
  final _ctl = TextEditingController();
  bool _prefilled = false;
  bool _busy = false;
  int? _value;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<int>>(openingSuggestionProvider, (_, next) {
      final v = next.value;
      if (_prefilled || v == null) return;
      _prefilled = true;
      if (_ctl.text.isEmpty) {
        _ctl.text = Money.toInput(v);
        _value = v;
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_busy || !_form.currentState!.validate()) return;
    final session = ref.read(sessionProvider);
    if (session == null || !session.can(Perm.openCloseShift)) return;
    setState(() => _busy = true);
    final amount = _value ?? Money.parse(_ctl.text) ?? 0;
    await runGuarded(
      context,
      // No register id: ShiftService scopes a null id to this register's
      // device code when sync is on (D-025).
      () => ref.read(shiftServiceProvider).open(userId: session.user.id, openingCash: amount),
      success: context.l10n.shiftOpenedToast(Money.format(amount)),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final suggestion = ref.watch(openingSuggestionProvider);
    final can = ref.watch(sessionProvider)?.can(Perm.openCloseShift) ?? false;
    final sug = suggestion.value;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(Gap.xl),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_open_rounded, size: 48, color: t.colorScheme.primary),
                    const SizedBox(height: Gap.m),
                    Text(l.shiftClosed, textAlign: TextAlign.center, style: t.textTheme.headlineSmall),
                    const SizedBox(height: Gap.s),
                    Text(
                      l.shiftOpenHint,
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: Gap.xl),
                    MoneyField(
                      key: const ValueKey('opening_cash'),
                      label: l.shiftOpeningCash,
                      controller: _ctl,
                      autofocus: true,
                      helper: sug != null && sug > 0
                          ? l.shiftOpeningSuggested
                          : l.shiftOpeningCashNow,
                      onChanged: (v) => _value = v,
                      onSubmitted: (_) => _open(),
                    ),
                    const SizedBox(height: Gap.xl),
                    Tooltip(
                      message: can ? '' : l.shiftNoRightOpen,
                      child: FilledButton.icon(
                        key: const ValueKey('open_shift'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                        onPressed: !can || _busy ? null : _open,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l.shiftOpenAction),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ open shift dashboard

class OpenShiftDashboard extends ConsumerWidget {
  const OpenShiftDashboard({super.key, required this.shift});
  final Shift shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final figs = ref.watch(shiftFiguresProvider(shift.id));
    final session = ref.watch(sessionProvider);
    final users = ref.watch(shiftUsersProvider).value ?? const <String, User>{};
    final settings = ref.watch(settingsProvider).value ?? const <String, String>{};
    final canCash = session?.can(Perm.cashInOut) ?? false;
    final canClose = session?.can(Perm.openCloseShift) ?? false;
    final profit = session?.can(Perm.viewCost) ?? false;

    return AsyncView(
      value: figs,
      onRetry: () => ref.invalidate(shiftFiguresProvider(shift.id)),
      data: (f) {
        final r = f.report;
        final header = _ShiftHeader(
          shift: shift,
          openedBy: users[shift.openedBy]?.name ?? '—',
          canClose: canClose,
          onClose: () => showCloseShiftDialog(context, shift.id),
        );
        final stats = LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 1100
                ? 4
                : c.maxWidth >= 520
                ? 2
                : 1;
            final w = (c.maxWidth - Gap.m * (cols - 1)) / cols;
            final cards = [
              StatCard(
                label: l.shiftSales,
                value: Money.format(r.salesTotal),
                hint: l.shiftSalesHint(l.commonReceiptsCount(r.salesCount), Money.format(f.averageCheck)),
                icon: Icons.shopping_cart_outlined,
              ),
              StatCard(
                label: l.shiftReturns,
                value: Money.format(r.returnsTotal),
                hint: r.returnsCount == 0 ? l.shiftNoReturns : l.commonReturnsCount(r.returnsCount),
                icon: Icons.undo,
                color: AppColors.warning,
              ),
              StatCard(
                label: profit ? l.shiftGrossProfit : l.shiftNetRevenue,
                value: Money.format(profit ? f.grossProfit : f.netRevenue),
                hint: profit ? l.shiftRevenueValue(Money.format(f.netRevenue)) : null,
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              StatCard(
                label: l.shiftExpectedInDrawer,
                value: Money.format(f.expectedCash),
                hint: l.shiftExpectedHint(Money.format(shift.openingCash)),
                icon: Icons.point_of_sale,
                color: AppColors.info,
              ),
            ];
            return Wrap(
              spacing: Gap.m,
              runSpacing: Gap.m,
              children: [for (final card in cards) SizedBox(width: w, child: card)],
            );
          },
        );
        final report = SectionCard(
          title: l.shiftXReport,
          trailing: PrintReportButton(shiftId: shift.id),
          child: ReportSectionsView(
            data: ZReportData(
              figures: f,
              settings: settings,
              openedByName: users[shift.openedBy]?.name ?? '—',
              showProfit: profit,
            ),
          ),
        );
        final cash = _CashPanel(shift: shift, figures: f, canCash: canCash, users: users);
        return LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 1000) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: Gap.m),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                stats,
                                const SizedBox(height: Gap.m),
                                report,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: Gap.m),
                        Expanded(flex: 2, child: SingleChildScrollView(child: cash)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView(
              children: [
                header,
                const SizedBox(height: Gap.m),
                stats,
                const SizedBox(height: Gap.m),
                cash,
                const SizedBox(height: Gap.m),
                report,
              ],
            );
          },
        );
      },
    );
  }
}

class _ShiftHeader extends StatefulWidget {
  const _ShiftHeader({required this.shift, required this.openedBy, required this.canClose, required this.onClose});
  final Shift shift;
  final String openedBy;
  final bool canClose;
  final VoidCallback onClose;

  @override
  State<_ShiftHeader> createState() => _ShiftHeaderState();
}

class _ShiftHeaderState extends State<_ShiftHeader> {
  /// Refreshes the running duration once a minute.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final openedBy = widget.openedBy;
    final canClose = widget.canClose;
    final onClose = widget.onClose;
    final t = Theme.of(context);
    final l = context.l10n;
    final dur = DateTime.now().difference(shift.openedAt);
    final h = dur.inHours, m = dur.inMinutes % 60;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l.shiftNumber(docNo(shift.number, shift.deviceCode)), style: t.textTheme.titleLarge),
            StatusChip(l.shiftStatusOpen, color: AppColors.success),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${l.shiftOpenedAt(formatDateTime(shift.openedAt))} · $openedBy · '
          '${dur.inMinutes < 1 ? l.shiftJustNow : l.shiftRunning(h > 0 ? l.shiftHoursMinutes('$h', '$m') : l.shiftMinutes('$m'))}',
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
      ],
    );
    final btn = Tooltip(
      message: canClose ? l.shiftCloseTooltip : l.shiftNoRightClose,
      child: FilledButton.icon(
        key: const ValueKey('close_shift'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
        onPressed: canClose ? onClose : null,
        icon: const Icon(Icons.lock_clock),
        label: Text(l.shiftCloseAction),
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: LayoutBuilder(
          builder: (context, c) => c.maxWidth < 520
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: Gap.m),
                    btn,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: info),
                    btn,
                  ],
                ),
        ),
      ),
    );
  }
}

class _CashPanel extends ConsumerWidget {
  const _CashPanel({required this.shift, required this.figures, required this.canCash, required this.users});
  final Shift shift;
  final ShiftFigures figures;
  final bool canCash;
  final Map<String, User> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moves = ref.watch(shiftMovementsProvider(shift.id));
    final t = Theme.of(context);
    final l = context.l10n;
    return SectionCard(
      title: l.shiftCashOperations,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - Gap.s) / 2;
              return Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  for (final k in cashKinds)
                    SizedBox(
                      width: w,
                      child: Tooltip(
                        message: canCash ? cashKindHint(k, l) : l.shiftNoRightCash,
                        child: OutlinedButton.icon(
                          key: ValueKey('cash_$k'),
                          style: OutlinedButton.styleFrom(foregroundColor: cashKindColor(k)),
                          onPressed: canCash
                              ? () => showCashOperationDialog(
                                  context,
                                  shiftId: shift.id,
                                  kind: k,
                                  cashInDrawer: figures.expectedCash,
                                )
                              : null,
                          icon: Icon(cashKindIcon(k)),
                          label: Text(cashKindLabel(k, l), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: Gap.l),
          Text(l.shiftOperationsList, style: t.textTheme.labelLarge),
          const SizedBox(height: Gap.s),
          AsyncView(
            value: moves,
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: Gap.l),
                    child: Text(
                      l.shiftNoOperations,
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                  )
                : Column(
                    children: [
                      for (final m in list)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: cashKindColor(m.kind).withValues(alpha: 0.12),
                            child: Icon(cashKindIcon(m.kind), size: 18, color: cashKindColor(m.kind)),
                          ),
                          title: Text(
                            [
                              cashKindLabel(m.kind, l),
                              if (m.expenseCategory != null) expenseCategoryLabel(m.expenseCategory!, l),
                            ].join(' · '),
                          ),
                          subtitle: Text(
                            [
                              formatTime(m.createdAt),
                              users[m.userId]?.name ?? '',
                              if ((m.reason ?? '').isNotEmpty && m.reason != m.expenseCategory) m.reason!,
                            ].where((s) => s.isNotEmpty).join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '${cashKindIsIn(m.kind) ? '+' : '−'}${Money.format(m.amount)}',
                            style: t.textTheme.titleSmall?.copyWith(
                              color: cashKindIsIn(m.kind) ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
