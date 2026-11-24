import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../settings_logic.dart';
import '../settings_providers.dart';
import '../settings_widgets.dart';

/// «Валюта и налоги».
class CurrencySection extends ConsumerStatefulWidget {
  const CurrencySection({super.key});

  @override
  ConsumerState<CurrencySection> createState() => _CurrencySectionState();
}

class _CurrencySectionState extends ConsumerState<CurrencySection> with SettingsFormMixin {
  @override
  List<String> get formKeys => const [SettingKeys.defaultVatPercent];

  @override
  String defaultFor(String key) => '0';

  @override
  String toStored(String key, String display) => formatPercentValue(parsePercent(display) ?? 0);

  String _presetName(CurrencyConfig c, AppLocalizations l) => switch (c.code) {
    'UZS' => l.settingsCurUzs,
    'TJS' => l.settingsCurTjs,
    'KZT' => l.settingsCurKzt,
    'KGS' => l.settingsCurKgs,
    'RUB' => l.settingsCurRub,
    'USD' => l.settingsCurUsd,
    _ => c.code,
  };

  bool _choosing = false;

  Future<void> _choose(CurrencyConfig c, CurrencyConfig current) async {
    if (c.code == current.code || _choosing) return;
    _choosing = true;
    try {
      await _doChoose(c, current);
    } finally {
      _choosing = false;
    }
  }

  Future<void> _doChoose(CurrencyConfig c, CurrencyConfig current) async {
    final locked = await hasAnySale(ref.read(databaseProvider));
    if (!mounted) return;
    if (locked) {
      showError(context, currencyLockedMessage);
      return;
    }
    final products = ref.read(activeProductCountProvider).value ?? 0;
    final sample = 15000 * current.factor;
    final rescale = products > 0 && c.decimals != current.decimals;
    final settings = ref.read(settingsProvider).value ?? const <String, String>{};
    final changes = currencyChangeSettings(c, settings);
    final resetsCash = changes.containsKey(SettingKeys.posBanknotes) || changes.containsKey(SettingKeys.cashRounding);
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.settingsCurChangeTitle(c.code),
      message: [
        l.settingsCurChangeSymbol(c.symbol),
        if (rescale)
          l.settingsCurChangeRescale('$products', Money.format(sample, c: current), Money.format(sample, c: c)),
        if (resetsCash) l.settingsCurChangeResetsCash,
        l.settingsCurChangeFinal,
      ].join('\n\n'),
      ok: l.settingsCurChangeOk,
      destructive: rescale,
    );
    if (!ok || !mounted) return;
    // changeCurrency re-checks for sales inside the write transaction.
    await runGuarded(
      context,
      () => changeCurrency(ref.read(databaseProvider), c, settings, userId: currentUserId(ref)),
      success: context.l10n.settingsCurrencyValue(_presetName(c, context.l10n)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const {};
    final current = CurrencyConfig.fromSettings(settings);
    final hasSales = ref.watch(hasSalesProvider);
    final locked = hasSales.value ?? true; // locked until we know
    final t = Theme.of(context);
    final l = context.l10n;

    return buildForm(
      title: l.settingsSecCurrency,
      description: l.settingsCurrencyDesc,
      children: [
        SectionCard(
          title: l.settingsCurBase,
          trailing: locked && hasSales.hasValue
              ? Tooltip(message: l.settingsCurLockedTooltip, child: const Icon(Icons.lock_outline, size: 20))
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasSales.hasValue && locked) ...[
                InfoBanner(icon: Icons.lock_outline, color: AppColors.warning, text: l.settingsCurLockedBanner),
                const SizedBox(height: Gap.m),
              ],
              if (hasSales.hasError) ...[
                InfoBanner(
                  icon: Icons.error_outline,
                  color: AppColors.danger,
                  text: l.settingsCurCheckFailed(errorText(hasSales.error!)),
                ),
                const SizedBox(height: Gap.m),
              ],
              for (final c in CurrencyConfig.presets)
                ListTile(
                  key: ValueKey('currency-${c.code}'),
                  enabled: !locked || c.code == current.code,
                  selected: c.code == current.code,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  selectedTileColor: t.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  // ISO code, not the symbol: сум/сомони/сом all start with «с».
                  leading: CircleAvatar(
                    radius: 20,
                    child: Text(
                      c.code,
                      style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text('${_presetName(c, l)} (${c.code})'),
                  subtitle: Text(
                    c.decimals > 0
                        ? l.settingsCurExampleCents(Money.format(123450, c: c))
                        : l.settingsCurExampleNoCents(Money.format(1234500, c: c)),
                  ),
                  trailing: c.code == current.code ? Icon(Icons.check_circle, color: t.colorScheme.primary) : null,
                  onTap: locked ? null : () => _choose(c, current),
                ),
            ],
          ),
        ),
        SectionCard(
          title: l.commonVat,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NarrowField(
                child: TextFormField(
                  controller: ctl(SettingKeys.defaultVatPercent),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l.settingsVatDefault,
                    suffixText: '%',
                    helperMaxLines: 3,
                    helperText: l.settingsVatHelper,
                  ),
                  validator: (v) => validatePercent(v, max: 50),
                  onFieldSubmitted: (_) => save(),
                ),
              ),
              const SizedBox(height: Gap.s),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  for (final v in const ['0', '12', '15', '20'])
                    ActionChip(label: Text('$v %'), onPressed: () => ctl(SettingKeys.defaultVatPercent).text = v),
                ],
              ),
              const SizedBox(height: Gap.m),
              InfoBanner(text: l.settingsVatInfo),
            ],
          ),
        ),
      ],
    );
  }
}
