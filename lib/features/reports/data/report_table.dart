// A tiny table model shared by every report table: it renders on screen,
// sorts, and exports to CSV / PDF from the same definition.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/money.dart';
import '../../../core/printing/pdf_fonts.dart';
import '../../../core/widgets/widgets.dart' show formatDateTime;
import '../../../l10n/l10n.dart';

class RCol {
  const RCol(this.title, {this.numeric = false, this.tooltip});
  final String title;
  final bool numeric;
  final String? tooltip;
}

class RCell {
  const RCell(this.text, {this.sort, String? csv, this.chipColor, this.colorValue})
      : _csv = csv;

  factory RCell.money(int minor) => RCell(Money.format(minor),
      sort: minor, csv: Money.toInput(minor).replaceAll('.', ','));
  factory RCell.integer(int v) => RCell('$v', sort: v, csv: '$v');
  factory RCell.qty(double v, [String? unit, AppLocalizations? l]) => RCell(Qty.format(v, unit, l),
      sort: v, csv: Qty.format(v));
  factory RCell.percent(double v, {int digits = 1}) {
    final s = v.toStringAsFixed(digits).replaceAll('.', ',');
    return RCell('$s%', sort: v, csv: s);
  }

  final String text;
  final Comparable<dynamic>? sort;
  final String? _csv;
  /// When set, the cell is drawn as a colored chip (ABC class, status…).
  final int? chipColor;
  /// Optional semantic color for the text (ARGB), e.g. red for losses.
  final int? colorValue;

  /// CSV value; text that a spreadsheet would treat as a formula
  /// (`=`, `+`, `@`, tab…) is prefixed with an apostrophe (CSV injection).
  String get csv {
    final v = _csv ?? text;
    if (_csv == null && v.isNotEmpty && const ['=', '+', '@', '\t', '\r'].contains(v[0])) {
      return "'$v";
    }
    return v;
  }
}

class RTable {
  const RTable({
    required this.title,
    required this.columns,
    required this.rows,
    this.subtitle,
    this.totals,
  });

  final String title;
  final String? subtitle;
  final List<RCol> columns;
  final List<List<RCell>> rows;
  final List<RCell>? totals;

  bool get isEmpty => rows.isEmpty;

  /// Semicolon-separated CSV (opens correctly in Excel with Russian locale).
  String toCsv() {
    String esc(String s) {
      if (s.contains(';') || s.contains('"') || s.contains('\n')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return s;
    }

    final b = StringBuffer();
    b.writeln(columns.map((c) => esc(c.title)).join(';'));
    for (final r in rows) {
      b.writeln(r.map((c) => esc(c.csv)).join(';'));
    }
    if (totals != null) b.writeln(totals!.map((c) => esc(c.csv)).join(';'));
    return b.toString();
  }

  Future<Uint8List> toPdf({String? storeName}) async {
    final theme = await PdfFonts.theme();
    final doc = pw.Document(theme: theme, title: L.printable(title));
    final wide = columns.length > 5;
    doc.addPage(pw.MultiPage(
      pageFormat: wide ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        if (storeName != null && storeName.isNotEmpty)
          pw.Text(L.printable(storeName), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.Text(L.printable(title), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        if (subtitle != null)
          pw.Text(L.printable(subtitle!), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
      ]),
      footer: (ctx) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('DreamPOS · ${formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ]),
      build: (ctx) => [
        pw.TableHelper.fromTextArray(
          headers: [for (final c in columns) L.printable(c.title)],
          data: [
            for (final r in rows) [for (final c in r) L.printable(c.text)],
            if (totals != null) [for (final c in totals!) L.printable(c.text)],
          ],
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {
            for (var i = 0; i < columns.length; i++)
              i: columns[i].numeric ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          },
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
          border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
        ),
      ],
    ));
    return doc.save();
  }

  String fileBaseName() {
    final safe = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${safe.isEmpty ? 'report' : safe}_${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }
}

/// Folder for exported reports: `Documents/DreamPOS/<localized "Reports">`.
Future<Directory> reportsDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'DreamPOS', L.current.repExportFolder));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

/// Writes CSV with a UTF-8 BOM (so Excel detects Cyrillic). Returns the path.
Future<String> saveCsv(RTable t) async {
  final dir = await reportsDirectory();
  final f = File(p.join(dir.path, '${t.fileBaseName()}.csv'));
  await f.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(t.toCsv())]);
  return f.path;
}

Future<String> savePdf(RTable t, {String? storeName}) async {
  final dir = await reportsDirectory();
  final f = File(p.join(dir.path, '${t.fileBaseName()}.pdf'));
  await f.writeAsBytes(await t.toPdf(storeName: storeName));
  return f.path;
}
