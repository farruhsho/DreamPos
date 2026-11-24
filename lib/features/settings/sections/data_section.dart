import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../settings_logic.dart';
import '../settings_providers.dart';
import '../settings_widgets.dart';

/// «Данные»: demo mode info and CSV export.
class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  String? _busy;
  File? _lastExport;

  Future<void> _export(String what) async {
    setState(() => _busy = what);
    final svc = ref.read(backupServiceProvider);
    File? f;
    await runGuarded(context, () async {
      f = what == 'products'
          ? await svc.exportProducts(userId: currentUserId(ref))
          : await svc.exportCustomers(userId: currentUserId(ref));
    });
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (f != null) _lastExport = f;
    });
    if (f != null) showSuccess(context, context.l10n.settingsFileSaved(f!.path));
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(settingProvider(SettingKeys.demoMode)) == '1';
    final dbPath = ref.watch(databasePathProvider).value;
    final t = Theme.of(context);
    final l = context.l10n;

    Widget exportTile(String what, IconData icon, String title, String subtitle) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: OutlinedButton.icon(
        onPressed: _busy != null ? null : () => _export(what),
        icon: _busy == what
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.file_download_outlined),
        label: const Text('CSV'),
      ),
    );

    return SectionView(
      title: l.settingsSecData,
      description: l.settingsDataDesc,
      children: [
        SectionCard(
          title: l.settingsMode,
          trailing: StatusChip(
            demo ? l.settingsDemoMode : l.settingsLiveDb,
            color: demo ? AppColors.warning : AppColors.success,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(demo ? l.settingsDemoText : l.settingsLiveText),
              if (demo) ...[
                const SizedBox(height: Gap.m),
                InfoBanner(color: AppColors.warning, icon: Icons.warning_amber, text: l.settingsDemoWarning),
                const SizedBox(height: Gap.s),
                for (final (i, s) in [
                  l.settingsDemoStep1,
                  l.settingsDemoStep2,
                  '${l.settingsDemoStep3}${dbPath == null ? '' : '\n${l.settingsDbFile(dbPath)}'}',
                  l.settingsDemoStep4,
                ].indexed)
                  Padding(
                    padding: const EdgeInsets.only(top: Gap.xs),
                    child: Text('${i + 1}. $s'),
                  ),
                if (dbPath != null) ...[
                  const SizedBox(height: Gap.s),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => copyToClipboard(context, dbPath, message: l.settingsPathCopied),
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(l.settingsCopyDbPath),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        TileCard(
          title: l.commonExport,
          children: [
            exportTile('products', Icons.inventory_2_outlined, l.commonProducts, l.settingsExportProductsHint),
            exportTile('customers', Icons.people_outline, l.commonCustomers, l.settingsExportCustomersHint),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.l),
              child: Text(l.settingsExportInfo, style: t.textTheme.bodySmall),
            ),
            if (_lastExport != null)
              ListTile(
                leading: const Icon(Icons.check_circle, color: AppColors.success),
                title: Text(l.settingsLastFile),
                subtitle: SelectableText(_lastExport!.path),
                trailing: IconButton(
                  tooltip: l.settingsCopyPath,
                  icon: const Icon(Icons.copy),
                  onPressed: () => copyToClipboard(context, _lastExport!.path, message: l.settingsPathCopied),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
