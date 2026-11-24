import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../settings_logic.dart';
import '../settings_widgets.dart';

/// «Внешний вид»: light / dark theme (applied instantly by app.dart).
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(settingProvider(SettingKeys.themeMode));
    final mode = v == 'light' || v == 'dark' ? v! : 'system';
    final l = context.l10n;
    return SectionView(
      title: l.settingsSecAppearance,
      description: l.settingsAppearanceDesc,
      children: [
        SectionCard(
          title: l.settingsTheme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  // Icons are dropped on narrow phones so the three labels fit at 360px.
                  final icons = c.maxWidth >= 380;
                  return NarrowField(
                    maxWidth: 520,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: 'system',
                          icon: icons ? const Icon(Icons.brightness_auto) : null,
                          label: Text(l.settingsThemeAuto),
                        ),
                        ButtonSegment(
                          value: 'light',
                          icon: icons ? const Icon(Icons.light_mode_outlined) : null,
                          label: Text(l.settingsThemeLight),
                        ),
                        ButtonSegment(
                          value: 'dark',
                          icon: icons ? const Icon(Icons.dark_mode_outlined) : null,
                          label: Text(l.settingsThemeDark),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (s) =>
                          runGuarded(context, () => applySettings(ref, {SettingKeys.themeMode: s.first})),
                    ),
                  );
                },
              ),
              const SizedBox(height: Gap.m),
              Text(
                l.settingsThemeHint,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        // l10n foundation: UI language picker (device preference ui_locale)
        SectionCard(title: l.coreUiLanguage, child: const UiLanguagePicker()),
      ],
    );
  }
}
