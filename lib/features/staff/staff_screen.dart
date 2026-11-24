import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
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
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    if (session == null || !session.can(Perm.manageStaff)) {
      return PageScaffold(
        title: l.staffTitle,
        body: EmptyState(
          icon: Icons.lock_outline,
          title: l.staffNoAccess,
          message: l.staffNoAccessHint,
        ),
      );
    }
    final audit = session.can(Perm.viewAudit);
    final tabs = <(Tab, Widget)>[
      (Tab(icon: const Icon(Icons.badge_outlined), text: l.staffTitle), const UsersTab()),
      (Tab(icon: const Icon(Icons.schedule), text: l.staffTabTime), const TimeTab()),
      (Tab(icon: const Icon(Icons.emoji_events_outlined), text: l.staffTabMotivation), const MotivationTab()),
      (Tab(icon: const Icon(Icons.admin_panel_settings_outlined), text: l.staffTabRoles), const RolesTab()),
      if (audit) (Tab(icon: const Icon(Icons.manage_search), text: l.staffTabAudit), const AuditTab()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: PageScaffold(
        title: l.staffTitle,
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
