import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import 'report_providers.dart';
import 'tabs/forecast_tab.dart';
import 'tabs/insights_tab.dart';
import 'tabs/products_tab.dart';
import 'tabs/sales_tab.dart';
import 'tabs/staff_payments_tabs.dart';
import 'tabs/stock_tab.dart';
import 'widgets/period_picker.dart';

/// Отчёты: продажи, товары (ABC), сотрудники, оплаты, склад,
/// прогноз спроса и правило-ориентированная «AI-аналитика».
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportTab {
  const _ReportTab(this.label, this.icon, this.usesPeriod, this.builder);
  final String label;
  final IconData icon;
  final bool usesPeriod;
  final Widget Function() builder;
}

final _tabs = <_ReportTab>[
  _ReportTab('Продажи', Icons.show_chart, true, () => const SalesTab()),
  _ReportTab('Товары', Icons.inventory_2_outlined, true, () => const ProductsTab()),
  _ReportTab('Сотрудники', Icons.badge_outlined, true, () => const StaffTab()),
  _ReportTab('Оплаты', Icons.payments_outlined, true, () => const PaymentsTab()),
  _ReportTab('Склад', Icons.warehouse_outlined, true, () => const StockTab()),
  _ReportTab('Прогноз спроса', Icons.timeline, false, () => const ForecastTab()),
  _ReportTab('AI-аналитика', Icons.auto_awesome_outlined, false, () => const InsightsTab()),
];

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tc = TabController(length: _tabs.length, vsync: this)
    ..addListener(() {
      if (!_tc.indexIsChanging && mounted) setState(() {});
    });

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final tab = _tabs[_tc.index];
    // keep the app-bar subtitle on one line on phones
    final compact = MediaQuery.sizeOf(context).width < 600;
    return PageScaffold(
      title: 'Отчёты',
      subtitle: tab.usesPeriod
          ? (compact ? period.rangeLabel : period.label)
          : tab.label == 'Прогноз спроса'
              ? 'По продажам за последние 28 дней'
              : 'Последние 30 дней',
      padding: EdgeInsets.zero,
      actions: [if (tab.usesPeriod) const PeriodButton()],
      bottom: TabBar(
        controller: _tc,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          for (final t in _tabs) Tab(height: 44, icon: null, child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(t.icon, size: 18),
                const SizedBox(width: 6),
                Text(t.label),
              ])),
        ],
      ),
      body: TabBarView(
        controller: _tc,
        children: [for (final t in _tabs) t.builder()],
      ),
    );
  }
}
