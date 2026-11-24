// Quick-tender helpers for the payment dialog: banknote denominations per
// currency and "round up" suggestions for the cash received field.
import '../../core/money.dart';

/// Banknote (and big coin) denominations in MAJOR units.
List<int> banknotesMajor(String currencyCode) => switch (currencyCode) {
      'UZS' => const [1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000],
      'TJS' => const [1, 3, 5, 10, 20, 50, 100, 200, 500],
      'KZT' => const [200, 500, 1000, 2000, 5000, 10000, 20000],
      'KGS' => const [20, 50, 100, 200, 500, 1000, 2000, 5000],
      'RUB' => const [50, 100, 200, 500, 1000, 2000, 5000],
      'USD' => const [1, 5, 10, 20, 50, 100],
      _ => const [1, 5, 10, 50, 100, 500, 1000, 5000],
    };

List<int> banknotesMinor(CurrencyConfig c) =>
    [for (final b in banknotesMajor(c.code)) b * c.factor];

/// Suggested cash amounts strictly greater than [due]: the amount rounded up
/// to each banknote, plus single banknotes that cover it. Sorted, unique.
List<int> quickTenders(int due, CurrencyConfig c, {int max = 4}) {
  if (due <= 0) return const [];
  final notes = banknotesMinor(c);
  final out = <int>{};
  for (final n in notes) {
    final up = ((due + n - 1) ~/ n) * n;
    if (up > due) out.add(up);
  }
  final list = out.toList()..sort();
  return list.take(max).toList();
}
