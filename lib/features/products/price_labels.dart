import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'product_logic.dart';
import 'products_repo.dart';

/// A4 label grid presets.
enum LabelLayout {
  small(4, 10, 'Маленькие 4×10 (52×29 мм)'),
  medium(3, 8, 'Средние 3×8 (70×37 мм)'),
  large(2, 5, 'Крупные 2×5 (105×59 мм)');

  const LabelLayout(this.cols, this.rows, this.label);
  final int cols;
  final int rows;
  final String label;
  int get perPage => cols * rows;
}

/// Picks a symbology the scanner will read back as the same code.
pw.Barcode? labelBarcode(String? code) {
  if (code == null || code.isEmpty) return null;
  if (Ean13.isValid(code)) return pw.Barcode.ean13();
  if (Ean13.isValidEan8(code)) return pw.Barcode.ean8();
  if (code.codeUnits.every((c) => c >= 32 && c < 127)) return pw.Barcode.code128();
  return null; // non-ASCII: cannot be encoded
}

/// Builds the price label PDF. [fonts] can be injected in tests.
Future<Uint8List> buildPriceLabelsPdf(
  List<Product> products, {
  LabelLayout layout = LabelLayout.medium,
  int copies = 1,
  bool showBarcode = true,
  String? storeName,
  DateTime? date,
  CurrencyConfig? currency,
  pw.ThemeData? theme,
}) async {
  final th = theme ?? await PdfFonts.theme();
  final doc = pw.Document(theme: th, title: 'Ценники', author: 'DreamPOS');
  final labels = [for (final p in products) for (var i = 0; i < copies; i++) p];
  final d = date ?? DateTime.now();
  final dateStr = formatDate(d);
  const margin = 6 * PdfPageFormat.mm;
  final pageW = PdfPageFormat.a4.width - 2 * margin;
  final pageH = PdfPageFormat.a4.height - 2 * margin;
  final w = pageW / layout.cols;
  final h = pageH / layout.rows;
  final big = layout == LabelLayout.large;
  final small = layout == LabelLayout.small;

  pw.Widget label(Product p) {
    final bc = showBarcode ? labelBarcode(p.barcode) : null;
    final perUnit = p.unit == 'pcs' ? '' : ' / ${Qty.unitLabel(p.unit)}';
    return pw.Container(
      width: w,
      height: h,
      padding: pw.EdgeInsets.all(small ? 3 : 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.4, style: pw.BorderStyle.dashed),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        if (storeName != null && storeName.isNotEmpty && !small)
          pw.Text(storeName,
              maxLines: 1, style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
        pw.Text(p.name,
            maxLines: small ? 2 : 3,
            style: pw.TextStyle(fontSize: big ? 12 : (small ? 7 : 9), fontWeight: pw.FontWeight.bold)),
        pw.Spacer(),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Expanded(
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              alignment: pw.Alignment.centerLeft,
              child: pw.Text('${Money.format(p.price, c: currency)}$perUnit',
                  style: pw.TextStyle(fontSize: big ? 30 : (small ? 14 : 20), fontWeight: pw.FontWeight.bold)),
            ),
          ),
        ]),
        pw.SizedBox(height: 2),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          if (bc != null)
            pw.Expanded(
              child: pw.BarcodeWidget(
                barcode: bc,
                data: p.barcode!,
                height: big ? 34 : (small ? 18 : 24),
                drawText: true,
                textStyle: pw.TextStyle(font: th.defaultTextStyle.font, fontSize: small ? 5 : 6),
              ),
            )
          else
            pw.Expanded(
              child: pw.Text(p.sku == null ? '' : 'арт. ${p.sku}', style: const pw.TextStyle(fontSize: 6)),
            ),
          pw.SizedBox(width: 4),
          pw.Text(dateStr, style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey700)),
        ]),
      ]),
    );
  }

  for (var start = 0; start < labels.length; start += layout.perPage) {
    final chunk = labels.sublist(start, (start + layout.perPage).clamp(0, labels.length));
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: th,
      margin: const pw.EdgeInsets.all(margin),
      build: (_) => pw.Wrap(children: [for (final p in chunk) label(p)]),
    ));
  }
  return doc.save();
}

/// Options dialog + print preview for price labels of [ids].
Future<void> showPriceLabelsDialog(BuildContext context, Set<String> ids) =>
    showFormDialog<void>(context, title: 'Печать ценников', width: 520, child: _LabelsDialog(ids: ids));

class _LabelsDialog extends ConsumerStatefulWidget {
  const _LabelsDialog({required this.ids});
  final Set<String> ids;
  @override
  ConsumerState<_LabelsDialog> createState() => _LabelsDialogState();
}

class _LabelsDialogState extends ConsumerState<_LabelsDialog> {
  LabelLayout _layout = LabelLayout.medium;
  final _copies = TextEditingController(text: '1');
  bool _barcode = true;
  bool _busy = false;

  @override
  void dispose() {
    _copies.dispose();
    super.dispose();
  }

  Future<void> _print() async {
    if (_busy) return;
    final copies = int.tryParse(_copies.text.trim()) ?? 0;
    if (copies < 1 || copies > 100) {
      showError(context, 'Количество копий — от 1 до 100');
      return;
    }
    setState(() => _busy = true);
    try {
      final products = await ref.read(productsRepoProvider).byIds(widget.ids);
      final store = ref.read(settingProvider('store_name'));
      final bytes = await buildPriceLabelsPdf(products,
          layout: _layout, copies: copies, showBarcode: _barcode, storeName: store);
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'Ценники');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copies = int.tryParse(_copies.text.trim()) ?? 0;
    final total = widget.ids.length * (copies < 1 ? 0 : copies);
    final pages = (total / _layout.perPage).ceil();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.s, Gap.xl, Gap.l),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Товаров: ${widget.ids.length}. Формат A4, линии реза пунктиром.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: Gap.m),
        Text('Размер ценника', style: Theme.of(context).textTheme.titleSmall),
        RadioGroup<LabelLayout>(
          groupValue: _layout,
          onChanged: (v) => setState(() => _layout = v ?? _layout),
          child: Column(children: [
            for (final l in LabelLayout.values)
              RadioListTile<LabelLayout>(
                value: l,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                title: Text(l.label),
              ),
          ]),
        ),
        const SizedBox(height: Gap.s),
        Row(children: [
          SizedBox(
            width: 160,
            child: TextField(
              controller: _copies,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Копий каждого'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _print(),
            ),
          ),
          const SizedBox(width: Gap.l),
          Expanded(
            child: Text('Всего ценников: $total\nСтраниц A4: $pages',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _barcode,
          onChanged: (v) => setState(() => _barcode = v),
          title: const Text('Печатать штрихкод'),
        ),
        const SizedBox(height: Gap.m),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          const SizedBox(width: Gap.s),
          FilledButton.icon(
            autofocus: true,
            onPressed: _busy || total == 0 ? null : _print,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print_outlined),
            label: const Text('Печать'),
          ),
        ]),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: Gap.s),
            child: Text('Готовим PDF…', style: TextStyle(color: AppColors.info)),
          ),
      ]),
    );
  }
}
