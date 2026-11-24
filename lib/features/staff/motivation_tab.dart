import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'staff_logic.dart';
import 'staff_providers.dart';
import 'staff_widgets.dart';
import 'user_form_dialog.dart';

const _months = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

String monthTitle(DateTime m) => '${_months[m.month - 1]} ${m.year}';

class MotivationTab extends ConsumerStatefulWidget {
  const MotivationTab({super.key});

  @override
  ConsumerState<MotivationTab> createState() => _MotivationTabState();
}

class _MotivationTabState extends ConsumerState<MotivationTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrent {
    final n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(motivationProvider(_month));
    final t = Theme.of(context);
    final nav = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Предыдущий месяц',
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(monthTitle(_month), style: t.textTheme.titleMedium),
        IconButton(
          tooltip: 'Следующий месяц',
          onPressed: _isCurrent ? null : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
          icon: const Icon(Icons.chevron_right),
        ),
        if (!_isCurrent)
          TextButton(
            onPressed: () => setState(() => _month = DateTime(DateTime.now().year, DateTime.now().month)),
            child: const Text('Текущий'),
          ),
      ],
    );
    final header = Wrap(
      spacing: Gap.l,
      runSpacing: Gap.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        nav,
        Text(
          'Выручка продавца без аннулированных чеков, за вычетом возвратов, сделанных в этом месяце',
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: Gap.s),
        Expanded(
          child: AsyncView(
            value: rows,
            onRetry: () => ref.invalidate(motivationProvider(_month)),
            data: (list) {
              if (list.isEmpty) {
                return const FillScroll(
                  child: EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'Нет продавцов',
                    message: 'Задайте сотрудникам план продаж и комиссию в карточке сотрудника',
                  ),
                );
              }
              final total = list.fold(0, (s, r) => s + r.netRevenue);
              final commission = list.fold(0, (s, r) => s + r.commission);
              final plan = list.fold(0, (s, r) => s + r.plan);
              return ListView(
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      // Full-width cards on phones instead of a ragged 260px column.
                      final w = c.maxWidth < 600 ? c.maxWidth : 260.0;
                      return Wrap(
                        spacing: Gap.m,
                        runSpacing: Gap.m,
                        children: [
                          SizedBox(
                            width: w,
                            child: StatCard(
                              label: 'Чистая выручка',
                              value: Money.format(total),
                              icon: Icons.payments_outlined,
                              hint: plan > 0 ? 'План ${Money.format(plan)}' : null,
                            ),
                          ),
                          SizedBox(
                            width: w,
                            child: StatCard(
                              label: 'Комиссия к выплате',
                              value: Money.format(commission),
                              icon: Icons.savings_outlined,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: Gap.m),
                  for (final (i, r) in list.indexed) ...[
                    _MotivationCard(rank: i + 1, row: r),
                    const SizedBox(height: Gap.s),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.rank, required this.row});
  final int rank;
  final MotivationRow row;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = row.completion;
    final color = c == null
        ? t.colorScheme.primary
        : c >= 1
        ? AppColors.success
        : c >= 0.7
        ? AppColors.info
        : AppColors.warning;
    final medal = switch (rank) {
      1 => const Color(0xFFD4A017),
      2 => const Color(0xFF9CA3AF),
      3 => const Color(0xFFB87333),
      _ => t.colorScheme.outline,
    };
    final role = Role.parse(row.user.role);
    final pct = NumberFormat('#0.#', 'ru');
    // Fixed-width columns so the same metric lines up across all employees
    // (a free Wrap put "Чеков" at a different x in every card).
    final metrics = LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth < 420 ? 2 : (box.maxWidth < 760 ? 3 : 5);
        final w = cols == 5 ? 170.0 : (box.maxWidth - Gap.l * (cols - 1)) / cols;
        return Wrap(
          spacing: Gap.l,
          runSpacing: Gap.s,
          children: [
            for (final (k, v) in [
              ('Выручка', Money.format(row.netRevenue)),
              ('Возвраты', row.refunds > 0 ? '−${Money.format(row.refunds)}' : '—'),
              ('Чеков', '${row.receipts}'),
              ('Средний чек', row.receipts > 0 ? Money.format(row.averageCheck) : '—'),
              ('Комиссия ${pct.format(row.user.commissionPercent)}%', Money.format(row.commission)),
            ])
              SizedBox(width: w, child: _metric(context, k, v)),
          ],
        );
      },
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: medal.withValues(alpha: 0.18),
                  child: Text(
                    '$rank',
                    style: TextStyle(color: medal, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: Wrap(
                    spacing: Gap.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(row.user.name, style: t.textTheme.titleMedium),
                      StatusChip(role.label, color: roleColor(role)),
                    ],
                  ),
                ),
                if (c == null)
                  // No plan is a neutral fact, not a call to action.
                  Text(
                    planText(row.plan),
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  )
                else
                  Text(
                    '${(c * 100).toStringAsFixed(0)}%',
                    style: t.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            if (c != null) ...[
              const SizedBox(height: Gap.s),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: c.clamp(0, 1).toDouble(),
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: Gap.xs),
              Text(
                '${Money.format(row.netRevenue)} из ${Money.format(row.plan)}'
                '${c < 1 ? ' · осталось ${Money.format(row.plan - row.netRevenue)}' : ' · план выполнен'}',
                style: t.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: Gap.s),
            metrics,
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String k, String v) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(k, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          v,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }
}
