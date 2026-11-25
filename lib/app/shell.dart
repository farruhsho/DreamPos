import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/db/database.dart' show Shift;
import '../core/doc_number.dart';
import '../core/providers.dart';
import '../core/sync/sync_service.dart';
import '../core/theme.dart';
import '../core/widgets/widgets.dart';
import '../features/notifications/notification_engine.dart';
import '../features/settings/sections/sync_section.dart' show syncPhaseVisual;
import '../features/staff/time_tab.dart' show ClockButton;
import '../l10n/l10n.dart';
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

    final body = Column(
      children: [
        _TopStatusBar(onLock: lock, showMenu: !wide),
        Expanded(child: child),
      ],
    );

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Scaffold(
        drawer: wide ? null : _NavDrawer(items: items, selected: idx),
        body: wide
            ? Row(
                children: [
                  _Rail(items: items, selected: idx),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
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
    return LayoutBuilder(
      builder: (context, c) {
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
                      label: Text(n.labelOf(context.l10n), style: const TextStyle(fontSize: 12)),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
      child: Text(
        'D',
        style: t.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      ),
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
        children.add(
          const Padding(padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8), child: Divider()),
        );
      }
      lastGroup = n.group;
      children.add(
        NavigationDrawerDestination(
          icon: Icon(n.icon),
          selectedIcon: Icon(n.selectedIcon),
          label: Text(n.labelOf(context.l10n)),
        ),
      );
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
          child: Row(
            children: [
              _Logo(),
              const SizedBox(width: Gap.m),
              Text('DreamPOS', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
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
            border: Border(bottom: BorderSide(color: t.colorScheme.outlineVariant.withValues(alpha: 0.6))),
          ),
          child: Row(
            children: [
              if (showMenu)
                IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: context.l10n.appMenu,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              const SizedBox(width: Gap.s),
              // Store name takes what the shift chip leaves; the chip itself is capped
              // to the free width and ellipsized (long uz/ky labels on phones).
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => Row(
                    children: [
                      Flexible(
                        child: Text(
                          store,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: Gap.m),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: (c.maxWidth - Gap.m).clamp(0.0, double.infinity),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => context.go('/shifts'),
                          child: shift == null
                              ? StatusChip(context.l10n.appShiftClosed, color: AppColors.warning)
                              : StatusChip(
                                  shiftChipLabel(context, shift, (c.maxWidth - Gap.m).clamp(0.0, double.infinity)),
                                  color: AppColors.success,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _SyncIndicator(),
              const ClockButton(compact: true),
              const SizedBox(width: Gap.xs),
              IconButton(
                tooltip: context.l10n.navNotifications,
                onPressed: () => context.go('/notifications'),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
              const SizedBox(width: Gap.xs),
              PopupMenuButton<String>(
                tooltip: context.l10n.appProfile,
                onSelected: (v) {
                  if (v == 'lock') onLock();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text('${session.user.name} · ${session.role.labelIn(context.l10n)}'),
                  ),
                  PopupMenuItem(
                    value: 'lock',
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(context.l10n.appLockSwitch),
                      subtitle: const Text('Ctrl+L'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.s),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: t.colorScheme.primaryContainer,
                        child: Text(
                          session.user.name.characters.first.toUpperCase(),
                          style: TextStyle(color: t.colorScheme.onPrimaryContainer, fontSize: 13),
                        ),
                      ),
                      if (MediaQuery.sizeOf(context).width > 700) ...[
                        const SizedBox(width: Gap.s),
                        Text(session.user.name, style: t.textTheme.bodyMedium),
                      ],
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shift chip text that fits [maxWidth]: «Смена №A-3 · с 09:00», else
/// «Смена №A-3», else «№A-3» (phones with the sync icon), so the number with
/// its register code stays readable (D-025).
String shiftChipLabel(BuildContext context, Shift shift, double maxWidth) {
  final l = context.l10n;
  final no = docNo(shift.number, shift.deviceCode);
  final scaler = MediaQuery.textScalerOf(context);
  const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  bool fits(String s) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final ok = tp.width + 16 <= maxWidth; // StatusChip horizontal padding
    tp.dispose();
    return ok;
  }

  final full = l.appShiftChip(no, formatTime(shift.openedAt));
  if (fits(full)) return full;
  final short = l.appShiftChipShort(no);
  return fits(short) ? short : l.appShiftChipNumber(no);
}

/// Small cloud icon (D-025, spec §11): sync state + pending count in the
/// tooltip, tap = «Синхронизировать сейчас». Shown only when sync is
/// configured. Also tells the engine when the app goes to the background (the
/// periodic sync only runs in the foreground).
class _SyncIndicator extends ConsumerStatefulWidget {
  const _SyncIndicator();

  @override
  ConsumerState<_SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends ConsumerState<_SyncIndicator> {
  late final AppLifecycleListener _life;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onStateChange: (s) {
        if (!mounted) return;
        ref.read(syncServiceProvider).setForeground(s == AppLifecycleState.resumed);
      },
    );
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(syncServiceProvider).syncNow();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(syncStatusProvider);
    if (!s.configured) return const SizedBox.shrink();
    final (icon, color) = syncPhaseVisual(s.phase);
    final syncing = _busy || s.phase == SyncPhase.syncing;
    return IconButton(
      key: const ValueKey('shell-sync'),
      tooltip: context.l10n.syncIndicatorTooltip(s.phase.labelIn(context.l10n), '${s.pending}'),
      constraints: const BoxConstraints.tightFor(width: 36, height: 40),
      padding: EdgeInsets.zero,
      iconSize: 20,
      onPressed: syncing ? null : _sync,
      icon: Badge(
        isLabelVisible: s.pending > 0 && !syncing,
        smallSize: 7,
        backgroundColor: AppColors.warning,
        child: Icon(icon, color: color),
      ),
    );
  }
}
