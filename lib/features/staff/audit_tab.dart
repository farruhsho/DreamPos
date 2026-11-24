import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'staff_logic.dart';
import 'staff_widgets.dart';
import 'staff_providers.dart';

class AuditTab extends ConsumerStatefulWidget {
  const AuditTab({super.key});

  @override
  ConsumerState<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends ConsumerState<AuditTab> {
  String? _userId;
  String? _group;
  late DateTimeRange _range = _defaultRange();

  static DateTimeRange _defaultRange() {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
  }

  AuditFilter get _filter => AuditFilter(
    userId: _userId,
    group: _group,
    from: _range.start,
    to: DateTime(_range.end.year, _range.end.month, _range.end.day + 1),
  );

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = context.l10n;
    final users = ref.watch(staffUsersProvider).value ?? const <User>[];
    final byId = {for (final u in users) u.id: u};
    final entries = ref.watch(auditProvider(_filter));

    final rangeButton = OutlinedButton.icon(
      onPressed: _pickRange,
      icon: const Icon(Icons.date_range),
      label: Text('${formatDate(_range.start)} — ${formatDate(_range.end)}'),
    );
    final pickers = [
      DropdownButtonFormField<String?>(
        isExpanded: true,
        initialValue: _userId,
        decoration: InputDecoration(labelText: l.commonEmployee),
        items: [
          DropdownMenuItem(value: null, child: Text(l.commonAll)),
          for (final u in users)
            DropdownMenuItem(
              value: u.id,
              child: Text(u.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) => setState(() => _userId = v),
      ),
      DropdownButtonFormField<String?>(
        isExpanded: true,
        initialValue: _group,
        decoration: InputDecoration(labelText: l.staffActionLabel),
        items: [
          DropdownMenuItem(value: null, child: Text(l.staffAllActions)),
          for (final e in auditGroupsOf(l).entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) => setState(() => _group = v),
      ),
    ];
    // Phone: full-width period, then both pickers side by side (was three
    // ragged rows of 220px fields).
    final filters = LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rangeButton,
              const SizedBox(height: Gap.s),
              Row(
                children: [
                  Expanded(child: pickers[0]),
                  const SizedBox(width: Gap.s),
                  Expanded(child: pickers[1]),
                ],
              ),
            ],
          );
        }
        return Wrap(
          spacing: Gap.m,
          runSpacing: Gap.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            rangeButton,
            for (final p in pickers) ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: p),
          ],
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filters,
        const SizedBox(height: Gap.m),
        Expanded(
          child: AsyncView(
            value: entries,
            onRetry: () => ref.invalidate(auditProvider(_filter)),
            data: (list) {
              if (list.isEmpty) {
                return FillScroll(
                  child: EmptyState(
                    icon: Icons.manage_search,
                    title: l.staffNoRecords,
                    message: l.staffNoRecordsHint,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (list.length >= auditLimit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.s),
                      child: Text(
                        l.staffAuditLimit('$auditLimit'),
                        style: t.textTheme.bodySmall?.copyWith(color: AppColors.warning),
                      ),
                    ),
                  Flexible(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final a = list[i];
                          // Phones: the date moves into the subtitle so the
                          // details get the full row width.
                          final compact = MediaQuery.sizeOf(context).width < 600;
                          final warn = auditIsWarning(a.action);
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              warn ? Icons.warning_amber_rounded : _auditIcon(a.action),
                              color: warn ? AppColors.warning : t.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(auditLabel(a.action, l)),
                            subtitle: Text(
                              [
                                if (compact) formatDateTime(a.at),
                                a.userId == null ? l.staffSystem : (byId[a.userId]?.name ?? '—'),
                                if ((a.details ?? '').isNotEmpty) auditDetailsText(a.action, a.details, l),
                              ].join(' · '),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: compact
                                ? null
                                : Text(
                                    formatDateTime(a.at),
                                    style: t.textTheme.bodySmall?.copyWith(
                                      color: t.colorScheme.onSurfaceVariant,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Per-group icon so the journal can be scanned by kind of action.
IconData _auditIcon(String action) {
  final group = action.split('.').first;
  return switch (group) {
    'auth' => Icons.login,
    'sale' => switch (action) {
      'sale.return' => Icons.assignment_return_outlined,
      'sale.discount' => Icons.percent,
      _ => Icons.receipt_long_outlined,
    },
    'pos' => Icons.point_of_sale_outlined,
    'discount' => Icons.percent,
    'shift' => Icons.schedule,
    'cash' => Icons.payments_outlined,
    'stock' || 'inventory' => Icons.inventory_2_outlined,
    'user' => Icons.person_outline,
    'time' => Icons.more_time,
    'product' => Icons.sell_outlined,
    'debt' => Icons.account_balance_wallet_outlined,
    'bonus' => Icons.card_giftcard_outlined,
    'customer' => Icons.people_outline,
    'supplier' || 'po' => Icons.local_shipping_outlined,
    'promotion' => Icons.campaign_outlined,
    'settings' => Icons.settings_outlined,
    'backup' => Icons.backup_outlined,
    _ => Icons.history,
  };
}
