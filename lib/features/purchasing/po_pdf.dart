import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/widgets/widgets.dart' show formatDate;
import 'purchasing_logic.dart';

/// Purchase order document (A4) to send to the supplier.
Future<Uint8List> buildPoPdf({
  required PurchaseOrder order,
  required Supplier supplier,
  required List<PurchaseOrderItem> items,
  required Map<String, Product> products,
  required Map<String, String> settings,
  pw.ThemeData? theme,
}) async {
  final doc = pw.Document(theme: theme ?? await PdfFonts.theme());
  final cur = CurrencyConfig.fromSettings(settings);
  String money(int v) => Money.format(v, c: cur);
  const small = pw.TextStyle(fontSize: 9);
  final store = settings['store_name'] ?? 'DreamPOS';
  final showReceived = items.any((i) => i.receivedQty > 0);
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (_) => [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Заказ поставщику №${order.number}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('от ${formatDate(order.createdAt)} · ${poStatusLabels[order.status] ?? order.status}', style: small),
          if (order.expectedAt != null) pw.Text('Ожидаемая дата поставки: ${formatDate(order.expectedAt!)}', style: small),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(store, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if ((settings['store_address'] ?? '').isNotEmpty) pw.Text(settings['store_address']!, style: small),
          if ((settings['store_phone'] ?? '').isNotEmpty) pw.Text(settings['store_phone']!, style: small),
        ]),
      ]),
      pw.SizedBox(height: 16),
      pw.Text('Поставщик: ${supplier.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      if (supplier.contactPerson != null || supplier.phone != null)
        pw.Text([?supplier.contactPerson, ?supplier.phone].join(', '), style: small),
      if (supplier.taxId != null) pw.Text('ИНН ${supplier.taxId}', style: small),
      if (supplier.address != null) pw.Text(supplier.address!, style: small),
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        cellStyle: small,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        columnWidths: {
          0: const pw.FixedColumnWidth(22),
          1: const pw.FlexColumnWidth(5),
          2: const pw.FlexColumnWidth(2),
        },
        cellAlignments: {
          0: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
          5: pw.Alignment.centerRight,
          6: pw.Alignment.centerRight,
        },
        headers: ['№', 'Товар', 'Штрихкод / арт.', 'Кол-во', if (showReceived) 'Получено', 'Цена', 'Сумма'],
        data: [
          for (var i = 0; i < items.length; i++)
            () {
              final it = items[i];
              final p = products[it.productId];
              return [
                '${i + 1}',
                p?.name ?? '—',
                p?.barcode ?? p?.sku ?? '',
                Qty.format(it.qty, p?.unit ?? 'pcs'),
                if (showReceived) Qty.format(it.receivedQty),
                money(it.unitCost),
                money((it.qty * it.unitCost).round()),
              ];
            }(),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Итого: ${money(items.fold(0, (s, i) => s + (i.qty * i.unitCost).round()))}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ),
      if (order.note != null) ...[pw.SizedBox(height: 12), pw.Text('Примечание: ${order.note}', style: small)],
      pw.SizedBox(height: 32),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Заказал: ____________________', style: small),
        pw.Text('Поставщик: ____________________', style: small),
      ]),
    ],
  ));
  return doc.save();
}

Future<Uint8List> _load(AppDatabase db, String orderId) async {
  final o = await (db.select(db.purchaseOrders)..where((t) => t.id.equals(orderId))).getSingle();
  final s = await (db.select(db.suppliers)..where((t) => t.id.equals(o.supplierId))).getSingle();
  final items = await (db.select(db.purchaseOrderItems)..where((i) => i.orderId.equals(orderId))).get();
  final ps = await (db.select(db.products)..where((p) => p.id.isIn(items.map((i) => i.productId)))).get();
  final settings = {for (final r in await db.select(db.settings).get()) r.key: r.value};
  return buildPoPdf(
      order: o, supplier: s, items: items, products: {for (final p in ps) p.id: p}, settings: settings);
}

Future<void> printPo(AppDatabase db, PurchaseOrder o) => Printing.layoutPdf(
    name: 'Заказ поставщику ${o.number}', format: PdfPageFormat.a4, onLayout: (_) => _load(db, o.id));

Future<void> sharePo(AppDatabase db, PurchaseOrder o) async =>
    Printing.sharePdf(bytes: await _load(db, o.id), filename: 'zakaz_${o.number}.pdf');
