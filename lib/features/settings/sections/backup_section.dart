import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../backup_service.dart';
import '../settings_logic.dart';
import '../settings_providers.dart';
import '../settings_widgets.dart';

/// «Резервное копирование».
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _busy = false;

  BackupService get _svc => ref.read(backupServiceProvider);

  void _refresh() {
    ref.invalidate(backupsListProvider);
    ref.invalidate(pendingRestoreProvider);
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    BackupInfo? made;
    await runGuarded(context, () async {
      made = await _svc.create(userId: currentUserId(ref));
    });
    if (!mounted) return;
    setState(() => _busy = false);
    _refresh();
    if (made != null) showSuccess(context, 'Копия создана: ${made!.name} (${formatBytes(made!.size)})');
  }

  Future<void> _delete(BackupInfo b) async {
    final ok = await confirm(
      context,
      title: 'Удалить копию?',
      message:
          '${b.name}\n${formatDateTime(b.date)} · ${formatBytes(b.size)}\n\n'
          'Файл будет удалён с диска без возможности восстановления.',
      ok: 'Удалить',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await runGuarded(context, () => _svc.delete(b, userId: currentUserId(ref)), success: 'Копия удалена');
    _refresh();
  }

  Future<void> _restore(BackupInfo b) async {
    final ok = await confirm(
      context,
      title: 'Восстановить данные из копии?',
      message:
          'Копия от ${formatDateTime(b.date)} заменит ВСЕ текущие данные: товары, продажи, '
          'клиентов, смены и настройки. Всё, что сделано после этой даты, пропадёт.\n\n'
          'Перед восстановлением будет автоматически создана копия текущих данных.\n\n'
          'Данные заменятся при следующем запуске программы.',
      ok: 'Восстановить',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final done = await runGuarded(context, () async {
      await _svc.create(userId: currentUserId(ref)); // safety copy of current data
      await _svc.stageRestore(b, userId: currentUserId(ref));
    });
    if (!mounted) return;
    setState(() => _busy = false);
    _refresh();
    if (done) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.restart_alt, size: 36),
          title: const Text('Перезапустите программу'),
          content: const Text(
            'Восстановление подготовлено.\n\n'
            '1. Закройте DreamPOS на этом компьютере.\n'
            '2. Запустите программу снова — данные будут заменены копией.\n'
            '3. Войдите и проверьте товары и последние продажи.\n\n'
            'До перезапуска не проводите продажи: они будут потеряны.',
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Понятно'))],
        ),
      );
    }
  }

  Future<void> _cancelRestore() async {
    await runGuarded(
      context,
      () => _svc.cancelPendingRestore(userId: currentUserId(ref)),
      success: 'Восстановление отменено',
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final backups = ref.watch(backupsListProvider);
    final pending = ref.watch(pendingRestoreProvider).value ?? false;
    final lastIso = ref.watch(settingProvider(SettingKeys.lastBackupAt));
    final last = lastIso == null ? null : DateTime.tryParse(lastIso)?.toLocal();
    final stale = last == null || DateTime.now().difference(last).inDays >= 7;
    final dirPath = ref.watch(_backupsDirProvider).value;

    return SectionView(
      title: 'Резервное копирование',
      description:
          'Копия базы данных защищает от потери данных при поломке компьютера, вирусе или ошибке. '
          'Храните копии также на флешке или в облаке.',
      children: [
        if (pending)
          InfoBanner(
            icon: Icons.restart_alt,
            color: AppColors.warning,
            text: 'Восстановление из копии подготовлено. Перезапустите программу, чтобы заменить данные.',
            action: TextButton(onPressed: _cancelRestore, child: const Text('Отменить')),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Gap.l),
            child: _StatusRow(
              status: Row(
                children: [
                  Icon(
                    stale ? Icons.warning_amber_rounded : Icons.verified_outlined,
                    color: stale ? AppColors.warning : AppColors.success,
                    size: 32,
                  ),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Последняя копия', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          last == null ? 'ещё не создавалась' : formatDateTime(last),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: stale ? AppColors.warning : null,
                          ),
                        ),
                        if (stale)
                          Text(
                            'Рекомендуем делать копию хотя бы раз в неделю',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              action: FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.backup_outlined),
                label: const Text('Создать копию сейчас'),
              ),
            ),
          ),
        ),
        TileCard(
          children: [
            const SettingSwitch(
              settingKey: SettingKeys.autoBackupDaily,
              icon: Icons.event_repeat,
              title: 'Ежедневная автоматическая копия',
              subtitle: 'Создаётся раз в сутки при запуске программы',
            ),
            if (dirPath != null)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Папка с копиями'),
                subtitle: SelectableText(dirPath),
                trailing: IconButton(
                  tooltip: 'Копировать путь',
                  icon: const Icon(Icons.copy),
                  onPressed: () => copyToClipboard(context, dirPath, message: 'Путь скопирован'),
                ),
              ),
          ],
        ),
        SectionCard(
          title: 'Копии',
          trailing: IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Обновить',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          child: AsyncView(
            value: backups,
            onRetry: _refresh,
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: Gap.m),
                    child: Text('Копий пока нет. Нажмите «Создать копию сейчас».'),
                  )
                : Column(
                    children: [
                      for (final b in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.storage),
                          title: Text(formatDateTime(b.date)),
                          subtitle: Text('${b.name} · ${formatBytes(b.size)}'),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Действия',
                            enabled: !_busy,
                            onSelected: (v) => switch (v) {
                              'restore' => _restore(b),
                              'copy' => copyToClipboard(context, b.file.path, message: 'Путь скопирован'),
                              _ => _delete(b),
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'restore',
                                child: ListTile(leading: Icon(Icons.restore), title: Text('Восстановить')),
                              ),
                              PopupMenuItem(
                                value: 'copy',
                                child: ListTile(leading: Icon(Icons.copy), title: Text('Копировать путь')),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline, color: AppColors.danger),
                                  title: Text('Удалить'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const InfoBanner(
          text:
              'Восстановление заменяет все данные программы содержимым копии и требует перезапуска. '
              'Перед восстановлением автоматически создаётся копия текущих данных.',
        ),
      ],
    );
  }
}

final _backupsDirProvider = FutureProvider.autoDispose<String>(
  (ref) async => (await ref.watch(backupServiceProvider).backupsDir()).path,
);

/// Status on the left, primary action on the right; stacked on phones.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status, required this.action});
  final Widget status;
  final Widget action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => c.maxWidth < 520
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              status,
              const SizedBox(height: Gap.m),
              action,
            ],
          )
        : Row(
            children: [
              Expanded(child: status),
              const SizedBox(width: Gap.l),
              action,
            ],
          ),
  );
}
