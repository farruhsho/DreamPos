import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/db/database.dart';
import '../../../core/printing/pdf_fonts.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../settings_logic.dart';
import '../settings_providers.dart';
import '../settings_widgets.dart';

/// «Кассы и устройства».
class DevicesSection extends ConsumerWidget {
  const DevicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SectionView(
      title: 'Кассы и устройства',
      description: 'Кассовые места магазина, привязка этого компьютера к кассе, сканер и принтер чеков.',
      children: [_RegistersCard(), _ThisDeviceCard(), _PrinterCard(), _ScannerTipsCard()],
    );
  }
}

class _RegistersCard extends ConsumerWidget {
  const _RegistersCard();

  Future<void> _edit(BuildContext context, WidgetRef ref, List<Register> all, [Register? r]) async {
    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (_) => _RegisterDialog(existing: all, register: r),
    );
    if (result == null || !context.mounted) return;
    await runGuarded(
        context,
        () => upsertRegister(ref.read(databaseProvider),
            id: r?.id, name: result.$1, isActive: result.$2, userId: currentUserId(ref)),
        success: r == null ? 'Касса «${result.$1}» добавлена' : 'Касса сохранена');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Register r) async {
    final ok = await confirm(context,
        title: 'Удалить кассу «${r.name}»?',
        message: 'Касса исчезнет из списка. Проданные на ней чеки и отчёты сохранятся.',
        ok: 'Удалить',
        destructive: true);
    if (!ok || !context.mounted) return;
    final bound = ref.read(deviceRegisterProvider).value == r.id;
    await runGuarded(context, () async {
      await deleteRegister(ref.read(databaseProvider), r, userId: currentUserId(ref));
      if (bound) await ref.read(deviceRegisterProvider.notifier).set(null);
    }, success: 'Касса удалена');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regs = ref.watch(registersProvider);
    final all = regs.value ?? const <Register>[];
    final deviceId = ref.watch(deviceRegisterProvider).value;
    return SectionCard(
      title: 'Кассы',
      trailing: FilledButton.tonalIcon(
        onPressed: regs.hasValue ? () => _edit(context, ref, all) : null,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      child: AsyncView(
        value: regs,
        onRetry: () => ref.invalidate(registersProvider),
        data: (list) => list.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: Gap.m),
                child: Text('Касс пока нет. Добавьте кассу, если в магазине несколько кассовых мест — '
                    'тогда в отчётах будет видно, где пробит чек.'),
              )
            : Column(children: [
                for (final r in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.point_of_sale,
                        color: r.isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor),
                    title: Text(r.name),
                    subtitle: Wrap(spacing: Gap.s, runSpacing: Gap.xs, children: [
                      if (!r.isActive) const StatusChip('Отключена', color: AppColors.warning),
                      if (r.id == deviceId) const StatusChip('Этот компьютер', color: AppColors.success),
                    ]),
                    onTap: () => _edit(context, ref, list, r),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Действия',
                      onSelected: (v) => switch (v) {
                        'edit' => _edit(context, ref, list, r),
                        _ => _delete(context, ref, r),
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Изменить')),
                        PopupMenuItem(value: 'delete', child: Text('Удалить')),
                      ],
                    ),
                  ),
              ]),
      ),
    );
  }
}

class _RegisterDialog extends StatefulWidget {
  const _RegisterDialog({required this.existing, this.register});
  final List<Register> existing;
  final Register? register;

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
      text: widget.register?.name ?? 'Касса ${widget.existing.length + 1}');
  late bool _active = widget.register?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, (_name.text.trim(), _active));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.register == null ? 'Новая касса' : 'Касса'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Название', hintText: 'Касса 1, Склад, Отдел №2'),
                validator: (v) => validateRegisterName(v, widget.existing, selfId: widget.register?.id),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Gap.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Активна'),
                subtitle: const Text('Отключённую кассу нельзя выбрать для работы'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: _submit, child: const Text('Сохранить')),
        ],
      );
}

class _ThisDeviceCard extends ConsumerWidget {
  const _ThisDeviceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regs = ref.watch(registersProvider).value ?? const <Register>[];
    final device = ref.watch(deviceRegisterProvider);
    final active = regs.where((r) => r.isActive).toList();
    final current = device.value;
    final valid = active.any((r) => r.id == current);
    return SectionCard(
      title: 'Этот компьютер',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          'Выберите, какой кассой работает это устройство. Настройка хранится только на этом '
          'компьютере и не переносится на другие.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Gap.m),
        if (device.isLoading)
          const LinearProgressIndicator()
        else if (active.isEmpty)
          const InfoBanner(text: 'Сначала добавьте хотя бы одну активную кассу.')
        else
          DropdownButtonFormField<String>(
            key: ValueKey('device-$current-${active.length}'),
            initialValue: valid ? current : null,
            decoration: const InputDecoration(labelText: 'Касса этого устройства'),
            hint: const Text('Не выбрана'),
            items: [
              for (final r in active) DropdownMenuItem(value: r.id, child: Text(r.name)),
            ],
            onChanged: (id) => runGuarded(context, () async {
              await ref.read(deviceRegisterProvider.notifier).set(id);
              await ref.read(databaseProvider).audit('register.bind_device',
                  userId: currentUserId(ref), entity: 'registers', entityId: id);
            }, success: 'Касса для этого устройства выбрана'),
          ),
        if (current != null && !valid && active.isNotEmpty) ...[
          const SizedBox(height: Gap.s),
          const InfoBanner(
              color: AppColors.warning,
              icon: Icons.warning_amber,
              text: 'Ранее выбранная касса удалена или отключена — выберите другую.'),
        ],
      ]),
    );
  }
}

/// Builds a short test receipt PDF (also used by tests).
Future<Uint8List> buildTestReceiptPdf(Map<String, String> settings, {DateTime? now}) async {
  final widthMm = settings[SettingKeys.receiptWidthMm] == '58' ? 58.0 : 80.0;
  final font = await PdfFonts.mono();
  final text = sampleReceiptText(settings,
      width: receiptCharsForWidth(settings[SettingKeys.receiptWidthMm]),
      now: now,
      title: 'ТЕСТОВАЯ ПЕЧАТЬ');
  final doc = pw.Document();
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat(widthMm * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm),
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(text, style: pw.TextStyle(font: font, fontSize: widthMm >= 80 ? 8 : 7)),
      pw.Text('Не является фискальным документом',
          style: pw.TextStyle(font: font, fontSize: 7)),
    ]),
  ));
  return doc.save();
}

class _PrinterCard extends ConsumerStatefulWidget {
  const _PrinterCard();

  @override
  ConsumerState<_PrinterCard> createState() => _PrinterCardState();
}

class _PrinterCardState extends ConsumerState<_PrinterCard> {
  bool _busy = false;

  Future<void> _print() async {
    final settings = ref.read(settingsProvider).value ?? const {};
    final widthMm = settings[SettingKeys.receiptWidthMm] == '58' ? 58.0 : 80.0;
    setState(() => _busy = true);
    await runGuarded(context, () async {
      await Printing.layoutPdf(
        name: 'Тестовый чек',
        format: PdfPageFormat(widthMm * PdfPageFormat.mm, double.infinity),
        onLayout: (_) => buildTestReceiptPdf(settings),
      );
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(settingProvider(SettingKeys.receiptWidthMm)) == '58' ? '58' : '80';
    return SectionCard(
      title: 'Принтер чеков',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          'Чек печатается через системный диалог печати. Установите драйвер принтера и выберите '
          'его принтером по умолчанию. Ширина ленты сейчас: $w мм (меняется в разделе «Магазин»).',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Gap.m),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _print,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print_outlined),
            label: const Text('Напечатать тестовый чек'),
          ),
        ),
      ]),
    );
  }
}

class _ScannerTipsCard extends StatelessWidget {
  const _ScannerTipsCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Подключите USB‑сканер — он работает как клавиатура, драйвер обычно не нужен.',
      'Сканер должен отправлять Enter после кода (суффикс CR). Так настроено у большинства моделей.',
      'Раскладка клавиатуры: если вместо цифр печатаются другие символы, переключите раскладку на EN '
          'или настройте сканер на «цифровой» режим.',
      'Проверка: откройте поиск товара и отсканируйте штрихкод — код должен появиться целиком.',
      'Беспроводные сканеры работают так же; держите базу в пределах 10 м от кассы.',
    ];
    final t = Theme.of(context);
    return SectionCard(
      title: 'Сканер штрихкодов',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (i, s) in tips.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.s),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: t.colorScheme.primaryContainer,
                child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: t.colorScheme.onPrimaryContainer)),
              ),
              const SizedBox(width: Gap.m),
              Expanded(child: Text(s)),
            ]),
          ),
      ]),
    );
  }
}
