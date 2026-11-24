import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../settings_logic.dart';
import '../settings_widgets.dart';

/// «Продажи»: rules the POS enforces.
class SalesSection extends ConsumerStatefulWidget {
  const SalesSection({super.key});

  @override
  ConsumerState<SalesSection> createState() => _SalesSectionState();
}

class _SalesSectionState extends ConsumerState<SalesSection> with SettingsFormMixin {
  CurrencyConfig get _cur => Money.currency;

  /// Sample total for the rounding example; has a non-round minor part so the
  /// example shows an actual change for currencies with decimals as well.
  int get _roundingSample => 12370 * _cur.factor + (_cur.decimals > 0 ? 37 : 0);

  @override
  List<String> get formKeys => const [SettingKeys.returnDays, SettingKeys.posBanknotes];

  @override
  String defaultFor(String key) => key == SettingKeys.returnDays ? '14' : '';

  @override
  String toDisplay(String key, String stored) =>
      key == SettingKeys.posBanknotes ? banknotesToInput(stored, _cur) : stored;

  @override
  String toStored(String key, String display) =>
      key == SettingKeys.posBanknotes ? parseBanknotes(display, _cur).stored : '${int.parse(display.trim())}';

  Future<bool> _confirmShift(BuildContext context, bool on) async {
    if (on) return true;
    return confirm(
      context,
      title: context.l10n.settingsShiftOffTitle,
      message: context.l10n.settingsShiftOffMessage,
      ok: context.l10n.settingsShiftOffOk,
      destructive: true,
    );
  }

  Future<bool> _confirmNegative(BuildContext context, bool on) async {
    if (!on) return true;
    return confirm(
      context,
      title: context.l10n.settingsNegativeTitle,
      message: context.l10n.settingsNegativeMessage,
      ok: context.l10n.settingsAllow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const {};
    final rounding = settings[SettingKeys.cashRounding] ?? 'none';
    final days = int.tryParse(ctl(SettingKeys.returnDays).text.trim());
    final defaults = defaultBanknotes(_cur);
    final parsed = parseBanknotes(ctl(SettingKeys.posBanknotes).text, _cur);
    final shown = parsed.ok && parsed.values.isNotEmpty ? parsed.values : defaults;
    final l = context.l10n;

    return buildForm(
      title: l.settingsSecSales,
      description: l.settingsSalesDesc,
      children: [
        TileCard(
          title: l.settingsControl,
          children: [
            SettingSwitch(
              settingKey: SettingKeys.requireShift,
              defaultOn: true,
              icon: Icons.schedule,
              title: l.settingsRequireShift,
              subtitle: l.settingsRequireShiftHint,
              confirmChange: _confirmShift,
            ),
            SettingSwitch(
              settingKey: SettingKeys.allowNegativeStock,
              icon: Icons.inventory_2_outlined,
              title: l.settingsAllowNegative,
              subtitle: l.settingsAllowNegativeHint,
              confirmChange: _confirmNegative,
            ),
            SettingSwitch(
              settingKey: SettingKeys.debtRequiresLimit,
              icon: Icons.credit_score_outlined,
              title: l.settingsDebtLimit,
              subtitle: l.settingsDebtLimitHint,
            ),
          ],
        ),
        SectionCard(
          title: l.settingsReturns,
          child: NarrowField(
            maxWidth: 480,
            child: TextFormField(
              controller: ctl(SettingKeys.returnDays),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.settingsReturnDays,
                suffixText: l.settingsDaysSuffix,
                helperMaxLines: 3,
                helperText: days == 0 ? l.settingsReturnNoLimit : l.settingsReturnWithin('${days ?? '…'}'),
              ),
              validator: validateReturnDays,
              onFieldSubmitted: (_) => save(),
            ),
          ),
        ),
        SectionCard(
          title: l.settingsQuickCash,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: ctl(SettingKeys.posBanknotes),
                decoration: InputDecoration(
                  labelText: l.settingsBanknotesLabel,
                  // Keep the label up so the default set is visible as a hint.
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: defaults.map((v) => Money.toInput(v, c: _cur)).join(', '),
                  helperMaxLines: 3,
                  helperText: l.settingsBanknotesHelper('$maxBanknotes'),
                  suffixText: _cur.symbol,
                ),
                validator: (v) => parseBanknotes(v ?? '', _cur).error,
                onFieldSubmitted: (_) => save(),
              ),
              const SizedBox(height: Gap.m),
              Text(
                l.settingsPosButtons,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: Gap.xs),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [for (final v in shown) Chip(label: Text(Money.format(v, withSymbol: false, c: _cur)))],
              ),
            ],
          ),
        ),
        SectionCard(
          title: l.settingsCashRounding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NarrowField(
                maxWidth: 480,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('rounding-$rounding'),
                  initialValue: cashRoundingOptions.contains(rounding) ? rounding : 'none',
                  decoration: InputDecoration(labelText: l.settingsRoundingLabel),
                  items: [
                    for (final o in cashRoundingOptions)
                      DropdownMenuItem(value: o, child: Text(cashRoundingLabel(o, _cur, l))),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    runGuarded(
                      context,
                      () => applySettings(ref, {SettingKeys.cashRounding: v}),
                      success: l.settingsRoundingChanged(cashRoundingLabel(v, _cur, l).toLowerCase()),
                    );
                  },
                ),
              ),
              const SizedBox(height: Gap.s),
              InfoBanner(
                text: rounding == 'none'
                    ? l.settingsRoundingOff
                    : l.settingsRoundingExample(
                        Money.format(_roundingSample, c: _cur),
                        Money.format(roundCash(_roundingSample, int.tryParse(rounding) ?? 0), c: _cur),
                      ),
                color: AppColors.info,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
