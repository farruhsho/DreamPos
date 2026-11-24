import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../core/widgets/widgets.dart';
import '../features/notifications/notification_engine.dart';
import '../features/staff/time_tab.dart' show ClockButton;
import 'background_jobs.dart';
import 'nav.dart';

/// App chrome: navigation rail (wide) / drawer (narrow), user + shift status,
/// lock screen, global shortcuts (F1 касса, F2 чеки, Ctrl+L блокировка).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();
    // background engines live as long as someone is logged in
    ref.watch(notificationEngineProvider);
    ref.watch(backgroundJobsProvider);
    final items = navItems.where((n) => session.can(n.perm)).toList();
    final idx = items.indexWhere((n) => location.startsWith(n.path));
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.medium;

    void lock() => ref.read(sessionProvider.notifier).logout();

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyL, control: true): lock,
      const SingleActivator(LogicalKeyboardKey.f1): () => context.go('/pos'),
      const SingleActivator(LogicalKeyboardKey.f2): () => context.go('/sales'),
    };

    final body = Column(children: [
      _TopStatusBar(onLock: lock, showMenu: !wide),
      Expanded(child: child),
    ]);

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Scaffold(
        drawer: wide ? null : _NavDrawer(items: items, selected: idx),
        body: wide
            ? Row(children: [
                _Rail(items: items, selected: idx),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ])
            : body,
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.items, required this.selected});
  final List<NavItem> items;
  final int selected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: selected < 0 ? null : selected,
              labelType: NavigationRailLabelType.all,
              minWidth: 84,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.m),
                child: _Logo(),
              ),
              onDestinationSelected: (i) => context.go(items[i].path),
              destinations: [
                for (final n in items)
                  NavigationRailDestination(
                    icon: Icon(n.icon),
                    selectedIcon: Icon(n.selectedIcon),
                    label: Text(n.label, style: const TextStyle(fontSize: 12)),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text('D',
          style: t.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}

class _NavDrawer extends StatelessWidget {
  const _NavDrawer({required this.items, required this.selected});
  final List<NavItem> items;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    int? lastGroup;
    for (var i = 0; i < items.length; i++) {
      final n = items[i];
      if (lastGroup != null && n.group != lastGroup) {
        children.add(const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8), child: Divider()));
      }
      lastGroup = n.group;
      children.add(NavigationDrawerDestination(
          icon: Icon(n.icon), selectedIcon: Icon(n.selectedIcon), label: Text(n.label)));
    }
    return NavigationDrawer(
      selectedIndex: selected < 0 ? null : selected,
      onDestinationSelected: (i) {
        Navigator.pop(context);
        context.go(items[i].path);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 16, 12),
          child: Row(children: [
            _Logo(),
            const SizedBox(width: Gap.m),
            Text('DreamPOS', style: Theme.of(context).textTheme.titleLarge),
          ]),
        ),
        ...children,
      ],
    );
  }
}

class _TopStatusBar extends ConsumerWidget {
  const _TopStatusBar({required this.onLock, required this.showMenu});
  final VoidCallback onLock;
  final bool showMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final session = ref.watch(sessionProvider)!;
    final shift = ref.watch(currentShiftProvider).value;
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    final store = ref.watch(settingProvider('store_name')) ?? 'DreamPOS';
    return Material(
      color: t.brightness == Brightness.light ? Colors.white : t.colorScheme.surfaceContainer,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: Gap.s),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.colorScheme.outlineVariant.withValues(alpha: 0.6)))),
          child: Row(children: [
            if (showMenu)
              IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Меню',
                  onPressed: () => Scaffold.of(context).openDrawer()),
            const SizedBox(width: Gap.s),
            Flexible(
              child: Text(store,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: Gap.m),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => context.go('/shifts'),
              child: shift == null
                  ? const StatusChip('Смена закрыта', color: AppColors.warning)
                  : StatusChip('Смена №${shift.number} · с ${formatTime(shift.openedAt)}',
                      color: AppColors.success),
            ),
            const Spacer(),
            const ClockButton(compact: true),
            const SizedBox(width: Gap.xs),
            IconButton(
              tooltip: 'Уведомления',
              onPressed: () => context.go('/notifications'),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            const SizedBox(width: Gap.xs),
            PopupMenuButton<String>(
              tooltip: 'Профиль',
              onSelected: (v) {
                if (v == 'lock') onLock();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text('${session.user.name} · ${session.role.label}'),
                ),
                const PopupMenuItem(
                  value: 'lock',
                  child: ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('Заблокировать / сменить кассира'),
                    subtitle: Text('Ctrl+L'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.s),
                child: Row(children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: t.colorScheme.primaryContainer,
                    child: Text(session.user.name.characters.first.toUpperCase(),
                        style: TextStyle(color: t.colorScheme.onPrimaryContainer, fontSize: 13)),
                  ),
                  if (MediaQuery.sizeOf(context).width > 700) ...[
                    const SizedBox(width: Gap.s),
                    Text(session.user.name, style: t.textTheme.bodyMedium),
                  ],
                  const Icon(Icons.arrow_drop_down),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
