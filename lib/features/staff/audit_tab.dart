import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
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
    final users = ref.watch(staffUsersProvider).value ?? const <User>[];
    final byId = {for (final u in users) u.id: u};
    final entries = ref.watch(auditProvider(_filter));

    final filters = Wrap(
      spacing: Gap.m,
      runSpacing: Gap.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _pickRange,
          icon: const Icon(Icons.date_range),
          label: Text('${formatDate(_range.start)} — ${formatDate(_range.end)}'),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _userId,
            decoration: const InputDecoration(labelText: 'Сотрудник'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Все')),
              for (final u in users)
                DropdownMenuItem(
                  value: u.id,
                  child: Text(u.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _userId = v),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _group,
            decoration: const InputDecoration(labelText: 'Действие'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Все действия')),
              for (final e in auditGroups.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _group = v),
          ),
        ),
      ],
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
                return const FillScroll(
                  child: EmptyState(
                    icon: Icons.manage_search,
                    title: 'Записей не найдено',
                    message: 'Измените период или фильтры',
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
                        'Показаны последние $auditLimit записей — уточните фильтр',
                        style: t.textTheme.bodySmall?.copyWith(color: AppColors.warning),
                      ),
                    ),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final a = list[i];
                          final warn = auditIsWarning(a.action);
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              warn ? Icons.warning_amber_rounded : Icons.history,
                              color: warn ? AppColors.warning : t.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(auditLabel(a.action)),
                            subtitle: Text(
                              [
                                a.userId == null ? 'система' : (byId[a.userId]?.name ?? '—'),
                                if ((a.details ?? '').isNotEmpty) a.details!,
                              ].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(formatDateTime(a.at), style: t.textTheme.bodySmall),
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
