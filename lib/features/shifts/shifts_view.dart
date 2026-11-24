import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'current_shift_view.dart';
import 'shift_history_view.dart';

/// The shifts page itself (no direct PDF dependency).
class ShiftsView extends ConsumerWidget {
  const ShiftsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final shift = ref.watch(currentShiftProvider).value;
    return DefaultTabController(
      length: 2,
      child: PageScaffold(
        title: l.commonShift,
        subtitle: shift == null ? l.shiftClosed : l.shiftNumberOpen('${shift.number}'),
        padding: EdgeInsets.zero,
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: const Icon(Icons.point_of_sale_outlined), text: l.shiftTabCurrent),
            Tab(icon: const Icon(Icons.history), text: l.shiftTabHistory),
          ],
        ),
        body: const TabBarView(
          children: [
            Padding(padding: EdgeInsets.all(Gap.l), child: CurrentShiftView()),
            Padding(padding: EdgeInsets.all(Gap.l), child: ShiftHistoryView()),
          ],
        ),
      ),
    );
  }
}
