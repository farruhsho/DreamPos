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
        Card(
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
      ],
    );
  }
}
