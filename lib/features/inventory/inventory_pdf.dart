import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/widgets/widgets.dart' show formatDate, formatDateTime;
import 'inventory_logic.dart';

/// Count sheet for counting by hand: blank «Факт» column.
Future<Uint8List> buildCountSheetPdf({
  required InventoryCount count,
  required List<CountLine> lines,
  required String storeName,
  bool showExpected = true,
  pw.ThemeData? theme,
}) async {
  final doc = pw.Document(theme: theme ?? await PdfFonts.theme());
  const headerStyle = pw.TextStyle(fontSize: 9);
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    header: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Инвентаризационная ведомость №${count.number}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('стр. ${ctx.pageNumber}/${ctx.pagesCount}', style: headerStyle),
      ]),
      pw.Text('$storeName · создана ${formatDateTime(count.createdAt)} · позиций ${lines.length}',
          style: headerStyle),
      if (count.note != null) pw.Text(count.note!, style: headerStyle),
      pw.SizedBox(height: 8),
    ]),
    footer: (ctx) => ctx.pageNumber == ctx.pagesCount
        ? pw.Padding(
            padding: const pw.EdgeInsets.only(top: 24),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Считал: ____________________', style: headerStyle),
              pw.Text('Проверил: ____________________', style: headerStyle),
              pw.Text('Дата: ${formatDate(DateTime.now())}', style: headerStyle),
            ]))
        : pw.SizedBox(),
    build: (_) => [
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellHeight: 20,
        columnWidths: {
          0: const pw.FixedColumnWidth(24),
          1: const pw.FlexColumnWidth(5),
          2: const pw.FlexColumnWidth(2.2),
          3: const pw.FixedColumnWidth(32),
          if (showExpected) 4: const pw.FixedColumnWidth(56),
          (showExpected ? 5 : 4): const pw.FixedColumnWidth(64),
        },
        cellAlignments: {
          0: pw.Alignment.centerRight,
          if (showExpected) 4: pw.Alignment.centerRight,
        },
        headers: ['№', 'Товар', 'Штрихкод / арт.', 'Ед.', if (showExpected) 'Учёт', 'Факт'],
        data: [
          for (var i = 0; i < lines.length; i++)
            [
              '${i + 1}',
              lines[i].name,
              lines[i].product?.barcode ?? lines[i].product?.sku ?? '',
              Qty.unitLabel(lines[i].unit),
              if (showExpected) Qty.format(lines[i].item.expectedQty),
              lines[i].item.countedQty == null ? '' : Qty.format(lines[i].item.countedQty!),
            ],
        ],
      ),
    ],
  ));
  return doc.save();
}

Future<void> printCountSheet(AppDatabase db, InventoryRepo repo, InventoryCount count,
    {bool showExpected = true}) async {
  final lines = await repo.loadLines(count.id);
  final store = await db.getSetting('store_name') ?? 'DreamPOS';
  await Printing.layoutPdf(
    name: 'Инвентаризация ${count.number}',
    format: PdfPageFormat.a4,
    onLayout: (_) => buildCountSheetPdf(count: count, lines: lines, storeName: store, showExpected: showExpected),
  );
}
