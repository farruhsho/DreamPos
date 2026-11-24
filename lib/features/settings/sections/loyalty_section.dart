import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../settings_logic.dart';
import '../settings_widgets.dart';

/// «Лояльность»: bonus program parameters.
class LoyaltySection extends ConsumerStatefulWidget {
  const LoyaltySection({super.key});

  @override
  ConsumerState<LoyaltySection> createState() => _LoyaltySectionState();
}

class _LoyaltySectionState extends ConsumerState<LoyaltySection> with SettingsFormMixin {
  @override
  List<String> get formKeys => const [SettingKeys.loyaltyEarnPercent, SettingKeys.loyaltyMaxRedeemPercent];

  @override
  String defaultFor(String key) => key == SettingKeys.loyaltyEarnPercent ? '0' : '100';

  @override
  String toDisplay(String key, String stored) => stored.replaceAll('.', ',');

  @override
  String toStored(String key, String display) => formatPercentValue(parsePercent(display) ?? 0);

  @override
  Widget build(BuildContext context) {
    final enabled = SettingSwitch.isOn(ref.watch(settingProvider(SettingKeys.loyaltyEnabled)));
    final earn = parsePercent(ctl(SettingKeys.loyaltyEarnPercent).text);
    final redeem = parsePercent(ctl(SettingKeys.loyaltyMaxRedeemPercent).text);
    final valid = earn != null && redeem != null && earn >= 0 && earn <= 100 && redeem >= 0 && redeem <= 100;
    final l = context.l10n;

    return buildForm(
      title: l.settingsSecLoyalty,
      description: l.settingsLoyaltyDesc,
      children: [
        TileCard(
          children: [
            SettingSwitch(
              settingKey: SettingKeys.loyaltyEnabled,
              icon: Icons.loyalty_outlined,
              title: l.settingsLoyaltyEnabled,
              subtitle: l.settingsLoyaltyEnabledHint,
            ),
          ],
        ),
        SectionCard(
          title: l.settingsRules,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!enabled) ...[InfoBanner(text: l.settingsLoyaltyOff), const SizedBox(height: Gap.m)],
              LayoutBuilder(
                builder: (context, c) {
                  final earnField = TextFormField(
                    controller: ctl(SettingKeys.loyaltyEarnPercent),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.settingsEarnLabel,
                      suffixText: '%',
                      helperMaxLines: 3,
                      helperText: l.settingsPercentRangeHelper,
                    ),
                    validator: (v) => validatePercent(v),
                    onFieldSubmitted: (_) => save(),
                  );
                  final redeemField = TextFormField(
                    controller: ctl(SettingKeys.loyaltyMaxRedeemPercent),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.settingsRedeemLabel,
                      suffixText: l.settingsRedeemSuffix,
                      helperMaxLines: 3,
                      helperText: l.settingsPercentRangeHelper,
                    ),
                    validator: (v) => validatePercent(v),
                    onFieldSubmitted: (_) => save(),
                  );
                  if (c.maxWidth < 520) {
                    return Column(
                      children: [
                        earnField,
                        const SizedBox(height: Gap.m),
                        redeemField,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: earnField),
                      const SizedBox(width: Gap.m),
                      Expanded(child: redeemField),
                    ],
                  );
                },
              ),
              const SizedBox(height: Gap.m),
              InfoBanner(
                icon: Icons.calculate_outlined,
                color: valid ? AppColors.success : AppColors.warning,
                text: valid ? loyaltyExample(earn, redeem, Money.currency, l) : l.settingsLoyaltyEnterPercents,
              ),
              const SizedBox(height: Gap.s),
              Text(l.settingsLoyaltyReturnInfo, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
