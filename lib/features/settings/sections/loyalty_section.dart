import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
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

    return buildForm(
      title: 'Лояльность',
      description: 'Бонусная программа: клиент получает бонусы с покупок и оплачивает ими часть '
          'следующих покупок. 1 бонус = 1 единица валюты.',
      children: [
        TileCard(children: [
          const SettingSwitch(
            settingKey: SettingKeys.loyaltyEnabled,
            icon: Icons.loyalty_outlined,
            title: 'Бонусная программа включена',
            subtitle: 'Бонусы начисляются только покупателям, выбранным в чеке',
          ),
        ]),
        SectionCard(
          title: 'Правила',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!enabled) ...[
              const InfoBanner(
                  text: 'Программа выключена: бонусы не начисляются и не списываются. '
                      'Накопленные балансы клиентов сохраняются.'),
              const SizedBox(height: Gap.m),
            ],
            LayoutBuilder(builder: (context, c) {
              final earnField = TextFormField(
                controller: ctl(SettingKeys.loyaltyEarnPercent),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Начислять с покупки', suffixText: '%', helperText: 'От 0 до 100'),
                validator: (v) => validatePercent(v),
                onFieldSubmitted: (_) => save(),
              );
              final redeemField = TextFormField(
                controller: ctl(SettingKeys.loyaltyMaxRedeemPercent),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Оплата бонусами, не больше', suffixText: '% чека', helperText: 'От 0 до 100'),
                validator: (v) => validatePercent(v),
                onFieldSubmitted: (_) => save(),
              );
              if (c.maxWidth < 520) {
                return Column(children: [earnField, const SizedBox(height: Gap.m), redeemField]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: earnField),
                const SizedBox(width: Gap.m),
                Expanded(child: redeemField),
              ]);
            }),
            const SizedBox(height: Gap.m),
            InfoBanner(
              icon: Icons.calculate_outlined,
              color: valid ? AppColors.success : AppColors.warning,
              text: valid
                  ? loyaltyExample(earn, redeem, Money.currency)
                  : 'Введите проценты от 0 до 100, чтобы увидеть пример.',
            ),
            const SizedBox(height: Gap.s),
            Text(
              'При возврате товара начисленные за него бонусы списываются пропорционально. '
              'Новые проценты действуют для следующих продаж; прошлые чеки не пересчитываются.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ]),
        ),
      ],
    );
  }
}
