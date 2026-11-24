import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/widgets/widgets.dart' show formatDate, formatDateTime;
import '../reports/data/report_table.dart' show reportsDirectory;
import 'purchasing_logic.dart';
import '../../l10n/l10n.dart';

/// Everything needed to render a reconciliation act (акт сверки).
class StatementData {
  const StatementData({
    required this.supplier,
    required this.statement,
    required this.from,
    required this.to,
    required this.operation,
    required this.settings,
  });
  final Supplier supplier;
  final SupplierStatement statement;

  /// `[from, to)`; null = unbounded.
  final DateTime? from;
  final DateTime? to;
  final String Function(SupplierLedgerEntry) operation;
  final Map<String, String> settings;

  String get storeName {
    final s = (settings['store_name'] ?? '').trim();
    return s.isEmpty ? 'DreamPOS' : s;
  }

  String get period => ledgerPeriodText(from, to, firstEntry: statement.rows.firstOrNull?.createdAt);

  /// Date the closing balance refers to (last day of the period, or today).
  String get closingDate => formatDate(to == null ? DateTime.now() : to!.subtract(const Duration(days: 1)));

  String get fileBase {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final name = supplier.name.replaceAll(RegExp(r'[\\/:*?"<>|«»]'), '').replaceAll(RegExp(r'\s+'), '_').trim();
    final l = L.current;
    return '${l.purActFilePrefix}_${name.isEmpty ? l.purActFileSupplier : name}'
        '_${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}';
  }

  String toCsv() => supplierStatementCsv(
    st: statement,
    supplierName: supplier.name,
    storeName: storeName,
    period: period,
    operation: operation,
  );
}

/// Reconciliation act PDF (A4): parties, period, opening balance, rows,
/// turnovers, closing balance, conclusion and signature lines.
Future<Uint8List> buildStatementPdf(StatementData d, {pw.ThemeData? theme}) async {
  final l = L.current;
  String pr(String s) => L.printable(s);
  final doc = pw.Document(theme: theme ?? await PdfFonts.theme(), title: pr(l.purActShort));
  final cur = CurrencyConfig.fromSettings(d.settings);
  String money(int v) => Money.format(v, c: cur);
  const small = pw.TextStyle(fontSize: 9);
  final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
  final st = d.statement;
  final s = d.supplier;
  pw.Widget party(String role, String name, List<String> lines) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(pr(role), style: small),
        pw.Text(pr(name), style: bold),
        for (final x in lines) pw.Text(pr(x), style: small),
      ],
    ),
  );
  pw.Widget sign(String role, String name) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(pr(role), style: small),
        pw.Text(pr(name), style: bold),
        pw.SizedBox(height: 24),
        pw.Text('____________________ / ____________________', style: small),
        pw.Text(
          pr(l.purSignatureCaption),
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Text(pr(l.purStampPlace), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'DreamPOS · ${formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            '${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
      build: (_) => [
        pw.Center(
          child: pw.Text(
            pr(l.purActTitle),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Center(child: pw.Text(pr(ledgerPeriodHeading(d.period)), style: small)),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            party(l.purBuyer, d.storeName, [
              if ((d.settings['store_address'] ?? '').isNotEmpty) d.settings['store_address']!,
              if ((d.settings['store_phone'] ?? '').isNotEmpty) d.settings['store_phone']!,
            ]),
            pw.SizedBox(width: 16),
            party(l.commonSupplier, s.name, [
              if (s.taxId != null) l.purTaxIdValue(s.taxId!),
              if (s.address != null) s.address!,
              if (s.phone != null) s.phone!,
            ]),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headerStyle: bold,
          cellStyle: small,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          ),
          columnWidths: {
            0: const pw.FixedColumnWidth(70),
            1: const pw.FlexColumnWidth(5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          cellAlignments: {2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
          headers: [l.commonDate, l.purOperation, l.purIncrease, l.purDecrease, l.commonBalance].map(pr).toList(),
          data: [
            ['', pr(l.purOpeningBalance), '', '', money(st.opening)],
            for (final e in st.rows)
              [
                formatDate(e.createdAt),
                pr([d.operation(e), if (e.note != null && e.note != d.operation(e)) e.note!].join(' — ')),
                e.amount > 0 ? money(e.amount) : '',
                e.amount < 0 ? money(-e.amount) : '',
                money(e.balanceAfter),
              ],
            ['', pr(l.purTurnover), money(st.increase), money(st.decrease), ''],
            ['', pr(l.purClosingBalance), '', '', money(st.closing)],
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          pr(statementConclusion(st.closing, store: d.storeName, supplier: s.name, at: d.closingDate)),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          pr(l.purActLegend),
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 28),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [sign(l.purFromBuyer, d.storeName), pw.SizedBox(width: 24), sign(l.purFromSupplier, s.name)],
        ),
      ],
    ),
  );
  return doc.save();
}

Future<void> printStatement(StatementData d) =>
    Printing.layoutPdf(name: d.fileBase, format: PdfPageFormat.a4, onLayout: (_) => buildStatementPdf(d));

Future<void> shareStatement(StatementData d) async =>
    Printing.sharePdf(bytes: await buildStatementPdf(d), filename: '${d.fileBase}.pdf');

/// Saves the act as CSV (UTF-8 with BOM, for Excel) into the reports folder.
/// Returns the file path.
Future<String> saveStatementCsv(StatementData d) async {
  final dir = await reportsDirectory();
  final f = File(p.join(dir.path, '${d.fileBase}.csv'));
  await f.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(d.toCsv())]);
  return f.path;
}
