import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'counts_tab.dart';
import 'movements_tab.dart';
import 'receipt_tab.dart';
import 'stock_tab.dart';
import 'writeoff_tab.dart';

/// Склад: остатки, приход, списание, инвентаризация, движения.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  static const tabs = [
    Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Остатки'),
    Tab(icon: Icon(Icons.move_to_inbox_outlined), text: 'Приход'),
    Tab(icon: Icon(Icons.delete_sweep_outlined), text: 'Списание'),
    Tab(icon: Icon(Icons.fact_check_outlined), text: 'Инвентаризация'),
    Tab(icon: Icon(Icons.swap_vert), text: 'Движения'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.can(Perm.stockOps)) {
      return const PageScaffold(
        title: 'Склад',
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Нет доступа',
          message: 'Складские операции доступны кладовщику, менеджеру и владельцу',
        ),
      );
    }
    return DefaultTabController(
      length: tabs.length,
      child: PageScaffold(
        title: 'Склад',
        padding: EdgeInsets.all(context.isCompact ? Gap.m : Gap.l),
        bottom: const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: tabs),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [StockTab(), ReceiptTab(), WriteOffTab(), CountsTab(), MovementsTab()],
        ),
      ),
    );
  }
}
