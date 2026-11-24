import 'package:drift/drift.dart';

import '../../l10n/l10n.dart';
import '../../core/db/database.dart';
import '../errors.dart';

class CustomerService {
  CustomerService(this.db);
  final AppDatabase db;

  /// Customer pays off debt. Cash payments are counted in the shift's cash.
  Future<void> payDebt({
    required String customerId,
    required int amount,
    required String method,
    required String userId,
    String? shiftId,
    String? note,
  }) async {
    if (amount <= 0) throw BusinessException(L.current.errAmountMustBePositive);
    await db.transaction(() async {
      final c = await (db.select(db.customers)..where((t) => t.id.equals(customerId))).getSingle();
      if (c.debtBalance <= 0) throw BusinessException(L.current.errNoDebt);
      if (amount > c.debtBalance) {
        throw BusinessException(L.current.errAmountExceedsDebt);
      }
      if (method == 'cash') {
        if (shiftId == null) throw BusinessException(L.current.errOpenShiftForCash);
      }
      final after = c.debtBalance - amount;
      final ledgerId = newId();
      await db.into(db.customerLedger).insert(CustomerLedgerCompanion.insert(
            id: ledgerId,
            customerId: customerId,
            kind: 'debt_payment',
            amount: -amount,
            balanceAfter: after,
            userId: Value(userId),
            shiftId: Value(shiftId),
            paymentMethod: Value(method),
            note: Value(note),
          ));
      await (db.update(db.customers)..where((t) => t.id.equals(customerId))).write(
          CustomersCompanion(debtBalance: Value(after), updatedAt: Value(DateTime.now())));
      await db.markDirty('customers', customerId);
      await db.markDirty('customer_ledger', ledgerId);
      await db.audit('debt.payment', userId: userId, entity: 'customer', entityId: customerId,
          details: '$amount $method');
    });
  }

  /// Manual bonus correction (requires managePromotions/editCustomers).
  Future<void> adjustBonus({
    required String customerId,
    required int delta,
    required String userId,
    required String reason,
  }) async {
    if (delta == 0) return;
    await db.transaction(() async {
      final c = await (db.select(db.customers)..where((t) => t.id.equals(customerId))).getSingle();
      final after = c.bonusBalance + delta;
      if (after < 0) throw BusinessException(L.current.errBonusNegative);
      final ledgerId = newId();
      await db.into(db.customerLedger).insert(CustomerLedgerCompanion.insert(
            id: ledgerId,
            customerId: customerId,
            kind: 'bonus_adjust',
            amount: delta,
            balanceAfter: after,
            userId: Value(userId),
            note: Value(reason),
          ));
      await (db.update(db.customers)..where((t) => t.id.equals(customerId)))
          .write(CustomersCompanion(bonusBalance: Value(after), updatedAt: Value(DateTime.now())));
      await db.markDirty('customers', customerId);
      await db.markDirty('customer_ledger', ledgerId);
      await db.audit('bonus.adjust', userId: userId, entity: 'customer', entityId: customerId,
          details: '$delta; $reason');
    });
  }
}
