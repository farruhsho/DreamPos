import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/services/sale_service.dart' show paymentMethodLabel;
import '../../l10n/l10n.dart';
import '../db/database.dart';
import '../doc_number.dart';
import '../money.dart';
import '../widgets/widgets.dart' show formatDateTime;
import 'pdf_fonts.dart';

/// Footer printed on gift card slips unless setting `gift_receipt_note` = '0'
/// (in the receipt language).
String get giftReceiptNote => L.receipt.coreGiftSlipNote;

/// `ABCD2345WXYZ` → `ABCD 2345 WXYZ`.
String groupGiftCode(String code) {
  final b = StringBuffer();
  for (var i = 0; i < code.length; i += 4) {
    if (i > 0) b.write(' ');
    b.write(code.substring(i, i + 4 > code.length ? code.length : i + 4));
  }
  return b.toString();
}

/// Everything needed to render a gift card sale slip («Продажа сертификата №N»).
class GiftReceiptData {
  GiftReceiptData({
    required this.sale,
    required this.card,
    required this.payments,
    required this.settings,
    this.cashier,
    this.customer,
    this.copy = false,
  });

  final GiftCardSale sale;
  final GiftCard card;
  final List<GiftCardSalePayment> payments;
  final Map<String, String> settings;
  final User? cashier;
  final Customer? customer;
  final bool copy;

  bool get voided => sale.status == 'voided';

  static Future<GiftReceiptData> load(AppDatabase db, String giftSaleId, {bool copy = false}) async {
    final sale = await (db.select(db.giftCardSales)..where((s) => s.id.equals(giftSaleId))).getSingle();
    final card = await (db.select(db.giftCards)..where((g) => g.id.equals(sale.giftCardId))).getSingle();
    final pays = await (db.select(db.giftCardSalePayments)
          ..where((p) => p.saleId.equals(giftSaleId) & p.deletedAt.isNull()))
        .get();
    final settings = {for (final s in await db.select(db.settings).get()) s.key: s.value};
    final cashier = sale.cashierId == null
        ? null
        : await (db.select(db.users)..where((u) => u.id.equals(sale.cashierId!))).getSingleOrNull();
    final customer = sale.customerId == null
        ? null
        : await (db.select(db.customers)..where((c) => c.id.equals(sale.customerId!))).getSingleOrNull();
    return GiftReceiptData(
      sale: sale,
      card: card,
      payments: pays,
      settings: settings,
      cashier: cashier,
      customer: customer,
      copy: copy,
    );
  }

  String get expiryText {
    final l = L.forReceipt(settings);
    return card.expiresAt == null
        ? l.coreGiftNoExpiry
        : l.coreGiftUntil(formatDateTime(card.expiresAt!).split(' ').first);
  }

  /// Plain-text slip. [width] chars. The code line is meant to be printed
  /// large; [buildGiftReceiptPdf] renders it separately.
  String toText({int width = 42, bool includeCode = true}) {
    final l = L.forReceipt(settings);
    final b = StringBuffer();
    String center(String s) => s.length >= width ? s : ' ' * ((width - s.length) ~/ 2) + s;
    String lr(String l, String r) {
      final space = width - l.length - r.length;
      return space >= 1 ? '$l${' ' * space}$r' : '$l\n${' ' * (width - r.length)}$r';
    }

    final line = '-' * width;
    b.writeln(center(settings['store_name'] ?? 'DreamPOS'));
    if ((settings['store_address'] ?? '').isNotEmpty) b.writeln(center(settings['store_address']!));
    if ((settings['store_phone'] ?? '').isNotEmpty) b.writeln(center(l.corePrintPhone(settings['store_phone']!)));
    if ((settings['store_tax_id'] ?? '').isNotEmpty) b.writeln(center(l.corePrintTaxId(settings['store_tax_id']!)));
    b.writeln(line);
    b.writeln(center(copy ? l.coreGiftSlipCopyTitle(docNo(sale.number, sale.deviceCode)) : l.coreGiftSlipTitle(docNo(sale.number, sale.deviceCode))));
    b.writeln(center(formatDateTime(sale.createdAt)));
    if (cashier != null) b.writeln(l.corePrintCashier(cashier!.name));
    if (customer != null) b.writeln(l.corePrintCustomer(customer!.name));
    b.writeln(line);
    if (includeCode) {
      b.writeln(center(l.coreGiftCode));
      b.writeln(center(groupGiftCode(card.code)));
      b.writeln(line);
    }
    b.writeln(lr(l.coreGiftFaceValue, Money.format(sale.amount)));
    b.writeln(lr(l.coreGiftValidity, expiryText));
    b.writeln(line);
    for (final p in payments) {
      final amount = p.method == 'cash' ? p.amount + sale.changeDue : p.amount;
      b.writeln(lr(paymentMethodLabel(p.method, l), Money.format(amount)));
      if ((p.reference ?? '').isNotEmpty) b.writeln('  ${p.reference}');
    }
    if (sale.changeDue > 0) b.writeln(lr(l.commonChange, Money.format(sale.changeDue)));
    if (voided) {
      b.writeln(center(l.corePrintVoided));
      if (sale.voidedAt != null) b.writeln(center(formatDateTime(sale.voidedAt!)));
      if ((sale.voidReason ?? '').isNotEmpty) b.writeln(l.corePrintReason(sale.voidReason!));
    }
    if (settings['gift_receipt_note'] != '0') {
      b.writeln(line);
      var cur = '';
      for (final w in l.coreGiftSlipNote.split(' ')) {
        if (cur.isNotEmpty && cur.length + 1 + w.length > width) {
          b.writeln(center(cur));
          cur = w;
        } else {
          cur = cur.isEmpty ? w : '$cur $w';
        }
      }
      if (cur.isNotEmpty) b.writeln(center(cur));
    }
    return L.printable(b.toString());
  }
}

/// 80mm (or 58mm) roll PDF: header text, the code large and monospaced,
/// then the rest.
Future<Uint8List> buildGiftReceiptPdf(GiftReceiptData r, {double widthMm = 80}) async {
  final font = await PdfFonts.mono();
  final doc = pw.Document();
  final chars = widthMm >= 80 ? 42 : 32;
  final full = r.toText(width: chars, includeCode: false);
  // Split after the header block (store … cashier/customer) to put the code
  // in between, large.
  final lines = full.split('\n');
  final sep = '-' * chars;
  final firstSep = lines.indexOf(sep);
  final secondSep = firstSep < 0 ? -1 : lines.indexOf(sep, firstSep + 1);
  final head = secondSep < 0 ? full : lines.sublist(0, secondSep + 1).join('\n');
  final tail = secondSep < 0 ? '' : lines.sublist(secondSep + 1).join('\n');
  final size = widthMm >= 80 ? 8.0 : 7.0;
  final style = pw.TextStyle(font: font, fontSize: size);
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat(widthMm * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm),
    build: (_) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(head, style: style),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text(L.printable(L.forReceipt(r.settings).coreGiftCode), style: style)),
        pw.Center(
          child: pw.Text(groupGiftCode(r.card.code),
              style: pw.TextStyle(font: font, fontSize: widthMm >= 80 ? 15 : 12, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Text('$sep\n$tail', style: style),
      ],
    ),
  ));
  return doc.save();
}

/// Sends the gift card slip to the system printer dialog.
Future<void> printGiftReceipt(AppDatabase db, String giftSaleId, {bool copy = false}) async {
  final data = await GiftReceiptData.load(db, giftSaleId, copy: copy);
  final width = double.tryParse(data.settings['receipt_width_mm'] ?? '') ?? 80;
  await Printing.layoutPdf(
    name: L.forReceipt(data.settings).corePrintJobGift(docNo(data.sale.number, data.sale.deviceCode)),
    format: PdfPageFormat(width * PdfPageFormat.mm, double.infinity),
    onLayout: (_) => buildGiftReceiptPdf(data, widthMm: width),
  );
}
