import 'dart:math';

import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/features/customers/customer_logic.dart';
import 'package:flutter_test/flutter_test.dart';

Customer cust(
  String id, {
  String? name,
  String? phone,
  String? card,
  DateTime? birthday,
  int debt = 0,
  int bonus = 0,
  int spent = 0,
  int visits = 0,
  DateTime? lastVisit,
  String? tags,
}) =>
    Customer(
      id: id,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      name: name ?? 'Клиент $id',
      phone: phone,
      cardNumber: card,
      birthday: birthday,
      discountPercent: 0,
      bonusBalance: bonus,
      debtBalance: debt,
      debtLimit: 0,
      totalSpent: spent,
      visits: visits,
      lastVisitAt: lastVisit,
      tags: tags,
    );

void main() {
  group('birthdays', () {
    test('today is 0 days, window includes next 6 days', () {
      final now = DateTime(2026, 11, 24, 15, 30);
      expect(daysUntilBirthday(DateTime(1990, 11, 24), now), 0);
      expect(daysUntilBirthday(DateTime(1990, 11, 30), now), 6);
      expect(hasBirthdaySoon(DateTime(1990, 11, 30), now), isTrue);
      expect(hasBirthdaySoon(DateTime(1990, 12, 1), now), isFalse);
      expect(hasBirthdaySoon(DateTime(1990, 11, 23), now), isFalse, reason: 'yesterday → next year');
      expect(hasBirthdaySoon(null, now), isFalse);
    });

    test('crosses the year boundary', () {
      final now = DateTime(2026, 12, 29);
      expect(daysUntilBirthday(DateTime(1985, 1, 2), now), 4);
      expect(hasBirthdaySoon(DateTime(1985, 1, 2), now), isTrue);
      expect(hasBirthdaySoon(DateTime(1985, 1, 5), now), isFalse);
      expect(daysUntilBirthday(DateTime(1985, 12, 28), now), 364);
    });

    test('Feb 29 is celebrated on Feb 28 in non-leap years', () {
      expect(daysUntilBirthday(DateTime(2000, 2, 29), DateTime(2027, 2, 27)), 1);
      expect(daysUntilBirthday(DateTime(2000, 2, 29), DateTime(2028, 2, 28)), 1);
    });
  });

  group('segments', () {
    final now = DateTime(2026, 11, 24);

    test('sleeping: bought before but not in 60+ days', () {
      expect(isSleeping(cust('a', lastVisit: now.subtract(const Duration(days: 61))), now), isTrue);
      expect(isSleeping(cust('b', lastVisit: now.subtract(const Duration(days: 30))), now), isFalse);
      expect(isSleeping(cust('c'), now), isFalse, reason: 'never bought');
    });

    test('VIP = top 10% by total spent (at least one)', () {
      final list = [for (var i = 1; i <= 20; i++) cust('$i', spent: i * 1000)] + [cust('zero')];
      expect(vipThreshold(list), 19000);
      final vip = applyCustomerQuery(list, const CustomerQuery(segment: CustomerSegment.vip), now: now);
      expect(vip.map((c) => c.id), unorderedEquals(['20', '19']));
      expect(vipThreshold([cust('x')]), isNull);
      expect(vipThreshold([cust('x', spent: 5)]), 5);
    });

    test('debtors, overdue, birthdays, tag and search filters', () {
      final list = [
        cust('d1', debt: 500, phone: '+998901234567'),
        cust('d2', debt: 300, tags: 'опт, VIP'),
        cust('b1', birthday: DateTime(1990, 11, 26), card: '2900000000017'),
        cust('n', name: 'Анна Петрова'),
      ];
      List<String> ids(CustomerQuery q) =>
          applyCustomerQuery(list, q, now: now, overdue: {'d2': 300}).map((c) => c.id).toList();
      expect(ids(const CustomerQuery(segment: CustomerSegment.debtors)), unorderedEquals(['d1', 'd2']));
      expect(ids(const CustomerQuery(segment: CustomerSegment.overdue)), ['d2']);
      expect(ids(const CustomerQuery(segment: CustomerSegment.birthdays)), ['b1']);
      expect(ids(const CustomerQuery(tag: 'опт')), ['d2']);
      expect(ids(const CustomerQuery(search: '90 123')), ['d1']);
      expect(ids(const CustomerQuery(search: 'петр')), ['n']);
      expect(ids(const CustomerQuery(search: '29000000')), ['b1']);
      expect(ids(const CustomerQuery(sort: CustomerSort.debt)).take(2), ['d1', 'd2']);
    });
  });

  group('overdue debt (FIFO)', () {
    final now = DateTime(2026, 11, 24);
    DebtCharge ch(int amount, DateTime created, DateTime? due) =>
        DebtCharge(customerId: 'c', amount: amount, createdAt: created, dueDate: due);

    test('payments cover oldest charges first', () {
      final charges = [
        ch(1000, DateTime(2026, 10, 1), DateTime(2026, 10, 15)), // overdue but paid
        ch(500, DateTime(2026, 11, 1), DateTime(2026, 11, 10)), // overdue, unpaid
        ch(700, DateTime(2026, 11, 20), DateTime(2026, 12, 20)), // not yet due
      ];
      // balance 1200 = 700 (newest) + 500
      expect(computeOverdue(charges, {'c': 1200}, now), {'c': 500});
      // partially paid second charge: balance 900 = 700 + 200 of the 500
      expect(computeOverdue(charges, {'c': 900}, now), {'c': 200});
      // only the newest remains → nothing overdue
      expect(computeOverdue(charges, {'c': 700}, now), isEmpty);
      expect(computeOverdue(charges, {'c': 0}, now), isEmpty);
      expect(earliestUnpaidDue(charges, 1200), DateTime(2026, 11, 10));
    });

    test('charges without due date never become overdue', () {
      expect(computeOverdue([ch(1000, DateTime(2025, 1, 1), null)], {'c': 1000}, now), isEmpty);
    });
  });

  group('fields', () {
    test('phone normalisation and duplicate key', () {
      expect(normalizePhone('+998 (90) 123-45-67'), '+998901234567');
      expect(normalizePhone('998901234567'), '+998901234567');
      expect(normalizePhone('90 123 45 67'), '901234567');
      expect(normalizePhone('  '), '');
      expect(phoneKey('+998901234567'), phoneKey('90-123-45-67'));
    });

    test('generated card number is a valid in-store EAN-13', () {
      final r = Random(42);
      final seen = <String>{};
      for (var i = 0; i < 200; i++) {
        final c = generateCardNumber(r);
        expect(c, hasLength(13));
        expect(c.startsWith('29'), isTrue);
        expect(int.parse(c[12]), ean13CheckDigit(c.substring(0, 12)));
        seen.add(c);
      }
      expect(seen.length, 200);
      expect(ean13CheckDigit('400638133393'), 1); // known EAN 4006381333931
    });

    test('tags parse/join', () {
      expect(parseTags(' опт, ,VIP,опт '), ['опт', 'VIP']);
      expect(joinTags(['', ' ']), isNull);
      expect(allTags([cust('a', tags: 'b, a'), cust('b', tags: 'c')]), ['a', 'b', 'c']);
    });

    test('initials', () {
      expect(initials('анна петрова'), 'АП');
      expect(initials('Bob'), 'B');
      expect(initials(' '), '?');
    });
  });

  group('texts', () {
    test('debt reminder mentions name, store and amount', () {
      final t = debtReminderText(name: 'Алишер', store: 'Магазин', debt: 150000, overdue: 50000);
      expect(t, startsWith('Здравствуйте, Алишер! Ваш долг в Магазин составляет ${Money.format(150000)}'));
      expect(t, contains('просрочено: ${Money.format(50000)}'));
    });

    test('template placeholders', () {
      final c = cust('x', name: 'Анна Петрова', debt: 1000, bonus: 250);
      expect(fillTemplate('{name}/{fullname}/{store}/{debt}/{bonus}', c, store: 'S'),
          'Анна/Анна Петрова/S/${Money.format(1000)}/${Money.format(250)}');
    });

    test('csv escapes separators and quotes', () {
      final csv = customersCsv([cust('x', name: 'ООО "Ромашка"; опт', phone: '+1')]);
      final lines = csv.trim().split('\n');
      expect(lines, hasLength(2));
      expect(lines[1], startsWith('"ООО ""Ромашка""; опт";+1;'));
    });
  });
}
