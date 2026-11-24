// Acceptance act for a warranty claim (A4 PDF, offline Cyrillic fonts).
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/widgets/widgets.dart' show formatDate, formatDateTime;
import 'warranty_logic.dart';
import 'warranty_repository.dart';

Future<Uint8List> buildClaimActPdf(ClaimRow row, Map<String, String> settings) async {
  final theme = await PdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final c = row.claim;
  final store = settings['store_name'] ?? 'DreamPOS';

  pw.TableRow kv(String k, String v) => pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(k, style: const pw.TextStyle(color: PdfColors.grey800)),
      ),
      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(v)),
    ],
  );

  final state = warrantyState(row.warrantyUntil, c.createdAt);
  final warrantyText = switch (state) {
    WarrantyState.none => 'не установлена',
    WarrantyState.active => 'до ${formatDate(row.warrantyUntil!)} (действует)',
    WarrantyState.expired => 'до ${formatDate(row.warrantyUntil!)} (истекла)',
  };

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(store, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if ((settings['store_address'] ?? '').isNotEmpty) pw.Text(settings['store_address']!),
          if ((settings['store_phone'] ?? '').isNotEmpty) pw.Text('Тел: ${settings['store_phone']}'),
          if ((settings['store_tax_id'] ?? '').isNotEmpty) pw.Text('ИНН: ${settings['store_tax_id']}'),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'АКТ ПРИЁМА ТОВАРА НА ГАРАНТИЙНОЕ ОБСЛУЖИВАНИЕ',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Center(child: pw.Text('№${c.number} от ${formatDateTime(c.createdAt)}')),
          pw.SizedBox(height: 18),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
            columnWidths: {0: const pw.FixedColumnWidth(150), 1: const pw.FlexColumnWidth()},
            children: [
              kv('Клиент', row.customerName ?? '______________________________'),
              kv('Телефон', row.customerPhone ?? '______________________________'),
              kv('Товар', row.productName ?? '—'),
              kv('Серийный номер', c.serialNumber ?? '—'),
              kv(
                'Документ покупки',
                row.saleNumber == null ? 'не предъявлен' : 'чек №${row.saleNumber} от ${formatDate(row.saleDate!)}',
              ),
              kv('Гарантия', warrantyText),
              kv('Заявленная неисправность', c.problem),
              kv('Комплектность и внешний вид', '\n\n'),
              kv('Статус', warrantyStatusLabel(c.status)),
              if ((c.resolution ?? '').isNotEmpty) kv('Решение', c.resolution!),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Срок рассмотрения заявки — в соответствии с законодательством о защите прав потребителей. '
            'Товар выдаётся при предъявлении настоящего акта.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Spacer(),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Сдал (клиент):'),
                    pw.SizedBox(height: 24),
                    pw.Text('_____________ / ${row.customerName ?? '______________'}'),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Принял (сотрудник):'),
                    pw.SizedBox(height: 24),
                    pw.Text('_____________ / ${row.userName ?? '______________'}'),
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
    name: 'Гарантия ${row.claim.number}',
    format: PdfPageFormat.a4,
    onLayout: (_) => buildClaimActPdf(row, settings),
  );
}
