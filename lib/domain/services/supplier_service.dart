import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../l10n/l10n.dart';
import '../../core/db/database.dart';
import '../../core/doc_number.dart';
import '../../core/money.dart';
import '../errors.dart';

/// Supplier payment methods accepted by [SupplierLedgerService.pay].
const supplierPaymentMethods = <String>{'cash', 'card', 'transfer'};

/// Supplier ledger kinds.
abstract final class SupplierLedgerKind {
  static const opening = 'opening';
  static const receipt = 'receipt';
  static const receiptReversal = 'receipt_reversal';
  static const payment = 'payment';
  static const paymentCancel = 'payment_cancel';
  static const adjustment = 'adjustment';
}

/// The only writer of `suppliers.balance` (D-021). Every change is appended
/// to `supplier_ledger` with the running balance; the cached balance always
/// equals Σ ledger amounts (D-025: with several registers `balanceAfter` is the
/// writing register's view, so "balance == last balanceAfter" is not kept).
class SupplierLedgerService {
  SupplierLedgerService(this.db);
  final AppDatabase db;

  /// Applies a signed [amount] (positive = store owes the supplier more) and
  /// writes a ledger row. Runs in its own transaction which nests into the
  /// caller's. Returns the new balance. [id] is the ledger row id (default:
  /// a new one; a one-time effect passes `effectId`, D-025).
  Future<int> post({
    String? id,
    required String supplierId,
    required String kind,
    required int amount,
    String? refType,
    String? refId,
    String? userId,
    String? note,
  }) {
    return db.transaction(() async {
      final s = await (db.select(db.suppliers)..where((t) => t.id.equals(supplierId))).getSingleOrNull();
      if (s == null) throw BusinessException(L.current.errSupplierNotFound);
      // A deleted supplier must keep balance 0 (deleteSupplier's invariant):
      // nothing can settle a balance hidden on it. Only the migration
      // `opening` back-fill may touch it.
      if (s.deletedAt != null && kind != SupplierLedgerKind.opening) {
        throw BusinessException(L.current.errSupplierDeleted(s.name));
      }
      if (id != null &&
          await (db.select(db.supplierLedger)..where((l) => l.id.equals(id))).getSingleOrNull() != null) {
        // A one-time effect pulled from another register before its
        // document header (see StockService.move).
        throw BusinessException(L.current.errEffectDoneElsewhere, code: 'effect_done');
      }
      final after = s.balance + amount;
      final rowId = id ?? newId();
      await db.into(db.supplierLedger).insert(SupplierLedgerCompanion.insert(
            id: rowId,
            supplierId: supplierId,
            kind: kind,
            amount: amount,
            balanceAfter: after,
            refType: Value(refType),
            refId: Value(refId),
            userId: Value(userId),
            note: Value(note),
          ));
      await (db.update(db.suppliers)..where((t) => t.id.equals(supplierId)))
          .write(SuppliersCompanion(balance: Value(after), updatedAt: Value(DateTime.now())));
      await db.markDirty('suppliers', supplierId);
      await db.markDirty('supplier_ledger', rowId);
      return after;
    });
  }

  /// Records a payment to a supplier and decreases the balance.
  /// Cash payments require an open shift ([shiftId]); paying more than the
  /// balance requires [allowOverpay] (creates a prepayment / credit).
  /// Returns the payment id.
  Future<String> pay({
    required String supplierId,
    required int amount,
    required String method,
    String? shiftId,
    String? userId,
    String? orderId,
    String? note,
    bool allowOverpay = false,
  }) async {
    if (amount <= 0) throw BusinessException(L.current.errPaymentMustBePositive);
    if (!supplierPaymentMethods.contains(method)) throw BusinessException(L.current.errUnknownPaymentMethod);
    if (method == 'cash' && shiftId == null) {
      throw BusinessException(L.current.errOpenShiftForCashPayout, code: 'shift');
    }
    final id = newId();
    await db.transaction(() async {
      final s = await (db.select(db.suppliers)..where((t) => t.id.equals(supplierId))).getSingleOrNull();
      if (s == null || s.deletedAt != null) throw BusinessException(L.current.errSupplierNotFound);
      if (amount > s.balance && !allowOverpay) {
        throw BusinessException(
          L.current.errOverpaySupplier(Money.format(math.max(0, s.balance))),
          code: 'overpay',
        );
      }
      PurchaseOrder? order;
      if (orderId != null) {
        order = await (db.select(db.purchaseOrders)..where((t) => t.id.equals(orderId))).getSingleOrNull();
        if (order == null || order.supplierId != supplierId) {
          throw BusinessException(L.current.errOrderOtherSupplier);
        }
        if (order.status == 'cancelled') {
          throw BusinessException(L.current.errOrderCancelled(docNo(order.number, order.deviceCode)));
        }
      }
      if (shiftId != null && method == 'cash') {
        final sh = await (db.select(db.shifts)..where((t) => t.id.equals(shiftId))).getSingleOrNull();
        if (sh == null || sh.status != 'open') throw BusinessException(L.current.errShiftClosedOpenShift);
      }
      final now = DateTime.now();
      final cleanNote = _clean(note);
      await db.into(db.supplierPayments).insert(SupplierPaymentsCompanion.insert(
            id: id,
            supplierId: supplierId,
            amount: amount,
            method: Value(method),
            orderId: Value(orderId),
            shiftId: Value(method == 'cash' ? shiftId : null),
            userId: Value(userId),
            note: Value(cleanNote),
          ));
      final after = await post(
        supplierId: supplierId,
        kind: SupplierLedgerKind.payment,
        amount: -amount,
        refType: 'supplier_payment',
        refId: id,
        userId: userId,
        note: cleanNote,
      );
      if (order != null) {
        await (db.update(db.purchaseOrders)..where((t) => t.id.equals(order!.id)))
            .write(PurchaseOrdersCompanion(paid: Value(order.paid + amount), updatedAt: Value(now)));
        await db.markDirty('purchase_orders', order.id);
      }
      await db.markDirty('supplier_payments', id);
      await db.audit(
        'supplier.payment',
        userId: userId,
        entity: 'supplier',
        entityId: supplierId,
        details: '$amount; $method; баланс ${s.balance} → $after',
      );
    });
    return id;
  }

  /// Cancels a payment: the payment row is kept (marked cancelled) and a
  /// `payment_cancel` entry restores the balance. A cash payment can only be
  /// cancelled while its shift is still open and belongs to this register
  /// (with sync other registers' open shifts are here too, D-025: the cash
  /// would go back into THAT drawer). The `payment_cancel` row has the same
  /// id on every register, so a payment cancelled on two registers offline
  /// restores the balance once.
  Future<void> cancelPayment(String paymentId, {required String reason, String? userId}) async {
    final why = reason.trim();
    if (why.isEmpty) throw BusinessException(L.current.errCancelReasonRequired);
    await db.transaction(() async {
      final p = await (db.select(db.supplierPayments)..where((t) => t.id.equals(paymentId))).getSingleOrNull();
      if (p == null || p.deletedAt != null) throw BusinessException(L.current.errPaymentNotFound);
      if (p.cancelledAt != null) throw BusinessException(L.current.errPaymentAlreadyCancelled);
      if (p.method == 'cash') {
        final sh = p.shiftId == null
            ? null
            : await (db.select(db.shifts)..where((t) => t.id.equals(p.shiftId!))).getSingleOrNull();
        if (sh == null || sh.status != 'open') {
          throw BusinessException(L.current.errPaymentShiftClosed);
        }
        // Same rule as ShiftService.currentShift: with a device code only
        // shifts with this code (or kept as own after a code change) are
        // this register's; without sync every shift is.
        final code = await db.deviceCode();
        if (code != null &&
            sh.deviceCode != code &&
            !AppDatabase.parseOwnShifts(await db.getSetting(AppDatabase.ownShiftsSettingKey)).contains(sh.id)) {
          throw BusinessException(L.current.errPaymentOtherRegisterShift);
        }
      }
      final now = DateTime.now();
      await (db.update(db.supplierPayments)..where((t) => t.id.equals(paymentId))).write(
        SupplierPaymentsCompanion(cancelledAt: Value(now), cancelReason: Value(why), updatedAt: Value(now)),
      );
      final after = await post(
        id: effectId('payment_cancel', p.id),
        supplierId: p.supplierId,
        kind: SupplierLedgerKind.paymentCancel,
        amount: p.amount,
        refType: 'supplier_payment',
        refId: p.id,
        userId: userId,
        note: why,
      );
      if (p.orderId != null) {
        final o = await (db.select(db.purchaseOrders)..where((t) => t.id.equals(p.orderId!))).getSingleOrNull();
        if (o != null) {
          await (db.update(db.purchaseOrders)..where((t) => t.id.equals(o.id))).write(
            PurchaseOrdersCompanion(paid: Value(math.max(0, o.paid - p.amount)), updatedAt: Value(now)),
          );
          await db.markDirty('purchase_orders', o.id);
        }
      }
      await db.markDirty('supplier_payments', p.id);
      await db.audit(
        'supplier.payment_cancel',
        userId: userId,
        entity: 'supplier',
        entityId: p.supplierId,
        details: 'оплата ${p.id}; ${p.amount}; ${p.method}; баланс → $after; $why',
      );
    });
  }

  /// Manual balance correction (owner/admin; UI gates it with
  /// `Perm.manageSettings`). Returns the new balance.
  Future<int> adjust(String supplierId, int amount, {required String reason, String? userId}) async {
    if (amount == 0) throw BusinessException(L.current.errAdjustmentZero);
    final why = reason.trim();
    if (why.isEmpty) throw BusinessException(L.current.errAdjustmentReasonRequired);
    return db.transaction(() async {
      final s = await (db.select(db.suppliers)..where((t) => t.id.equals(supplierId))).getSingleOrNull();
      if (s == null || s.deletedAt != null) throw BusinessException(L.current.errSupplierNotFound);
      final after = await post(
        supplierId: supplierId,
        kind: SupplierLedgerKind.adjustment,
        amount: amount,
        userId: userId,
        note: why,
      );
      await db.audit(
        'supplier.adjust',
        userId: userId,
        entity: 'supplier',
        entityId: supplierId,
        details: '$amount; баланс ${s.balance} → $after; $why',
      );
      return after;
    });
  }
}

String? _clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
