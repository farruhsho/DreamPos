// Language pickers: UI language (device preference `ui_locale`) and receipt
// language (store setting `receipt_locale`). See docs/L10N.md.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../providers.dart';
import '../theme.dart';

/// Choice chips with the native language names; switches the UI at once.
class UiLanguagePicker extends ConsumerWidget {
  const UiLanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(uiLocaleProvider);
    return Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
      for (final code in supportedLanguageCodes)
        ChoiceChip(
          key: ValueKey('ui-lang-$code'),
          label: Text(languageNativeNames[code]!),
          selected: current == code,
          onSelected: (_) => ref.read(uiLocaleProvider.notifier).set(code),
        ),
    ]);
  }
}

/// Compact chip («RU ▾») for the login screen.
class UiLanguageChip extends ConsumerWidget {
  const UiLanguageChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(uiLocaleProvider);
    final t = Theme.of(context);
    return PopupMenuButton<String>(
      key: const ValueKey('ui-lang-chip'),
      tooltip: context.l10n.coreUiLanguage,
      initialValue: current,
      onSelected: (code) => ref.read(uiLocaleProvider.notifier).set(code),
      itemBuilder: (_) => [
        for (final code in supportedLanguageCodes)
          PopupMenuItem(value: code, child: Text(languageNativeNames[code]!)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.xs),
        decoration: BoxDecoration(
          border: Border.all(color: t.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.language, size: 16, color: t.colorScheme.onSurfaceVariant),
          const SizedBox(width: Gap.xs),
          Text(languageShortNames[current]!, style: t.textTheme.labelLarge),
          Icon(Icons.arrow_drop_down, size: 18, color: t.colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}

/// Settings tile «Язык чека»: store setting `receipt_locale` (default ru).
class ReceiptLanguageTile extends ConsumerWidget {
  const ReceiptLanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(receiptLocaleProvider);
    return ListTile(
      leading: const Icon(Icons.translate),
      title: Text(context.l10n.coreReceiptLanguage),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: Gap.s),
        child: Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
          for (final code in supportedLanguageCodes)
            ChoiceChip(
              key: ValueKey('receipt-lang-$code'),
              label: Text(languageNativeNames[code]!),
              selected: current == code,
              onSelected: (_) async {
                if (code == current) return;
                // same audit/sync trail as the settings module's saveSettings()
                final db = ref.read(databaseProvider);
                final old = await db.getSetting('receipt_locale');
                await db.transaction(() async {
                  await db.setSetting('receipt_locale', code);
                  await db.audit('settings.change',
                      userId: ref.read(sessionProvider)?.user.id,
                      entity: 'settings',
                      entityId: 'receipt_locale',
                      details: 'receipt_locale: ${old ?? '—'} → $code');
                  await db.markDirty('settings', 'receipt_locale');
                });
              },
            ),
        ]),
      ),
    );
  }
}
