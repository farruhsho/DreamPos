// Pure CRM logic: segments, phone normalisation, card numbers, overdue debt
// (FIFO), CSV export, reminder texts. No Flutter widgets here so that the
// rules are fully unit-testable and can be reused by the marketing module.
import 'dart:math';

import '../../core/db/database.dart';
import '../../core/money.dart';

// ------------------------------------------------------------------ segments

enum CustomerSegment {
  all('Все'),
  debtors('Должники'),
  overdue('Просрочка'),
  vip('VIP'),
  sleeping('Спящие'),
  birthdays('Именинники');

  const CustomerSegment(this.label);
  final String label;

  String get hint => switch (this) {
        all => 'Все клиенты',
        debtors => 'Клиенты с непогашенным долгом',
        overdue => 'Срок оплаты долга прошёл',
        vip => 'Топ-10% клиентов по сумме покупок',
        sleeping => 'Не покупали больше $sleepingDays дней',
        birthdays => 'День рождения в ближайшие $birthdayWindowDays дней',
      };
}

const sleepingDays = 60;
const birthdayWindowDays = 7;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Days until the next birthday (0 = today). Null if birthday unknown.
/// Feb 29 birthdays are celebrated on Feb 28 in non-leap years.
int? daysUntilBirthday(DateTime? birthday, DateTime now) {
  if (birthday == null) return null;
  final today = _dateOnly(now);
  DateTime occurrence(int year) {
    var day = birthday.day;
    if (birthday.month == 2 && day == 29 && !_isLeap(year)) day = 28;
    return DateTime(year, birthday.month, day);
  }

  var next = occurrence(today.year);
  if (next.isBefore(today)) next = occurrence(today.year + 1);
  // Use UTC-free day arithmetic to be DST-safe.
  return DateTime.utc(next.year, next.month, next.day)
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays;
}

bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

/// Birthday within the next [days] days, today included.
bool hasBirthdaySoon(DateTime? birthday, DateTime now, {int days = birthdayWindowDays}) {
  final d = daysUntilBirthday(birthday, now);
  return d != null && d < days;
}

/// Customer bought before but not in the last [days] days.
bool isSleeping(Customer c, DateTime now, {int days = sleepingDays}) =>
    c.lastVisitAt != null && now.difference(c.lastVisitAt!).inDays > days;

/// Minimum totalSpent to be in the top 10% of buying customers.
/// Null when nobody bought anything yet.
int? vipThreshold(Iterable<Customer> customers, {double share = 0.10}) {
  final spent = customers.map((c) => c.totalSpent).where((s) => s > 0).toList()
    ..sort((a, b) => b.compareTo(a));
  if (spent.isEmpty) return null;
  final n = max(1, (spent.length * share).ceil());
  return spent[n - 1];
}

/// One debt_sale ledger row reduced to what overdue computation needs.
class DebtCharge {
  DebtCharge({required this.customerId, required this.amount, required this.createdAt, this.dueDate});
  final String customerId;
  final int amount;
  final DateTime createdAt;
  final DateTime? dueDate;
}

/// Overdue debt per customer. Payments are applied FIFO (oldest charges are
/// paid first), so the customer's current [debtBalance] consists of the most
/// recent charges. Every unpaid part of a charge whose due date has passed is
/// overdue. Charges without a due date never become overdue.
Map<String, int> computeOverdue(
    Iterable<DebtCharge> charges, Map<String, int> debtBalances, DateTime now) {
  final byCustomer = <String, List<DebtCharge>>{};
  for (final c in charges) {
    if (c.amount <= 0) continue;
    (byCustomer[c.customerId] ??= []).add(c);
  }
  final res = <String, int>{};
  byCustomer.forEach((id, list) {
    var remaining = debtBalances[id] ?? 0;
    if (remaining <= 0) return;
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
    var overdue = 0;
    for (final c in list) {
      if (remaining <= 0) break;
      final unpaid = min(remaining, c.amount);
      remaining -= unpaid;
      if (c.dueDate != null && c.dueDate!.isBefore(now)) overdue += unpaid;
    }
    if (overdue > 0) res[id] = overdue;
  });
  return res;
}

/// Earliest due date among still-unpaid charges (for reminders).
DateTime? earliestUnpaidDue(Iterable<DebtCharge> charges, int debtBalance) {
  final list = charges.where((c) => c.amount > 0).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  var remaining = debtBalance;
  DateTime? earliest;
  for (final c in list) {
    if (remaining <= 0) break;
    remaining -= min(remaining, c.amount);
    if (c.dueDate != null && (earliest == null || c.dueDate!.isBefore(earliest))) {
      earliest = c.dueDate;
    }
  }
  return earliest;
}

// ------------------------------------------------------------------ query

enum CustomerSort {
  name('По имени'),
  lastVisit('По последнему визиту'),
  spent('По сумме покупок'),
  debt('По долгу'),
  bonus('По бонусам'),
  created('Сначала новые');

  const CustomerSort(this.label);
  final String label;
}

class CustomerQuery {
  const CustomerQuery({
    this.search = '',
    this.segment = CustomerSegment.all,
    this.tag,
    this.sort = CustomerSort.name,
  });
  final String search;
  final CustomerSegment segment;
  final String? tag;
  final CustomerSort sort;

  CustomerQuery copyWith({
    String? search,
    CustomerSegment? segment,
    String? Function()? tag,
    CustomerSort? sort,
  }) =>
      CustomerQuery(
        search: search ?? this.search,
        segment: segment ?? this.segment,
        tag: tag != null ? tag() : this.tag,
        sort: sort ?? this.sort,
      );
}

/// Whether [c] belongs to [segment].
bool inSegment(Customer c, CustomerSegment segment,
    {required DateTime now, required Map<String, int> overdue, int? vipMin}) {
  return switch (segment) {
    CustomerSegment.all => true,
    CustomerSegment.debtors => c.debtBalance > 0,
    CustomerSegment.overdue => (overdue[c.id] ?? 0) > 0,
    CustomerSegment.vip => vipMin != null && c.totalSpent >= vipMin && c.totalSpent > 0,
    CustomerSegment.sleeping => isSleeping(c, now),
    CustomerSegment.birthdays => hasBirthdaySoon(c.birthday, now),
  };
}

bool matchesSearch(Customer c, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (c.name.toLowerCase().contains(q)) return true;
  if ((c.cardNumber ?? '').toLowerCase().contains(q)) return true;
  if ((c.email ?? '').toLowerCase().contains(q)) return true;
  final digits = q.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 3 && (c.phone ?? '').replaceAll(RegExp(r'\D'), '').contains(digits)) {
    return true;
  }
  return false;
}

List<Customer> applyCustomerQuery(List<Customer> all, CustomerQuery q,
    {required DateTime now, Map<String, int> overdue = const {}}) {
  final vipMin = q.segment == CustomerSegment.vip ? vipThreshold(all) : null;
  final res = all
      .where((c) =>
          inSegment(c, q.segment, now: now, overdue: overdue, vipMin: vipMin) &&
          (q.tag == null || parseTags(c.tags).contains(q.tag)) &&
          matchesSearch(c, q.search))
      .toList();
  int byName(Customer a, Customer b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
  int cmp(Customer a, Customer b) {
    final r = switch (q.sort) {
      CustomerSort.name => 0,
      CustomerSort.lastVisit => (b.lastVisitAt ?? DateTime(0)).compareTo(a.lastVisitAt ?? DateTime(0)),
      CustomerSort.spent => b.totalSpent.compareTo(a.totalSpent),
      CustomerSort.debt => b.debtBalance.compareTo(a.debtBalance),
      CustomerSort.bonus => b.bonusBalance.compareTo(a.bonusBalance),
      CustomerSort.created => b.createdAt.compareTo(a.createdAt),
    };
    return r != 0 ? r : byName(a, b);
  }

  if (q.segment == CustomerSegment.birthdays && q.sort == CustomerSort.name) {
    res.sort((a, b) {
      final r = (daysUntilBirthday(a.birthday, now) ?? 999)
          .compareTo(daysUntilBirthday(b.birthday, now) ?? 999);
      return r != 0 ? r : byName(a, b);
    });
  } else {
    res.sort(cmp);
  }
  return res;
}

// ------------------------------------------------------------------ fields

/// Normalises a phone: keeps digits and a leading "+".
/// "+998 (90) 123-45-67" -> "+998901234567"; "90 123 45 67" -> "901234567".
String normalizePhone(String input) {
  final t = input.trim();
  final digits = t.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  if (t.startsWith('+') || digits.length >= 11) return '+$digits';
  return digits;
}

/// Key for duplicate detection: last 9 digits (local number without
/// country code), so "+998901234567" and "901234567" are duplicates.
String phoneKey(String? phone) {
  final d = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  return d.length > 9 ? d.substring(d.length - 9) : d;
}

bool isValidEmail(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

List<String> parseTags(String? tags) => (tags ?? '')
    .split(',')
    .map((t) => t.trim())
    .where((t) => t.isNotEmpty)
    .toSet()
    .toList();

String? joinTags(Iterable<String> tags) {
  final list = tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().toList();
  return list.isEmpty ? null : list.join(', ');
}

/// All distinct tags in use, sorted.
List<String> allTags(Iterable<Customer> customers) {
  final s = <String>{};
  for (final c in customers) {
    s.addAll(parseTags(c.tags));
  }
  return s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}

/// EAN-13 check digit for the first 12 digits.
int ean13CheckDigit(String twelve) {
  assert(twelve.length == 12);
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = twelve.codeUnitAt(i) - 48;
    sum += i.isEven ? d : d * 3;
  }
  return (10 - sum % 10) % 10;
}

/// Loyalty card number: EAN-13 in the in-store range (prefix "29"), so it can
/// be printed as a barcode and scanned at the till.
String generateCardNumber([Random? random]) {
  final r = random ?? Random.secure();
  final b = StringBuffer('29');
  for (var i = 0; i < 10; i++) {
    b.write(r.nextInt(10));
  }
  final twelve = b.toString();
  return '$twelve${ean13CheckDigit(twelve)}';
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters1.toUpperCase();
  return (parts[0].characters1 + parts[1].characters1).toUpperCase();
}

extension on String {
  String get characters1 => isEmpty ? '' : String.fromCharCode(runes.first);
}

// ------------------------------------------------------------------ labels

String ledgerKindLabel(String kind) => switch (kind) {
      'debt_sale' => 'Продажа в долг',
      'debt_payment' => 'Погашение долга',
      'debt_adjust' => 'Корректировка долга',
      'bonus_earn' => 'Начисление бонусов',
      'bonus_spend' => 'Списание бонусов',
      'bonus_adjust' => 'Корректировка бонусов',
      _ => kind,
    };

bool isDebtKind(String kind) => kind.startsWith('debt_');

String saleStatusLabel(String s) => switch (s) {
      'completed' => 'Оплачен',
      'voided' => 'Аннулирован',
      'partially_returned' => 'Частичный возврат',
      'returned' => 'Возвращён',
      'held' => 'Отложен',
      _ => s,
    };

// ------------------------------------------------------------------ texts

/// Debt reminder for messengers / SMS (copied to clipboard, D-014).
String debtReminderText({
  required String name,
  required String store,
  required int debt,
  int overdue = 0,
  DateTime? dueDate,
  String? storePhone,
}) {
  final b = StringBuffer('Здравствуйте, $name! Ваш долг в $store составляет ${Money.format(debt)}.');
  if (overdue > 0) {
    b.write(' Из них просрочено: ${Money.format(overdue)}.');
  } else if (dueDate != null) {
    b.write(' Срок оплаты — до ${_d(dueDate)}.');
  }
  b.write(' Просим погасить задолженность при ближайшем посещении магазина.');
  if (storePhone != null && storePhone.trim().isNotEmpty) {
    b.write(' Телефон для связи: ${storePhone.trim()}.');
  }
  b.write(' Спасибо!');
  return b.toString();
}

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Fills {name} {store} {debt} {bonus} {discount} placeholders.
String fillTemplate(String template, Customer c, {required String store}) {
  final first = c.name.trim().split(RegExp(r'\s+')).first;
  return template
      .replaceAll('{name}', first.isEmpty ? c.name : first)
      .replaceAll('{fullname}', c.name)
      .replaceAll('{store}', store)
      .replaceAll('{debt}', Money.format(c.debtBalance))
      .replaceAll('{bonus}', Money.format(c.bonusBalance))
      .replaceAll('{discount}', '${_pct(c.discountPercent)}%');
}

String _pct(double p) => p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1);
String formatPercent(double p) => _pct(p);

// ------------------------------------------------------------------ CSV

String _csvCell(String? v) {
  final s = v ?? '';
  if (s.contains(';') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

/// Semicolon-separated CSV (opens correctly in Excel with Russian locale).
String customersCsv(List<Customer> list) {
  final b = StringBuffer()
    ..writeln([
      'Имя', 'Телефон', 'Email', 'Карта', 'День рождения', 'Скидка %', 'Бонусы', 'Долг',
      'Лимит долга', 'Сумма покупок', 'Визитов', 'Последний визит', 'Теги', 'Заметка',
    ].join(';'));
  for (final c in list) {
    b.writeln([
      c.name,
      c.phone,
      c.email,
      c.cardNumber,
      c.birthday == null ? '' : _d(c.birthday!),
      _pct(c.discountPercent),
      Money.format(c.bonusBalance, withSymbol: false),
      Money.format(c.debtBalance, withSymbol: false),
      Money.format(c.debtLimit, withSymbol: false),
      Money.format(c.totalSpent, withSymbol: false),
      '${c.visits}',
      c.lastVisitAt == null ? '' : _d(c.lastVisitAt!),
      c.tags,
      c.note,
    ].map(_csvCell).join(';'));
  }
  return b.toString();
}
