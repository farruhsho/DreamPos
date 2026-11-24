// Return slip ("Акт возврата") — a small PDF the customer signs.
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/widgets/widgets.dart' show formatDateTime;
import '../../domain/services/sale_service.dart' show paymentMethodLabel;

class ReturnSlipData {
  ReturnSlipData({
    required this.ret,
    required this.sale,
    required this.lines,
    required this.settings,
    this.userName,
    this.customerName,
  });
  final Return ret;
  final Sale sale;

  /// (product name, qty, amount, unit)
  final List<(String, double, int, String?)> lines;
  final Map<String, String> settings;
  final String? userName;
  final String? customerName;

  static Future<ReturnSlipData> load(AppDatabase db, String returnId) async {
    final ret = await (db.select(db.returns)..where((r) => r.id.equals(returnId))).getSingle();
    final sale = await (db.select(db.sales)..where((s) => s.id.equals(ret.saleId))).getSingle();
    final items = await (db.select(db.returnItems)..where((i) => i.returnId.equals(returnId))).get();
    final saleItems = await (db.select(db.saleItems)..where((i) => i.saleId.equals(sale.id))).get();
    final names = {for (final s in saleItems) s.id: s.productName};
    final productIds = items.map((i) => i.productId).toSet();
    final units = {
      for (final p in await (db.select(db.products)..where((p) => p.id.isIn(productIds))).get()) p.id: p.unit,
    };
    final settings = {for (final s in await db.select(db.settings).get()) s.key: s.value};
    final user = ret.userId == null
        ? null
        : await (db.select(db.users)..where((u) => u.id.equals(ret.userId!))).getSingleOrNull();
    final customer = sale.customerId == null
        ? null
        : await (db.select(db.customers)..where((c) => c.id.equals(sale.customerId!))).getSingleOrNull();
    return ReturnSlipData(
      ret: ret,
      sale: sale,
      lines: [for (final i in items) (names[i.saleItemId] ?? '—', i.qty, i.amount, units[i.productId])],
      settings: settings,
      userName: user?.name,
      customerName: customer?.name,
    );
  }
}

Future<Uint8List> buildReturnSlipPdf(ReturnSlipData d) async {
  final theme = await PdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final store = d.settings['store_name'] ?? 'DreamPOS';
  pw.Widget kv(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(k, style: const pw.TextStyle(color: PdfColors.grey700)),
        ),
        pw.Expanded(child: pw.Text(v)),
      ],
    ),
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(store, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          if ((d.settings['store_address'] ?? '').isNotEmpty) pw.Text(d.settings['store_address']!),
          if ((d.settings['store_phone'] ?? '').isNotEmpty) pw.Text('Тел: ${d.settings['store_phone']}'),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              'АКТ ВОЗВРАТА ТОВАРА №${d.ret.number}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          kv('Дата', formatDateTime(d.ret.createdAt)),
          kv('По чеку', '№${d.sale.number} от ${formatDateTime(d.sale.createdAt)}'),
          if (d.customerName != null) kv('Покупатель', d.customerName!),
          kv('Способ возврата', paymentMethodLabel(d.ret.refundMethod)),
          kv('Причина', d.ret.reason ?? '—'),
          kv('На склад', d.ret.restock ? 'да' : 'нет (брак / не подлежит продаже)'),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Товар', 'Кол-во', 'Сумма'],
            data: [
              for (final l in d.lines) [l.$1, Qty.format(l.$2, l.$4), Money.format(l.$3)],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
            },
          ),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Итого к возврату: ${Money.format(d.ret.total)}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Spacer(),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Выдал: ${d.userName ?? ''} ____________')),
              pw.SizedBox(width: 12),
              pw.Expanded(child: pw.Text('Получил: ____________')),
            ],
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

Future<void> printReturnSlip(AppDatabase db, String returnId) async {
  final data = await ReturnSlipData.load(db, returnId);
  await Printing.layoutPdf(
    name: 'Возврат ${data.ret.number}',
    format: PdfPageFormat.a5,
    onLayout: (_) => buildReturnSlipPdf(data),
  );
}
