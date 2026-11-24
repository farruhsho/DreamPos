import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../reports/tabs/insights_tab.dart' show canOpenRoute;
import 'notification_engine.dart';

/// Kind metadata for display and navigation.
({String label, IconData icon, Color color, String? route}) kindInfo(String kind) => switch (kind) {
      NotificationKind.lowStock =>
        (label: 'Мало товара', icon: Icons.inventory_outlined, color: AppColors.warning, route: '/inventory'),
      NotificationKind.outOfStock => (
          label: 'Нет в наличии',
          icon: Icons.remove_shopping_cart_outlined,
          color: AppColors.danger,
          route: '/inventory'
        ),
      NotificationKind.debtDue => (
          label: 'Долги',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.danger,
          route: '/customers'
        ),
      NotificationKind.birthday =>
        (label: 'Дни рождения', icon: Icons.cake_outlined, color: AppColors.info, route: '/customers'),
      NotificationKind.shift =>
        (label: 'Смены', icon: Icons.schedule_outlined, color: AppColors.warning, route: '/shifts'),
      NotificationKind.task => (label: 'Задачи', icon: Icons.task_alt, color: AppColors.brand, route: null),
      _ => (label: 'Система', icon: Icons.info_outline, color: AppColors.info, route: null),
    };

final _notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.notifications)
        ..where((n) => n.deletedAt.isNull())
        ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
        ..limit(500))
      .watch();
});

/// Marks notifications read/unread (reference data: direct drift write + outbox).
Future<void> setNotificationsRead(AppDatabase db, Iterable<String> ids, {required bool read}) async {
  final list = ids.toList();
  if (list.isEmpty) return;
  final now = DateTime.now();
  await db.transaction(() async {
    await (db.update(db.notifications)..where((n) => n.id.isIn(list)))
        .write(NotificationsCompanion(isRead: Value(read), updatedAt: Value(now)));
    for (final id in list) {
      await db.markDirty('notifications', id);
    }
  });
}

/// Soft-deletes (or restores) notifications.
Future<void> softDeleteNotifications(AppDatabase db, Iterable<String> ids,
    {bool restore = false}) async {
  final list = ids.toList();
  if (list.isEmpty) return;
  final now = DateTime.now();
  await db.transaction(() async {
    await (db.update(db.notifications)..where((n) => n.id.isIn(list))).write(
        NotificationsCompanion(deletedAt: Value(restore ? null : now), updatedAt: Value(now)));
    for (final id in list) {
      await db.markDirty('notifications', id, op: restore ? 'upsert' : 'delete');
    }
  });
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

/// Filter: null = all, '' = unread only, otherwise a kind.
class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _filter;
  bool _checking = false;
  /// Swiped-away items hidden immediately (before the stream catches up), as
  /// Dismissible requires the dismissed child to leave the tree synchronously.
  final _hidden = <String>{};
  late final AppDatabase _db = ref.read(databaseProvider);

  Future<void> _setRead(Iterable<String> ids, bool read) =>
      setNotificationsRead(_db, ids, read: read);

  Future<void> _softDelete(Iterable<String> ids, {bool restore = false}) =>
      softDeleteNotifications(_db, ids, restore: restore);

  /// Soft-deletes one notification and offers "Отменить" in a snackbar.
  Future<void> _deleteWithUndo(AppNotification n) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = _db;
    setState(() => _hidden.add(n.id));
    try {
      await _softDelete([n.id]);
    } catch (e) {
      if (mounted) {
        setState(() => _hidden.remove(n.id));
        showError(context, e);
      }
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Уведомление удалено'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () async {
            await softDeleteNotifications(db, [n.id], restore: true);
            if (mounted) setState(() => _hidden.remove(n.id));
          },
        ),
      ));
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    try {
      final r = await runNotificationChecksDetailed(_db);
      if (!mounted) return;
      showSuccess(
          context,
          r.created == 0
              ? 'Проверка завершена — новых уведомлений нет'
              : 'Новых уведомлений: ${r.created}');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _deleteRead(List<AppNotification> all) async {
    final read = all.where((n) => n.isRead).map((n) => n.id).toList();
    if (read.isEmpty) return;
    final ok = await confirm(context,
        title: 'Удалить прочитанные?',
        message: 'Будет удалено уведомлений: ${read.length}. Непрочитанные останутся.',
        ok: 'Удалить',
        destructive: true);
    if (!ok || !mounted) return;
    await runGuarded(context, () => _softDelete(read), success: 'Прочитанные уведомления удалены');
  }

  void _open(AppNotification n) {
    if (!n.isRead) unawaited(_setRead([n.id], true).catchError((Object _) {}));
    final route = kindInfo(n.kind).route;
    if (route == null) return;
    if (!canOpenRoute(ref.read(sessionProvider), route)) {
      showError(context, 'Нет доступа к разделу — обратитесь к администратору');
      return;
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_notificationsProvider);
    final all = [
      for (final n in data.value ?? const <AppNotification>[])
        if (!_hidden.contains(n.id)) n,
    ];
    final unread = all.where((n) => !n.isRead).length;
    final compact = context.isCompact;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): () {
          if (!_checking) _checkNow();
        },
      },
      child: Focus(
        autofocus: true,
        child: PageScaffold(
          title: 'Уведомления',
          subtitle: unread == 0 ? 'Все прочитаны' : 'Непрочитанных: $unread',
          padding: EdgeInsets.zero,
          actions: [
            if (compact)
              IconButton(
                tooltip: 'Проверить сейчас (F5)',
                onPressed: _checking ? null : _checkNow,
                icon: _checking
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
              )
            else
              FilledButton.tonalIcon(
                key: const ValueKey('check-now'),
                onPressed: _checking ? null : _checkNow,
                icon: _checking
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Проверить сейчас'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            const SizedBox(width: Gap.xs),
            IconButton(
              tooltip: 'Прочитать все',
              onPressed: unread == 0
                  ? null
                  : () => runGuarded(
                      context, () => _setRead(all.where((n) => !n.isRead).map((n) => n.id), true),
                      success: 'Все уведомления прочитаны'),
              icon: const Icon(Icons.done_all),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ещё',
              onSelected: (v) {
                if (v == 'delete_read') _deleteRead(all);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete_read',
                  enabled: all.any((n) => n.isRead),
                  child: const ListTile(
                      dense: true,
                      leading: Icon(Icons.delete_sweep_outlined),
                      title: Text('Удалить прочитанные')),
                ),
              ],
            ),
          ],
          body: AsyncView<List<AppNotification>>(
            value: data,
            onRetry: () => ref.invalidate(_notificationsProvider),
            data: (_) => _body(context, all),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<AppNotification> list) {
    final kinds = <String>{for (final n in list) n.kind}.toList()
      ..sort((a, b) => kindInfo(a).label.compareTo(kindInfo(b).label));
    final unread = list.where((n) => !n.isRead).length;
    final filtered = list
        .where((n) => _filter == null || (_filter == '' ? !n.isRead : n.kind == _filter))
        .toList();

    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none,
        title: 'Уведомлений нет',
        message: 'Здесь появятся напоминания о заканчивающихся товарах, просроченных долгах, '
            'днях рождения клиентов и незакрытых сменах. Проверка идёт автоматически каждые 10 минут.',
        action: FilledButton.icon(
          onPressed: _checking ? null : _checkNow,
          icon: const Icon(Icons.refresh),
          label: const Text('Проверить сейчас'),
        ),
      );
    }

    // group by local calendar day
    final groups = <String, List<AppNotification>>{};
    for (final n in filtered) {
      groups.putIfAbsent(_dayLabel(n.createdAt), () => []).add(n);
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, Gap.s),
            sliver: SliverToBoxAdapter(
              child: _filterBar(context, [
                ChoiceChip(
                  label: Text('Все (${list.length})'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                ChoiceChip(
                  label: Text('Непрочитанные ($unread)'),
                  selected: _filter == '',
                  onSelected: (_) => setState(() => _filter = ''),
                ),
                for (final k in kinds)
                  ChoiceChip(
                    avatar: Icon(kindInfo(k).icon, size: 16),
                    label: Text('${kindInfo(k).label} (${list.where((n) => n.kind == k).length})'),
                    selected: _filter == k,
                    onSelected: (_) => setState(() => _filter = _filter == k ? null : k),
                  ),
              ]),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: _filter == '' ? 'Все уведомления прочитаны' : 'Нет уведомлений этого типа',
                action: TextButton(
                    onPressed: () => setState(() => _filter = null), child: const Text('Показать все')),
              ),
            ),
          for (final e in groups.entries) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, Gap.xs),
              sliver: SliverToBoxAdapter(
                child: Text(e.key,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.l),
              sliver: SliverList.separated(
                itemCount: e.value.length,
                separatorBuilder: (_, _) => const SizedBox(height: Gap.xs),
                itemBuilder: (_, i) => _tile(context, e.value[i]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: Gap.xl)),
        ]),
      ),
    );
  }

  /// Filter chips: wrap on wide screens; one horizontally scrolling line on
  /// phones (two rows of chips pushed the list down).
  Widget _filterBar(BuildContext context, List<Widget> chips) {
    if (!context.isCompact) return Wrap(spacing: Gap.s, runSpacing: Gap.s, children: chips);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: Gap.s),
          chips[i],
        ],
      ]),
    );
  }

  Widget _tile(BuildContext context, AppNotification n) {
    final t = Theme.of(context);
    final info = kindInfo(n.kind);
    final hasBody = n.body != null && n.body!.isNotEmpty;
    // Phones: the menu moves to the time line, so the title gets the full
    // width of the card instead of wrapping into 3 short lines.
    final compact = context.isCompact;
    final time = Text(formatTime(n.createdAt),
        style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant));
    final menu = PopupMenuButton<String>(
      tooltip: 'Действия',
      onSelected: (v) {
        switch (v) {
          case 'read':
            runGuarded(context, () => _setRead([n.id], !n.isRead));
          case 'open':
            _open(n);
          case 'delete':
            _deleteWithUndo(n);
        }
      },
      itemBuilder: (_) => [
        if (info.route != null) const PopupMenuItem(value: 'open', child: Text('Перейти')),
        PopupMenuItem(
            value: 'read',
            child: Text(n.isRead ? 'Отметить непрочитанным' : 'Отметить прочитанным')),
        const PopupMenuItem(value: 'delete', child: Text('Удалить')),
      ],
    );
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Gap.xl),
        decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) => _deleteWithUndo(n),
      child: Card(
        key: ValueKey('notification-${n.id}'),
        color: n.isRead ? null : t.colorScheme.primaryContainer.withValues(alpha: 0.35),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _open(n),
          contentPadding: EdgeInsets.fromLTRB(compact ? Gap.m : Gap.l, Gap.xs, Gap.xs, 0),
          horizontalTitleGap: compact ? Gap.m : null,
          leading: CircleAvatar(
            backgroundColor: info.color.withValues(alpha: 0.12),
            child: Icon(info.icon, color: info.color),
          ),
          title: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!n.isRead) ...[
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(color: t.colorScheme.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: Gap.s),
            ],
            Expanded(
              child: Text(n.title,
                  style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700)),
            ),
          ]),
          // body is capped on its own, so the time line is never cut off
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (hasBody) Text(n.body!, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (compact)
              Row(children: [
                Expanded(child: time),
                SizedBox(width: 44, height: 44, child: menu),
              ])
            else ...[
              const SizedBox(height: 2),
              time,
              const SizedBox(height: Gap.xs),
            ],
          ]),
          titleAlignment: ListTileTitleAlignment.top,
          trailing: compact ? null : menu,
        ),
      ),
    );
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    return formatDate(d);
  }
}
