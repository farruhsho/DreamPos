// Return slip ("Акт возврата") — a small PDF the customer signs.
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/doc_number.dart';
import '../../core/money.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/widgets/widgets.dart' show formatDateTime;
import '../../domain/services/sale_service.dart' show paymentMethodLabel;
import '../../l10n/l10n.dart';

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
  // Customer document: printed in the receipt language (store setting).
  final l = L.forReceipt(d.settings);
  String p(String s) => L.printable(s);
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
          if ((d.settings['store_phone'] ?? '').isNotEmpty) pw.Text(p(l.corePrintPhone(d.settings['store_phone']!))),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              p(l.salesSlipTitle(docNo(d.ret.number, d.ret.deviceCode))),
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          kv(p(l.commonDate), formatDateTime(d.ret.createdAt)),
          kv(p(l.salesSlipBySale), p(l.salesSlipSaleRef(docNo(d.sale.number, d.sale.deviceCode), formatDateTime(d.sale.createdAt)))),
          if (d.customerName != null) kv(p(l.salesSlipBuyer), d.customerName!),
          kv(p(l.salesSlipMethod), p(paymentMethodLabel(d.ret.refundMethod, l))),
          kv(p(l.commonReason), d.ret.reason ?? '—'),
          kv(p(l.salesSlipRestock), p(d.ret.restock ? l.salesSlipYes : l.salesSlipNoRestock)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [p(l.commonProduct), p(l.salesSlipQty), p(l.commonAmount)],
            data: [
              for (final x in d.lines) [x.$1, p(Qty.format(x.$2, x.$4, l)), Money.format(x.$3)],
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
              p(l.salesSlipTotal(Money.format(d.ret.total))),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Spacer(),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text(p(l.salesSlipIssued(d.userName ?? '')))),
              pw.SizedBox(width: 12),
              pw.Expanded(child: pw.Text(p(l.salesSlipReceived))),
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
    name: L.printable(L.forReceipt(data.settings).salesSlipJobName(docNo(data.ret.number, data.ret.deviceCode))),
    format: PdfPageFormat.a5,
    onLayout: (_) => buildReturnSlipPdf(data),
  );
}
