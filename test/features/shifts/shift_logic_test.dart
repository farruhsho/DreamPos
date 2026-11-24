import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/shifts/shift_logic.dart';
import 'package:dreampos/features/shifts/report_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  group('denominations', () {
    test('UZS uses the national banknote set', () {
      expect(denominationsFor(const CurrencyConfig()), [
        200000,
        100000,
        50000,
        20000,
        10000,
        5000,
        2000,
        1000,
        500,
        200,
        100,
      ]);
    });

    test('currencies with decimals are converted to minor units', () {
      const tjs = CurrencyConfig(code: 'TJS', symbol: 'сом.', decimals: 2);
      final d = denominationsFor(tjs);
      expect(d.first, 50000); // 500 somoni
      expect(d, contains(10)); // 10 dirams
      expect(d, orderedEquals([...d]..sort((a, b) => b.compareTo(a))));
    });

    test('coins not representable with 0 decimals are dropped', () {
      const usd0 = CurrencyConfig(code: 'USD', symbol: r'$', decimals: 0);
      expect(denominationsFor(usd0), isNot(contains(0)));
      expect(denominationsFor(usd0).last, 1);
    });

    test('unknown currency falls back to generic set', () {
      expect(denominationsFor(const CurrencyConfig(code: 'XXX')), isNotEmpty);
    });
  });

  group('cash count', () {
    test('total and pieces', () {
      final c = CashCount().withCount(200000, 3).withCount(1000, 5).withCount(500, 0).withCount(100, -2);
      expect(c.total, 605000);
      expect(c.pieces, 8);
      String m(int v) => Money.format(v, withSymbol: false);
      expect(c.describe(const CurrencyConfig()), '${m(200000)} × 3; ${m(1000)} × 5');
    });

    test('classifyDiff', () {
      expect(classifyDiff(100, 100), CashDiff.exact);
      expect(classifyDiff(90, 100), CashDiff.shortage);
      expect(classifyDiff(110, 100), CashDiff.surplus);
    });

    test('note is required when counted differs from expected', () {
      expect(validateClose(counted: null, expected: 10, note: ''), isNotNull);
      expect(validateClose(counted: 9, expected: 10, note: ''), contains('причину'));
      expect(validateClose(counted: 9, expected: 10, note: 'ошибка сдачи'), isNull);
      expect(validateClose(counted: 10, expected: 10, note: ''), isNull);
      expect(validateClose(counted: 10, expected: 10, note: '', collection: 11), isNotNull);
    });
  });

  group('figures & history (db)', () {
    late Fixture f;
    setUp(() async => f = await Fixture.create());
    tearDown(() => f.db.close());

    test('gross profit is net of returns; expected cash follows movements', () async {
      final p = await f.product('Tea', price: 1000, cost: 600, stock: 10);
      final sales = SaleService(f.db);
      final res = await sales.checkout(
        CheckoutRequest(
          lines: [CheckoutLine(productId: p.id, qty: 3, unitPrice: 1000)],
          payments: [PaymentInput('cash', 3000)],
          cashierId: f.owner.id,
          shiftId: f.shift.id,
        ),
      );
      final item = (await f.db.select(f.db.saleItems).get()).single;
      await sales.returnItems(
        saleId: res.sale.id,
        lines: [ReturnLineInput(item.id, 1)],
        refundMethod: 'cash',
        userId: f.owner.id,
        shiftId: f.shift.id,
      );
      final svc = ShiftService(f.db);
      await svc.cashMovement(
        shiftId: f.shift.id,
        kind: 'expense',
        amount: 500,
        userId: f.owner.id,
        expenseCategory: 'Хозтовары',
      );
      await svc.cashMovement(shiftId: f.shift.id, kind: 'pay_in', amount: 200, userId: f.owner.id);

      final fig = await ShiftFigures.load(f.db, f.shift.id);
      expect(fig.netRevenue, 2000);
      expect(fig.returnedCost, 600);
      expect(fig.grossProfit, 2000 - (1800 - 600));
      expect(fig.expectedCash, 10000 + 3000 - 1000 - 500 + 200);
      expect(fig.expensesByCategory, {'Хозтовары': 500});
      expect(fig.averageCheck, 3000);

      final text = ZReportData(figures: fig, settings: const {'store_name': 'Магазин'}, openedByName: 'Owner').toText();
      expect(text, contains('X-ОТЧЁТ'));
      expect(text, isNot(contains('Валовая прибыль')), reason: 'profit hidden without viewCost');
    });

    test('opening suggestion = counted cash of previous shift (after collection)', () async {
      expect(await suggestOpeningCash(f.db), 0);
      final svc = ShiftService(f.db);
      await svc.cashMovement(shiftId: f.shift.id, kind: 'collection', amount: 7000, userId: f.owner.id);
      await svc.close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 3000);
      expect(await suggestOpeningCash(f.db), 3000);
      final fig = await ShiftFigures.load(f.db, f.shift.id);
      expect(fig.difference, 0);
      final z = ZReportData(figures: fig, settings: const {}, openedByName: 'Owner', showProfit: true);
      expect(z.title, 'Z-отчёт');
      expect(z.toText(), contains('Инкассация'));
    });

    test('close with collection is atomic and keeps the difference intact', () async {
      // Failure: counted < collection makes close() throw -> collection rolled back.
      await expectLater(
        closeShiftWithCollection(f.db, shiftId: f.shift.id, userId: f.owner.id, counted: 3000, collection: 5000),
        throwsA(anything),
      );
      expect(await f.db.select(f.db.cashMovements).get(), isEmpty, reason: 'collection rolled back');
      expect((await ShiftService(f.db).currentShift())?.id, f.shift.id, reason: 'shift still open');

      // Success: 10000 expected, 9500 counted, 6000 collected -> shortage 500, 3500 left as float.
      final rep = await closeShiftWithCollection(
        f.db,
        shiftId: f.shift.id,
        userId: f.owner.id,
        counted: 9500,
        collection: 6000,
        note: 'недостача',
      );
      expect(rep.shift.status, 'closed');
      expect(rep.shift.countedCash, 3500);
      expect(rep.shift.expectedCash, 4000);
      expect(rep.difference, -500);
      final moves = await f.db.select(f.db.cashMovements).get();
      expect(moves.single.kind, 'collection');
      expect(moves.single.amount, 6000);
      expect(await suggestOpeningCash(f.db), 3500);
    });

    test('history shows only own shifts when filtered by user', () async {
      final cashier = await AuthService(f.db).createUser(name: 'Cashier', role: Role.cashier, pin: '1357');
      final svc = ShiftService(f.db);
      await svc.close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 9000);
      final s2 = await svc.open(userId: cashier.id, openingCash: 0);

      final all = await watchShiftHistory(f.db).first;
      expect(all.map((r) => r.shift.number), [s2.number, f.shift.number]);
      expect(all.last.difference, -1000);

      final own = await watchShiftHistory(f.db, onlyUserId: cashier.id).first;
      expect(own.map((r) => r.shift.id), [s2.id]);
    });
  });
}
