import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/l10n.dart';
import 'sections/about_section.dart';
import 'sections/appearance_section.dart';
import 'sections/backup_section.dart';
import 'sections/currency_section.dart';
import 'sections/data_section.dart';
import 'sections/devices_section.dart';
import 'sections/loyalty_section.dart';
import 'sections/sales_section.dart';
import 'sections/store_section.dart';
import 'sections/sync_section.dart';
import 'settings_providers.dart';
import 'settings_widgets.dart';

enum SettingsSection {
  store(Icons.storefront_outlined),
  currency(Icons.currency_exchange),
  sales(Icons.shopping_cart_outlined),
  loyalty(Icons.loyalty_outlined),
  devices(Icons.devices_outlined),
  sync(Icons.cloud_sync_outlined),
  appearance(Icons.palette_outlined),
  backup(Icons.backup_outlined),
  data(Icons.dataset_outlined),
  about(Icons.info_outline);

  const SettingsSection(this.icon);
  final IconData icon;

  String labelIn(AppLocalizations l) => switch (this) {
    store => l.settingsSecStore,
    currency => l.settingsSecCurrency,
    sales => l.settingsSecSales,
    loyalty => l.settingsSecLoyalty,
    devices => l.settingsSecDevices,
    sync => l.settingsSecSync,
    appearance => l.settingsSecAppearance,
    backup => l.settingsSecBackup,
    data => l.settingsSecData,
    about => l.settingsSecAbout,
  };

  String hintIn(AppLocalizations l) => switch (this) {
    store => l.settingsSecStoreHint,
    currency => l.settingsSecCurrencyHint,
    sales => l.settingsSecSalesHint,
    loyalty => l.settingsSecLoyaltyHint,
    devices => l.settingsSecDevicesHint,
    sync => l.settingsSecSyncHint,
    appearance => l.settingsSecAppearanceHint,
    backup => l.settingsSecBackupHint,
    data => l.settingsSecDataHint,
    about => l.settingsSecAboutHint,
  };

  String get label => labelIn(L.current);
  String get hint => hintIn(L.current);

  Widget build() => switch (this) {
    store => const StoreSection(),
    currency => const CurrencySection(),
    sales => const SalesSection(),
    loyalty => const LoyaltySection(),
    devices => const DevicesSection(),
    sync => const SyncSection(),
    appearance => const AppearanceSection(),
    backup => const BackupSection(),
    data => const DataSection(),
    about => const AboutSection(),
  };
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsSection _selected = SettingsSection.store;
  final _dirty = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // Starts the trial clock on first open (sets `installed_at` if missing).
    ref.read(installedAtProvider);
  }

  @override
  void dispose() {
    _dirty.dispose();
    super.dispose();
  }

  Future<void> _select(SettingsSection s) async {
    if (s == _selected) return;
    if (_dirty.value && !await confirmDiscard(context)) return;
    _dirty.value = false;
    if (mounted) setState(() => _selected = s);
  }

  void _open(SettingsSection s) {
    final dirty = ValueNotifier<bool>(false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (c) => SettingsDirtyScope(
          dirty: dirty,
          child: _SectionPage(section: s, dirty: dirty),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.can(Perm.manageSettings)) {
      return PageScaffold(
        title: context.l10n.settingsTitle,
        body: EmptyState(
          icon: Icons.lock_outline,
          title: context.l10n.settingsNoAccess,
          message: context.l10n.settingsNoAccessMessage,
        ),
      );
    }
    final settings = ref.watch(settingsProvider);
    return LayoutBuilder(
      builder: (context, c) {
        final wide = context.isWide;
        return PageScaffold(
          title: context.l10n.settingsTitle,
          padding: EdgeInsets.zero,
          body: AsyncView(
            value: settings,
            onRetry: () => ref.invalidate(settingsProvider),
            data: (_) => wide ? _wide(context) : _narrow(context),
          ),
        );
      },
    );
  }

  Widget _wide(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 290,
          child: Material(
            color: t.cardTheme.color,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: Gap.m, horizontal: Gap.s),
              children: [
                for (final s in SettingsSection.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      key: ValueKey('nav-${s.name}'),
                      selected: s == _selected,
                      selectedTileColor: t.colorScheme.primaryContainer.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(s.icon),
                      title: Text(s.labelIn(context.l10n)),
                      subtitle: Text(s.hintIn(context.l10n), maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _select(s),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: SettingsDirtyScope(
            dirty: _dirty,
            child: KeyedSubtree(key: ValueKey(_selected), child: _selected.build()),
          ),
        ),
      ],
    );
  }

  Widget _narrow(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: Gap.s),
    children: [
      for (final s in SettingsSection.values) ...[
        ListTile(
          key: ValueKey('nav-${s.name}'),
          leading: Icon(s.icon),
          title: Text(s.labelIn(context.l10n)),
          subtitle: Text(s.hintIn(context.l10n)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(s),
        ),
        if (s == SettingsSection.loyalty || s == SettingsSection.appearance) const Divider(),
      ],
    ],
  );
}

/// Section pushed as its own page on phones/tablets.
class _SectionPage extends StatelessWidget {
  const _SectionPage({required this.section, required this.dirty});
  final SettingsSection section;
  final ValueNotifier<bool> dirty;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      if (dirty.value && !await confirmDiscard(context)) return;
      dirty.value = false;
      if (context.mounted) Navigator.of(context).pop();
    },
    child: PageScaffold(title: section.labelIn(context.l10n), padding: EdgeInsets.zero, body: section.build()),
  );
}
