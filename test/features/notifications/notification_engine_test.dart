import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/domain/services/customer_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/notifications/notification_engine.dart';
import 'package:dreampos/features/reports/data/insights.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late Fixture f;
  final now = DateTime(2026, 11, 20, 10);
  late Product low, out, ok, neverStocked;
  late Customer debtor, birthday;

  Future<List<AppNotification>> all() =>
      (f.db.select(f.db.notifications)..where((n) => n.deletedAt.isNull())).get();

  setUp(() async {
    f = await Fixture.create();
    low = await f.product('Молоко', stock: 2);
    out = await f.product('Хлеб', stock: 0);
    ok = await f.product('Сахар', stock: 100);
    neverStocked = await f.product('Новинка', stock: 0);
    for (final p in [low, out, ok]) {
      await (f.db.update(f.db.products)..where((t) => t.id.equals(p.id)))
          .write(ProductsCompanion(minStock: Value(p.id == ok.id ? 2 : 5)));
    }

    debtor = await f.customer('Должник', debtLimit: 1000000);
    await SaleService(f.db).checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: ok.id, qty: 1, unitPrice: 1000)],
      payments: [PaymentInput('debt', 1000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
      customerId: debtor.id,
      debtDueDate: DateTime(2026, 11, 10),
      now: DateTime(2026, 11, 1),
    ));
    birthday = await f.customer('Именинник');
    await (f.db.update(f.db.customers)..where((c) => c.id.equals(birthday.id)))
        .write(CustomersCompanion(birthday: Value(DateTime(1990, 11, 20))));
    await (f.db.update(f.db.shifts)..where((s) => s.id.equals(f.shift.id)))
        .write(ShiftsCompanion(openedAt: Value(DateTime(2026, 11, 19, 8))));
  });
  tearDown(() => f.db.close());

  test('creates one notification per problem', () async {
    final unread = await runNotificationChecks(f.db, now: now);
    final list = await all();
    final byKind = {for (final n in list) n.kind: n};
    expect(unread, 5);
    expect(list.length, 5);
    expect(byKind[NotificationKind.lowStock]!.refId, low.id);
    expect(byKind[NotificationKind.outOfStock]!.refId, out.id);
    expect(byKind[NotificationKind.debtDue]!.refId, debtor.id);
    expect(byKind[NotificationKind.birthday]!.refId, birthday.id);
    expect(byKind[NotificationKind.shift]!.refId, f.shift.id);
    expect(list.any((n) => n.refId == neverStocked.id), isFalse,
        reason: 'never-stocked products with no minimum are not alerts');
  });

  test('is idempotent: repeated runs do not duplicate unread notifications', () async {
    await runNotificationChecks(f.db, now: now);
    final r2 = await runNotificationChecksDetailed(f.db, now: now.add(const Duration(minutes: 10)));
    expect(r2.created, 0);
    expect(r2.unread, 5);
    expect((await all()).length, 5);
  });

  test('read notifications are not repeated within 24h, but are after', () async {
    await runNotificationChecks(f.db, now: now);
    await f.db.update(f.db.notifications).write(const NotificationsCompanion(isRead: Value(true)));
    final r2 = await runNotificationChecksDetailed(f.db, now: now.add(const Duration(hours: 2)));
    expect(r2.created, 0);
    expect(r2.unread, 0);

    final r3 = await runNotificationChecksDetailed(f.db, now: now.add(const Duration(hours: 25)));
    // low, out, debt, shift are still true; the birthday was yesterday.
    expect(r3.created, 4);
  });

  test('auto-resolves alerts whose problem is gone', () async {
    await runNotificationChecks(f.db, now: now);
    await StockService(f.db).receive(productId: low.id, qty: 50, unitCost: 600);
    final r = await runNotificationChecksDetailed(f.db, now: now.add(const Duration(minutes: 10)));
    expect(r.resolved, 1);
    expect(r.unread, 4);
    final n = (await all()).firstWhere((n) => n.kind == NotificationKind.lowStock);
    expect(n.isRead, isTrue);
  });

  test('soft-deleted notifications are not resurrected within 24h', () async {
    await runNotificationChecks(f.db, now: now);
    await f.db.update(f.db.notifications).write(NotificationsCompanion(deletedAt: Value(now)));
    final r = await runNotificationChecksDetailed(f.db, now: now.add(const Duration(hours: 1)));
    expect(r.created, 0);
    expect(r.unread, 0);
  });

  test('birthday reminder is cleared the next day so next year it is created again', () async {
    await runNotificationChecks(f.db, now: now);
    final r = await runNotificationChecksDetailed(f.db, now: DateTime(2026, 11, 21, 10));
    final b = (await all()).firstWhere((n) => n.kind == NotificationKind.birthday);
    expect(b.isRead, isTrue, reason: 'yesterday birthday is auto-resolved');
    expect(r.resolved, greaterThanOrEqualTo(1));

    final next = await runNotificationChecksDetailed(f.db, now: DateTime(2027, 11, 20, 9));
    final births = (await all()).where((n) => n.kind == NotificationKind.birthday).toList();
    expect(births.length, 2);
    expect(next.created, greaterThanOrEqualTo(1));
  });

  test('29 February birthdays are celebrated on 28 February in common years', () {
    final b = DateTime(2000, 2, 29);
    expect(isBirthdayOn(b, DateTime(2027, 2, 28)), isTrue);
    expect(isBirthdayOn(b, DateTime(2027, 3, 1)), isFalse);
    expect(isBirthdayOn(b, DateTime(2028, 2, 28)), isFalse);
    expect(isBirthdayOn(b, DateTime(2028, 2, 29)), isTrue);
    expect(isBirthdayOn(DateTime(1990, 5, 3), DateTime(2026, 5, 3, 23, 59)), isTrue);
  });

  group('overdue debt (FIFO)', () {
    Future<void> creditSale(Customer c, int amount, DateTime at, DateTime? due) =>
        SaleService(f.db).checkout(CheckoutRequest(
          lines: [CheckoutLine(productId: ok.id, qty: 1, unitPrice: amount)],
          payments: [PaymentInput('debt', amount)],
          cashierId: f.owner.id,
          shiftId: f.shift.id,
          customerId: c.id,
          debtDueDate: due,
          now: at,
        ));

    test('a paid-off overdue sale does not make newer, not yet due debt overdue', () async {
      final c = await f.customer('Аккуратный', debtLimit: 10000000);
      await creditSale(c, 5000, DateTime(2026, 10, 1), DateTime(2026, 10, 15)); // overdue…
      await CustomerService(f.db).payDebt(
          customerId: c.id, amount: 5000, method: 'card', userId: f.owner.id); // …but paid
      await creditSale(c, 3000, DateTime(2026, 11, 15), DateTime(2026, 12, 15)); // not due yet
      final list = await loadOverdueDebtors(f.db, now: now);
      expect(list.any((d) => d.customerId == c.id), isFalse);
      // the engine therefore does not nag about this customer
      await runNotificationChecks(f.db, now: now);
      expect((await all()).any((n) => n.kind == NotificationKind.debtDue && n.refId == c.id),
          isFalse);
    });

    test('partial payment leaves the unpaid overdue part', () async {
      final c = await f.customer('Частичный', debtLimit: 10000000);
      await creditSale(c, 5000, DateTime(2026, 10, 1), DateTime(2026, 10, 15)); // overdue
      await creditSale(c, 3000, DateTime(2026, 11, 15), DateTime(2026, 12, 15)); // not due
      await CustomerService(f.db).payDebt(
          customerId: c.id, amount: 2000, method: 'card', userId: f.owner.id);
      final d = (await loadOverdueDebtors(f.db, now: now)).firstWhere((d) => d.customerId == c.id);
      expect(d.debt, 6000);
      expect(d.overdue, 3000, reason: 'newest 3000 is not due; 3000 of the old sale is overdue');
      expect(d.oldestDue, DateTime(2026, 10, 15));
    });

    test('credit sales without a due date never become overdue', () async {
      final c = await f.customer('Без срока', debtLimit: 10000000);
      await creditSale(c, 4000, DateTime(2026, 1, 1), null);
      expect((await loadOverdueDebtors(f.db, now: now)).any((d) => d.customerId == c.id), isFalse);
    });
  });
}
