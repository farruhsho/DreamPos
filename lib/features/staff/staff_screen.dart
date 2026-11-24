import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'audit_tab.dart';
import 'motivation_tab.dart';
import 'roles_tab.dart';
import 'time_tab.dart';
import 'users_tab.dart';

/// Staff: users, time tracking, motivation, roles matrix, audit journal.
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.can(Perm.manageStaff)) {
      return const PageScaffold(
        title: 'Сотрудники',
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Нет доступа',
          message: 'Раздел доступен владельцу и администратору',
        ),
      );
    }
    final audit = session.can(Perm.viewAudit);
    final tabs = <(Tab, Widget)>[
      (const Tab(icon: Icon(Icons.badge_outlined), text: 'Сотрудники'), const UsersTab()),
      (const Tab(icon: Icon(Icons.schedule), text: 'Рабочее время'), const TimeTab()),
      (const Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Мотивация'), const MotivationTab()),
      (const Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: 'Роли и права'), const RolesTab()),
      if (audit) (const Tab(icon: Icon(Icons.manage_search), text: 'Журнал действий'), const AuditTab()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: PageScaffold(
        title: 'Сотрудники',
        padding: EdgeInsets.zero,
        // Labelled even on phones: the app bar already has the bare timer icon.
        actions: [ClockButton(short: context.isCompact)],
        bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [for (final t in tabs) t.$1]),
        body: TabBarView(
          children: [for (final t in tabs) Padding(padding: const EdgeInsets.all(Gap.l), child: t.$2)],
        ),
      ),
    );
  }
}
