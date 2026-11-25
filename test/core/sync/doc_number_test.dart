import 'package:dreampos/core/doc_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('docNo: N without a code, CODE-N with one', () {
    expect(docNo(15, null), '15');
    expect(docNo(15, ''), '15');
    expect(docNo(15, '  '), '15');
    expect(docNo(15, 'A'), 'A-15');
    expect(docNo(7, 'AB'), 'AB-7');
  });

  test('parseDocNo accepts 15, №15, A-15, a15, AB-7', () {
    expect(parseDocNo('15'), (code: null, number: 15));
    expect(parseDocNo(' №15 '), (code: null, number: 15));
    expect(parseDocNo('#15'), (code: null, number: 15));
    expect(parseDocNo('A-15'), (code: 'A', number: 15));
    expect(parseDocNo('a15'), (code: 'A', number: 15));
    expect(parseDocNo('№ab-7'), (code: 'AB', number: 7));
    expect(parseDocNo('A - 3'), (code: 'A', number: 3));
    for (final bad in ['', 'A', 'A-', 'Чай', '15-A', 'ABCD-1', '1.5', '-3']) {
      expect(parseDocNo(bad), isNull, reason: bad);
    }
    for (final n in [1, 42, 123456]) {
      for (final c in [null, 'A', 'ZZ']) {
        final p = parseDocNo(docNo(n, c))!;
        expect((p.code, p.number), (c, n));
      }
    }
  });
}
