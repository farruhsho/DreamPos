import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/services/sale_service.dart' show paymentMethodLabel;
import '../db/database.dart';
import '../money.dart';
import '../widgets/widgets.dart' show formatDateTime;
import 'pdf_fonts.dart';

/// Everything needed to render a sale receipt.
class ReceiptData {
  ReceiptData({
    required this.sale,
    required this.items,
    required this.payments,
    required this.settings,
    this.cashier,
    this.customer,
    this.copy = false,
  });

  final Sale sale;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final Map<String, String> settings;
  final User? cashier;
  final Customer? customer;
  final bool copy;

  static Future<ReceiptData> load(AppDatabase db, String saleId, {bool copy = false}) async {
    final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();
    final items = await (db.select(db.saleItems)..where((i) => i.saleId.equals(saleId))).get();
    final pays = await (db.select(db.salePayments)..where((p) => p.saleId.equals(saleId))).get();
    final settings = {for (final s in await db.select(db.settings).get()) s.key: s.value};
    final cashier = sale.cashierId == null
        ? null
        : await (db.select(db.users)..where((u) => u.id.equals(sale.cashierId!))).getSingleOrNull();
    final customer = sale.customerId == null
        ? null
        : await (db.select(db.customers)..where((c) => c.id.equals(sale.customerId!)))
            .getSingleOrNull();
    return ReceiptData(
        sale: sale,
        items: items,
        payments: pays,
        settings: settings,
        cashier: cashier,
        customer: customer,
        copy: copy);
  }

  /// Plain-text receipt (for preview, ESC/POS printers, sharing). [width] chars.
  String toText({int width = 42}) {
    final b = StringBuffer();
    String center(String s) => s.length >= width ? s : ' ' * ((width - s.length) ~/ 2) + s;
    String lr(String l, String r) {
      final space = width - l.length - r.length;
      return space >= 1 ? '$l${' ' * space}$r' : '$l\n${' ' * (width - r.length)}$r';
    }

    final line = '-' * width;
    b.writeln(center(settings['store_name'] ?? 'DreamPOS'));
    if ((settings['store_address'] ?? '').isNotEmpty) b.writeln(center(settings['store_address']!));
    if ((settings['store_phone'] ?? '').isNotEmpty) b.writeln(center('Тел: ${settings['store_phone']}'));
    if ((settings['store_tax_id'] ?? '').isNotEmpty) b.writeln(center('ИНН: ${settings['store_tax_id']}'));
    b.writeln(line);
    b.writeln(center('${copy ? 'КОПИЯ ' : ''}ЧЕК №${sale.number}'));
    b.writeln(center(formatDateTime(sale.createdAt)));
    if (cashier != null) b.writeln('Кассир: ${cashier!.name}');
    if (customer != null) b.writeln('Клиент: ${customer!.name}');
    b.writeln(line);
    for (final i in items) {
      b.writeln(i.productName);
      b.writeln(lr('  ${Qty.format(i.qty)} x ${Money.format(i.unitPrice, withSymbol: false)}',
          Money.format((i.qty * i.unitPrice).round(), withSymbol: false)));
      if (i.discount > 0) b.writeln(lr('  Скидка', '-${Money.format(i.discount, withSymbol: false)}'));
      if (i.warrantyUntil != null) b.writeln('  Гарантия до ${formatDateTime(i.warrantyUntil!).split(' ').first}');
    }
    b.writeln(line);
    if (sale.discountTotal > 0) {
      b.writeln(lr('Сумма', Money.format(sale.subtotal)));
      b.writeln(lr('Скидка', '-${Money.format(sale.discountTotal)}'));
    }
    b.writeln(lr('ИТОГО', Money.format(sale.total)));
    if (sale.vatTotal > 0) b.writeln(lr('в т.ч. НДС', Money.format(sale.vatTotal)));
    for (final p in payments) {
      final amount = p.method == 'cash' ? p.amount + sale.changeDue : p.amount;
      b.writeln(lr(paymentMethodLabel(p.method), Money.format(amount)));
    }
    if (sale.changeDue > 0) b.writeln(lr('Сдача', Money.format(sale.changeDue)));
    if (sale.bonusEarned > 0) b.writeln(lr('Начислено бонусов', Money.format(sale.bonusEarned)));
    if (customer != null && customer!.debtBalance > 0) {
      b.writeln(lr('Долг клиента', Money.format(customer!.debtBalance)));
    }
    if (sale.status == 'voided') b.writeln(center('*** АННУЛИРОВАН ***'));
    b.writeln(line);
    if ((settings['receipt_footer'] ?? '').isNotEmpty) b.writeln(center(settings['receipt_footer']!));
    return b.toString();
  }
}

/// Builds an 80mm (or 58mm) roll PDF.
Future<Uint8List> buildReceiptPdf(ReceiptData r, {double widthMm = 80}) async {
  final font = await PdfFonts.mono();
  final doc = pw.Document();
  final chars = widthMm >= 80 ? 42 : 32;
  final text = r.toText(width: chars);
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat(widthMm * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm),
    build: (_) => pw.Text(text, style: pw.TextStyle(font: font, fontSize: widthMm >= 80 ? 8 : 7)),
  ));
  return doc.save();
}

/// Sends the receipt to the system printer dialog (or default printer).
Future<void> printReceipt(AppDatabase db, String saleId, {bool copy = false}) async {
  final data = await ReceiptData.load(db, saleId, copy: copy);
  final width = double.tryParse(data.settings['receipt_width_mm'] ?? '') ?? 80;
  await Printing.layoutPdf(
    name: 'Чек ${data.sale.number}',
    format: PdfPageFormat(width * PdfPageFormat.mm, double.infinity),
    onLayout: (_) => buildReceiptPdf(data, widthMm: width),
  );
}
