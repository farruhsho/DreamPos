import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../settings_logic.dart';
import '../settings_widgets.dart';

/// «Внешний вид»: light / dark theme (applied instantly by app.dart).
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(settingProvider(SettingKeys.themeMode));
    final mode = v == 'light' || v == 'dark' ? v! : 'system';
    return SectionView(
      title: 'Внешний вид',
      description: 'Тема оформления применяется сразу на всех экранах этой программы.',
      children: [
        SectionCard(
          title: 'Тема',
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
                          label: const Text('Авто'),
                        ),
                        ButtonSegment(
                          value: 'light',
                          icon: icons ? const Icon(Icons.light_mode_outlined) : null,
                          label: const Text('Светлая'),
                        ),
                        ButtonSegment(
                          value: 'dark',
                          icon: icons ? const Icon(Icons.dark_mode_outlined) : null,
                          label: const Text('Тёмная'),
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
                '«Авто» — как в настройках Windows/Android. '
                'Тёмная тема снижает нагрузку на глаза в вечернюю смену и экономит заряд на телефонах '
                'с OLED-экраном. Светлая лучше читается при ярком освещении торгового зала.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
