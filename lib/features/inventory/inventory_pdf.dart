import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/printing/pdf_fonts.dart';
import '../../core/widgets/widgets.dart' show formatDate, formatDateTime;
import 'inventory_logic.dart';
import '../../l10n/l10n.dart';

/// Count sheet for counting by hand: blank «Факт» column.
Future<Uint8List> buildCountSheetPdf({
  required InventoryCount count,
  required List<CountLine> lines,
  required String storeName,
  bool showExpected = true,
  pw.ThemeData? theme,
}) async {
  final doc = pw.Document(theme: theme ?? await PdfFonts.theme());
  final l = L.current;
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
                L.printable(l.invSheetTitle('${count.number}')),
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(L.printable(l.invPageOf('${ctx.pageNumber}', '${ctx.pagesCount}')), style: headerStyle),
            ],
          ),
          pw.Text(
            L.printable(l.invSheetSubtitle(storeName, formatDateTime(count.createdAt), '${lines.length}')),
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
                  pw.Text(L.printable(l.invCountedBy), style: headerStyle),
                  pw.Text(L.printable(l.invCheckedBy), style: headerStyle),
                  pw.Text(L.printable(l.invDateLine(formatDate(DateTime.now()))), style: headerStyle),
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
          headers: [
            for (final h in [l.invNoHeader, l.commonProduct, l.invBarcodeSku, l.invUnitShort, if (showExpected) l.invBook, l.invFact])
              L.printable(h),
          ],
          data: [
            for (var i = 0; i < lines.length; i++)
              [
                '${i + 1}',
                lines[i].name,
                lines[i].product?.barcode ?? lines[i].product?.sku ?? '',
                L.printable(Qty.unitLabel(lines[i].unit, l)),
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
    name: L.printable(L.current.invCountFileName('${count.number}')),
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
  final l = L.current;
  String p(String s) => L.printable(s);
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
          pw.TextSpan(text: '${p(label)}: ', style: small),
          pw.TextSpan(text: p(value), style: bold),
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
                p(l.invReceiptPdfTitle('${receipt.number}', formatDate(receipt.createdAt))),
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(p(l.invPageOf('${ctx.pageNumber}', '${ctx.pagesCount}')), style: small),
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
                  pw.Text(p(l.invHandedBy), style: small),
                  pw.Text(p(l.invAcceptedByLine), style: small),
                ],
              ),
            )
          : pw.SizedBox(),
      build: (_) => [
        info(l.commonSupplier, supplierName ?? l.invNoSupplier),
        if (receipt.supplierInvoice != null) info(l.invSupplierInvoice, receipt.supplierInvoice!),
        if (orderNumber != null) info(l.invBasis, l.invSupplierOrderRef('$orderNumber')),
        info(l.invReceiptPosted, formatDateTime(receipt.createdAt)),
        if (authorName != null) info(l.invAcceptedBy, authorName),
        if (receipt.note != null) info(l.commonComment, receipt.note!),
        if (reversed)
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 6),
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red700)),
            child: pw.Text(
              p(
                '${l.invReversedCaps}'
                '${receipt.reversedAt != null ? ' ${formatDateTime(receipt.reversedAt!)}' : ''}'
                '${reversedByName != null ? ' · $reversedByName' : ''}'
                '${receipt.reverseReason != null ? '\n${l.invReasonLine(receipt.reverseReason!)}' : ''}',
              ),
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
          headers: [
            for (final h in [
              l.invNoHeader,
              l.commonProduct,
              l.invQtyShort,
              l.invUnitShort,
              l.commonPrice,
              l.commonAmount,
              if (anyPrice) l.invNewRetailShort,
            ])
              p(h),
          ],
          data: [
            for (var i = 0; i < lines.length; i++)
              [
                '${i + 1}',
                lines[i].name,
                Qty.format(lines[i].item.qty),
                p(Qty.unitLabel(lines[i].unit, l)),
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
              pw.Text(p(l.invTotalsLine('${lines.length}', Qty.format(qtyTotal))), style: small),
              pw.Text(
                p(l.invTotalLine(Money.format(receipt.total))),
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
    name: L.printable(L.current.invReceiptFileName('${receipt.number}')),
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
