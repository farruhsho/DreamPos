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
import '../../../l10n/l10n.dart';
import '../settings_logic.dart';
import '../settings_providers.dart';
import '../settings_widgets.dart';

/// «Кассы и устройства».
class DevicesSection extends ConsumerWidget {
  const DevicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionView(
      title: context.l10n.settingsSecDevices,
      description: context.l10n.settingsDevicesDesc,
      children: const [_RegistersCard(), _ThisDeviceCard(), _PrinterCard(), _ScannerTipsCard()],
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
      () => upsertRegister(
        ref.read(databaseProvider),
        id: r?.id,
        name: result.$1,
        isActive: result.$2,
        userId: currentUserId(ref),
      ),
      success: r == null ? context.l10n.settingsRegisterAdded(result.$1) : context.l10n.settingsRegisterSaved,
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Register r) async {
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.settingsRegisterDeleteTitle(r.name),
      message: l.settingsRegisterDeleteMessage,
      ok: l.commonDelete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final bound = ref.read(deviceRegisterProvider).value == r.id;
    await runGuarded(context, () async {
      await deleteRegister(ref.read(databaseProvider), r, userId: currentUserId(ref));
      if (bound) await ref.read(deviceRegisterProvider.notifier).set(null);
    }, success: context.l10n.settingsRegisterDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regs = ref.watch(registersProvider);
    final all = regs.value ?? const <Register>[];
    final deviceId = ref.watch(deviceRegisterProvider).value;
    final l = context.l10n;
    return SectionCard(
      title: l.settingsRegisters,
      trailing: FilledButton.tonalIcon(
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        onPressed: regs.hasValue ? () => _edit(context, ref, all) : null,
        icon: const Icon(Icons.add),
        label: Text(l.commonAdd),
      ),
      child: AsyncView(
        value: regs,
        onRetry: () => ref.invalidate(registersProvider),
        data: (list) => list.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.m),
                child: Text(l.settingsNoRegisters),
              )
            : Column(
                children: [
                  for (final r in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.point_of_sale,
                        color: r.isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                      ),
                      title: Text(r.name),
                      subtitle: r.isActive && r.id != deviceId
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: Gap.xs),
                              child: Wrap(
                                spacing: Gap.s,
                                runSpacing: Gap.xs,
                                children: [
                                  if (!r.isActive) StatusChip(l.settingsRegisterDisabled, color: AppColors.warning),
                                  if (r.id == deviceId) StatusChip(l.settingsThisDevice, color: AppColors.success),
                                ],
                              ),
                            ),
                      onTap: () => _edit(context, ref, list, r),
                      trailing: PopupMenuButton<String>(
                        tooltip: l.commonActions,
                        onSelected: (v) => switch (v) {
                          'edit' => _edit(context, ref, list, r),
                          _ => _delete(context, ref, r),
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(l.commonEdit)),
                          PopupMenuItem(value: 'delete', child: Text(l.commonDelete)),
                        ],
                      ),
                    ),
                ],
              ),
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
    text: widget.register?.name ?? L.current.settingsRegisterDefaultName('${widget.existing.length + 1}'),
  );
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
    title: Text(widget.register == null ? context.l10n.settingsNewRegister : context.l10n.settingsRegister),
    content: SizedBox(
      width: 380,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.commonName,
                hintText: context.l10n.settingsRegisterNameHint,
              ),
              validator: (v) => validateRegisterName(v, widget.existing, selfId: widget.register?.id),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Gap.s),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.settingsRegisterActive),
              subtitle: Text(context.l10n.settingsRegisterActiveHint),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonCancel)),
      FilledButton(onPressed: _submit, child: Text(context.l10n.commonSave)),
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
    final l = context.l10n;
    return SectionCard(
      title: l.settingsThisDevice,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.settingsThisDeviceHint,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Gap.m),
          if (device.isLoading)
            const LinearProgressIndicator()
          else if (active.isEmpty)
            InfoBanner(text: l.settingsAddRegisterFirst)
          else
            NarrowField(
              maxWidth: 480,
              child: DropdownButtonFormField<String>(
                key: ValueKey('device-$current-${active.length}'),
                initialValue: valid ? current : null,
                decoration: InputDecoration(labelText: l.settingsDeviceRegister),
                hint: Text(l.settingsNotSelected),
                items: [for (final r in active) DropdownMenuItem(value: r.id, child: Text(r.name))],
                onChanged: (id) => runGuarded(context, () async {
                  await ref.read(deviceRegisterProvider.notifier).set(id);
                  await ref
                      .read(databaseProvider)
                      .audit('register.bind_device', userId: currentUserId(ref), entity: 'registers', entityId: id);
                }, success: l.settingsDeviceRegisterSet),
              ),
            ),
          if (current != null && !valid && active.isNotEmpty) ...[
            const SizedBox(height: Gap.s),
            InfoBanner(color: AppColors.warning, icon: Icons.warning_amber, text: l.settingsDeviceRegisterGone),
          ],
        ],
      ),
    );
  }
}

/// Builds a short test receipt PDF (also used by tests).
Future<Uint8List> buildTestReceiptPdf(Map<String, String> settings, {DateTime? now}) async {
  final widthMm = settings[SettingKeys.receiptWidthMm] == '58' ? 58.0 : 80.0;
  final font = await PdfFonts.mono();
  final rl = L.forReceipt(settings);
  final text = sampleReceiptText(
    settings,
    width: receiptCharsForWidth(settings[SettingKeys.receiptWidthMm]),
    now: now,
    title: L.printable(rl.settingsTestPrintTitle),
  );
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(widthMm * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            text,
            style: pw.TextStyle(font: font, fontSize: widthMm >= 80 ? 8 : 7),
          ),
          pw.Text(L.printable(rl.settingsNotFiscal), style: pw.TextStyle(font: font, fontSize: 7)),
        ],
      ),
    ),
  );
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
        name: context.l10n.settingsTestReceiptJob,
        format: PdfPageFormat(widthMm * PdfPageFormat.mm, double.infinity),
        onLayout: (_) => buildTestReceiptPdf(settings),
      );
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(settingProvider(SettingKeys.receiptWidthMm)) == '58' ? '58' : '80';
    final l = context.l10n;
    return SectionCard(
      title: l.settingsPrinter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.settingsPrinterHint(w), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: Gap.m),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _print,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.print_outlined),
              label: Text(l.settingsPrintTest),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerTipsCard extends StatelessWidget {
  const _ScannerTipsCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tips = [
      l.settingsScannerTip1,
      l.settingsScannerTip2,
      l.settingsScannerTip3,
      l.settingsScannerTip4,
      l.settingsScannerTip5,
    ];
    final t = Theme.of(context);
    return SectionCard(
      title: l.settingsScanner,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, s) in tips.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: t.colorScheme.primaryContainer,
                    child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: t.colorScheme.onPrimaryContainer)),
                  ),
                  const SizedBox(width: Gap.m),
                  Expanded(child: Text(s)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
