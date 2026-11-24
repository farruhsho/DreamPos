import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
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
    final preview = {...settings, for (final k in formKeys) k: ctl(k).text};
    final l = context.l10n;

    final fields = Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: ctl(SettingKeys.storeName),
              // Keyboard would pop up on phones/tablets on opening the section.
              autofocus: context.isWide,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: l.settingsStoreName,
                helperMaxLines: 3,
                helperText: l.settingsStoreNameHelper,
              ),
              validator: validateStoreName,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => save(),
            ),
            const SizedBox(height: Gap.m),
            TextFormField(
              controller: ctl(SettingKeys.storeAddress),
              maxLength: 160,
              decoration: InputDecoration(labelText: l.commonAddress, hintText: l.settingsAddressHint),
              onFieldSubmitted: (_) => save(),
            ),
            const SizedBox(height: Gap.m),
            TextFormField(
              controller: ctl(SettingKeys.storePhone),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l.commonPhone, hintText: '+998 90 123-45-67'),
              validator: validatePhone,
              onFieldSubmitted: (_) => save(),
            ),
            const SizedBox(height: Gap.m),
            TextFormField(
              controller: ctl(SettingKeys.storeTaxId),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.settingsTaxId,
                helperMaxLines: 3,
                helperText: l.settingsTaxIdHelper,
              ),
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
              decoration: InputDecoration(
                labelText: l.settingsFooter,
                hintText: l.settingsFooterHint,
                alignLabelWithHint: true,
              ),
              validator: validateReceiptFooter,
            ),
          ],
        ),
      ),
    );

    final receiptOptions = TileCard(
      title: l.commonReceipt,
      children: [
        ListTile(
          leading: const Icon(Icons.straighten),
          title: Text(l.settingsPaperWidth),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.settingsPaperWidthHint),
              const SizedBox(height: Gap.s),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: '58', label: Text(l.settingsMm('58'))),
                  ButtonSegment(value: '80', label: Text(l.settingsMm('80'))),
                ],
                selected: {width},
                onSelectionChanged: (v) =>
                    runGuarded(context, () => applySettings(ref, {SettingKeys.receiptWidthMm: v.first})),
              ),
            ],
          ),
        ),
        SettingSwitch(
          settingKey: SettingKeys.autoPrintReceipt,
          icon: Icons.print_outlined,
          title: l.settingsAutoPrint,
          subtitle: l.settingsAutoPrintHint,
        ),
        // l10n foundation: receipt language picker (store setting receipt_locale)
        const ReceiptLanguageTile(),
      ],
    );

    final previewCard = _ReceiptPreview(
      text: sampleReceiptText(preview, width: receiptCharsForWidth(width)),
      widthMm: width,
    );

    return buildForm(
      title: l.settingsSecStore,
      description: l.settingsStoreDesc,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        fields,
                        const SizedBox(height: Gap.l),
                        receiptOptions,
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.l),
                  SizedBox(width: 370, child: previewCard),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fields,
                const SizedBox(height: Gap.l),
                receiptOptions,
                const SizedBox(height: Gap.l),
                previewCard,
              ],
            );
          },
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.settingsReceiptSample,
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(context.l10n.settingsMm(widthMm), style: t.textTheme.bodySmall),
              ],
            ),
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
                    style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 12, height: 1.3, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
