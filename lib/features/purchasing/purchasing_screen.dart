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

/// Закупки: поставщики, заказы, автозаказ, контроль закупочных цен.
class PurchasingScreen extends ConsumerWidget {
  const PurchasingScreen({super.key});

  static const tabs = [
    Tab(icon: Icon(Icons.storefront_outlined), text: 'Поставщики'),
    Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Заказы'),
    Tab(icon: Icon(Icons.auto_mode_outlined), text: 'Автозаказ'),
    Tab(icon: Icon(Icons.price_change_outlined), text: 'Закупочные цены'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.can(Perm.purchasing)) {
      return const PageScaffold(
        title: 'Закупки',
        body: EmptyState(
            icon: Icons.lock_outline,
            title: 'Нет доступа',
            message: 'Закупки доступны кладовщику, менеджеру и владельцу'),
      );
    }
    return DefaultTabController(
      length: tabs.length,
      child: PageScaffold(
        title: 'Закупки',
        padding: EdgeInsets.all(context.isCompact ? Gap.m : Gap.l),
        bottom: const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: tabs),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [SuppliersTab(), OrdersTab(), ReorderTab(), PriceControlTab()],
        ),
      ),
    );
  }
}
