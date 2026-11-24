import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'orders_tab.dart';
import 'price_tab.dart';
import 'reorder_tab.dart';
import 'suppliers_tab.dart';
import '../../l10n/l10n.dart';

/// Закупки: поставщики, заказы, автозаказ, контроль закупочных цен.
class PurchasingScreen extends ConsumerWidget {
  const PurchasingScreen({super.key});

  static List<Tab> tabsOf(AppLocalizations l) => [
    Tab(icon: const Icon(Icons.storefront_outlined), text: l.purTabSuppliers),
    Tab(icon: const Icon(Icons.receipt_long_outlined), text: l.purTabOrders),
    Tab(icon: const Icon(Icons.auto_mode_outlined), text: l.purTabReorder),
    Tab(icon: const Icon(Icons.price_change_outlined), text: l.purTabPrices),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    if (session == null || !session.can(Perm.purchasing)) {
      return PageScaffold(
        title: l.purTitle,
        body: EmptyState(
          icon: Icons.lock_outline,
          title: l.purNoAccess,
          message: l.purNoAccessMessage,
        ),
      );
    }
    final tabs = tabsOf(l);
    return DefaultTabController(
      length: tabs.length,
      child: PageScaffold(
        title: l.purTitle,
        padding: EdgeInsets.all(context.isCompact ? Gap.m : Gap.l),
        bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: tabs),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [SuppliersTab(), OrdersTab(), ReorderTab(), PriceControlTab()],
        ),
      ),
    );
  }
}
