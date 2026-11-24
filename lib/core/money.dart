import 'package:intl/intl.dart';

/// Currency configuration. Money is always an `int` of minor units;
/// `decimals` says how many minor digits one major unit has
/// (UZS/TJS cash practice: 0 or 2; USD: 2).
class CurrencyConfig {
  const CurrencyConfig({
    this.code = 'UZS',
    this.symbol = 'сум',
    this.decimals = 0,
    this.symbolBefore = false,
  });

  final String code;
  final String symbol;
  final int decimals;
  final bool symbolBefore;

  int get factor {
    var f = 1;
    for (var i = 0; i < decimals; i++) {
      f *= 10;
    }
    return f;
  }

  static CurrencyConfig fromSettings(Map<String, String> s) => CurrencyConfig(
        code: s['currency_code'] ?? 'UZS',
        symbol: s['currency_symbol'] ?? 'сум',
        decimals: int.tryParse(s['currency_decimals'] ?? '') ?? 0,
        symbolBefore: s['currency_symbol_before'] == '1',
      );

  static const presets = <CurrencyConfig>[
    CurrencyConfig(code: 'UZS', symbol: 'сум', decimals: 0),
    CurrencyConfig(code: 'TJS', symbol: 'сом.', decimals: 2),
    CurrencyConfig(code: 'KZT', symbol: '₸', decimals: 0),
    CurrencyConfig(code: 'KGS', symbol: 'сом', decimals: 2),
    CurrencyConfig(code: 'RUB', symbol: '₽', decimals: 2),
    CurrencyConfig(code: 'USD', symbol: r'$', decimals: 2, symbolBefore: true),
  ];
}

class Money {
  Money._();

  static CurrencyConfig currency = const CurrencyConfig();

  /// Formats minor units, e.g. 1234500 -> "1 234 500 сум".
  static String format(int minor, {bool withSymbol = true, CurrencyConfig? c}) {
    final cfg = c ?? currency;
    final neg = minor < 0;
    final abs = minor.abs();
    final major = abs ~/ cfg.factor;
    final frac = abs % cfg.factor;
    final grouped = NumberFormat('#,##0', 'en_US')
        .format(major)
        .replaceAll(',', ' ');
    var s = grouped;
    if (cfg.decimals > 0) {
      s += ',${frac.toString().padLeft(cfg.decimals, '0')}';
    }
    if (neg) s = '−$s';
    if (!withSymbol) return s;
    return cfg.symbolBefore ? '${cfg.symbol}$s' : '$s ${cfg.symbol}';
  }

  /// Parses user input ("12 500,50", "12500.5") into minor units.
  /// Returns null on invalid input.
  static int? parse(String input, {CurrencyConfig? c}) {
    final cfg = c ?? currency;
    var t = input.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
    t = t.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (t.isEmpty || t == '-' || t == '.') return null;
    if ('.'.allMatches(t).length > 1) return null;
    final v = double.tryParse(t);
    if (v == null || v.isNaN || v.isInfinite) return null;
    return (v * cfg.factor).round();
  }

  /// Minor units -> editable string without grouping ("12500.5").
  static String toInput(int minor, {CurrencyConfig? c}) {
    final cfg = c ?? currency;
    if (cfg.decimals == 0) return (minor ~/ cfg.factor).toString();
    final v = minor / cfg.factor;
    var s = v.toStringAsFixed(cfg.decimals);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Rounds percent of an amount, half-up.
  static int percent(int amount, double pct) => (amount * pct / 100).round();
}

class Qty {
  Qty._();

  static double round(double q) => (q * 1000).roundToDouble() / 1000;

  static String format(double q, [String? unit]) {
    final r = round(q);
    final s = r == r.truncateToDouble()
        ? r.toStringAsFixed(0)
        : r.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(',', '.');
    final u = unit == null ? '' : ' ${unitLabel(unit)}';
    return '$s$u'.replaceAll('.', ',');
  }

  static const units = ['pcs', 'kg', 'g', 'l', 'm', 'pack'];

  static String unitLabel(String unit) => switch (unit) {
        'pcs' => 'шт',
        'kg' => 'кг',
        'g' => 'г',
        'l' => 'л',
        'm' => 'м',
        'pack' => 'уп',
        _ => unit,
      };

  static bool isFractional(String unit) => unit == 'kg' || unit == 'l' || unit == 'm';
}
