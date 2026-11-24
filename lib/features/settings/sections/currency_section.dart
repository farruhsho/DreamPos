import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
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

  String _presetName(CurrencyConfig c) => switch (c.code) {
    'UZS' => 'Узбекский сум',
    'TJS' => 'Таджикский сомони',
    'KZT' => 'Казахстанский тенге',
    'KGS' => 'Киргизский сом',
    'RUB' => 'Российский рубль',
    'USD' => 'Доллар США',
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
    final resetsCash =
        changes.containsKey(SettingKeys.posBanknotes) || changes.containsKey(SettingKeys.cashRounding);
    final ok = await confirm(
      context,
      title: 'Сменить валюту на ${c.code}?',
      message: [
        'Все суммы будут показываться в «${c.symbol}».',
        if (rescale)
          'Внимание: у вас уже заведено товаров: $products. Цены хранятся в минимальных единицах, '
              'поэтому цена ${Money.format(sample, c: current)} станет ${Money.format(sample, c: c)}. '
              'Проверьте и исправьте цены после смены валюты.',
        if (resetsCash)
          'Номиналы купюр быстрой оплаты и округление наличных будут сброшены '
              'на стандартные для новой валюты (раздел «Продажи»).',
        'После первой продажи валюту изменить будет нельзя.',
      ].join('\n\n'),
      ok: 'Сменить валюту',
      destructive: rescale,
    );
    if (!ok || !mounted) return;
    // changeCurrency re-checks for sales inside the write transaction.
    await runGuarded(
      context,
      () => changeCurrency(ref.read(databaseProvider), c, settings, userId: currentUserId(ref)),
      success: 'Валюта: ${_presetName(c)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const {};
    final current = CurrencyConfig.fromSettings(settings);
    final hasSales = ref.watch(hasSalesProvider);
    final locked = hasSales.value ?? true; // locked until we know
    final t = Theme.of(context);

    return buildForm(
      title: 'Валюта и налоги',
      description: 'Валюта, в которой ведётся учёт, и ставка НДС по умолчанию для новых товаров.',
      children: [
        SectionCard(
          title: 'Валюта учёта',
          trailing: locked && hasSales.hasValue
              ? const Tooltip(
                  message: 'Валюта зафиксирована после первой продажи',
                  child: Icon(Icons.lock_outline, size: 20),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasSales.hasValue && locked) ...[
                const InfoBanner(
                  icon: Icons.lock_outline,
                  color: AppColors.warning,
                  text:
                      'Валюта зафиксирована: в базе уже есть продажи. Все суммы в чеках, отчётах, '
                      'долгах и бонусах хранятся в этой валюте — её смена исказила бы всю историю.',
                ),
                const SizedBox(height: Gap.m),
              ],
              if (hasSales.hasError) ...[
                InfoBanner(
                  icon: Icons.error_outline,
                  color: AppColors.danger,
                  text: 'Не удалось проверить наличие продаж: ${errorText(hasSales.error!)}',
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
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text('${_presetName(c)} (${c.code})'),
                  subtitle: Text(
                    'Пример: ${Money.format(c.decimals == 0 ? 1234500 : 123450, c: c)}'
                    '${c.decimals > 0 ? ' · с копейками' : ' · без копеек'}',
                  ),
                  trailing: c.code == current.code
                      ? Icon(Icons.check_circle, color: t.colorScheme.primary)
                      : null,
                  onTap: locked ? null : () => _choose(c, current),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'НДС',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NarrowField(
                child: TextFormField(
                  controller: ctl(SettingKeys.defaultVatPercent),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'НДС по умолчанию для новых товаров',
                    suffixText: '%',
                    helperMaxLines: 3,
                    helperText: '0 — если магазин не плательщик НДС',
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
                    ActionChip(
                      label: Text('$v %'),
                      onPressed: () => ctl(SettingKeys.defaultVatPercent).text = v,
                    ),
                ],
              ),
              const SizedBox(height: Gap.m),
              const InfoBanner(
                text:
                    'Цены товаров указываются с НДС. Сумма НДС выделяется из цены по ставке товара '
                    'и печатается в чеке строкой «в т.ч. НДС». Ставку можно изменить в карточке товара.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
