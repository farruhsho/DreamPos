import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'staff_logic.dart';
import 'staff_providers.dart';

/// Clock in / out button for the current session user.
class ClockButton extends ConsumerStatefulWidget {
  const ClockButton({super.key, this.compact = false});
  final bool compact;

  @override
  ConsumerState<ClockButton> createState() => _ClockButtonState();
}

class _ClockButtonState extends ConsumerState<ClockButton> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    await runGuarded(context, action, success: success);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final open = ref.watch(myOpenWorkSessionProvider);
    final user = ref.watch(sessionProvider)?.user;
    if (user == null || open.isLoading && !open.hasValue) return const SizedBox.shrink();
    final s = open.value;
    final clock = ref.read(timeClockProvider);
    final compact = widget.compact;
    if (s == null) {
      return FilledButton.tonalIcon(
        key: const ValueKey('clock_in'),
        onPressed: _busy
            ? null
            : () => _run(() => clock.clockIn(user.id), 'Приход отмечен в ${formatTime(DateTime.now())}'),
        icon: const Icon(Icons.login),
        label: Text(compact ? 'Приход' : 'Отметить приход'),
      );
    }
    final dur = DateTime.now().difference(s.startedAt);
    return OutlinedButton.icon(
      key: const ValueKey('clock_out'),
      onPressed: _busy
          ? null
          : () async {
              final ok = await confirm(
                context,
                title: 'Отметить уход?',
                message: 'На работе с ${formatTime(s.startedAt)} (${formatDuration(dur)}).',
                ok: 'Отметить уход',
              );
              if (!ok || !mounted) return;
              await _run(() => clock.clockOut(user.id), 'Уход отмечен');
            },
      icon: const Icon(Icons.logout),
      label: Text(compact ? 'Уход' : 'Отметить уход · ${formatDuration(dur)}'),
    );
  }
}

enum _Range { today, week, month, lastMonth }

Period _periodFor(_Range r, DateTime now) {
  final d = DateTime(now.year, now.month, now.day);
  return switch (r) {
    _Range.today => (from: d, to: DateTime(d.year, d.month, d.day + 1)),
    _Range.week => (
      from: DateTime(d.year, d.month, d.day - (d.weekday - 1)),
      to: DateTime(d.year, d.month, d.day + 1),
    ),
    _Range.month => (from: DateTime(d.year, d.month), to: DateTime(d.year, d.month + 1)),
    _Range.lastMonth => (from: DateTime(d.year, d.month - 1), to: DateTime(d.year, d.month)),
  };
}

String _rangeLabel(_Range r) => switch (r) {
  _Range.today => 'Сегодня',
  _Range.week => 'Эта неделя',
  _Range.month => 'Этот месяц',
  _Range.lastMonth => 'Прошлый месяц',
};

class TimeTab extends ConsumerStatefulWidget {
  const TimeTab({super.key});

  @override
  ConsumerState<TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends ConsumerState<TimeTab> {
  _Range _range = _Range.week;
  String? _userId;
  late Period _period = _periodFor(_range, DateTime.now());

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final users = ref.watch(staffUsersProvider).value ?? const <User>[];
    final byId = {for (final u in users) u.id: u};
    final sessions = ref.watch(workSessionsProvider(_period));
    final canManage = ref.watch(sessionProvider)?.can(Perm.manageStaff) ?? false;
    final now = DateTime.now();

    final filters = Wrap(
      spacing: Gap.s,
      runSpacing: Gap.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final r in _Range.values)
          ChoiceChip(
            label: Text(_rangeLabel(r)),
            selected: _range == r,
            onSelected: (_) => setState(() {
              _range = r;
              _period = _periodFor(r, DateTime.now());
            }),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _userId,
            decoration: const InputDecoration(labelText: 'Сотрудник'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Все сотрудники')),
              for (final u in users)
                DropdownMenuItem(
                  value: u.id,
                  child: Text(u.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _userId = v),
          ),
        ),
        const ClockButton(),
        if (canManage)
          OutlinedButton.icon(
            key: const ValueKey('add_session'),
            onPressed: () => showWorkSessionDialog(context, users: users, userId: _userId),
            icon: const Icon(Icons.more_time),
            label: const Text('Добавить запись'),
          ),
      ],
    );

    List<Widget> content(List<WorkSession> all) {
      final list = all.where((s) => _userId == null || s.userId == _userId).toList();
      final totals = <String, (Duration, int)>{};
      for (final s in list) {
        final cur = totals[s.userId] ?? (Duration.zero, 0);
        totals[s.userId] = (cur.$1 + overlap(s, _period.from, _period.to, now: now), cur.$2 + 1);
      }
      if (list.isEmpty) {
        return const [
          EmptyState(
            icon: Icons.schedule,
            title: 'Нет отметок за период',
            message: 'Сотрудники отмечают приход и уход кнопкой «Отметить приход»',
          ),
        ];
      }
      final summary = Wrap(
        spacing: Gap.m,
        runSpacing: Gap.m,
        children: [
          for (final e in totals.entries.toList()..sort((a, b) => b.value.$1.compareTo(a.value.$1)))
            SizedBox(
              width: 220,
              child: StatCard(
                label: byId[e.key]?.name ?? '—',
                value: formatDuration(e.value.$1),
                hint: '${e.value.$2} отмет.',
                icon: Icons.timer_outlined,
              ),
            ),
        ],
      );
      return [
        summary,
        const SizedBox(height: Gap.m),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, s) in list.indexed) ...[
                if (i > 0) const Divider(),
                ListTile(
                  onTap: canManage ? () => showWorkSessionDialog(context, users: users, session: s) : null,
                  leading: Icon(
                    s.endedAt == null ? Icons.play_circle : Icons.check_circle_outline,
                    color: s.endedAt == null ? AppColors.success : t.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(byId[s.userId]?.name ?? '—'),
                  subtitle: Text(
                    [
                      '${formatDateTime(s.startedAt)} — ${s.endedAt == null ? 'на работе' : _endText(s.startedAt, s.endedAt!)}',
                      if ((s.note ?? '').isNotEmpty) s.note!,
                    ].join('\n'),
                  ),
                  isThreeLine: (s.note ?? '').isNotEmpty,
                  trailing: Text(
                    formatDuration((s.endedAt ?? now).difference(s.startedAt)),
                    style: t.textTheme.titleSmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ];
    }

    return ListView(
      children: [
        filters,
        const SizedBox(height: Gap.m),
        ...switch (sessions) {
          AsyncData(:final value) => content(value),
          AsyncError(:final error) => [
            ErrorView(error: error, onRetry: () => ref.invalidate(workSessionsProvider(_period))),
          ],
          _ => const [Padding(padding: EdgeInsets.all(Gap.xl), child: LoadingView())],
        },
      ],
    );
  }

  static String _endText(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day ? formatTime(b) : formatDateTime(b);
}

/// Add ([session] == null) or edit a work session (manager).
Future<void> showWorkSessionDialog(
  BuildContext context, {
  required List<User> users,
  WorkSession? session,
  String? userId,
}) {
  return showFormDialog<void>(
    context,
    title: session == null ? 'Новая запись рабочего времени' : 'Запись рабочего времени',
    width: 480,
    child: _SessionForm(users: users, session: session, userId: userId),
  );
}

class _SessionForm extends ConsumerStatefulWidget {
  const _SessionForm({required this.users, this.session, this.userId});
  final List<User> users;
  final WorkSession? session;
  final String? userId;

  @override
  ConsumerState<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<_SessionForm> {
  late String? _userId = widget.session?.userId ?? widget.userId;
  late final _defaults = defaultManualSession(DateTime.now());
  late DateTime _start = widget.session?.startedAt ?? _defaults.start;
  late DateTime? _end = widget.session == null ? _defaults.end : widget.session!.endedAt;
  late final _note = TextEditingController(text: widget.session?.note);
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return null;
    final tm = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (tm == null) return null;
    return DateTime(d.year, d.month, d.day, tm.hour, tm.minute);
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_userId == null) {
      showError(context, 'Выберите сотрудника');
      return;
    }
    final actor = ref.read(sessionProvider)?.user;
    if (actor == null) return;
    setState(() => _busy = true);
    final ok = await runGuarded(
      context,
      () => ref
          .read(timeClockProvider)
          .save(
            id: widget.session?.id,
            userId: _userId!,
            start: _start,
            end: _end,
            note: _note.text,
            actorId: actor.id,
          ),
      success: 'Запись сохранена',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final actor = ref.read(sessionProvider)?.user;
    if (actor == null || widget.session == null) return;
    final ok = await confirm(
      context,
      title: 'Удалить запись?',
      message: 'Действие будет записано в журнал.',
      ok: 'Удалить',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(
      context,
      () => ref.read(timeClockProvider).delete(widget.session!.id, actorId: actor.id),
      success: 'Запись удалена',
    );
    if (done && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dur = _end?.difference(_start);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _userId,
            decoration: const InputDecoration(labelText: 'Сотрудник *'),
            items: [
              for (final u in widget.users)
                DropdownMenuItem(
                  value: u.id,
                  child: Text(u.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: widget.session == null ? (v) => setState(() => _userId = v) : null,
          ),
          const SizedBox(height: Gap.m),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.login),
            title: const Text('Приход'),
            subtitle: Text(formatDateTime(_start)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final v = await _pick(_start);
              if (v != null) setState(() => _start = v);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: const Text('Уход'),
            subtitle: Text(_end == null ? 'ещё на работе' : formatDateTime(_end!)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_end != null)
                  IconButton(
                    tooltip: 'Ещё на работе',
                    onPressed: () => setState(() => _end = null),
                    icon: const Icon(Icons.clear),
                  ),
                const Icon(Icons.edit_calendar),
              ],
            ),
            onTap: () async {
              final v = await _pick(_end ?? DateTime.now());
              if (v != null) setState(() => _end = v);
            },
          ),
          if (dur != null)
            Text(
              dur.isNegative ? 'Уход раньше прихода' : 'Длительность: ${formatDuration(dur)}',
              style: TextStyle(color: dur.isNegative ? AppColors.danger : null),
            ),
          const SizedBox(height: Gap.m),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Комментарий (причина правки)'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Gap.xl),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: Gap.s,
            overflowSpacing: Gap.xs,
            children: [
              if (widget.session != null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
                ),
              TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Отмена')),
              FilledButton(
                key: const ValueKey('session_save'),
                onPressed: _busy ? null : _save,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
