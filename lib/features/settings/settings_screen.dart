import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'sections/about_section.dart';
import 'sections/appearance_section.dart';
import 'sections/backup_section.dart';
import 'sections/currency_section.dart';
import 'sections/data_section.dart';
import 'sections/devices_section.dart';
import 'sections/loyalty_section.dart';
import 'sections/sales_section.dart';
import 'sections/store_section.dart';
import 'settings_providers.dart';
import 'settings_widgets.dart';

enum SettingsSection {
  store('Магазин', 'Название, реквизиты, чек', Icons.storefront_outlined),
  currency('Валюта и налоги', 'Валюта учёта, НДС', Icons.currency_exchange),
  sales('Продажи', 'Смены, возвраты, оплата', Icons.shopping_cart_outlined),
  loyalty('Лояльность', 'Бонусная программа', Icons.loyalty_outlined),
  devices('Кассы и устройства', 'Кассы, принтер, сканер', Icons.devices_outlined),
  appearance('Внешний вид', 'Светлая и тёмная тема', Icons.palette_outlined),
  backup('Резервное копирование', 'Копии и восстановление', Icons.backup_outlined),
  data('Данные', 'Демо-режим, экспорт', Icons.dataset_outlined),
  about('О программе', 'Версия, лицензия, помощь', Icons.info_outline);

  const SettingsSection(this.label, this.hint, this.icon);
  final String label;
  final String hint;
  final IconData icon;

  Widget build() => switch (this) {
    store => const StoreSection(),
    currency => const CurrencySection(),
    sales => const SalesSection(),
    loyalty => const LoyaltySection(),
    devices => const DevicesSection(),
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
      return const PageScaffold(
        title: 'Настройки',
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Нет доступа',
          message: 'Настройки может менять только владелец или администратор.',
        ),
      );
    }
    final settings = ref.watch(settingsProvider);
    return LayoutBuilder(
      builder: (context, c) {
        final wide = context.isWide;
        return PageScaffold(
          title: 'Настройки',
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
                      title: Text(s.label),
                      subtitle: Text(s.hint, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          title: Text(s.label),
          subtitle: Text(s.hint),
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
    child: PageScaffold(title: section.label, padding: EdgeInsets.zero, body: section.build()),
  );
}
