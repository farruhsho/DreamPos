import 'package:drift/drift.dart';

import '../../l10n/l10n.dart';
import '../../core/db/database.dart';
import '../../core/doc_number.dart';
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
    this.returnedCost = 0,
    this.giftSalesCount = 0,
    this.giftVoidsCount = 0,
    this.giftSalesByMethod = const {},
    this.giftRefundsByMethod = const {},
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
  /// Cost of goods returned in this shift.
  final int returnedCost;

  /// Gift card sale documents recorded in this shift (D-023), including ones
  /// voided later: the money did come into this shift's drawer.
  final int giftSalesCount;

  /// Gift card sales voided in this shift (whatever shift sold them).
  final int giftVoidsCount;

  /// Gift card sale payments by method for [giftSalesCount] documents.
  /// An advance, not revenue: never part of [salesTotal] / [byMethod].
  final Map<String, int> giftSalesByMethod;

  /// Refunds of gift card sales voided in this shift, by original method.
  final Map<String, int> giftRefundsByMethod;

  int get giftSalesTotal => giftSalesByMethod.values.fold(0, (s, v) => s + v);
  int get giftRefundsTotal => giftRefundsByMethod.values.fold(0, (s, v) => s + v);

  /// Net effect of gift card sales and voids on the cash drawer.
  int get giftCashNet => (giftSalesByMethod['cash'] ?? 0) - (giftRefundsByMethod['cash'] ?? 0);

  int get cashSales => byMethod['cash'] ?? 0;
  int get cashRefunds => refundsByMethod['cash'] ?? 0;
  int get netRevenue => salesTotal - returnsTotal;
  /// Net gross profit: (sales - cost) - (refunds - cost of returned goods).
  int get grossProfit => (salesTotal - costTotal) - (returnsTotal - returnedCost);

  int get expectedCash =>
      shift.openingCash +
      cashSales -
      cashRefunds +
      payIn -
      payOut +
      debtCollectedCash -
      supplierCashPaid +
      giftCashNet;

  int? get difference =>
      shift.countedCash == null ? null : shift.countedCash! - expectedCash;
}

class ShiftService {
  ShiftService(this.db);
  final AppDatabase db;

  /// The open shift of THIS register. With sync on (a device code is set)
  /// other registers' open shifts are synced here too, so the shift is the
  /// one with this register's code, or one this database kept as its own
  /// when its code changed (D-025, [AppDatabase.ownShiftsSettingKey]);
  /// without sync, the latest open shift as before. [registerId] narrows it
  /// further.
  Future<Shift?> currentShift({String? registerId}) async {
    final code = await db.deviceCode();
    final own = AppDatabase.parseOwnShifts(await db.getSetting(AppDatabase.ownShiftsSettingKey));
    return db.currentShiftQuery(code, own, registerId: registerId).getSingleOrNull();
  }

  Future<Shift> open({required String userId, required int openingCash, String? registerId}) async {
    if (openingCash < 0) throw BusinessException(L.current.errAmountNegative);
    return db.transaction(() async {
      final existing = await currentShift(registerId: registerId);
      if (existing != null) {
        throw BusinessException(L.current.errShiftAlreadyOpen(docNo(existing.number, existing.deviceCode)));
      }
      final id = newId();
      final number = await db.nextNumber('shift');
      await db.into(db.shifts).insert(ShiftsCompanion.insert(
            id: id,
            number: number,
            deviceCode: Value(await db.deviceCode()),
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
    if (amount <= 0) throw BusinessException(L.current.errAmountMustBePositive);
    if (!const ['pay_in', 'pay_out', 'expense', 'collection'].contains(kind)) {
      throw BusinessException(L.current.errUnknownOperation);
    }
    await db.transaction(() async {
      final shift = await (db.select(db.shifts)..where((s) => s.id.equals(shiftId))).getSingle();
      if (shift.status != 'open') throw BusinessException(L.current.errShiftClosed);
      if (kind != 'pay_in') {
        final rep = await report(shiftId);
        if (amount > rep.expectedCash) {
          throw BusinessException(L.current.errNotEnoughCash);
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
    var returnedCost = 0;
    if (rets.isNotEmpty) {
      final row = await db.customSelect(
        'SELECT COALESCE(SUM(ri.qty * si.unit_cost), 0) AS c FROM return_items ri '
        'JOIN sale_items si ON si.id = ri.sale_item_id '
        'WHERE ri.return_id IN (${List.filled(rets.length, '?').join(',')})',
        variables: [for (final r in rets) Variable.withString(r.id)],
      ).getSingle();
      returnedCost = (row.data['c'] as num).round();
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
          ..where((p) => p.shiftId.equals(shiftId) & p.method.equals('cash') & p.cancelledAt.isNull() & p.deletedAt.isNull()))
        .get();
    final giftSold = await (db.select(db.giftCardSales)
          ..where((g) => g.shiftId.equals(shiftId) & g.deletedAt.isNull()))
        .get();
    final giftVoided = await (db.select(db.giftCardSales)
          ..where((g) => g.voidShiftId.equals(shiftId) & g.status.equals('voided') & g.deletedAt.isNull()))
        .get();
    Future<Map<String, int>> giftByMethod(List<GiftCardSale> docs) async {
      final out = <String, int>{};
      if (docs.isEmpty) return out;
      final pays = await (db.select(db.giftCardSalePayments)
            ..where((p) => p.saleId.isIn(docs.map((d) => d.id)) & p.deletedAt.isNull()))
          .get();
      for (final p in pays) {
        out[p.method] = (out[p.method] ?? 0) + p.amount;
      }
      return out;
    }

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
      returnedCost: returnedCost,
      giftSalesCount: giftSold.length,
      giftVoidsCount: giftVoided.length,
      giftSalesByMethod: await giftByMethod(giftSold),
      giftRefundsByMethod: await giftByMethod(giftVoided),
    );
  }

  Future<ShiftReport> close({
    required String shiftId,
    required String userId,
    required int countedCash,
    String? note,
  }) async {
    if (countedCash < 0) throw BusinessException(L.current.errAmountNegative);
    return db.transaction(() async {
      final shift = await (db.select(db.shifts)..where((s) => s.id.equals(shiftId))).getSingle();
      if (shift.status != 'open') throw BusinessException(L.current.errShiftAlreadyClosed);
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
