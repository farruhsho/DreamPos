// X/Z report PDF output: 80mm roll and A4 (fonts via PdfFonts, offline).
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/widgets/widgets.dart' show formatDateTime;
import '../../l10n/l10n.dart';
import 'report_data.dart';

Future<Uint8List> buildZReportRollPdf(ZReportData d, {double widthMm = 80}) async {
  final font = await PdfFonts.mono();
  final doc = pw.Document(title: L.printable(d.printL10n.shiftZTitleA4(d.title, '${d.figures.shift.number}')));
  final chars = widthMm >= 80 ? 42 : 32;
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(widthMm * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm),
      build: (_) => pw.Text(
        d.toText(width: chars),
        style: pw.TextStyle(font: font, fontSize: widthMm >= 80 ? 8 : 7),
      ),
    ),
  );
  return doc.save();
}

Future<Uint8List> buildZReportA4Pdf(ZReportData d) async {
  final theme = await PdfFonts.theme();
  final l = d.printL10n;
  final p = L.printable;
  final doc = pw.Document(title: p(l.shiftZTitleA4(d.title, '${d.figures.shift.number}')), theme: theme);
  final store = d.settings['store_name'] ?? '';
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        if (store.isNotEmpty) pw.Text(p(store), style: const pw.TextStyle(fontSize: 11)),
        pw.Text(
          p(l.shiftZTitleA4(d.title, '${d.figures.shift.number}')),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          p(l.shiftZGenerated(formatDateTime(DateTime.now()))),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        for (final sec in d.sections(l)) ...[
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            color: PdfColors.grey200,
            child: pw.Text(p(sec.title), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Table(
            columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(2)},
            children: [
              for (final line in sec.lines)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.fromLTRB(line.indent ? 18 : 6, 3, 6, 3),
                      child: pw.Text(
                        p(line.label),
                        style: pw.TextStyle(fontWeight: line.bold ? pw.FontWeight.bold : pw.FontWeight.normal),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.fromLTRB(6, 3, 6, 3),
                      child: pw.Text(
                        p(line.value),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontWeight: line.bold ? pw.FontWeight.bold : pw.FontWeight.normal),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 10),
        ],
        if (d.isClosed) ...[
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(p('${l.shiftZCashierSign}: ____________________')),
              pw.Text(p('${l.shiftZReceivedSign}: ____________________')),
            ],
          ),
        ],
      ],
    ),
  );
  return doc.save();
}

Future<void> printZReport(AppDatabase db, String shiftId, {required bool a4, bool showProfit = false}) async {
  final d = await ZReportData.load(db, shiftId, showProfit: showProfit);
  final name = L.printable(d.printL10n.shiftZFileName(d.title, '${d.figures.shift.number}'));
  if (a4) {
    await Printing.layoutPdf(name: name, format: PdfPageFormat.a4, onLayout: (_) => buildZReportA4Pdf(d));
  } else {
    final width = double.tryParse(d.settings['receipt_width_mm'] ?? '') ?? 80;
    await Printing.layoutPdf(
      name: name,
      format: PdfPageFormat(width * PdfPageFormat.mm, double.infinity),
      onLayout: (_) => buildZReportRollPdf(d, widthMm: width),
    );
  }
}
