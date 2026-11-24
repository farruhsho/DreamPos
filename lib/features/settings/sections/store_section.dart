import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../settings_logic.dart';
import '../settings_widgets.dart';

/// «Магазин»: store requisites printed on the receipt + receipt options.
class StoreSection extends ConsumerStatefulWidget {
  const StoreSection({super.key});

  @override
  ConsumerState<StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends ConsumerState<StoreSection> with SettingsFormMixin {
  @override
  List<String> get formKeys => const [
        SettingKeys.storeName,
        SettingKeys.storeAddress,
        SettingKeys.storePhone,
        SettingKeys.storeTaxId,
        SettingKeys.receiptFooter,
      ];

  @override
  String toStored(String key, String display) =>
      key == SettingKeys.receiptFooter ? display.trimRight() : display.trim();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const {};
    final width = settings[SettingKeys.receiptWidthMm] == '58' ? '58' : '80';
    final preview = {
      ...settings,
      for (final k in formKeys) k: ctl(k).text,
    };

    final fields = Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: ctl(SettingKeys.storeName),
            autofocus: true,
            maxLength: 120,
            decoration: const InputDecoration(
                labelText: 'Название магазина *', helperText: 'Печатается в шапке чека и на экране входа'),
            validator: validateStoreName,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => save(),
          ),
          const SizedBox(height: Gap.m),
          TextFormField(
            controller: ctl(SettingKeys.storeAddress),
            maxLength: 160,
            decoration: const InputDecoration(labelText: 'Адрес', hintText: 'г. Ташкент, ул. Навои, 12'),
            onFieldSubmitted: (_) => save(),
          ),
          const SizedBox(height: Gap.m),
          TextFormField(
            controller: ctl(SettingKeys.storePhone),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Телефон', hintText: '+998 90 123-45-67'),
            validator: validatePhone,
            onFieldSubmitted: (_) => save(),
          ),
          const SizedBox(height: Gap.m),
          TextFormField(
            controller: ctl(SettingKeys.storeTaxId),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'ИНН / БИН', helperText: 'Только цифры, 9–14 знаков'),
            validator: validateTaxId,
            onFieldSubmitted: (_) => save(),
          ),
          const SizedBox(height: Gap.m),
          TextFormField(
            controller: ctl(SettingKeys.receiptFooter),
            minLines: 2,
            maxLines: 6,
            maxLength: 300,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'Текст внизу чека',
              hintText: 'Спасибо за покупку!\nОбмен и возврат в течение 14 дней',
              alignLabelWithHint: true,
            ),
            validator: validateReceiptFooter,
          ),
        ]),
      ),
    );

    final receiptOptions = TileCard(title: 'Чек', children: [
      ListTile(
        leading: const Icon(Icons.straighten),
        title: const Text('Ширина ленты'),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Смотрите в инструкции принтера: 58 мм — компактные, 80 мм — стандарт'),
          const SizedBox(height: Gap.s),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: '58', label: Text('58 мм')),
              ButtonSegment(value: '80', label: Text('80 мм')),
            ],
            selected: {width},
            onSelectionChanged: (v) => runGuarded(
                context, () => applySettings(ref, {SettingKeys.receiptWidthMm: v.first})),
          ),
        ]),
      ),
      const SettingSwitch(
        settingKey: SettingKeys.autoPrintReceipt,
        icon: Icons.print_outlined,
        title: 'Печатать чек автоматически',
        subtitle: 'Сразу после оплаты, без вопроса кассиру',
      ),
      ListTile(
        enabled: false,
        leading: const Icon(Icons.image_outlined),
        title: const Text('Логотип на чеке'),
        subtitle: const Text('Появится в следующих версиях'),
      ),
    ]);

    final previewCard = _ReceiptPreview(
      text: sampleReceiptText(preview, width: receiptCharsForWidth(width)),
      widthMm: width,
    );

    return buildForm(
      title: 'Магазин',
      description: 'Реквизиты магазина и оформление чека. Изменения в чеке видны справа сразу.',
      children: [
        LayoutBuilder(builder: (context, c) {
          if (c.maxWidth >= 760) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(children: [fields, const SizedBox(height: Gap.l), receiptOptions])),
              const SizedBox(width: Gap.l),
              SizedBox(width: 330, child: previewCard),
            ]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            fields,
            const SizedBox(height: Gap.l),
            receiptOptions,
            const SizedBox(height: Gap.l),
            previewCard,
          ]);
        }),
      ],
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.text, required this.widthMm});
  final String text;
  final String widthMm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text('Образец чека',
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            Text('$widthMm мм', style: t.textTheme.bodySmall),
          ]),
          const SizedBox(height: Gap.m),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.l),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6)],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text.trimRight(),
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontFamilyFallback: ['Consolas', 'Courier New', 'RobotoMono'],
                      fontSize: 11,
                      height: 1.3,
                      color: Colors.black87),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
