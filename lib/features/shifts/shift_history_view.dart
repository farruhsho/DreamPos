import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/doc_number.dart';
import '../../core/money.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'shift_logic.dart';
import 'shift_providers.dart';
import 'shift_widgets.dart';
import 'z_report.dart';

class ShiftHistoryView extends ConsumerStatefulWidget {
  const ShiftHistoryView({super.key});

  @override
  ConsumerState<ShiftHistoryView> createState() => _ShiftHistoryViewState();
}

class _ShiftHistoryViewState extends ConsumerState<ShiftHistoryView> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final rows = ref.watch(shiftHistoryProvider);
    final users = ref.watch(shiftUsersProvider).value ?? const <String, User>{};
    final all = ref.watch(sessionProvider)?.can(Perm.viewAllShifts) ?? false;
    final period = ref.watch(historyPeriodProvider);

    final filters = Wrap(
      spacing: Gap.s,
      runSpacing: Gap.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (d, l) in [
          (7, loc.commonDaysCount(7)),
          (30, loc.commonDaysCount(30)),
          (90, loc.commonDaysCount(90)),
          (null, loc.commonAll),
        ])
          ChoiceChip(
            label: Text(l),
            selected: period == d,
            onSelected: (_) => ref.read(historyPeriodProvider.notifier).set(d),
          ),
        if (!all)
          Padding(
            padding: const EdgeInsets.only(left: Gap.s),
            child: StatusChip(loc.shiftOnlyMine, color: AppColors.info),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        // Master-detail from tablet width up (the report reads fine at ~380px).
        final wide = c.maxWidth >= 840;
        final list = AsyncView(
          value: rows,
          onRetry: () => ref.invalidate(shiftHistoryProvider),
          data: (items) {
            if (items.isEmpty) {
              return FillScroll(
                child: EmptyState(
                  icon: Icons.history,
                  title: loc.shiftHistoryEmptyTitle,
                  message: loc.shiftHistoryEmptyMessage,
                ),
              );
            }
            // Card hugs its rows instead of a tall empty panel under a short list.
            return Align(
              alignment: Alignment.topCenter,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) => _HistoryTile(
                    row: items[i],
                    users: users,
                    selected: wide && items[i].shift.id == _selected,
                    onTap: () {
                      if (wide) {
                        setState(() => _selected = items[i].shift.id);
                      } else {
                        showZReportDialog(context, items[i].shift.id);
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            filters,
            const SizedBox(height: Gap.m),
            Expanded(child: list),
          ],
        );
        if (!wide) return left;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: left),
            const SizedBox(width: Gap.m),
            Expanded(
              flex: 4,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.l),
                  child: _selected == null
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: loc.shiftPickShift,
                          message: loc.shiftPickShiftMessage,
                        )
                      : ZReportPanel(key: ValueKey(_selected), shiftId: _selected!),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.row, required this.users, required this.selected, required this.onTap});
  final ShiftHistoryRow row;
  final Map<String, User> users;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final s = row.shift;
    final open = s.status == 'open';
    final diff = row.difference;
    final diffColor = diff == null || diff == 0
        ? AppColors.success
        : diff < 0
        ? AppColors.danger
        : AppColors.warning;
    final who = [
      users[s.openedBy]?.name ?? '—',
      if (s.closedBy != null && s.closedBy != s.openedBy) users[s.closedBy]?.name ?? '—',
    ].join(' → ');
    final when = s.closedAt == null
        ? '${formatDateTime(s.openedAt)} — ${l.shiftNow}'
        : '${formatDateTime(s.openedAt)} — ${formatSameDayTime(s.openedAt, s.closedAt!)}';
    return ListTile(
      selected: selected,
      // Highlight the row, but keep text colours (a fully purple row reads like a link).
      selectedTileColor: t.colorScheme.secondaryContainer.withValues(alpha: 0.6),
      selectedColor: t.colorScheme.onSurface,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: (open ? AppColors.success : t.colorScheme.primary).withValues(alpha: 0.12),
        // «A-15» with sync on: shrink instead of overflowing the circle
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              docNo(s.number, s.deviceCode),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: open ? AppColors.success : t.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(l.shiftNumber(docNo(s.number, s.deviceCode)), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: Gap.s),
          if (open) StatusChip(l.shiftStatusOpen, color: AppColors.success),
        ],
      ),
      subtitle: Text('$when\n$who', maxLines: 3, overflow: TextOverflow.ellipsis),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Money.format(row.salesTotal), style: t.textTheme.titleSmall),
          Text(l.commonReceiptsCount(row.salesCount), style: t.textTheme.bodySmall),
          if (diff != null)
            Text(
              diff == 0 ? l.shiftNoDifference : '${diff < 0 ? '−' : '+'}${Money.format(diff.abs())}',
              style: t.textTheme.bodySmall?.copyWith(color: diffColor, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

/// "12:30" if same day as [a], otherwise full date-time.
String formatSameDayTime(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day ? formatTime(b) : formatDateTime(b);
