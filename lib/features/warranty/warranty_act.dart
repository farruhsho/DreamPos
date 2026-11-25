// Acceptance act for a warranty claim (A4 PDF, offline Cyrillic fonts).
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/doc_number.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/widgets/widgets.dart' show formatDate, formatDateTime;
import '../../l10n/l10n.dart';
import 'warranty_logic.dart';
import 'warranty_repository.dart';

Future<Uint8List> buildClaimActPdf(ClaimRow row, Map<String, String> settings) async {
  final theme = await PdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final c = row.claim;
  final store = settings['store_name'] ?? 'DreamPOS';
  // a customer document: printed in the receipt language of the store
  final l = L.forReceipt(settings);
  String p(String s) => L.printable(s);

  pw.TableRow kv(String k, String v) => pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(p(k), style: const pw.TextStyle(color: PdfColors.grey800)),
      ),
      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p(v))),
    ],
  );

  final state = warrantyState(row.warrantyUntil, c.createdAt);
  final warrantyText = switch (state) {
    WarrantyState.none => l.warrantyNotSet,
    WarrantyState.active => l.warrantyActUntilActive(formatDate(row.warrantyUntil!)),
    WarrantyState.expired => l.warrantyActUntilExpired(formatDate(row.warrantyUntil!)),
  };

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p(store), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if ((settings['store_address'] ?? '').isNotEmpty) pw.Text(p(settings['store_address']!)),
          if ((settings['store_phone'] ?? '').isNotEmpty) pw.Text(p(l.corePrintPhone(settings['store_phone']!))),
          if ((settings['store_tax_id'] ?? '').isNotEmpty) pw.Text(p(l.corePrintTaxId(settings['store_tax_id']!))),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(p(l.warrantyActTitle), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Center(child: pw.Text(p(l.warrantyActNumber(docNo(c.number, c.deviceCode), formatDateTime(c.createdAt))))),
          pw.SizedBox(height: 18),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
            columnWidths: {0: const pw.FixedColumnWidth(150), 1: const pw.FlexColumnWidth()},
            children: [
              kv(l.commonCustomer, row.customerName ?? '______________________________'),
              kv(l.commonPhone, row.customerPhone ?? '______________________________'),
              kv(l.commonProduct, row.productName ?? '—'),
              kv(l.warrantySerialNumber, c.serialNumber ?? '—'),
              kv(
                l.warrantyActPurchaseDoc,
                row.saleNumber == null
                    ? l.warrantyActNotPresented
                    : l.warrantyReceiptRef(row.saleNo!, formatDate(row.saleDate!)),
              ),
              kv(l.warrantyWarranty, warrantyText),
              kv(l.warrantyActProblem, c.problem),
              kv(l.warrantyActCompleteness, '\n\n'),
              kv(l.commonStatus, warrantyStatusLabel(c.status, l)),
              if ((c.resolution ?? '').isNotEmpty) kv(l.warrantyResolution, c.resolution!),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(p(l.warrantyActTerms), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Spacer(),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(p(l.warrantyActHandedBy)),
                    pw.SizedBox(height: 24),
                    pw.Text(p('_____________ / ${row.customerName ?? '______________'}')),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(p(l.warrantyActReceivedBy)),
                    pw.SizedBox(height: 24),
                    pw.Text(p('_____________ / ${row.userName ?? '______________'}')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

Future<void> printClaimAct(AppDatabase db, ClaimRow row) async {
  final settings = {for (final s in await db.select(db.settings).get()) s.key: s.value};
  await Printing.layoutPdf(
    name: L.forReceipt(settings).warrantyActJobName(docNo(row.claim.number, row.claim.deviceCode)),
    format: PdfPageFormat.a4,
    onLayout: (_) => buildClaimActPdf(row, settings),
  );
}
