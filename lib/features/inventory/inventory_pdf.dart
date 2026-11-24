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
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Инвентаризационная ведомость №${count.number}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('стр. ${ctx.pageNumber}/${ctx.pagesCount}', style: headerStyle),
            ],
          ),
          pw.Text(
            '$storeName · создана ${formatDateTime(count.createdAt)} · позиций ${lines.length}',
            style: headerStyle,
          ),
          if (count.note != null) pw.Text(count.note!, style: headerStyle),
          pw.SizedBox(height: 8),
        ],
      ),
      footer: (ctx) => ctx.pageNumber == ctx.pagesCount
          ? pw.Padding(
              padding: const pw.EdgeInsets.only(top: 24),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Считал: ____________________', style: headerStyle),
                  pw.Text('Проверил: ____________________', style: headerStyle),
                  pw.Text('Дата: ${formatDate(DateTime.now())}', style: headerStyle),
                ],
              ),
            )
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
          cellAlignments: {0: pw.Alignment.centerRight, if (showExpected) 4: pw.Alignment.centerRight},
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
    ),
  );
  return doc.save();
}

Future<void> printCountSheet(
  AppDatabase db,
  InventoryRepo repo,
  InventoryCount count, {
  bool showExpected = true,
}) async {
  final lines = await repo.loadLines(count.id);
  final store = await db.getSetting('store_name') ?? 'DreamPOS';
  await Printing.layoutPdf(
    name: 'Инвентаризация ${count.number}',
    format: PdfPageFormat.a4,
    onLayout: (_) => buildCountSheetPdf(count: count, lines: lines, storeName: store, showExpected: showExpected),
  );
}

/// Goods receipt document «Приход №N» (A4). Offline fonts via [PdfFonts].
Future<Uint8List> buildReceiptPdf({
  required GoodsReceipt receipt,
  required List<ReceiptDocLine> lines,
  required String storeName,
  String? supplierName,
  int? orderNumber,
  String? authorName,
  String? reversedByName,
  pw.ThemeData? theme,
}) async {
  final doc = pw.Document(theme: theme ?? await PdfFonts.theme());
  const small = pw.TextStyle(fontSize: 9);
  final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
  final reversed = receipt.status == ReceiptStatus.reversed;
  final anyPrice = lines.any((l) => l.priceChanged);
  final qtyTotal = lines.fold<double>(0, (s, l) => s + l.item.qty);
  pw.Widget info(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: '$label: ', style: small),
          pw.TextSpan(text: value, style: bold),
        ],
      ),
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Приходная накладная №${receipt.number} от ${formatDate(receipt.createdAt)}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('стр. ${ctx.pageNumber}/${ctx.pagesCount}', style: small),
            ],
          ),
          pw.Text(storeName, style: small),
          pw.SizedBox(height: 8),
        ],
      ),
      footer: (ctx) => ctx.pageNumber == ctx.pagesCount
          ? pw.Padding(
              padding: const pw.EdgeInsets.only(top: 24),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Сдал: ____________________', style: small),
                  pw.Text('Принял: ____________________', style: small),
                ],
              ),
            )
          : pw.SizedBox(),
      build: (_) => [
        info('Поставщик', supplierName ?? 'Без поставщика'),
        if (receipt.supplierInvoice != null) info('Накладная поставщика', receipt.supplierInvoice!),
        if (orderNumber != null) info('Основание', 'Заказ поставщику №$orderNumber'),
        info('Проведён', formatDateTime(receipt.createdAt)),
        if (authorName != null) info('Принял', authorName),
        if (receipt.note != null) info('Комментарий', receipt.note!),
        if (reversed)
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 6),
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red700)),
            child: pw.Text(
              'СТОРНИРОВАН'
              '${receipt.reversedAt != null ? ' ${formatDateTime(receipt.reversedAt!)}' : ''}'
              '${reversedByName != null ? ' · $reversedByName' : ''}'
              '${receipt.reverseReason != null ? '\nПричина: ${receipt.reverseReason}' : ''}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
            ),
          ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: bold,
          cellStyle: small,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellHeight: 18,
          columnWidths: {
            0: const pw.FixedColumnWidth(24),
            1: const pw.FlexColumnWidth(5),
            2: const pw.FixedColumnWidth(58),
            3: const pw.FixedColumnWidth(30),
            4: const pw.FixedColumnWidth(72),
            5: const pw.FixedColumnWidth(80),
            if (anyPrice) 6: const pw.FixedColumnWidth(72),
          },
          cellAlignments: {
            0: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
            if (anyPrice) 6: pw.Alignment.centerRight,
          },
          headers: ['№', 'Товар', 'Кол-во', 'Ед.', 'Цена', 'Сумма', if (anyPrice) 'Новая розн.'],
          data: [
            for (var i = 0; i < lines.length; i++)
              [
                '${i + 1}',
                lines[i].name,
                Qty.format(lines[i].item.qty),
                Qty.unitLabel(lines[i].unit),
                Money.format(lines[i].item.unitCost, withSymbol: false),
                Money.format(lines[i].total, withSymbol: false),
                if (anyPrice) lines[i].priceChanged ? Money.format(lines[i].item.newPrice!, withSymbol: false) : '',
              ],
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Позиций: ${lines.length} · количество ${Qty.format(qtyTotal)}', style: small),
              pw.Text(
                'Итого: ${Money.format(receipt.total)}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return doc.save();
}

/// Opens the print/share dialog for a receipt document.
Future<void> printReceiptDocument(
  AppDatabase db, {
  required GoodsReceipt receipt,
  required List<ReceiptDocLine> lines,
  String? supplierName,
  int? orderNumber,
  String? authorName,
  String? reversedByName,
}) async {
  final store = await db.getSetting('store_name') ?? 'DreamPOS';
  await Printing.layoutPdf(
    name: 'Приход ${receipt.number}',
    format: PdfPageFormat.a4,
    onLayout: (_) => buildReceiptPdf(
      receipt: receipt,
      lines: lines,
      storeName: store,
      supplierName: supplierName,
      orderNumber: orderNumber,
      authorName: authorName,
      reversedByName: reversedByName,
    ),
  );
}
