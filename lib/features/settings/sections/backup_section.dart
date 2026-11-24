import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
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
    if (made != null) {
      showSuccess(context, context.l10n.settingsBackupCreated(made!.name, formatBytes(made!.size, context.l10n)));
    }
  }

  Future<void> _delete(BackupInfo b) async {
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.settingsBackupDeleteTitle,
      message: l.settingsBackupDeleteMessage(b.name, formatDateTime(b.date), formatBytes(b.size, l)),
      ok: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await runGuarded(
      context,
      () => _svc.delete(b, userId: currentUserId(ref)),
      success: context.l10n.settingsBackupDeleted,
    );
    _refresh();
  }

  Future<void> _restore(BackupInfo b) async {
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.settingsRestoreTitle,
      message: l.settingsRestoreMessage(formatDateTime(b.date)),
      ok: l.settingsRestore,
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
          title: Text(c.l10n.settingsRestartTitle),
          content: Text(c.l10n.settingsRestartMessage),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(c.l10n.settingsGotIt))],
        ),
      );
    }
  }

  Future<void> _cancelRestore() async {
    await runGuarded(
      context,
      () => _svc.cancelPendingRestore(userId: currentUserId(ref)),
      success: context.l10n.settingsRestoreCancelled,
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
    final l = context.l10n;

    return SectionView(
      title: l.settingsSecBackup,
      description: l.settingsBackupDesc,
      children: [
        if (pending)
          InfoBanner(
            icon: Icons.restart_alt,
            color: AppColors.warning,
            text: l.settingsRestorePending,
            action: TextButton(onPressed: _cancelRestore, child: Text(l.settingsCancelVerb)),
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
                        Text(l.settingsLastBackup, style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          last == null ? l.settingsNeverBackedUp : formatDateTime(last),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: stale ? AppColors.warning : null,
                          ),
                        ),
                        if (stale)
                          Text(
                            l.settingsBackupWeekly,
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
                label: Text(l.settingsBackupCreateNow),
              ),
            ),
          ),
        ),
        TileCard(
          children: [
            SettingSwitch(
              settingKey: SettingKeys.autoBackupDaily,
              icon: Icons.event_repeat,
              title: l.settingsAutoBackup,
              subtitle: l.settingsAutoBackupHint,
            ),
            if (dirPath != null)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(l.settingsBackupFolder),
                subtitle: SelectableText(dirPath),
                trailing: IconButton(
                  tooltip: l.settingsCopyPath,
                  icon: const Icon(Icons.copy),
                  onPressed: () => copyToClipboard(context, dirPath, message: l.settingsPathCopied),
                ),
              ),
          ],
        ),
        SectionCard(
          title: l.settingsBackups,
          trailing: IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l.settingsRefresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          child: AsyncView(
            value: backups,
            onRetry: _refresh,
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: Gap.m),
                    child: Text(l.settingsNoBackups),
                  )
                : Column(
                    children: [
                      for (final b in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.storage),
                          title: Text(formatDateTime(b.date)),
                          subtitle: Text('${b.name} · ${formatBytes(b.size, l)}'),
                          trailing: PopupMenuButton<String>(
                            tooltip: l.commonActions,
                            enabled: !_busy,
                            onSelected: (v) => switch (v) {
                              'restore' => _restore(b),
                              'copy' => copyToClipboard(context, b.file.path, message: l.settingsPathCopied),
                              _ => _delete(b),
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'restore',
                                child: ListTile(leading: const Icon(Icons.restore), title: Text(l.settingsRestore)),
                              ),
                              PopupMenuItem(
                                value: 'copy',
                                child: ListTile(leading: const Icon(Icons.copy), title: Text(l.settingsCopyPath)),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                                  title: Text(l.commonDelete),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        InfoBanner(text: l.settingsRestoreInfo),
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
