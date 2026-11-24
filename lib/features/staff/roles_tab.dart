import 'package:flutter/material.dart';

import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'staff_logic.dart';
import 'user_form_dialog.dart';

/// Read-only roles x permissions matrix.
class RolesTab extends StatelessWidget {
  const RolesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ListView(
      children: [
        Text(
          'Права ролей заданы системой. Чтобы изменить доступ сотрудника, смените его роль.',
          style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: Gap.m),
        if (MediaQuery.sizeOf(context).width < 600)
          // Phone: a 6-column matrix only shows one role at a time, so list
          // each permission with the roles that have it.
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, p) in Perm.values.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(permLabel(p), style: t.textTheme.bodyMedium),
                        const SizedBox(height: Gap.xs),
                        Wrap(
                          spacing: Gap.xs,
                          runSpacing: Gap.xs,
                          children: [
                            for (final r in Role.values)
                              if (r.can(p)) StatusChip(r.label, color: roleColor(r)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          // Shrink-wrap the matrix: a full-width card around a ~850px table
          // left a large empty panel on desktop.
          Align(
            alignment: Alignment.topLeft,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 48,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 40,
                  columnSpacing: Gap.xl,
                  columns: [
                    const DataColumn(label: Text('Право')),
                    for (final r in Role.values) DataColumn(label: StatusChip(r.label, color: roleColor(r))),
                  ],
                  rows: [
                    for (final p in Perm.values)
                      DataRow(
                        cells: [
                          DataCell(Text(permLabel(p))),
                          for (final r in Role.values)
                            DataCell(
                              Center(
                                child: r.can(p)
                                    ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                                    : Icon(Icons.remove, color: t.colorScheme.outlineVariant, size: 18),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
