import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/customer_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/customers/customer_logic.dart';
import 'package:dreampos/features/customers/customer_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late Fixture f;
  late CustomerRepo repo;

  setUp(() async {
    f = await Fixture.create();
    repo = CustomerRepo(f.db);
  });
  tearDown(() => f.db.close());

  Future<void> debtSale(Customer c, int amount, DateTime? due) async {
    final p = await f.product('P${DateTime.now().microsecondsSinceEpoch}', price: amount, stock: 5);
    await SaleService(f.db).checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: amount)],
      payments: [PaymentInput('debt', amount)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
      customerId: c.id,
      debtDueDate: due,
    ));
  }

  test('save creates customer with normalised phone, audit and outbox', () async {
    final id = await repo.save(
        CustomerDraft(name: '  Анна ', phone: '+998 (90) 111-22-33', tags: ['опт', 'опт'], discountPercent: 5),
        userId: f.owner.id);
    final c = (await repo.byId(id))!;
    expect(c.name, 'Анна');
    expect(c.phone, '+998901112233');
    expect(c.tags, 'опт');
    expect(c.discountPercent, 5);
    final audit = await f.db.select(f.db.auditLog).get();
    expect(audit.map((a) => a.action), containsAll(['customer.create', 'customer.terms']));
    final outbox = await f.db.select(f.db.syncOutbox).get();
    expect(outbox.any((o) => o.entityId == id), isTrue);
  });

  test('validation: name, discount range, email, unique card', () async {
    expect(() => repo.save(CustomerDraft(name: ' '), userId: f.owner.id), throwsA(isA<BusinessException>()));
    expect(() => repo.save(CustomerDraft(name: 'A', discountPercent: 101), userId: f.owner.id),
        throwsA(isA<BusinessException>()));
    expect(() => repo.save(CustomerDraft(name: 'A', email: 'bad'), userId: f.owner.id),
        throwsA(isA<BusinessException>()));
    final id = await repo.save(CustomerDraft(name: 'A', cardNumber: '123'), userId: f.owner.id);
    expect(() => repo.save(CustomerDraft(name: 'B', cardNumber: '123'), userId: f.owner.id),
        throwsA(isA<BusinessException>()));
    // editing the same customer keeps its card
    await repo.save(CustomerDraft(id: id, name: 'A2', cardNumber: '123'), userId: f.owner.id);
    expect((await repo.byId(id))!.name, 'A2');
    expect(await repo.isCardTaken('123'), isTrue);
    expect(await repo.isCardTaken('123', exceptId: id), isFalse);
    final gen = await repo.generateUniqueCard();
    expect(gen, hasLength(13));
  });

  test('permissions: cashier cannot change discount or debt limit', () async {
    final id = await repo.save(CustomerDraft(name: 'A', discountPercent: 5), userId: f.owner.id);
    expect(
        () => repo.save(CustomerDraft(id: id, name: 'A', discountPercent: 10),
            userId: f.owner.id, canEditDiscount: false),
        throwsA(isA<BusinessException>()));
    expect(() => repo.save(CustomerDraft(name: 'B', debtLimit: 1000), userId: f.owner.id, canEditDebtLimit: false),
        throwsA(isA<BusinessException>()));
    // unchanged terms are fine
    await repo.save(CustomerDraft(id: id, name: 'A+', discountPercent: 5),
        userId: f.owner.id, canEditDiscount: false, canEditDebtLimit: false);
    expect((await repo.byId(id))!.name, 'A+');
  });

  test('duplicate phone detection ignores country code and formatting', () async {
    await repo.save(CustomerDraft(name: 'A', phone: '+998901234567'), userId: f.owner.id);
    expect(await repo.phoneDuplicates('90 123 45 67'), hasLength(1));
    expect(await repo.phoneDuplicates('90 123 45 68'), isEmpty);
  });

  test('duplicate phone found when stored formatted (POS quick-create, demo data)', () async {
    // Customers created outside the CRM editor keep spaces in the phone.
    final c = await f.customer('Отформатирован');
    await (f.db.update(f.db.customers)..where((t) => t.id.equals(c.id)))
        .write(const CustomersCompanion(phone: Value('+998 90 123 45 67')));
    expect((await repo.phoneDuplicates('+998901234567')).map((d) => d.id), [c.id]);
    expect(await repo.phoneDuplicates('+998901234567', exceptId: c.id), isEmpty);
  });

  test('markBalanceChanged puts customer and newest ledger row into the sync outbox', () async {
    final c = await f.customer('Бонусный');
    final before = (await repo.byId(c.id))!.updatedAt;
    await Future<void>.delayed(const Duration(milliseconds: 1100)); // drift stores seconds
    await CustomerService(f.db).adjustBonus(customerId: c.id, delta: 500, userId: f.owner.id, reason: 'тест');
    await repo.markBalanceChanged(c.id);
    final after = (await repo.byId(c.id))!;
    expect(after.bonusBalance, 500, reason: 'balance itself is not touched');
    expect(after.updatedAt.isAfter(before), isTrue);
    final ledger = await (f.db.select(f.db.customerLedger)..where((l) => l.customerId.equals(c.id))).getSingle();
    final outbox = await f.db.select(f.db.syncOutbox).get();
    expect(outbox.where((o) => o.entity == 'customers' && o.entityId == c.id), isNotEmpty);
    expect(outbox.where((o) => o.entity == 'customer_ledger' && o.entityId == ledger.id), isNotEmpty);
  });

  test('delete is soft and blocked while debt exists', () async {
    final c = await f.customer('Должник', debtLimit: 100000);
    await debtSale(c, 5000, null);
    expect(() => repo.delete(c.id, userId: f.owner.id), throwsA(isA<BusinessException>()));
    await CustomerService(f.db).payDebt(
        customerId: c.id, amount: 5000, method: 'cash', userId: f.owner.id, shiftId: f.shift.id);
    await repo.delete(c.id, userId: f.owner.id);
    final row = (await repo.byId(c.id))!;
    expect(row.deletedAt, isNotNull);
    expect(await repo.segment(CustomerSegment.all), isEmpty);
  });

  test('segments from the database: debtors, overdue, sleeping, birthdays', () async {
    final now = DateTime.now();
    final debtor = await f.customer('Должник', debtLimit: 100000);
    final late = await f.customer('Просрочил', debtLimit: 100000);
    await debtSale(debtor, 3000, now.add(const Duration(days: 10)));
    await debtSale(late, 4000, now.subtract(const Duration(days: 1)));
    final sleeper = await f.customer('Спящий');
    await (f.db.update(f.db.customers)..where((t) => t.id.equals(sleeper.id)))
        .write(CustomersCompanion(lastVisitAt: Value(now.subtract(const Duration(days: 90)))));
    final bday = await f.customer('Именинник');
    final soon = now.add(const Duration(days: 3));
    await (f.db.update(f.db.customers)..where((t) => t.id.equals(bday.id)))
        .write(CustomersCompanion(birthday: Value(DateTime(1990, soon.month, soon.day))));

    Future<List<String>> names(CustomerSegment s) async => (await repo.segment(s)).map((c) => c.name).toList();
    expect(await names(CustomerSegment.debtors), unorderedEquals(['Должник', 'Просрочил']));
    expect(await names(CustomerSegment.overdue), ['Просрочил']);
    expect(await names(CustomerSegment.sleeping), ['Спящий']);
    expect(await names(CustomerSegment.birthdays), ['Именинник']);
    expect(await names(CustomerSegment.vip), isNotEmpty);

    // partial payment leaves the overdue part unpaid (FIFO), full payment clears it
    await CustomerService(f.db).payDebt(
        customerId: late.id, amount: 1000, method: 'card', userId: f.owner.id, shiftId: f.shift.id);
    final charges = await repo.debtCharges(customerId: late.id);
    expect(computeOverdue(charges, {late.id: 3000}, now)[late.id], 3000);
    await CustomerService(f.db).payDebt(
        customerId: late.id, amount: 3000, method: 'card', userId: f.owner.id, shiftId: f.shift.id);
    expect(await names(CustomerSegment.overdue), isEmpty);
  });
}
