// CRM data access. Customers are reference data (written via drift directly,
// with updatedAt + markDirty); debts and bonuses go through CustomerService.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../domain/errors.dart';
import '../../l10n/l10n.dart';
import 'customer_logic.dart';

/// Editable customer fields.
class CustomerDraft {
  CustomerDraft({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.cardNumber,
    this.birthday,
    this.discountPercent = 0,
    this.debtLimit = 0,
    this.tags = const [],
    this.note,
  });

  factory CustomerDraft.from(Customer c) => CustomerDraft(
        id: c.id,
        name: c.name,
        phone: c.phone,
        email: c.email,
        cardNumber: c.cardNumber,
        birthday: c.birthday,
        discountPercent: c.discountPercent,
        debtLimit: c.debtLimit,
        tags: parseTags(c.tags),
        note: c.note,
      );

  final String? id;
  final String name;
  final String? phone;
  final String? email;
  final String? cardNumber;
  final DateTime? birthday;
  final double discountPercent;
  final int debtLimit;
  final List<String> tags;
  final String? note;
}

String? _blank(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

class CustomerRepo {
  CustomerRepo(this.db);
  final AppDatabase db;

  Future<Customer?> byId(String id) =>
      (db.select(db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Other (not deleted) customers with the same phone number.
  /// Compared on digits only: phones created elsewhere (POS quick-create, demo
  /// data) may be stored formatted, e.g. "+998 90 123 45 67", so a SQL LIKE on
  /// a digit substring would miss them.
  Future<List<Customer>> phoneDuplicates(String phone, {String? exceptId}) async {
    final key = phoneKey(phone);
    if (key.length < 5) return [];
    final rows = await (db.select(db.customers)
          ..where((c) => c.deletedAt.isNull() & c.phone.isNotNull()))
        .get();
    return rows.where((c) => c.id != exceptId && phoneKey(c.phone) == key).toList();
  }

  /// After a CustomerService call (payDebt/adjustBonus) make sure the changed
  /// customer row and its newest ledger entry reach the sync outbox, and that
  /// updatedAt moves (adjustBonus does not set it). Customers are reference
  /// data, so touching updatedAt here is allowed; balances are not modified.
  Future<void> markBalanceChanged(String customerId) async {
    await db.transaction(() async {
      await (db.update(db.customers)..where((c) => c.id.equals(customerId)))
          .write(CustomersCompanion(updatedAt: Value(DateTime.now())));
      await db.markDirty('customers', customerId);
      final last = await (db.select(db.customerLedger)
            ..where((l) => l.customerId.equals(customerId))
            ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      if (last != null) await db.markDirty('customer_ledger', last.id);
    });
  }

  Future<bool> isCardTaken(String card, {String? exceptId}) async {
    final rows = await (db.select(db.customers)
          ..where((c) => c.deletedAt.isNull() & c.cardNumber.equals(card.trim())))
        .get();
    return rows.any((c) => c.id != exceptId);
  }

  Future<String> generateUniqueCard() async {
    for (var i = 0; i < 20; i++) {
      final c = generateCardNumber();
      if (!await isCardTaken(c)) return c;
    }
    throw BusinessException(L.current.custCardGenFailed);
  }

  /// Validates business rules and inserts/updates. Returns the customer id.
  /// [canEditDiscount]/[canEditDebtLimit] reflect the user's permissions:
  /// without them the stored values may not change.
  Future<String> save(CustomerDraft d,
      {required String userId, bool canEditDiscount = true, bool canEditDebtLimit = true}) async {
    final name = d.name.trim();
    if (name.isEmpty) throw BusinessException(L.current.custEnterName);
    if (name.length > 160) throw BusinessException(L.current.custNameTooLong);
    if (d.discountPercent < 0 || d.discountPercent > 100) {
      throw BusinessException(L.current.custDiscountRange);
    }
    if (d.debtLimit < 0) throw BusinessException(L.current.custDebtLimitNegative);
    final email = _blank(d.email);
    if (email != null && !isValidEmail(email)) throw BusinessException(L.current.custEmailInvalid);
    final card = _blank(d.cardNumber);
    final phone = _blank(d.phone) == null ? null : normalizePhone(d.phone!);
    final now = DateTime.now();

    return db.transaction(() async {
      if (card != null && await isCardTaken(card, exceptId: d.id)) {
        throw BusinessException(L.current.custCardTakenBy(card));
      }
      final comp = CustomersCompanion(
        name: Value(name),
        phone: Value(_blank(phone)),
        email: Value(email),
        cardNumber: Value(card),
        birthday: Value(d.birthday == null
            ? null
            : DateTime(d.birthday!.year, d.birthday!.month, d.birthday!.day)),
        discountPercent: Value(d.discountPercent),
        debtLimit: Value(d.debtLimit),
        tags: Value(joinTags(d.tags)),
        note: Value(_blank(d.note)),
        updatedAt: Value(now),
      );
      if (d.id == null) {
        if (!canEditDiscount && d.discountPercent != 0) {
          throw BusinessException(L.current.custNoAssignDiscountPerm);
        }
        if (!canEditDebtLimit && d.debtLimit != 0) {
          throw BusinessException(L.current.custNoOpenCreditPerm);
        }
        final id = newId();
        await db.into(db.customers).insert(comp.copyWith(id: Value(id), createdAt: Value(now)));
        await db.markDirty('customers', id);
        await db.audit('customer.create', userId: userId, entity: 'customer', entityId: id, details: name);
        if (d.discountPercent > 0 || d.debtLimit > 0) {
          await db.audit('customer.terms', userId: userId, entity: 'customer', entityId: id,
              details: 'discount=${d.discountPercent}; debtLimit=${d.debtLimit}');
        }
        return id;
      }
      final old = await byId(d.id!);
      if (old == null || old.deletedAt != null) throw BusinessException(L.current.commonCustomerNotFound);
      if (!canEditDiscount && old.discountPercent != d.discountPercent) {
        throw BusinessException(L.current.custNoChangeDiscountPerm);
      }
      if (!canEditDebtLimit && old.debtLimit != d.debtLimit) {
        throw BusinessException(L.current.custNoChangeDebtLimitPerm);
      }
      await (db.update(db.customers)..where((c) => c.id.equals(d.id!))).write(comp);
      await db.markDirty('customers', d.id!);
      if (old.discountPercent != d.discountPercent || old.debtLimit != d.debtLimit) {
        await db.audit('customer.terms', userId: userId, entity: 'customer', entityId: d.id,
            details: 'discount ${old.discountPercent}→${d.discountPercent}; '
                'debtLimit ${old.debtLimit}→${d.debtLimit}');
      }
      return d.id!;
    });
  }

  /// Soft delete; blocked while the customer has debt or prepayment.
  Future<void> delete(String id, {required String userId}) async {
    await db.transaction(() async {
      final c = await byId(id);
      if (c == null || c.deletedAt != null) throw BusinessException(L.current.commonCustomerNotFound);
      if (c.debtBalance != 0) {
        throw BusinessException(c.debtBalance > 0
            ? L.current.custDeleteDebtRepo
            : L.current.custDeleteOverpaid);
      }
      final now = DateTime.now();
      await (db.update(db.customers)..where((t) => t.id.equals(id)))
          .write(CustomersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await db.markDirty('customers', id, op: 'delete');
      await db.audit('customer.delete', userId: userId, entity: 'customer', entityId: id,
          details: '${c.name}; bonus=${c.bonusBalance}');
    });
  }

  /// Unpaid debt_sale charges for customers that currently owe money.
  Future<List<DebtCharge>> debtCharges({String? customerId}) => _chargesQuery(customerId).get();

  Stream<List<DebtCharge>> watchDebtCharges({String? customerId}) =>
      _chargesQuery(customerId).watch();

  Selectable<DebtCharge> _chargesQuery(String? customerId) {
    final l = db.customerLedger;
    final c = db.customers;
    final q = db.select(l).join([innerJoin(c, c.id.equalsExp(l.customerId))])
      ..where(l.kind.equals('debt_sale') &
          c.debtBalance.isBiggerThanValue(0) &
          c.deletedAt.isNull() &
          l.deletedAt.isNull() &
          (customerId == null ? const Constant(true) : l.customerId.equals(customerId)));
    return q.map((r) {
      final e = r.readTable(l);
      return DebtCharge(
          customerId: e.customerId, amount: e.amount, createdAt: e.createdAt, dueDate: e.dueDate);
    });
  }

  /// Customers in [segment] (live data, used by marketing lists too).
  Future<List<Customer>> segment(CustomerSegment segment, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final all = await (db.select(db.customers)..where((c) => c.deletedAt.isNull())).get();
    Map<String, int> overdue = const {};
    if (segment == CustomerSegment.overdue) {
      overdue = computeOverdue(await debtCharges(), {for (final c in all) c.id: c.debtBalance}, at);
    }
    return applyCustomerQuery(all, CustomerQuery(segment: segment), now: at, overdue: overdue);
  }
}

final customerRepoProvider = Provider((ref) => CustomerRepo(ref.watch(databaseProvider)));

/// All active (not deleted) customers, live.
final customersListProvider = StreamProvider<List<Customer>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.customers)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch();
});

/// Overdue amount per customer id, live.
final overdueDebtsProvider = StreamProvider<Map<String, int>>((ref) {
  final repo = ref.watch(customerRepoProvider);
  final customers = ref.watch(customersListProvider).value ?? const <Customer>[];
  final balances = {for (final c in customers) c.id: c.debtBalance};
  return repo.watchDebtCharges().map((charges) => computeOverdue(charges, balances, DateTime.now()));
});

final customerProvider = StreamProvider.family<Customer?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.customers)..where((c) => c.id.equals(id))).watchSingleOrNull();
});

final customerSalesProvider = StreamProvider.family<List<Sale>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.sales)
        ..where((s) => s.customerId.equals(id) & s.status.isNotIn(['held']) & s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
        ..limit(300))
      .watch();
});

final saleItemsProvider = FutureProvider.family<List<SaleItem>, String>((ref, saleId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.saleItems)..where((i) => i.saleId.equals(saleId))).get();
});

final customerLedgerProvider = StreamProvider.family<List<LedgerEntry>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.customerLedger)
        ..where((l) => l.customerId.equals(id) & l.deletedAt.isNull())
        ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
        ..limit(500))
      .watch();
});

class FavoriteProduct {
  FavoriteProduct(this.productId, this.name, this.qty, this.total);
  final String productId;
  final String name;
  final double qty;
  final int total;
}

/// Top 5 products by net quantity for a customer.
final favoriteProductsProvider = StreamProvider.family<List<FavoriteProduct>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.customSelect(
    'SELECT si.product_id AS pid, MAX(si.product_name) AS name, '
    'SUM(si.qty - si.returned_qty) AS q, SUM(si.total) AS t '
    'FROM sale_items si JOIN sales s ON s.id = si.sale_id '
    "WHERE s.customer_id = ? AND s.status NOT IN ('voided', 'held') AND s.deleted_at IS NULL "
    'GROUP BY si.product_id HAVING q > 0 ORDER BY q DESC, t DESC LIMIT 5',
    variables: [Variable.withString(id)],
    readsFrom: {db.saleItems, db.sales},
  ).watch().map((rows) => [
        for (final r in rows)
          FavoriteProduct(r.read<String>('pid'), r.read<String>('name'),
              r.read<double>('q'), r.read<int>('t')),
      ]);
});
