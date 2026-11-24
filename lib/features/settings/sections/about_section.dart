import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../settings_logic.dart';
import '../settings_providers.dart';
import '../settings_widgets.dart';

/// «О программе»: version, subscription placeholder, support diagnostics.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final installed = ref.watch(installedAtProvider);
    final diag = ref.watch(diagnosticsProvider);
    final settings = ref.watch(settingsProvider).value ?? const {};

    return SectionView(
      title: 'О программе',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Gap.l),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(Gap.m),
                decoration: BoxDecoration(
                    color: t.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.point_of_sale, size: 32, color: t.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: Gap.l),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DreamPOS', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text('Версия $appVersion', style: t.textTheme.bodyMedium),
                  Text('Касса и учёт для розничных магазинов. Работает без интернета.',
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                ]),
              ),
            ]),
          ),
        ),
        SectionCard(
          title: 'Лицензия',
          child: AsyncView(
            value: installed,
            onRetry: () => ref.invalidate(installedAtProvider),
            data: (at) {
              final left = trialDaysLeft(at, DateTime.now());
              final expired = left == 0;
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const Expanded(child: Text('Тариф: «Магазин» (1 точка)')),
                  StatusChip(expired ? 'Пробный период истёк' : 'Пробный период',
                      color: expired ? AppColors.danger : AppColors.info),
                ]),
                const SizedBox(height: Gap.m),
                LinearProgressIndicator(
                  value: (trialPeriodDays - left) / trialPeriodDays,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: Gap.s),
                Text(expired
                    ? 'Пробный период закончился. Свяжитесь с поддержкой для продления — данные сохранены.'
                    : 'Осталось $left ${_daysWord(left)} из $trialPeriodDays · установлено ${formatDate(at.toLocal())}'),
              ]);
            },
          ),
        ),
        SectionCard(
          title: 'Связаться с поддержкой',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('При обращении в поддержку приложите сведения ниже — они помогут быстрее '
                'разобраться. Личные данные клиентов в них не входят.'),
            const SizedBox(height: Gap.m),
            AsyncView(
              value: diag,
              onRetry: () => ref.invalidate(diagnosticsProvider),
              data: (d) {
                final text = diagnosticsText(
                    platform: d.platform, dbSize: d.dbSize, counts: d.counts, settings: settings);
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    padding: const EdgeInsets.all(Gap.m),
                    decoration: BoxDecoration(
                      color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(text,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4)),
                  ),
                  const SizedBox(height: Gap.m),
                  Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                    FilledButton.tonalIcon(
                      onPressed: () => copyToClipboard(context, text, message: 'Сведения скопированы'),
                      icon: const Icon(Icons.copy),
                      label: const Text('Копировать сведения'),
                    ),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(diagnosticsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Обновить'),
                    ),
                  ]),
                ]);
              },
            ),
          ]),
        ),
      ],
    );
  }
}

String _daysWord(int n) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return 'день';
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'дня';
  return 'дней';
}
