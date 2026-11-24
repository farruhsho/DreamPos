// Ledger operation labels, period ranges, the reconciliation act CSV and PDF.
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:dreampos/features/purchasing/statement_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

SupplierLedgerEntry _e(String kind, int amount, int after, DateTime at, {String? refId, String? note}) =>
    SupplierLedgerEntry(
      id: '$kind$amount${at.millisecondsSinceEpoch}',
      createdAt: at,
      updatedAt: at,
      supplierId: 's',
      kind: kind,
      amount: amount,
      balanceAfter: after,
      refType: refId == null ? null : (kind.startsWith('receipt') ? 'goods_receipt' : 'supplier_payment'),
      refId: refId,
      note: note,
    );

SupplierPayment _pay(String id, String method, {DateTime? cancelledAt}) => SupplierPayment(
  id: id,
  createdAt: DateTime(2026, 11, 2),
  updatedAt: DateTime(2026, 11, 2),
  supplierId: 's',
  amount: 30000,
  method: method,
  cancelledAt: cancelledAt,
);

Supplier _supplier() => Supplier(
  id: 's',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  name: 'ООО «Молоко; и Ко»',
  balance: 55000,
  taxId: '123456789',
);

void main() {
  final entries = [
    _e('opening', 10000, 10000, DateTime(2026, 9, 1), note: 'Начальный остаток'),
    _e('receipt', 90000, 100000, DateTime(2026, 10, 5), refId: 'r1', note: 'Приход №7'),
    _e('payment', -30000, 70000, DateTime(2026, 11, 2), refId: 'p1', note: 'п/п 5'),
    _e('payment_cancel', 30000, 100000, DateTime(2026, 11, 3), refId: 'p1', note: '=HYPERLINK("x")'),
    _e('receipt_reversal', -90000, 10000, DateTime(2026, 11, 4), refId: 'r1'),
    _e('adjustment', -5000, 5000, DateTime(2026, 11, 5), note: 'Скидка'),
  ];
  final numbers = {'r1': 7};
  final payments = {'p1': _pay('p1', 'transfer')};
  String op(SupplierLedgerEntry e) => supplierLedgerOperation(e, receiptNumbers: numbers, payments: payments);

  test('operation labels per ledger kind', () {
    expect(entries.map(op).toList(), [
      'Начальный остаток',
      'Приход №7',
      'Оплата (Перечисление)',
      'Отмена оплаты',
      'Сторно прихода №7',
      'Корректировка',
    ]);
    // Unknown references fall back to the bare kind label.
    expect(supplierLedgerOperation(entries[1]), 'Приход');
    expect(supplierLedgerOperation(entries[2]), 'Оплата');
  });

  test('cancellablePayment: only payment rows of not-cancelled payments', () {
    expect(cancellablePayment(entries[2], payments)?.id, 'p1');
    expect(cancellablePayment(entries[3], payments), isNull, reason: 'cancel row itself');
    expect(cancellablePayment(entries[1], payments), isNull);
    expect(cancellablePayment(entries[2], {'p1': _pay('p1', 'cash', cancelledAt: DateTime(2026, 11, 3))}), isNull);
    expect(cancellablePayment(entries[2], const {}), isNull);
  });

  test('ledger period ranges are half-open [from, to)', () {
    final now = DateTime(2026, 11, 24, 15, 30);
    expect(ledgerPeriodRange(LedgerPeriod.all, now: now), (from: null, to: null));
    expect(ledgerPeriodRange(LedgerPeriod.month, now: now), (from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 25)));
    expect(ledgerPeriodRange(LedgerPeriod.lastMonth, now: now), (
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 11, 1),
    ));
    expect(ledgerPeriodRange(LedgerPeriod.quarter, now: now).from, DateTime(2026, 10, 1));
    expect(ledgerPeriodRange(LedgerPeriod.year, now: now).from, DateTime(2026, 1, 1));
    expect(ledgerPeriodRange(LedgerPeriod.custom, first: DateTime(2026, 11, 2, 13), last: DateTime(2026, 11, 3)), (
      from: DateTime(2026, 11, 2),
      to: DateTime(2026, 11, 4),
    ));
    expect(ledgerPeriodText(DateTime(2026, 11, 1), DateTime(2026, 11, 25)), '01.11.2026 – 24.11.2026');
    expect(ledgerPeriodText(null, null), 'всё время');
    expect(ledgerPeriodText(null, DateTime(2026, 11, 25)), 'по 24.11.2026');
  });

  test('act heading: «за всё время», not «за период за всё время»', () {
    expect(ledgerPeriodHeading(ledgerPeriodText(null, null)), 'за всё время');
    expect(ledgerPeriodHeading(ledgerPeriodText(DateTime(2026, 11, 1), DateTime(2026, 11, 25))),
        'за период 01.11.2026 – 24.11.2026');
    final empty = StatementData(
      supplier: _supplier(),
      statement: SupplierStatement.of(const []),
      from: null,
      to: null,
      operation: op,
      settings: const {},
    );
    expect(ledgerPeriodHeading(empty.period), 'за всё время');
  });

  test('migration opening row is the opening balance, not turnover', () {
    // All time: opening 10 000 is «Сальдо на начало», not «Приход».
    final all = SupplierStatement.of(entries);
    expect(all.opening, 10000);
    expect(all.rows.map((e) => e.kind), isNot(contains('opening')));
    expect(all.increase, 90000 + 30000);
    expect(all.decrease, 30000 + 90000 + 5000);
    expect(all.closing, 5000);
    // A period that contains the opening row (September).
    final sep = SupplierStatement.of(entries, from: DateTime(2026, 9, 1), to: DateTime(2026, 10, 1));
    expect(sep.opening, 10000);
    expect(sep.rows, isEmpty);
    expect(sep.increase, 0);
    expect(sep.closing, 10000);
    // Negative opening (prepayment) is not «Расход».
    final credit = SupplierStatement.of([_e('opening', -300, -300, DateTime(2026, 11, 1))]);
    expect(credit.opening, -300);
    expect(credit.decrease, 0);
    expect(credit.closing, -300);
  });

  test('cancelling a cash payment needs the cash permission', () {
    expect(supplierPaymentCancelAllowed(_pay('p', 'cash'), canCash: false), isFalse);
    expect(supplierPaymentCancelAllowed(_pay('p', 'cash'), canCash: true), isTrue);
    expect(supplierPaymentCancelAllowed(_pay('p', 'transfer'), canCash: false), isTrue);
    expect(supplierPaymentCancelAllowed(_pay('p', 'card'), canCash: false), isTrue);
  });

  test('act CSV: «-digit» formulas are escaped, plain negative numbers are not', () {
    final st = SupplierStatement.of([
      _e('receipt', 500, 500, DateTime(2026, 11, 1)),
      _e('adjustment', -700, -200, DateTime(2026, 11, 2), note: "-2+3+cmd|' /C calc'!A0"),
      _e('adjustment', 100, -100, DateTime(2026, 11, 3), note: '-15'),
    ]);
    final csv = supplierStatementCsv(
      st: st,
      supplierName: '-1+1',
      storeName: 'М',
      period: 'всё время',
      operation: (e) => supplierLedgerOperation(e),
    );
    expect(csv, contains(";'-2+3+cmd|' /C calc'!A0;"));
    expect(csv, isNot(contains(';-2+3')));
    expect(csv, contains("Поставщик;'-1+1"));
    expect(csv, contains(';-15;'), reason: 'a plain number stays numeric');
    expect(csv, contains(';Сальдо на конец периода;;;;${Money.toInput(-100)}'));
  });

  test('statement for November: opening, turnovers, closing', () {
    final r = ledgerPeriodRange(LedgerPeriod.month, now: DateTime(2026, 11, 24));
    final st = SupplierStatement.of(entries, from: r.from, to: r.to);
    expect(st.opening, 100000);
    expect(st.rows, hasLength(4));
    expect(st.increase, 30000);
    expect(st.decrease, 125000);
    expect(st.closing, 5000);
    expect(st.closing, st.rows.last.balanceAfter);
  });

  test('conclusion text names the debtor', () {
    expect(statementConclusion(0, store: 'А', supplier: 'Б', at: '01.12.2026'), contains('отсутствует'));
    expect(statementConclusion(5000, store: 'А', supplier: 'Б', at: '01.12.2026'), contains('«А» перед «Б»'));
    expect(statementConclusion(-5000, store: 'А', supplier: 'Б', at: '01.12.2026'), contains('«Б» перед «А» (аванс)'));
  });

  test('act CSV: header, opening, rows, turnovers, closing; escaping and formula guard', () {
    final st = SupplierStatement.of(entries, from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 25));
    final csv = supplierStatementCsv(
      st: st,
      supplierName: 'ООО «Молоко; и Ко»',
      storeName: 'Магазин',
      period: '01.11.2026 – 24.11.2026',
      operation: op,
    );
    final lines = csv.split('\r\n');
    expect(lines.first, 'Акт сверки взаиморасчётов');
    expect(lines[2], 'Поставщик;"ООО «Молоко; и Ко»"');
    expect(lines, contains('Дата;Операция;Комментарий;Приход (+);Расход (−);Баланс'));
    expect(lines, contains(';Сальдо на начало периода;;;;${Money.toInput(100000)}'));
    expect(lines.where((l) => l.contains(';Оплата (Перечисление);п/п 5;;')), hasLength(1));
    // Formula-looking note is neutralised and quoted.
    expect(csv, contains('"\'=HYPERLINK(""x"")"'));
    expect(lines, contains(';Обороты за период;;${Money.toInput(30000)};${Money.toInput(125000)};'));
    expect(lines.last, ';Сальдо на конец периода;;;;${Money.toInput(5000)}');
  });

  testWidgets('act PDF builds with bundled fonts and StatementData texts', (tester) async {
    final st = SupplierStatement.of(entries, from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 25));
    final d = StatementData(
      supplier: _supplier(),
      statement: st,
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 25),
      operation: op,
      settings: const {'store_name': 'Магазин «Ташкент»', 'store_address': 'ул. Навои, 12'},
    );
    expect(d.storeName, 'Магазин «Ташкент»');
    expect(d.period, '01.11.2026 – 24.11.2026');
    expect(d.closingDate, '24.11.2026');
    expect(d.fileBase, startsWith('Акт_сверки_ООО_Молоко;_и_Ко_'));
    expect(d.toCsv(), contains('Магазин «Ташкент»'));
    final bytes = (await tester.runAsync(() => buildStatementPdf(d)))!;
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
    expect(
      StatementData(
        supplier: _supplier(),
        statement: st,
        from: null,
        to: null,
        operation: op,
        settings: const {},
      ).storeName,
      'DreamPOS',
    );
  });
}
