import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../data/period.dart';
import '../report_providers.dart';

/// Button showing the current period; opens a menu of presets and a
/// date-range picker for "Произвольный".
class PeriodButton extends ConsumerWidget {
  const PeriodButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return MenuAnchor(
      builder: (context, ctl, _) => compact
          ? IconButton(
              key: const ValueKey('period-button'),
              tooltip: 'Период: ${period.label}',
              icon: const Icon(Icons.date_range),
              onPressed: () => ctl.isOpen ? ctl.close() : ctl.open(),
            )
          : OutlinedButton.icon(
              key: const ValueKey('period-button'),
              onPressed: () => ctl.isOpen ? ctl.close() : ctl.open(),
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(period.label),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
      menuChildren: [
        for (final p in PeriodPreset.values)
          MenuItemButton(
            leadingIcon: Icon(
              period.preset == p ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
            ),
            onPressed: () async {
              if (p == PeriodPreset.custom) {
                await pickCustomPeriod(context, ref);
              } else {
                ref.read(reportPeriodProvider.notifier).preset(p);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: Gap.l),
              child: Text(p == PeriodPreset.custom ? 'Произвольный…' : p.label),
            ),
          ),
      ],
    );
  }
}

Future<void> pickCustomPeriod(BuildContext context, WidgetRef ref) async {
  final cur = ref.read(reportPeriodProvider);
  final now = DateTime.now();
  final last = cur.end.subtract(const Duration(seconds: 1));
  final r = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2015),
    lastDate: DateTime(now.year, now.month, now.day),
    initialDateRange: DateTimeRange(
      start: cur.start.isAfter(now) ? now : cur.start,
      end: last.isAfter(now) ? now : last,
    ),
    helpText: 'Выберите период',
    saveText: 'Применить',
    cancelText: 'Отмена',
    confirmText: 'Применить',
    fieldStartLabelText: 'С',
    fieldEndLabelText: 'По',
  );
  if (r != null) ref.read(reportPeriodProvider.notifier).set(ReportPeriod.days(r.start, r.end));
}
