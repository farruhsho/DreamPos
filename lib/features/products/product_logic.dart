// Pure-Dart helpers of the products module: EAN-13, price rounding,
// margins, CSV parsing/serialisation and catalog filters. No widgets, no DB,
// so everything here is unit-tested directly. User-visible labels and import
// errors come from `L.current` (lib/l10n).
import 'dart:math' as math;

import '../../core/money.dart';
import '../../l10n/l10n.dart';

// ------------------------------------------------------------------ EAN-13

class Ean13 {
  Ean13._();

  /// Prefix for in-store (internal) barcodes. GS1 reserves 200–299 for
  /// restricted in-store circulation, so they never clash with real goods.
  static const internalPrefix = '200';

  static final _digits = RegExp(r'^\d+$');

  /// Check digit for the first 12 digits of an EAN-13.
  /// Weights from the left: 1,3,1,3,... (equivalently 3 for even positions
  /// counted from the right of the 12-digit body).
  static int checkDigit(String twelve) {
    if (twelve.length != 12 || !_digits.hasMatch(twelve)) {
      throw ArgumentError.value(twelve, 'twelve', 'нужно ровно 12 цифр'); // l10n-ignore
    }
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final d = twelve.codeUnitAt(i) - 48;
      sum += i.isEven ? d : d * 3;
    }
    return (10 - sum % 10) % 10;
  }

  /// Appends the check digit to a 12-digit body.
  static String complete(String twelve) => '$twelve${checkDigit(twelve)}';

  static bool isValid(String? code) {
    if (code == null || code.length != 13 || !_digits.hasMatch(code)) return false;
    return checkDigit(code.substring(0, 12)) == code.codeUnitAt(12) - 48;
  }

  /// EAN-8 validation (used to pick the right symbology on labels).
  static bool isValidEan8(String? code) {
    if (code == null || code.length != 8 || !_digits.hasMatch(code)) return false;
    var sum = 0;
    for (var i = 0; i < 7; i++) {
      final d = code.codeUnitAt(i) - 48;
      sum += i.isEven ? d * 3 : d;
    }
    return (10 - sum % 10) % 10 == code.codeUnitAt(7) - 48;
  }

  /// Internal barcode number [seq] (1..999 999 999): `200` + 9 digits + check.
  static String internal(int seq) {
    if (seq < 0 || seq > 999999999) {
      throw RangeError.range(seq, 0, 999999999, 'seq');
    }
    return complete('$internalPrefix${seq.toString().padLeft(9, '0')}');
  }

  /// Sequence number of an internal barcode, or null if [code] is not one.
  static int? internalSeq(String? code) {
    if (!isValid(code) || !code!.startsWith(internalPrefix)) return null;
    return int.parse(code.substring(3, 12));
  }
}

// ------------------------------------------------------------ prices & margin

enum RoundMode {
  nearest,
  up,
  down;

  String labelIn(AppLocalizations l) => switch (this) {
        RoundMode.nearest => l.prodRoundNearest,
        RoundMode.up => l.prodRoundUp,
        RoundMode.down => l.prodRoundDown,
      };
  String get label => labelIn(L.current);
}

/// Rounds a non-negative minor-unit amount to a multiple of [step].
int roundToStep(int value, int step, [RoundMode mode = RoundMode.nearest]) {
  if (step <= 1) return value;
  final v = math.max(0, value);
  final r = v % step;
  if (r == 0) return v;
  return switch (mode) {
    RoundMode.down => v - r,
    RoundMode.up => v - r + step,
    RoundMode.nearest => r * 2 >= step ? v - r + step : v - r,
  };
}

/// New price after a percentage change (+10 / -15.5), rounded to [step].
/// A positive price never rounds down to zero: it becomes one [step].
int applyPercentChange(int price, double percent,
    {int step = 1, RoundMode mode = RoundMode.nearest}) {
  final raw = (price * (100 + percent) / 100).round();
  if (raw <= 0) return 0;
  final r = roundToStep(raw, step, mode);
  return r <= 0 ? math.max(step, 1) : r;
}

/// Rounding step presets in *major* units, filtered by currency decimals.
/// For UZS (decimals 0) a step of 100 means "до 100 сум".
List<int> roundingStepsMinor(CurrencyConfig c) {
  final f = c.factor;
  final steps = <int>{1};
  if (c.decimals > 0) {
    steps.add(f ~/ 10 == 0 ? 1 : f ~/ 10); // 0,10
    steps.add(f); // 1
  }
  for (final major in [10, 100, 500, 1000]) {
    steps.add(major * f);
  }
  return steps.toList()..sort();
}

/// [l] defaults to the UI language (pass `L.of('ru')` for text stored in the DB).
String roundingStepLabel(int stepMinor, CurrencyConfig c, [AppLocalizations? l]) {
  final t = l ?? L.current;
  return stepMinor <= 1 ? t.prodRoundNone : t.prodRoundTo(Money.format(stepMinor, c: c));
}

/// Margin (наценка в цене) in percent: (price-cost)/price.
double? marginPercent(int price, int cost) =>
    price <= 0 ? null : (price - cost) * 100 / price;

/// Markup (наценка на себестоимость) in percent: (price-cost)/cost.
double? markupPercent(int price, int cost) =>
    cost <= 0 ? null : (price - cost) * 100 / cost;

String formatPercent(double? p, {int digits = 1}) {
  if (p == null) return '—';
  var s = p.toStringAsFixed(digits);
  if (s.contains('.')) s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return '${s.replaceAll('.', ',')}%';
}

/// Parses user decimal input ("1,5", "2 000.25"). Null when invalid.
double? parseDecimal(String? s) {
  if (s == null) return null;
  final t = s.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
  if (t.isEmpty || !RegExp(r'^-?\d*\.?\d+$|^-?\d+\.?$').hasMatch(t)) return null;
  return double.tryParse(t);
}

// -------------------------------------------------------------- list filters

enum StockFilter {
  all,
  inStock,
  low,
  out,
  negative;

  String labelIn(AppLocalizations l) => switch (this) {
        StockFilter.all => l.prodStockAll,
        StockFilter.inStock => l.prodStockIn,
        StockFilter.low => l.prodStockLow,
        StockFilter.out => l.prodStockOut,
        StockFilter.negative => l.prodStockNegative,
      };
  String get label => labelIn(L.current);
}

enum ActiveFilter {
  active,
  archived,
  all;

  String labelIn(AppLocalizations l) => switch (this) {
        ActiveFilter.active => l.prodActive,
        ActiveFilter.archived => l.prodArchive,
        ActiveFilter.all => l.commonAll,
      };
  String get label => labelIn(L.current);
}

enum ProductSort {
  name,
  price,
  stock,
  margin,
  updated;

  String labelIn(AppLocalizations l) => switch (this) {
        ProductSort.name => l.prodSortName,
        ProductSort.price => l.prodSortPrice,
        ProductSort.stock => l.prodSortStock,
        ProductSort.margin => l.prodSortMargin,
        ProductSort.updated => l.prodSortUpdated,
      };
  String get label => labelIn(L.current);
}

/// Sentinel for "products without category" in the category filter.
const noCategoryId = '__none__';

/// Immutable list query (value equality — used as a provider family key).
class ProductQuery {
  const ProductQuery({
    this.search = '',
    this.categoryId,
    this.stock = StockFilter.all,
    this.active = ActiveFilter.active,
    this.sort = ProductSort.name,
    this.descending = false,
    this.favoritesOnly = false,
    this.limit = 100,
  });

  final String search;
  final String? categoryId;
  final StockFilter stock;
  final ActiveFilter active;
  final ProductSort sort;
  final bool descending;
  final bool favoritesOnly;
  final int limit;

  ProductQuery copyWith({
    String? search,
    String? Function()? categoryId,
    StockFilter? stock,
    ActiveFilter? active,
    ProductSort? sort,
    bool? descending,
    bool? favoritesOnly,
    int? limit,
  }) =>
      ProductQuery(
        search: search ?? this.search,
        categoryId: categoryId == null ? this.categoryId : categoryId(),
        stock: stock ?? this.stock,
        active: active ?? this.active,
        sort: sort ?? this.sort,
        descending: descending ?? this.descending,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        limit: limit ?? this.limit,
      );

  /// Same filter without the paging limit (used for count/export).
  ProductQuery get unlimited => copyWith(limit: 0);

  bool get isFiltered =>
      search.isNotEmpty ||
      categoryId != null ||
      stock != StockFilter.all ||
      active != ActiveFilter.active ||
      favoritesOnly;

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.stock == stock &&
      other.active == active &&
      other.sort == sort &&
      other.descending == descending &&
      other.favoritesOnly == favoritesOnly &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(search, categoryId, stock, active, sort, descending, favoritesOnly, limit);
}

/// SQLite LIKE is case-insensitive only for ASCII, so Cyrillic search is
/// done with several case variants of the query.
List<String> caseVariants(String q) {
  final lower = q.toLowerCase();
  final cap = lower.isEmpty ? lower : lower[0].toUpperCase() + lower.substring(1);
  return {q, lower, q.toUpperCase(), cap}.toList();
}

/// Strips LIKE wildcards from user input.
String likeSafe(String q) => q.replaceAll('%', '').replaceAll('_', '');

// ---------------------------------------------------------------------- units

/// Maps a unit text from CSV / user ("шт", "kg", "Кг.") to a unit code.
String? parseUnit(String? s) {
  final t = (s ?? '').trim().toLowerCase().replaceAll('.', '');
  if (t.isEmpty) return 'pcs';
  // Input aliases (matched against user/CSV text), not UI text.
  const map = {
    'pcs': 'pcs', 'шт': 'pcs', 'штук': 'pcs', 'штука': 'pcs', 'ед': 'pcs', 'pc': 'pcs', // l10n-ignore
    'kg': 'kg', 'кг': 'kg', 'килограмм': 'kg', // l10n-ignore
    'g': 'g', 'г': 'g', 'гр': 'g', 'грамм': 'g', // l10n-ignore
    'l': 'l', 'л': 'l', 'литр': 'l', // l10n-ignore
    'm': 'm', 'м': 'm', 'метр': 'm', // l10n-ignore
    'pack': 'pack', 'уп': 'pack', 'упак': 'pack', 'упаковка': 'pack', // l10n-ignore
  };
  final hit = map[t];
  if (hit != null) return hit;
  // Unit labels of every UI language (a CSV exported under uz/ky/en).
  for (final code in supportedLanguageCodes) {
    for (final u in Qty.units) {
      if (Qty.unitLabel(u, L.of(code)).toLowerCase().replaceAll('.', '') == t) return u;
    }
  }
  return null;
}

// ------------------------------------------------------------------------ CSV

/// Picks the delimiter that occurs most often (outside quotes) in the first
/// non-empty line. Priority on ties: tab, semicolon, comma.
String detectDelimiter(String text) {
  final line = text
      .replaceFirst('﻿', '')
      .split(RegExp(r'\r?\n'))
      .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  final counts = {'\t': 0, ';': 0, ',': 0};
  var inQ = false;
  for (final ch in line.split('')) {
    if (ch == '"') {
      inQ = !inQ;
    } else if (!inQ && counts.containsKey(ch)) {
      counts[ch] = counts[ch]! + 1;
    }
  }
  var best = ';';
  var bestN = 0;
  for (final d in ['\t', ';', ',']) {
    if (counts[d]! > bestN) {
      best = d;
      bestN = counts[d]!;
    }
  }
  return best;
}

/// RFC-4180-ish parser: quoted fields, doubled quotes, CRLF, BOM.
/// Fully empty lines are skipped.
List<List<String>> parseCsvRows(String text, String delimiter) {
  final src = text.replaceFirst('﻿', '');
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQ = false;
  var i = 0;
  void endCell() {
    row.add(cell.toString());
    cell.clear();
  }

  void endRow() {
    endCell();
    if (!(row.length == 1 && row.first.trim().isEmpty)) rows.add(row);
    row = <String>[];
  }

  while (i < src.length) {
    final ch = src[i];
    if (inQ) {
      if (ch == '"') {
        if (i + 1 < src.length && src[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQ = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"' && cell.isEmpty) {
      inQ = true;
    } else if (ch == delimiter) {
      endCell();
    } else if (ch == '\n') {
      endRow();
    } else if (ch == '\r') {
      // swallow; \n follows (or old-Mac line end)
      if (i + 1 >= src.length || src[i + 1] != '\n') endRow();
    } else {
      cell.write(ch);
    }
    i++;
  }
  if (cell.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

String csvEscape(String v, [String delimiter = ';']) {
  if (v.contains(delimiter) || v.contains('"') || v.contains('\n') || v.contains('\r')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String toCsv(List<List<String>> rows, {String delimiter = ';'}) =>
    rows.map((r) => r.map((c) => csvEscape(c, delimiter)).join(delimiter)).join('\r\n');

enum ImportField {
  name,
  barcode,
  sku,
  category,
  price,
  cost,
  unit,
  stock;

  String labelIn(AppLocalizations l) => switch (this) {
        ImportField.name => l.commonName,
        ImportField.barcode => l.commonBarcode,
        ImportField.sku => l.commonSku,
        ImportField.category => l.commonCategory,
        ImportField.price => l.commonPrice,
        ImportField.cost => l.commonCost,
        ImportField.unit => l.prodUnitShort,
        ImportField.stock => l.commonStock,
      };
  String get label => labelIn(L.current);
}

// CSV header aliases (matched against file headers), not UI text.
const _aliases = <ImportField, List<String>>{
  ImportField.name: ['name', 'название', 'наименование', 'товар', 'имя'], // l10n-ignore
  ImportField.barcode: ['barcode', 'штрихкод', 'штрих-код', 'штрих код', 'ean', 'шк'], // l10n-ignore
  ImportField.sku: ['sku', 'артикул', 'код', 'арт'], // l10n-ignore
  ImportField.category: ['category', 'категория', 'группа'], // l10n-ignore
  ImportField.price: ['price', 'цена', 'розница', 'цена продажи', 'розничная цена'], // l10n-ignore
  ImportField.cost: ['cost', 'себестоимость', 'закупка', 'закупочная цена', 'цена закупки', 'закупочная'], // l10n-ignore
  ImportField.unit: ['unit', 'ед', 'ед.', 'ед. изм.', 'единица', 'ед.изм.', 'ед изм'], // l10n-ignore
  ImportField.stock: ['stock', 'остаток', 'количество', 'кол-во', 'qty'], // l10n-ignore
};

ImportField? _fieldFor(String header) {
  final h = header.trim().toLowerCase().replaceAll('*', '').trim();
  for (final e in _aliases.entries) {
    if (e.value.contains(h)) return e.key;
  }
  return null;
}

/// Returns column mapping if [row] looks like a header (≥2 known names, or
/// the name column), otherwise null.
Map<ImportField, int>? detectHeader(List<String> row) {
  final map = <ImportField, int>{};
  for (var i = 0; i < row.length; i++) {
    final f = _fieldFor(row[i]);
    if (f != null && !map.containsKey(f)) map[f] = i;
  }
  if (map.length >= 2 || map.containsKey(ImportField.name)) return map;
  return null;
}

/// Default positional order when the file has no header.
const defaultImportOrder = [
  ImportField.name,
  ImportField.barcode,
  ImportField.sku,
  ImportField.category,
  ImportField.price,
  ImportField.cost,
  ImportField.unit,
  ImportField.stock,
];

class ImportRow {
  ImportRow(this.line);

  /// 1-based line in the source text (including the header).
  final int line;
  String name = '';
  String? barcode;
  String? sku;
  String? category;
  int? price;
  int? cost;
  String unit = 'pcs';

  /// True when the unit cell was filled (otherwise [unit] is the default).
  bool unitGiven = false;
  double? stock;
  final errors = <String>[];
  final warnings = <String>[];

  bool get isValid => errors.isEmpty;
}

class ImportParseResult {
  ImportParseResult({
    required this.delimiter,
    required this.hasHeader,
    required this.columns,
    required this.rows,
  });

  final String delimiter;
  final bool hasHeader;
  final Map<ImportField, int> columns;
  final List<ImportRow> rows;

  int get validCount => rows.where((r) => r.isValid).length;
  int get errorCount => rows.length - validCount;

  String get delimiterLabel => switch (delimiter) {
        '\t' => L.current.prodDelimTab,
        ';' => L.current.prodDelimSemicolon,
        ',' => L.current.prodDelimComma,
        _ => delimiter,
      };
}

final _moneyRe = RegExp(r'^\d+([.,]\d+)?$');
final _sciRe = RegExp(r'^\d+([.,]\d+)?[eE][+-]?\d+$');

int? _parseMoneyCell(String raw, CurrencyConfig c, List<String> errors, String label,
    {bool required = false}) {
  final t = raw.replaceAll(RegExp(r'[\s ]'), '');
  if (t.isEmpty) {
    if (required) errors.add(L.current.prodImpErrMissing(label));
    return null;
  }
  if (t.startsWith('-')) {
    errors.add(L.current.prodImpErrNegative(label));
    return null;
  }
  if (!_moneyRe.hasMatch(t)) {
    errors.add(L.current.prodImpErrNotNumber(label, raw));
    return null;
  }
  return Money.parse(t, c: c);
}

/// Parses pasted CSV/TSV text into validated import rows.
ImportParseResult parseImport(String text, {CurrencyConfig? currency}) {
  final c = currency ?? Money.currency;
  final l = L.current;
  final delim = detectDelimiter(text);
  final raw = parseCsvRows(text, delim);
  if (raw.isEmpty) {
    return ImportParseResult(delimiter: delim, hasHeader: false, columns: const {}, rows: const []);
  }
  final header = detectHeader(raw.first);
  final cols = header ??
      {for (var i = 0; i < defaultImportOrder.length; i++) defaultImportOrder[i]: i};
  final rows = <ImportRow>[];
  final seenBarcodes = <String, int>{};
  // Line numbers: parseCsvRows skips blank lines, so we track by index.
  for (var i = header == null ? 0 : 1; i < raw.length; i++) {
    final cells = raw[i];
    String cell(ImportField f) {
      final idx = cols[f];
      if (idx == null || idx >= cells.length) return '';
      return cells[idx].trim();
    }

    final r = ImportRow(i + 1);
    r.name = cell(ImportField.name);
    if (r.name.isEmpty) r.errors.add(l.prodImpErrNoName);
    if (r.name.length > 200) r.errors.add(l.prodNameTooLong);

    final bc = cell(ImportField.barcode);
    if (bc.isNotEmpty) {
      if (_sciRe.hasMatch(bc)) {
        r.errors.add(l.prodImpErrBarcodeSci(bc));
      } else {
        r.barcode = bc;
        final prev = seenBarcodes[bc];
        if (prev != null) {
          r.errors.add(l.prodImpErrBarcodeDup(bc, '$prev'));
        } else {
          seenBarcodes[bc] = r.line;
        }
        if (RegExp(r'^\d{13}$').hasMatch(bc) && !Ean13.isValid(bc)) {
          r.warnings.add(l.prodEan13BadCheck);
        }
      }
    }
    final sku = cell(ImportField.sku);
    r.sku = sku.isEmpty ? null : sku;
    final cat = cell(ImportField.category);
    r.category = cat.isEmpty ? null : cat;

    r.price = _parseMoneyCell(cell(ImportField.price), c, r.errors, l.commonPrice, required: true);
    r.cost = _parseMoneyCell(cell(ImportField.cost), c, r.errors, l.commonCost);

    final unitRaw = cell(ImportField.unit);
    final unit = parseUnit(unitRaw);
    if (unit == null) {
      r.errors.add(l.prodImpErrUnit(unitRaw));
    } else {
      r.unit = unit;
      r.unitGiven = unitRaw.isNotEmpty;
    }

    final stockRaw = cell(ImportField.stock);
    if (stockRaw.isNotEmpty) {
      final q = parseDecimal(stockRaw);
      if (q == null) {
        r.errors.add(l.prodImpErrStockNotNumber(stockRaw));
      } else if (q < 0) {
        r.errors.add(l.prodImpErrStockNegative);
      } else {
        if (unit != null && !Qty.isFractional(unit) && q != q.roundToDouble()) {
          r.errors.add(l.prodImpErrStockInteger(Qty.unitLabel(unit, l)));
        }
        r.stock = Qty.round(q);
      }
    }
    if (r.price != null && r.cost != null && r.price! < r.cost!) {
      r.warnings.add(l.prodPriceBelowCost);
    }
    rows.add(r);
  }
  return ImportParseResult(delimiter: delim, hasHeader: header != null, columns: cols, rows: rows);
}

/// Formats minor units for CSV (no grouping, decimal comma): 12500,5.
String moneyCsv(int minor, [CurrencyConfig? c]) =>
    Money.toInput(minor, c: c).replaceAll('.', ',');

/// Quantity for CSV (decimal comma).
String qtyCsv(double q) {
  final r = Qty.round(q);
  if (r == r.truncateToDouble()) return r.toStringAsFixed(0);
  return r.toString().replaceAll('.', ',');
}

/// Labels for stock movement types ([l] defaults to the UI language).
String movementTypeLabel(String type, [AppLocalizations? l]) {
  final t = l ?? L.current;
  return switch (type) {
    'sale' => t.commonSale,
    'return' => t.commonReturn,
    'receipt' => t.prodMoveReceipt,
    'receipt_reversal' => t.prodMoveReceiptReversal,
    'writeoff' => t.prodMoveWriteoff,
    'adjustment' => t.prodMoveAdjustment,
    'inventory' => t.prodMoveInventory,
    'transfer' => t.prodMoveTransfer,
    _ => type,
  };
}

/// VAT presets common in the region (UZ 12%, KZ 12%, TJ 15%, RU 20%).
const vatPresets = <double>[0, 12, 15, 20];

/// VAT % for a new product from the raw `default_vat_percent` setting
/// ("12", "12,5", "12%"). Missing or invalid (outside 0–100) → 0.
double defaultVatFromSetting(String? raw) {
  final x = parseDecimal(raw?.replaceAll('%', ''));
  if (x == null || x.isNaN || x < 0 || x > 100) return 0;
  return x;
}

/// Palette for categories (ARGB).
const categoryPalette = <int>[
  0xFF4F46E5, 0xFF0EA5E9, 0xFF14B8A6, 0xFF22C55E, 0xFF84CC16, 0xFFEAB308,
  0xFFF97316, 0xFFEF4444, 0xFFEC4899, 0xFFA855F7, 0xFF64748B, 0xFF78350F,
];
