import 'package:dreampos/core/money.dart';
import 'package:dreampos/features/products/product_logic.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

const uzs = CurrencyConfig(code: 'UZS', symbol: 'сум', decimals: 0);
const tjs = CurrencyConfig(code: 'TJS', symbol: 'сом.', decimals: 2);

void main() {
  group('EAN-13', () {
    test('check digit of known codes', () {
      expect(Ean13.checkDigit('400638133393'), 1);
      expect(Ean13.checkDigit('590123412345'), 7);
      expect(Ean13.checkDigit('460000000000'), 8); // 4*1 + 6*3 = 22
    });

    test('isValid accepts real codes and rejects wrong check digit', () {
      expect(Ean13.isValid('4006381333931'), isTrue);
      expect(Ean13.isValid('5901234123457'), isTrue);
      expect(Ean13.isValid('4006381333932'), isFalse);
      expect(Ean13.isValid('400638133393'), isFalse);
      expect(Ean13.isValid('40063813339A1'), isFalse);
      expect(Ean13.isValid(null), isFalse);
    });

    test('internal codes: prefix 200, 13 digits, valid check digit, round-trip seq', () {
      expect(Ean13.internal(1), '2000000000015');
      for (final seq in [1, 2, 42, 999, 123456789, 999999999]) {
        final code = Ean13.internal(seq);
        expect(code.length, 13);
        expect(code.startsWith('200'), isTrue);
        expect(Ean13.isValid(code), isTrue, reason: code);
        expect(Ean13.internalSeq(code), seq);
      }
      expect(Ean13.internalSeq('4006381333931'), isNull);
      expect(() => Ean13.internal(1000000000), throwsRangeError);
    });

    test('EAN-8 validation', () {
      expect(Ean13.isValidEan8('96385074'), isTrue);
      expect(Ean13.isValidEan8('96385075'), isFalse);
    });
  });

  group('price rounding', () {
    test('roundToStep modes', () {
      expect(roundToStep(12345, 100), 12300);
      expect(roundToStep(12350, 100), 12400);
      expect(roundToStep(12301, 100, RoundMode.up), 12400);
      expect(roundToStep(12399, 100, RoundMode.down), 12300);
      expect(roundToStep(12300, 100, RoundMode.up), 12300);
      expect(roundToStep(12345, 1), 12345);
    });

    test('applyPercentChange with currency steps', () {
      expect(applyPercentChange(10000, 10, step: 100), 11000);
      expect(applyPercentChange(12345, 7, step: 100), 13200); // 13209.15 -> 13200
      expect(applyPercentChange(12345, 7, step: 100, mode: RoundMode.up), 13300);
      expect(applyPercentChange(12345, -5, step: 1000, mode: RoundMode.down), 11000);
      expect(applyPercentChange(999, 0.5), 1004); // 1003.995 -> 1004
      // positive price never becomes 0 because of rounding
      expect(applyPercentChange(40, 0, step: 100), 100);
      expect(applyPercentChange(5000, -100, step: 100), 0);
    });

    test('rounding step presets depend on currency decimals', () {
      expect(roundingStepsMinor(uzs), [1, 10, 100, 500, 1000]);
      expect(roundingStepsMinor(tjs), [1, 10, 100, 1000, 10000, 50000, 100000]);
      expect(roundingStepLabel(1, uzs), 'Без округления');
    });

    test('margin and markup', () {
      expect(marginPercent(1000, 600), 40);
      expect(markupPercent(1000, 600), closeTo(66.67, 0.01));
      expect(marginPercent(0, 600), isNull);
      expect(markupPercent(1000, 0), isNull);
      expect(formatPercent(12.5), '12,5%');
      expect(formatPercent(40), '40%');
    });
  });

  group('CSV', () {
    test('delimiter auto-detect', () {
      expect(detectDelimiter('a;b;c\n1;2;3'), ';');
      expect(detectDelimiter('a,b,c\n1,2,3'), ',');
      expect(detectDelimiter('a\tb\tc'), '\t');
      expect(detectDelimiter('"x;y",b,c'), ',', reason: 'quoted delimiter ignored');
      expect(detectDelimiter('﻿name;price'), ';');
    });

    test('quoted fields, doubled quotes, CRLF and blank lines', () {
      final rows = parseCsvRows('a;"b;c";"say ""hi"""\r\n\r\n1;"multi\nline";3\r\n', ';');
      expect(rows, [
        ['a', 'b;c', 'say "hi"'],
        ['1', 'multi\nline', '3'],
      ]);
    });

    test('toCsv escapes and round-trips', () {
      final data = [
        ['Молоко; 1 л', 'x"y', ''],
        ['a', 'b', 'c'],
      ];
      expect(parseCsvRows(toCsv(data), ';'), data);
    });

    test('parseImport with header (any order), comma decimals and units', () {
      const text = 'Цена;Название;Штрихкод;Ед.;Остаток;Категория;Себестоимость\n'
          '"12 500,50";Сахар;4006381333931;кг;12,5;Бакалея;10000\n'
          '3000;Хлеб;;шт;10;;\n';
      final r = parseImport(text, currency: tjs);
      expect(r.hasHeader, isTrue);
      expect(r.delimiter, ';');
      expect(r.rows, hasLength(2));
      final a = r.rows[0];
      expect(a.isValid, isTrue, reason: a.errors.join());
      expect(a.name, 'Сахар');
      expect(a.price, 1250050);
      expect(a.cost, 1000000);
      expect(a.unit, 'kg');
      expect(a.stock, 12.5);
      expect(a.category, 'Бакалея');
      expect(a.barcode, '4006381333931');
      expect(a.line, 2);
      final b = r.rows[1];
      expect(b.isValid, isTrue);
      expect(b.barcode, isNull);
      expect(b.category, isNull);
      expect(b.price, 300000);
    });

    test('parseImport without header uses default column order; tab separated', () {
      const text = 'Молоко\t4870001234561\tM-1\tМолочные\t12000\t9500\tшт\t24';
      final r = parseImport(text, currency: uzs);
      expect(r.hasHeader, isFalse);
      expect(r.delimiter, '\t');
      final row = r.rows.single;
      expect(row.isValid, isTrue, reason: row.errors.join());
      expect(row.sku, 'M-1');
      expect(row.price, 12000);
      expect(row.cost, 9500);
      expect(row.stock, 24);
      expect(row.warnings, contains('Неверная контрольная цифра EAN-13'));
    });

    test('parseImport reports per-row errors', () {
      const text = 'name,barcode,price,unit,stock\n'
          ',111,100,шт,1\n' // no name
          'A,4.60123E+12,100,шт,1\n' // Excel-mangled barcode
          'B,222,abc,шт,1\n' // bad price
          'C,333,100,ящик,1\n' // unknown unit
          'D,333,100,шт,1\n' // duplicate barcode in file -> ok first time? (333 first seen at C)
          'E,444,100,шт,1.5\n' // fractional pcs
          'F,555,-5,шт,\n' // negative price
          'G,666,,кг,-1\n'; // missing price, negative stock
      final r = parseImport(text, currency: uzs);
      expect(r.delimiter, ',');
      final e = r.rows.map((x) => x.errors.join('|')).toList();
      expect(e[0], contains('название'));
      expect(e[1], contains('Excel'));
      expect(e[2], contains('не число'));
      expect(e[3], contains('ед. изм.'));
      expect(e[4], contains('повторяется'));
      expect(e[5], contains('целым'));
      expect(e[6], contains('отрицательной'));
      expect(e[7], allOf(contains('Цена: не указана'), contains('отрицательным')));
      expect(r.validCount, 0);
      expect(r.errorCount, 8);
    });

    test('parseUnit and parseDecimal', () {
      expect(parseUnit('Кг.'), 'kg');
      expect(parseUnit(''), 'pcs');
      expect(parseUnit('уп'), 'pack');
      expect(parseUnit('коробка'), isNull);
      // Unit labels of every UI language re-import (CSV written under uz/ky).
      for (final code in supportedLanguageCodes) {
        for (final u in Qty.units) {
          expect(parseUnit(Qty.unitLabel(u, L.of(code))), u, reason: '$code $u');
        }
      }
      expect(parseDecimal('1 234,5'), 1234.5);
      expect(parseDecimal('abc'), isNull);
      expect(parseDecimal('1.2.3'), isNull);
    });

    test('money/qty CSV formatting round-trips through parseImport', () {
      expect(moneyCsv(1250050, tjs), '12500,5');
      expect(moneyCsv(12000, uzs), '12000');
      expect(qtyCsv(12.5), '12,5');
      expect(qtyCsv(3), '3');
    });
  });

  test('case variants for Cyrillic search', () {
    expect(caseVariants('мол'), containsAll(['мол', 'МОЛ', 'Мол']));
    expect(likeSafe('50%_off'), '50off');
  });

  test('ProductQuery equality (provider family key)', () {
    const a = ProductQuery(search: 'x', limit: 100);
    expect(a, const ProductQuery(search: 'x', limit: 100));
    expect(a == a.copyWith(limit: 200), isFalse);
    expect(a.copyWith(categoryId: () => 'c').categoryId, 'c');
    expect(a.copyWith(categoryId: () => 'c').copyWith(categoryId: () => null).categoryId, isNull);
    expect(const ProductQuery().isFiltered, isFalse);
    expect(a.isFiltered, isTrue);
  });

  test('defaultVatFromSetting parses the setting, falls back to 0', () {
    expect(defaultVatFromSetting(null), 0);
    expect(defaultVatFromSetting(''), 0);
    expect(defaultVatFromSetting('12'), 12);
    expect(defaultVatFromSetting('12,5'), 12.5);
    expect(defaultVatFromSetting('15%'), 15);
    expect(defaultVatFromSetting('abc'), 0);
    expect(defaultVatFromSetting('150'), 0);
    expect(defaultVatFromSetting('-1'), 0);
  });
}
