import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/staff/staff_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late Fixture f;
  late StaffService staff;
  setUp(() async {
    f = await Fixture.create();
    staff = StaffService(f.db);
  });
  tearDown(() => f.db.close());

  Future<User> reload(String id) => (f.db.select(f.db.users)..where((u) => u.id.equals(id))).getSingle();

  group('last owner protection', () {
    test('cannot deactivate or demote the only active owner', () async {
      final admin = await staff.create(
        UserInput(name: 'Admin', role: Role.admin, pin: '4826'),
        actor: f.owner,
      );
      expect(() => staff.setActive(f.owner.id, false, actor: admin), throwsA(isA<BusinessException>()));
      expect(
        () => staff.update(
          f.owner.id,
          UserInput(name: 'Owner', role: Role.manager),
          actor: f.owner,
        ),
        throwsA(isA<BusinessException>()),
      );
      expect((await reload(f.owner.id)).role, 'owner');
      expect((await reload(f.owner.id)).isActive, isTrue);
    });

    test('second owner allows demoting the first; audit is written', () async {
      final o2 = await staff.create(
        UserInput(name: 'Owner 2', role: Role.owner, pin: '7391'),
        actor: f.owner,
      );
      await staff.update(
        f.owner.id,
        UserInput(name: 'Owner', role: Role.admin),
        actor: o2,
      );
      expect((await reload(f.owner.id)).role, 'admin');
      final audit = await f.db.select(f.db.auditLog).get();
      expect(audit.map((a) => a.action), contains('user.role'));
      // and now o2 is the last owner
      expect(
        lastOwnerGuard(await f.db.select(f.db.users).get(), userId: o2.id, newRole: Role.owner, newActive: false),
        isNotNull,
      );
    });

    test('only an owner can assign the owner role', () async {
      final admin = await staff.create(
        UserInput(name: 'Admin', role: Role.admin, pin: '4826'),
        actor: f.owner,
      );
      expect(
        () => staff.create(
          UserInput(name: 'X', role: Role.owner, pin: '9182'),
          actor: admin,
        ),
        throwsA(isA<BusinessException>()),
      );
      expect(
        () => staff.update(
          f.owner.id,
          UserInput(name: 'Renamed', role: Role.owner),
          actor: admin,
        ),
        throwsA(isA<BusinessException>()),
        reason: 'admin cannot edit the owner',
      );
    });

    test('cannot deactivate yourself; reactivation requires a new unique PIN', () async {
      final c = await staff.create(
        UserInput(name: 'Cashier', role: Role.cashier, pin: '4826', salesPlan: 500000, commissionPercent: 2),
        actor: f.owner,
      );
      expect(c.salesPlan, 500000);
      expect(c.commissionPercent, 2);
      expect(() => staff.setActive(f.owner.id, false, actor: f.owner), throwsA(isA<BusinessException>()));
      await TimeClock(f.db).clockIn(c.id);
      await staff.setActive(c.id, false, actor: f.owner);
      expect((await reload(c.id)).isActive, isFalse);
      expect(await TimeClock(f.db).openSession(c.id), isNull, reason: 'open work session closed');

      expect(() => staff.setActive(c.id, true, actor: f.owner), throwsA(isA<BusinessException>()));
      expect(
        () => staff.setActive(c.id, true, actor: f.owner, newPin: '2580'),
        throwsA(isA<BusinessException>()),
        reason: "owner's PIN",
      );
      await staff.setActive(c.id, true, actor: f.owner, newPin: '6173');
      expect((await reload(c.id)).isActive, isTrue);
    });

    test('input validation', () {
      expect(UserInput(name: ' ', role: Role.cashier, pin: '4826').validate(creating: true), isNotNull);
      expect(UserInput(name: 'A', role: Role.cashier).validate(creating: true), isNotNull);
      expect(UserInput(name: 'A', role: Role.cashier, pin: '1111').validate(creating: true), isNotNull);
      expect(
        UserInput(name: 'A', role: Role.cashier, pin: '4826', maxDiscountPercent: 120).validate(creating: true),
        isNotNull,
      );
      expect(UserInput(name: 'A', role: Role.cashier).validate(creating: false), isNull);
    });
  });

  group('time clock', () {
    test('prevents double clock-in and clock-out without clock-in', () async {
      final clock = TimeClock(f.db);
      expect(() => clock.clockOut(f.owner.id), throwsA(isA<BusinessException>()));
      final start = DateTime.now().subtract(const Duration(hours: 3));
      await clock.clockIn(f.owner.id, at: start);
      expect(() => clock.clockIn(f.owner.id), throwsA(isA<BusinessException>()));
      final s = await clock.clockOut(f.owner.id);
      expect(s.endedAt, isNotNull);
      expect(overlap(s, start, DateTime.now().add(const Duration(minutes: 1))).inMinutes, inInclusiveRange(179, 181));
      // can clock in again after clocking out
      await clock.clockIn(f.owner.id);
      expect(await clock.openSession(f.owner.id), isNotNull);
    });

    test('manual sessions: validation, overlap and audit', () async {
      final clock = TimeClock(f.db);
      final now = DateTime(2026, 11, 20, 20);
      final d = DateTime(2026, 11, 20);
      await clock.save(
        userId: f.owner.id,
        start: d.add(const Duration(hours: 9)),
        end: d.add(const Duration(hours: 13)),
        actorId: f.owner.id,
        now: now,
      );
      expect(
        () => clock.save(
          userId: f.owner.id,
          start: d.add(const Duration(hours: 12)),
          end: d.add(const Duration(hours: 18)),
          actorId: f.owner.id,
          now: now,
        ),
        throwsA(isA<BusinessException>()),
        reason: 'overlap',
      );
      expect(
        () => clock.save(
          userId: f.owner.id,
          start: d.add(const Duration(hours: 15)),
          end: d.add(const Duration(hours: 14)),
          actorId: f.owner.id,
          now: now,
        ),
        throwsA(isA<BusinessException>()),
        reason: 'end before start',
      );
      expect(
        () => clock.save(userId: f.owner.id, start: now.add(const Duration(hours: 1)), actorId: f.owner.id, now: now),
        throwsA(isA<BusinessException>()),
        reason: 'future',
      );
      final s = (await f.db.select(f.db.workSessions).get()).single;
      await clock.save(
        id: s.id,
        userId: f.owner.id,
        start: d.add(const Duration(hours: 8)),
        end: d.add(const Duration(hours: 13)),
        note: 'забыл отметиться',
        actorId: f.owner.id,
        now: now,
      );
      final edited = (await f.db.select(f.db.workSessions).get()).single;
      expect(edited.startedAt, d.add(const Duration(hours: 8)));
      expect(overlap(edited, d, d.add(const Duration(days: 1))), const Duration(hours: 5));
      final actions = (await f.db.select(f.db.auditLog).get()).map((a) => a.action);
      expect(actions, containsAll(['time.add', 'time.edit']));
    });
  });

  group('motivation', () {
    test('net of returns, excludes voided, commission and average check', () async {
      final seller = await staff.create(
        UserInput(name: 'Seller', role: Role.cashier, pin: '4826', salesPlan: 10000, commissionPercent: 5),
        actor: f.owner,
      );
      final p = await f.product('Item', price: 1000, cost: 500, stock: 100);
      final sales = SaleService(f.db);
      Future<Sale> sell(int qty, {String? sellerId}) async => (await sales.checkout(
        CheckoutRequest(
          lines: [CheckoutLine(productId: p.id, qty: qty.toDouble(), unitPrice: 1000)],
          payments: [PaymentInput('cash', qty * 1000)],
          cashierId: f.owner.id,
          sellerId: sellerId,
          shiftId: f.shift.id,
        ),
      )).sale;

      final a = await sell(4, sellerId: seller.id);
      await sell(2, sellerId: seller.id);
      final voided = await sell(3, sellerId: seller.id);
      await sales.voidSale(voided.id, userId: f.owner.id, reason: 'ошибка', shiftId: f.shift.id);
      await sell(1); // owner's own sale (seller defaults to cashier)

      final item = (await (f.db.select(f.db.saleItems)..where((i) => i.saleId.equals(a.id))).get()).single;
      await sales.returnItems(
        saleId: a.id,
        lines: [ReturnLineInput(item.id, 1)],
        refundMethod: 'cash',
        userId: f.owner.id,
        shiftId: f.shift.id,
      );

      final (from, to) = monthRange(DateTime.now());
      final rows = await computeMotivation(f.db, from, to);
      final r = rows.firstWhere((x) => x.user.id == seller.id);
      expect(r.grossRevenue, 6000);
      expect(r.refunds, 1000);
      expect(r.netRevenue, 5000);
      expect(r.receipts, 2);
      expect(r.averageCheck, 3000);
      expect(r.commission, 250);
      expect(r.completion, closeTo(0.5, 1e-9));
      expect(rows.first.user.id, seller.id, reason: 'leaderboard sorted by net revenue');
      final o = rows.firstWhere((x) => x.user.id == f.owner.id);
      expect(o.netRevenue, 1000);
      expect(o.completion, isNull);

      // next month is empty for revenue
      final next = monthRange(DateTime(from.year, from.month + 1));
      final rows2 = await computeMotivation(f.db, next.$1, next.$2);
      expect(rows2.every((x) => x.netRevenue == 0), isTrue);
    });

    test('commission is never negative', () {
      final u = User(
        id: 'u',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        name: 'U',
        role: 'cashier',
        pinHash: '',
        pinSalt: '',
        isActive: true,
        maxDiscountPercent: 0,
        salesPlan: 0,
        commissionPercent: 10,
        failedPinAttempts: 0,
      );
      expect(MotivationRow(user: u, grossRevenue: 0, refunds: 500, receipts: 0).commission, 0);
    });
  });

  group('atomic writes', () {
    test('update with a PIN already in use leaves the user untouched', () async {
      final a = await staff.create(
        UserInput(name: 'Анна', role: Role.cashier, pin: '4826'),
        actor: f.owner,
      );
      await expectLater(
        staff.update(
          a.id,
          UserInput(name: 'Анна Петрова', role: Role.manager, pin: '2580', salesPlan: 500000),
          actor: f.owner,
        ),
        throwsA(isA<BusinessException>()),
      );
      final after = await reload(a.id);
      expect(after.name, 'Анна');
      expect(after.role, Role.cashier.name);
      expect(after.salesPlan, 0);
    });

    test('create stores plan, commission and limits in one go', () async {
      final u = await staff.create(
        UserInput(
          name: 'Бобур',
          role: Role.cashier,
          pin: '9137',
          salesPlan: 1000000,
          commissionPercent: 2.5,
          maxDiscountPercent: 10,
        ),
        actor: f.owner,
      );
      expect(u.salesPlan, 1000000);
      expect(u.commissionPercent, 2.5);
      expect(u.maxDiscountPercent, 10);
      // a duplicate PIN fails without leaving a half-created user
      await expectLater(
        staff.create(
          UserInput(name: 'Дубль', role: Role.cashier, pin: '9137'),
          actor: f.owner,
        ),
        throwsA(isA<BusinessException>()),
      );
      final names = (await f.db.select(f.db.users).get()).map((u) => u.name);
      expect(names, isNot(contains('Дубль')));
    });

    test('reactivation with a PIN in use keeps the user inactive', () async {
      final a = await staff.create(
        UserInput(name: 'А', role: Role.cashier, pin: '4826'),
        actor: f.owner,
      );
      await staff.setActive(a.id, false, actor: f.owner);
      await expectLater(staff.setActive(a.id, true, actor: f.owner, newPin: '2580'), throwsA(isA<BusinessException>()));
      expect((await reload(a.id)).isActive, isFalse);
    });

    test('deleting a work session is soft and audited with its times', () async {
      final clock = TimeClock(f.db);
      final ws = await clock.clockIn(f.owner.id, at: DateTime.now().subtract(const Duration(hours: 2)));
      await clock.delete(ws.id, actorId: f.owner.id);
      final row = await (f.db.select(f.db.workSessions)..where((w) => w.id.equals(ws.id))).getSingle();
      expect(row.deletedAt, isNotNull);
      expect(await clock.openSession(f.owner.id), isNull, reason: 'deleted session no longer blocks clock-in');
      final audit = await (f.db.select(f.db.auditLog)..where((a) => a.action.equals('time.delete'))).getSingle();
      expect(audit.details, isNotEmpty);
    });
  });

  test('default manual session is never in the future', () {
    final morning = defaultManualSession(DateTime(2026, 3, 10, 7, 30));
    expect(morning.end, DateTime(2026, 3, 10, 7, 30));
    expect(morning.start, DateTime(2026, 3, 10, 6, 30));
    final noon = defaultManualSession(DateTime(2026, 3, 10, 12, 5));
    expect(noon.start, DateTime(2026, 3, 10, 9));
    expect(noon.end, DateTime(2026, 3, 10, 12, 5));
    final evening = defaultManualSession(DateTime(2026, 3, 10, 21));
    expect(evening.start, DateTime(2026, 3, 10, 9));
    expect(evening.end, DateTime(2026, 3, 10, 18));
  });

  test('labels cover every permission and known audit actions', () {
    for (final p in Perm.values) {
      expect(permLabel(p), isNot(p.name));
    }
    for (final a in [
      'auth.login',
      'auth.fail',
      'sale.discount',
      'sale.return',
      'sale.void',
      'shift.open',
      'shift.close',
      'cash.pay_in',
      'cash.expense',
      'user.create',
      'product.price',
      'debt.payment',
      'bonus.adjust',
      'inventory.complete',
      'discount.override',
      'stock.receipt',
      'pos.price_edit',
      'settings.change',
      'backup.restore_applied',
      'time.delete',
    ]) {
      expect(auditLabel(a), isNot(a));
    }
    expect(auditLabel('stock.something'), startsWith('Склад'));
    // AuthService is used by the fixture; keep import meaningful.
    expect(AuthService.maxAttempts, greaterThan(0));
  });
}
