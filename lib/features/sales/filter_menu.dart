import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'sales_logic.dart';

class _Opt<T> {
  const _Opt(this.value);
  final T? value;
}

/// Compact dropdown "chip" used in filter bars: «Статус: Все ▾».
class FilterMenu<T> extends StatelessWidget {
  const FilterMenu({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.icon,
    this.valueLabel,
  });

  final String label;
  final T? value;

  /// (value, title); a null value means "all".
  final List<(T?, String)> options;
  final ValueChanged<T?> onSelected;
  final IconData? icon;

  /// Overrides the shown value text.
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final current = valueLabel ?? options.firstWhere((o) => o.$1 == value, orElse: () => (null, options.first.$2)).$2;
    final active = value != null;
    return PopupMenuButton<_Opt<T>>(
      tooltip: label,
      onSelected: (o) => onSelected(o.value),
      itemBuilder: (_) => [
        for (final o in options)
          CheckedPopupMenuItem<_Opt<T>>(value: _Opt(o.$1), checked: o.$1 == value, child: Text(o.$2)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 9),
        decoration: BoxDecoration(
          color: active ? t.colorScheme.secondaryContainer : t.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? t.colorScheme.secondary : t.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
            Text('$label: ', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            Text(current, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Period selector with a custom date range option.
class PeriodMenu extends StatelessWidget {
  const PeriodMenu({super.key, required this.period, required this.custom, required this.onChanged});
  final Period period;
  final DateSpan? custom;
  final void Function(Period, DateSpan?) onChanged;

  @override
  Widget build(BuildContext context) => FilterMenu<Period>(
    label: 'Период',
    icon: Icons.calendar_today_outlined,
    value: period,
    valueLabel: periodTitle(period, custom),
    options: [for (final p in Period.values) (p, p.label)],
    onSelected: (p) async {
      if (p == null) return;
      if (p != Period.custom) return onChanged(p, null);
      final now = DateTime.now();
      final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year, now.month, now.day),
        initialDateRange: custom?.from == null
            ? null
            : DateTimeRange(start: custom!.from!, end: custom!.to!.subtract(const Duration(days: 1))),
        helpText: 'Выберите период',
        saveText: 'Готово',
      );
      if (r == null) return;
      onChanged(
        Period.custom,
        DateSpan(
          DateTime(r.start.year, r.start.month, r.start.day),
          DateTime(r.end.year, r.end.month, r.end.day).add(const Duration(days: 1)),
        ),
      );
    },
  );
}
