import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Bundled Cyrillic-capable fonts (Apache 2.0). Never download fonts at
/// runtime: the POS must print offline.
class PdfFonts {
  PdfFonts._();
  static pw.Font? _mono, _monoBold, _sans, _sansBold;

  static Future<pw.Font> mono() async =>
      _mono ??= pw.Font.ttf(await rootBundle.load('assets/fonts/RobotoMono-Regular.ttf'));
  static Future<pw.Font> monoBold() async =>
      _monoBold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/RobotoMono-Bold.ttf'));
  static Future<pw.Font> sans() async =>
      _sans ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  static Future<pw.Font> sansBold() async =>
      _sansBold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

  /// Theme for A4 documents (reports, price labels, Z-reports).
  static Future<pw.ThemeData> theme() async =>
      pw.ThemeData.withFont(base: await sans(), bold: await sansBold());
}
