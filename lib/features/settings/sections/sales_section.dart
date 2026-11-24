import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
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
  String toStored(String key, String display) => key == SettingKeys.posBanknotes
      ? parseBanknotes(display, _cur).stored
      : '${int.parse(display.trim())}';

  Future<bool> _confirmShift(BuildContext context, bool on) async {
    if (on) return true;
    return confirm(context,
        title: 'Разрешить продажи без смены?',
        message: 'Не рекомендуется. Без открытой смены:\n'
            '• не будет контроля наличных в кассе и Z-отчёта;\n'
            '• продажи не попадут ни в одну смену, расхождения не найти;\n'
            '• кассиры смогут продавать, не пересчитав размен.\n\n'
            'Отключайте, только если касса не принимает наличные.',
        ok: 'Всё равно отключить',
        destructive: true);
  }

  Future<bool> _confirmNegative(BuildContext context, bool on) async {
    if (!on) return true;
    return confirm(context,
        title: 'Разрешить продажу при нулевом остатке?',
        message: 'Остаток сможет уйти в минус. Это удобно, если приход оформляют позже продажи, '
            'но скрывает пересорт и недостачи. Отрицательные остатки нужно регулярно '
            'исправлять приходом или инвентаризацией.',
        ok: 'Разрешить');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const {};
    final rounding = settings[SettingKeys.cashRounding] ?? 'none';
    final days = int.tryParse(ctl(SettingKeys.returnDays).text.trim());
    final defaults = defaultBanknotes(_cur);
    final parsed = parseBanknotes(ctl(SettingKeys.posBanknotes).text, _cur);
    final shown = parsed.ok && parsed.values.isNotEmpty ? parsed.values : defaults;

    return buildForm(
      title: 'Продажи',
      description: 'Правила, которые касса проверяет при каждой продаже и возврате.',
      children: [
        TileCard(title: 'Контроль', children: [
          SettingSwitch(
            settingKey: SettingKeys.requireShift,
            defaultOn: true,
            icon: Icons.schedule,
            title: 'Продавать только при открытой смене',
            subtitle: 'Рекомендуется: контроль наличных и Z-отчёт по каждой смене',
            confirmChange: _confirmShift,
          ),
          SettingSwitch(
            settingKey: SettingKeys.allowNegativeStock,
            icon: Icons.inventory_2_outlined,
            title: 'Разрешить продажу при нулевом остатке',
            subtitle: 'Остаток может уйти в минус (для всех товаров)',
            confirmChange: _confirmNegative,
          ),
          const SettingSwitch(
            settingKey: SettingKeys.debtRequiresLimit,
            icon: Icons.credit_score_outlined,
            title: 'В долг — только клиентам с лимитом',
            subtitle: 'Продажа в долг клиенту без установленного лимита будет запрещена',
          ),
        ]),
        SectionCard(
          title: 'Возвраты',
          child: TextFormField(
            controller: ctl(SettingKeys.returnDays),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Срок возврата, дней',
              suffixText: 'дн.',
              helperText: days == 0
                  ? 'Без ограничения срока'
                  : 'Возврат по чеку возможен в течение ${days ?? '…'} дней. 0 — без ограничения',
            ),
            validator: validateReturnDays,
            onFieldSubmitted: (_) => save(),
          ),
        ),
        SectionCard(
          title: 'Быстрая оплата наличными',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: ctl(SettingKeys.posBanknotes),
              decoration: InputDecoration(
                labelText: 'Номиналы купюр на экране оплаты',
                hintText: defaults.map((v) => Money.toInput(v, c: _cur)).join(', '),
                helperText: 'Через запятую, до $maxBanknotes штук. Пусто — стандартный набор',
                suffixText: _cur.symbol,
              ),
              validator: (v) => parseBanknotes(v ?? '', _cur).error,
              onFieldSubmitted: (_) => save(),
            ),
            const SizedBox(height: Gap.m),
            Text('Кнопки на кассе:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Gap.xs),
            Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
              for (final v in shown) Chip(label: Text(Money.format(v, withSymbol: false, c: _cur))),
            ]),
          ]),
        ),
        SectionCard(
          title: 'Округление наличных',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<String>(
              key: ValueKey('rounding-$rounding'),
              initialValue: cashRoundingOptions.contains(rounding) ? rounding : 'none',
              decoration: const InputDecoration(labelText: 'Округлять итог при оплате наличными'),
              items: [
                for (final o in cashRoundingOptions)
                  DropdownMenuItem(value: o, child: Text(cashRoundingLabel(o, _cur))),
              ],
              onChanged: (v) {
                if (v == null) return;
                runGuarded(context, () => applySettings(ref, {SettingKeys.cashRounding: v}),
                    success: 'Округление: ${cashRoundingLabel(v, _cur).toLowerCase()}');
              },
            ),
            const SizedBox(height: Gap.s),
            InfoBanner(
              text: rounding == 'none'
                  ? 'Итог к оплате наличными не округляется.'
                  : 'Пример: ${Money.format(_roundingSample, c: _cur)} → '
                      '${Money.format(roundCash(_roundingSample, int.tryParse(rounding) ?? 0), c: _cur)}. '
                      'Применяется только к наличной оплате; безналичные платежи не округляются.',
              color: AppColors.info,
            ),
          ]),
        ),
      ],
    );
  }
}
