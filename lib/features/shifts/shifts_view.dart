import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'current_shift_view.dart';
import 'shift_history_view.dart';

/// The shifts page itself (no direct PDF dependency).
class ShiftsView extends ConsumerWidget {
  const ShiftsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(currentShiftProvider).value;
    return DefaultTabController(
      length: 2,
      child: PageScaffold(
        title: 'Смена',
        subtitle: shift == null ? 'Смена закрыта' : 'Смена №${shift.number} открыта',
        padding: EdgeInsets.zero,
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: Icon(Icons.point_of_sale_outlined), text: 'Текущая смена'),
            Tab(icon: Icon(Icons.history), text: 'История смен'),
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
