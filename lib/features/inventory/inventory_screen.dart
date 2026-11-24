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
import '../../l10n/l10n.dart';

/// Склад: остатки, приход, списание, инвентаризация, движения.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  static List<Tab> tabs(AppLocalizations l) => [
    Tab(icon: const Icon(Icons.inventory_2_outlined), text: l.invStockTab),
    Tab(icon: const Icon(Icons.move_to_inbox_outlined), text: l.invReceipt),
    Tab(icon: const Icon(Icons.delete_sweep_outlined), text: l.invWriteoff),
    Tab(icon: const Icon(Icons.fact_check_outlined), text: l.invCount),
    Tab(icon: const Icon(Icons.swap_vert), text: l.invMovements),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    if (session == null || !session.can(Perm.stockOps)) {
      return PageScaffold(
        title: l.navInventory,
        body: EmptyState(
          icon: Icons.lock_outline,
          title: l.invNoAccess,
          message: l.invNoAccessMessage,
        ),
      );
    }
    final tabList = tabs(l);
    return DefaultTabController(
      length: tabList.length,
      child: PageScaffold(
        title: l.navInventory,
        padding: EdgeInsets.all(context.isCompact ? Gap.m : Gap.l),
        bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: tabList),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [StockTab(), ReceiptTab(), WriteOffTab(), CountsTab(), MovementsTab()],
        ),
      ),
    );
  }
}
