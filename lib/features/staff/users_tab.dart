import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'staff_logic.dart';
import 'staff_providers.dart';
import 'staff_widgets.dart';
import 'user_form_dialog.dart';

class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  String _q = '';
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final users = ref.watch(staffUsersProvider);
    final today = todayPeriod();
    final sessions = ref.watch(workSessionsProvider(today)).value ?? const <WorkSession>[];
    final now = DateTime.now();
    final worked = <String, Duration>{};
    final onShift = <String>{};
    for (final s in sessions) {
      worked[s.userId] = (worked[s.userId] ?? Duration.zero) + overlap(s, today.from, today.to, now: now);
      if (s.endedAt == null) onShift.add(s.userId);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final search = SearchField(hint: l.staffSearchHint, onChanged: (v) => setState(() => _q = v));
            final inactive = FilterChip(
              label: Text(l.staffInactiveFilter),
              tooltip: l.staffInactiveFilterTip,
              selected: _showInactive,
              onSelected: (v) => setState(() => _showInactive = v),
            );
            final compact = c.maxWidth < 600;
            final add = FilledButton.icon(
              key: const ValueKey('add_user'),
              onPressed: () => showUserFormDialog(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(compact ? l.commonAdd : l.staffAddUser),
            );
            if (compact) {
              // Phone: full-width search, then filter + primary action on one row.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: Gap.s),
                  Row(
                    children: [
                      inactive,
                      const SizedBox(width: Gap.s),
                      Expanded(child: add),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: search),
                      ),
                      const SizedBox(width: Gap.m),
                      inactive,
                    ],
                  ),
                ),
                const SizedBox(width: Gap.m),
                add,
              ],
            );
          },
        ),
        const SizedBox(height: Gap.m),
        Expanded(
          child: AsyncView(
            value: users,
            onRetry: () => ref.invalidate(staffUsersProvider),
            data: (list) {
              final q = _q.toLowerCase();
              final filtered = list
                  .where((u) => _showInactive || u.isActive)
                  .where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || (u.phone ?? '').contains(q))
                  .toList();
              if (filtered.isEmpty) {
                return FillScroll(
                  child: EmptyState(
                    icon: Icons.badge_outlined,
                    title: list.isEmpty ? l.staffEmpty : l.staffNobodyFound,
                    message: list.isEmpty ? l.staffEmptyHint : null,
                  ),
                );
              }
              // Card hugs its rows instead of a tall empty panel under a short list.
              return Align(
                alignment: Alignment.topCenter,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, i) => _UserTile(
                      user: filtered[i],
                      worked: worked[filtered[i].id] ?? Duration.zero,
                      onShift: onShift.contains(filtered[i].id),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user, required this.worked, required this.onShift});
  final User user;
  final Duration worked;
  final bool onShift;

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final actor = ref.read(sessionProvider)?.user;
    if (actor == null) return;
    final l = context.l10n;
    final svc = ref.read(staffServiceProvider);
    if (user.isActive) {
      final ok = await confirm(
        context,
        title: l.staffDeactivateTitle(user.name),
        message: l.staffDeactivateMessage,
        ok: l.staffDeactivate,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await runGuarded(
        context,
        () => svc.setActive(user.id, false, actor: actor),
        success: l.staffDeactivated(user.name),
      );
    } else {
      final pin = await showPinDialog(
        context,
        title: l.staffActivateTitle(user.name),
        message: l.staffActivateMessage,
      );
      if (pin == null || !context.mounted) return;
      await runGuarded(
        context,
        () => svc.setActive(user.id, true, actor: actor, newPin: pin),
        success: l.staffReactivated(user.name),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final l = context.l10n;
    final role = Role.parse(user.role);
    final session = ref.watch(sessionProvider);
    final actorRole = session?.role ?? Role.cashier;
    final editable = canEditUserWithRole(actorRole, role);
    final isMe = session?.user.id == user.id;
    final muted = t.colorScheme.onSurfaceVariant;
    final details = [
      if ((user.phone ?? '').isNotEmpty) user.phone!,
      user.lastLoginAt == null ? l.staffNeverLoggedIn : l.staffLastLogin(formatDateTime(user.lastLoginAt!)),
    ].join(' · ');

    return ListTile(
      enabled: true,
      onTap: editable ? () => showUserFormDialog(context, user: user) : null,
      leading: CircleAvatar(
        backgroundColor: roleColor(role).withValues(alpha: user.isActive ? 0.15 : 0.05),
        child: Text(
          user.name.characters.first.toUpperCase(),
          style: TextStyle(color: user.isActive ? roleColor(role) : muted, fontWeight: FontWeight.w700),
        ),
      ),
      title: Wrap(
        spacing: Gap.s,
        runSpacing: Gap.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            user.name,
            style: TextStyle(
              color: user.isActive ? null : muted,
              decoration: user.isActive ? null : TextDecoration.lineThrough,
            ),
          ),
          StatusChip(role.labelIn(l), color: roleColor(role)),
          if (isMe) StatusChip(l.staffYou, color: AppColors.info),
          if (!user.isActive) StatusChip(l.staffInactiveChip, color: muted),
          if (onShift) StatusChip(l.staffAtWork, color: AppColors.success),
        ],
      ),
      subtitle: Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hours worked today; omitted when nothing was clocked (a lone
          // dash over "сегодня" read like a missing value).
          if (worked > Duration.zero)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatDuration(worked),
                  style: t.textTheme.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                Text(l.staffTodayLower, style: t.textTheme.bodySmall),
              ],
            ),
          PopupMenuButton<String>(
            tooltip: editable ? l.commonActions : l.staffErrOwnerEditOnlyOwner,
            enabled: editable,
            onSelected: (v) {
              if (v == 'edit') showUserFormDialog(context, user: user);
              if (v == 'toggle') _toggleActive(context, ref);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l.staffEditAction)),
              PopupMenuItem(
                value: 'toggle',
                enabled: !isMe,
                child: Text(user.isActive ? l.staffDeactivate : l.staffActivate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
