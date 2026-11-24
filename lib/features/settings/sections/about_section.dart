import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
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
    final l = context.l10n;

    return SectionView(
      title: l.settingsSecAbout,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Gap.l),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Gap.m),
                  decoration: BoxDecoration(
                    color: t.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.point_of_sale, size: 32, color: t.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: Gap.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DreamPOS', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(l.settingsVersion(appVersion), style: t.textTheme.bodyMedium),
                      Text(
                        l.settingsAboutTagline,
                        style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionCard(
          title: l.settingsLicense,
          child: AsyncView(
            value: installed,
            onRetry: () => ref.invalidate(installedAtProvider),
            data: (at) {
              final left = trialDaysLeft(at, DateTime.now());
              final expired = left == 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l.settingsPlan)),
                      StatusChip(
                        expired ? l.settingsTrialExpired : l.settingsTrial,
                        color: expired ? AppColors.danger : AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.m),
                  LinearProgressIndicator(
                    value: (trialPeriodDays - left) / trialPeriodDays,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: Gap.s),
                  Text(
                    expired
                        ? l.settingsTrialEnded
                        : l.settingsTrialLeft(left, '$trialPeriodDays', formatDate(at.toLocal())),
                  ),
                ],
              );
            },
          ),
        ),
        SectionCard(
          title: l.settingsSupport,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.settingsSupportHint),
              const SizedBox(height: Gap.m),
              AsyncView(
                value: diag,
                onRetry: () => ref.invalidate(diagnosticsProvider),
                data: (d) {
                  final text = diagnosticsText(
                    platform: d.platform,
                    dbSize: d.dbSize,
                    counts: d.counts,
                    settings: settings,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(Gap.m),
                        decoration: BoxDecoration(
                          color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          text,
                          style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: Gap.m),
                      Wrap(
                        spacing: Gap.s,
                        runSpacing: Gap.s,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => copyToClipboard(context, text, message: l.settingsInfoCopied),
                            icon: const Icon(Icons.copy),
                            label: Text(l.settingsCopyInfo),
                          ),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(diagnosticsProvider),
                            icon: const Icon(Icons.refresh),
                            label: Text(l.settingsRefresh),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
