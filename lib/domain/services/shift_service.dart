import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../errors.dart';

/// X/Z report figures for a shift.
class ShiftReport {
  ShiftReport({
    required this.shift,
    required this.salesCount,
    required this.salesTotal,
    required this.discountTotal,
    required this.costTotal,
    required this.byMethod,
    required this.returnsCount,
    required this.returnsTotal,
    required this.refundsByMethod,
    required this.payIn,
    required this.payOut,
    required this.debtCollectedCash,
    required this.debtCollectedNonCash,
    required this.supplierCashPaid,
    required this.voidedCount,
  });

  final Shift shift;
  final int salesCount;
  final int salesTotal;
  final int discountTotal;
  final int costTotal;
  final Map<String, int> byMethod;
  final int returnsCount;
  final int returnsTotal;
  final Map<String, int> refundsByMethod;
  final int payIn;
  /// pay_out + expense + collection
  final int payOut;
  final int debtCollectedCash;
  final int debtCollectedNonCash;
  final int supplierCashPaid;
  final int voidedCount;

  int get cashSales => byMethod['cash'] ?? 0;
  int get cashRefunds => refundsByMethod['cash'] ?? 0;
  int get netRevenue => salesTotal - returnsTotal;
  int get grossProfit => salesTotal - costTotal - (returnsTotal > 0 ? 0 : 0);

  int get expectedCash =>
      shift.openingCash +
      cashSales -
      cashRefunds +
      payIn -
      payOut +
      debtCollectedCash -
      supplierCashPaid;

  int? get difference =>
      shift.countedCash == null ? null : shift.countedCash! - expectedCash;
}

class ShiftService {
  ShiftService(this.db);
  final AppDatabase db;

  Future<Shift?> currentShift({String? registerId}) {
    final q = db.select(db.shifts)..where((s) => s.status.equals('open'));
    if (registerId != null) q.where((s) => s.registerId.equals(registerId));
    q.orderBy([(s) => OrderingTerm.desc(s.openedAt)]);
    q.limit(1);
    return q.getSingleOrNull();
  }

  Future<Shift> open({required String userId, required int openingCash, String? registerId}) async {
    if (openingCash < 0) throw BusinessException('Сумма не может быть отрицательной');
    return db.transaction(() async {
      final existing = await currentShift(registerId: registerId);
      if (existing != null) {
        throw BusinessException('Смена №${existing.number} уже открыта');
      }
      final id = newId();
      final number = await db.nextNumber('shift');
      await db.into(db.shifts).insert(ShiftsCompanion.insert(
            id: id,
            number: number,
            registerId: Value(registerId),
            openedBy: userId,
            openedAt: DateTime.now(),
            openingCash: Value(openingCash),
          ));
      await db.audit('shift.open', userId: userId, entity: 'shift', entityId: id,
          details: 'opening=$openingCash');
      return (db.select(db.shifts)..where((s) => s.id.equals(id))).getSingle();
    });
  }

  Future<void> cashMovement({
    required String shiftId,
    required String kind,
    required int amount,
    required String userId,
    String? reason,
    String? expenseCategory,
  }) async {
    if (amount <= 0) throw BusinessException('Сумма должна быть больше нуля');
    if (!const ['pay_in', 'pay_out', 'expense', 'collection'].contains(kind)) {
      throw BusinessException('Неизвестная операция');
    }
    await db.transaction(() async {
      final shift = await (db.select(db.shifts)..where((s) => s.id.equals(shiftId))).getSingle();
      if (shift.status != 'open') throw BusinessException('Смена закрыта');
      if (kind != 'pay_in') {
        final rep = await report(shiftId);
        if (amount > rep.expectedCash) {
          throw BusinessException('В кассе недостаточно наличных');
        }
      }
      await db.into(db.cashMovements).insert(CashMovementsCompanion.insert(
            id: newId(),
            shiftId: shiftId,
            kind: kind,
            amount: amount,
            reason: Value(reason),
            expenseCategory: Value(expenseCategory),
            userId: Value(userId),
          ));
      await db.audit('cash.$kind', userId: userId, entity: 'shift', entityId: shiftId,
          details: '$amount; ${reason ?? ''}');
    });
  }

  Future<ShiftReport> report(String shiftId) async {
    final shift = await (db.select(db.shifts)..where((s) => s.id.equals(shiftId))).getSingle();
    final sales = await (db.select(db.sales)..where((s) => s.shiftId.equals(shiftId))).get();
    final valid = sales.where((s) => s.status != 'voided' && s.status != 'held').toList();
    final validIds = valid.map((s) => s.id).toSet();
    final payments = validIds.isEmpty
        ? <SalePayment>[]
        : await (db.select(db.salePayments)..where((p) => p.saleId.isIn(validIds))).get();
    final byMethod = <String, int>{};
    for (final p in payments) {
      byMethod[p.method] = (byMethod[p.method] ?? 0) + p.amount;
    }
    final rets = await (db.select(db.returns)..where((r) => r.shiftId.equals(shiftId))).get();
    final refunds = <String, int>{};
    for (final r in rets) {
      refunds[r.refundMethod] = (refunds[r.refundMethod] ?? 0) + r.total;
    }
    final moves = await (db.select(db.cashMovements)..where((m) => m.shiftId.equals(shiftId))).get();
    var payIn = 0, payOut = 0;
    for (final m in moves) {
      if (m.kind == 'pay_in') {
        payIn += m.amount;
      } else {
        payOut += m.amount;
      }
    }
    final debtPays = await (db.select(db.customerLedger)
          ..where((l) => l.shiftId.equals(shiftId) & l.kind.equals('debt_payment')))
        .get();
    var debtCash = 0, debtNonCash = 0;
    for (final d in debtPays) {
      if ((d.paymentMethod ?? 'cash') == 'cash') {
        debtCash += -d.amount;
      } else {
        debtNonCash += -d.amount;
      }
    }
    final supPays = await (db.select(db.supplierPayments)
          ..where((p) => p.shiftId.equals(shiftId) & p.method.equals('cash')))
        .get();
    return ShiftReport(
      shift: shift,
      salesCount: valid.length,
      salesTotal: valid.fold(0, (s, x) => s + x.total),
      discountTotal: valid.fold(0, (s, x) => s + x.discountTotal),
      costTotal: valid.fold(0, (s, x) => s + x.costTotal),
      byMethod: byMethod,
      returnsCount: rets.length,
      returnsTotal: rets.fold(0, (s, r) => s + r.total),
      refundsByMethod: refunds,
      payIn: payIn,
      payOut: payOut,
      debtCollectedCash: debtCash,
      debtCollectedNonCash: debtNonCash,
      supplierCashPaid: supPays.fold(0, (s, p) => s + p.amount),
      voidedCount: sales.where((s) => s.status == 'voided').length,
    );
  }

  Future<ShiftReport> close({
    required String shiftId,
    required String userId,
    required int countedCash,
    String? note,
  }) async {
    if (countedCash < 0) throw BusinessException('Сумма не может быть отрицательной');
    return db.transaction(() async {
      final shift = await (db.select(db.shifts)..where((s) => s.id.equals(shiftId))).getSingle();
      if (shift.status != 'open') throw BusinessException('Смена уже закрыта');
      final rep = await report(shiftId);
      await (db.update(db.shifts)..where((s) => s.id.equals(shiftId))).write(ShiftsCompanion(
            status: const Value('closed'),
            closedBy: Value(userId),
            closedAt: Value(DateTime.now()),
            expectedCash: Value(rep.expectedCash),
            countedCash: Value(countedCash),
            note: Value(note),
            updatedAt: Value(DateTime.now()),
          ));
      await db.audit('shift.close', userId: userId, entity: 'shift', entityId: shiftId,
          details: 'expected=${rep.expectedCash}; counted=$countedCash');
      return report(shiftId);
    });
  }
}
