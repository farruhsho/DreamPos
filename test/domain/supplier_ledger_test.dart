import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, RowIdExtension, Value;
import 'package:drift/native.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/sql_functions.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/receipt_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/domain/services/supplier_service.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late Fixture f;
  late SupplierLedgerService ledger;

  setUp(() async {
    f = await Fixture.create();
    ledger = SupplierLedgerService(f.db);
  });
  tearDown(() => f.db.close());

  Future<Supplier> supplier({String name = 'ООО Поставка', int balance = 0}) async {
    final id = newId();
    await f.db.into(f.db.suppliers).insert(SuppliersCompanion.insert(id: id, name: name));
    if (balance != 0) {
      await ledger.post(supplierId: id, kind: SupplierLedgerKind.opening, amount: balance, note: 'Начальный остаток');
    }
    return (f.db.select(f.db.suppliers)..where((s) => s.id.equals(id))).getSingle();
  }

  Future<Supplier> reloadS(String id) => (f.db.select(f.db.suppliers)..where((s) => s.id.equals(id))).getSingle();

  Future<List<SupplierLedgerEntry>> ledgerOf(String id) => (f.db.select(f.db.supplierLedger)
        ..where((l) => l.supplierId.equals(id))
        ..orderBy([(l) => OrderingTerm.asc(l.createdAt), (l) => OrderingTerm.asc(l.rowId)]))
      .get();

  Future<void> expectConsistent(String id) async {
    final rows = await ledgerOf(id);
    final s = await reloadS(id);
    // D-021 as relaxed by D-025: the invariant is cache == Σ amounts.
    expect(rows.fold<int>(0, (a, e) => a + e.amount), s.balance, reason: 'Σ amounts == balance');
    // On one register balanceAfter is still the running balance.
    var running = 0;
    for (final e in rows) {
      running += e.amount;
      expect(e.balanceAfter, running);
    }
  }

  test('post: running balance, markDirty; unknown supplier refused', () async {
    final s = await supplier();
    expect(await ledger.post(supplierId: s.id, kind: 'receipt', amount: 500), 500);
    expect(await ledger.post(supplierId: s.id, kind: 'payment', amount: -200), 300);
    await expectConsistent(s.id);
    await expectLater(ledger.post(supplierId: 'missing', kind: 'receipt', amount: 1), throwsA(isA<BusinessException>()));
    final dirty = (await f.db.select(f.db.syncOutbox).get()).map((e) => e.entity).toSet();
    expect(dirty, containsAll(['suppliers', 'supplier_ledger']));
  });

  test('post: a deleted supplier is refused except for the opening back-fill', () async {
    final s = await supplier();
    final pid = await ledger.pay(supplierId: s.id, amount: 400, method: 'transfer', allowOverpay: true);
    await ledger.post(supplierId: s.id, kind: SupplierLedgerKind.adjustment, amount: 400);
    expect((await reloadS(s.id)).balance, 0);
    await (f.db.update(f.db.suppliers)..where((t) => t.id.equals(s.id)))
        .write(SuppliersCompanion(deletedAt: Value(DateTime.now())));
    for (final kind in [
      SupplierLedgerKind.receipt,
      SupplierLedgerKind.receiptReversal,
      SupplierLedgerKind.payment,
      SupplierLedgerKind.paymentCancel,
      SupplierLedgerKind.adjustment,
    ]) {
      await expectLater(ledger.post(supplierId: s.id, kind: kind, amount: -100), throwsA(isA<BusinessException>()));
    }
    // Cancelling an old payment of a deleted supplier would hide a debt too.
    await expectLater(ledger.cancelPayment(pid, reason: 'x'), throwsA(isA<BusinessException>()));
    expect((await reloadS(s.id)).balance, 0);
    expect((await f.db.select(f.db.supplierPayments).getSingle()).cancelledAt, isNull);
    expect(await ledger.post(supplierId: s.id, kind: SupplierLedgerKind.opening, amount: 0), 0);
    await expectConsistent(s.id);
  });

  test('pay: payment row + ledger entry, order paid, audit; validations kept', () async {
    final s = await supplier(balance: 10000);
    final p = await f.product('A', stock: 0);
    final repo = PurchasingRepo(f.db, StockService(f.db), null, ledger);
    final oid = await repo.saveDraftOrder(supplierId: s.id, lines: [PoLineInput(productId: p.id, qty: 4, unitCost: 500)]);

    await expectLater(ledger.pay(supplierId: s.id, amount: 0, method: 'transfer'), throwsA(isA<BusinessException>()));
    await expectLater(ledger.pay(supplierId: s.id, amount: 1, method: 'crypto'), throwsA(isA<BusinessException>()));
    await expectLater(ledger.pay(supplierId: s.id, amount: 1, method: 'cash'),
        throwsA(isA<BusinessException>().having((e) => e.code, 'code', 'shift')));
    await expectLater(ledger.pay(supplierId: s.id, amount: 20000, method: 'card'),
        throwsA(isA<BusinessException>().having((e) => e.code, 'code', 'overpay')));

    final pid = await ledger.pay(supplierId: s.id, amount: 1500, method: 'transfer', orderId: oid, userId: f.owner.id);
    expect((await reloadS(s.id)).balance, 8500);
    final row = (await ledgerOf(s.id)).last;
    expect(row.kind, 'payment');
    expect(row.amount, -1500);
    expect(row.refType, 'supplier_payment');
    expect(row.refId, pid);
    final o = await (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
    expect(o.paid, 1500);
    expect((await f.db.select(f.db.auditLog).get()).map((e) => e.action), contains('supplier.payment'));
    await expectConsistent(s.id);
  });

  test('cancelPayment: reason, reversal entry, order paid, cannot cancel twice', () async {
    final s = await supplier(balance: 5000);
    final p = await f.product('A', stock: 0);
    final repo = PurchasingRepo(f.db, StockService(f.db), null, ledger);
    final oid = await repo.saveDraftOrder(supplierId: s.id, lines: [PoLineInput(productId: p.id, qty: 4, unitCost: 500)]);
    final pid = await repo.paySupplier(supplierId: s.id, amount: 2000, method: 'card', orderId: oid);
    expect((await reloadS(s.id)).balance, 3000);

    await expectLater(ledger.cancelPayment(pid, reason: ' '), throwsA(isA<BusinessException>()));
    await expectLater(ledger.cancelPayment('missing', reason: 'x'), throwsA(isA<BusinessException>()));
    await repo.cancelSupplierPayment(pid, reason: 'Ошибочный платёж', userId: f.owner.id);

    expect((await reloadS(s.id)).balance, 5000);
    final pay = await (f.db.select(f.db.supplierPayments)..where((t) => t.id.equals(pid))).getSingle();
    expect(pay.cancelledAt, isNotNull);
    expect(pay.cancelReason, 'Ошибочный платёж');
    final rows = await ledgerOf(s.id);
    expect(rows.map((e) => e.kind), ['opening', 'payment', 'payment_cancel']);
    expect(rows.last.amount, 2000);
    expect(rows.last.refId, pid);
    final o = await (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
    expect(o.paid, 0);
    expect((await f.db.select(f.db.auditLog).get()).map((e) => e.action), contains('supplier.payment_cancel'));

    await expectLater(ledger.cancelPayment(pid, reason: 'ещё раз'),
        throwsA(isA<BusinessException>().having((e) => e.message, 'message', 'Оплата уже отменена')));
    await expectConsistent(s.id);
  });

  test('cash payment: cancel ignored by shift report; blocked once the shift is closed', () async {
    final s = await supplier(balance: 10000);
    final shifts = ShiftService(f.db);
    final before = await shifts.report(f.shift.id);
    final p1 = await ledger.pay(supplierId: s.id, amount: 4000, method: 'cash', shiftId: f.shift.id);
    final p2 = await ledger.pay(supplierId: s.id, amount: 1000, method: 'cash', shiftId: f.shift.id);
    var rep = await shifts.report(f.shift.id);
    expect(rep.supplierCashPaid, 5000);
    expect(rep.expectedCash, before.expectedCash - 5000);

    await ledger.cancelPayment(p1, reason: 'Не та сумма');
    rep = await shifts.report(f.shift.id);
    expect(rep.supplierCashPaid, 1000, reason: 'cancelled payment ignored');
    expect(rep.expectedCash, before.expectedCash - 1000);

    await shifts.close(shiftId: f.shift.id, userId: f.owner.id, countedCash: rep.expectedCash);
    await expectLater(ledger.cancelPayment(p2, reason: 'поздно'),
        throwsA(isA<BusinessException>()
            .having((e) => e.message, 'message', 'Смена оплаты закрыта — отмена невозможна')));
    expect((await reloadS(s.id)).balance, 10000 - 1000);
    await expectConsistent(s.id);
  });

  test('adjust: non-zero amount and reason required, audited', () async {
    final s = await supplier(balance: 1000);
    await expectLater(ledger.adjust(s.id, 0, reason: 'x'), throwsA(isA<BusinessException>()));
    await expectLater(ledger.adjust(s.id, 100, reason: ''), throwsA(isA<BusinessException>()));
    expect(await ledger.adjust(s.id, -300, reason: 'Скидка поставщика', userId: f.owner.id), 700);
    final row = (await ledgerOf(s.id)).last;
    expect(row.kind, 'adjustment');
    expect(row.note, 'Скидка поставщика');
    expect(row.userId, f.owner.id);
    expect((await f.db.select(f.db.auditLog).get()).map((e) => e.action), contains('supplier.adjust'));
    await expectConsistent(s.id);
  });

  test('mixed operations keep the ledger consistent; statement for a period', () async {
    final s = await supplier(balance: 1000);
    final a = await f.product('A', stock: 0);
    final receipts = ReceiptService(f.db, StockService(f.db), ledger);
    final r = await receipts.post(supplierId: s.id, lines: [ReceiptLineInput(productId: a.id, qty: 10, unitCost: 300)]);
    final pid = await ledger.pay(supplierId: s.id, amount: 2500, method: 'transfer');
    await ledger.adjust(s.id, 50, reason: 'округление');
    await ledger.cancelPayment(pid, reason: 'возврат платежа');
    await receipts.reverse(r.id, reason: 'ошибка');
    expect((await reloadS(s.id)).balance, 1050);
    await expectConsistent(s.id);

    final rows = await ledgerOf(s.id);
    final st = SupplierStatement.of(rows);
    expect(st.opening, 1000, reason: 'the opening row is the starting balance, not turnover');
    expect(st.increase, 3000 + 50 + 2500);
    expect(st.decrease, 2500 + 3000);
    expect(st.closing, 1050);
    final later = SupplierStatement.of(rows, from: DateTime.now().add(const Duration(days: 1)));
    expect(later.opening, 1050);
    expect(later.rows, isEmpty);
    expect(later.closing, 1050);
    expect(supplierLedgerKindLabels.keys, containsAll(rows.map((e) => e.kind)));
  });

  group('migration v2 → v3', () {
    test('opening entries back-fill is idempotent', () async {
      final a = newId(), b = newId();
      await f.db.into(f.db.suppliers).insert(SuppliersCompanion.insert(id: a, name: 'A', balance: const Value(7000)));
      await f.db.into(f.db.suppliers).insert(SuppliersCompanion.insert(id: b, name: 'B'));
      expect(await insertOpeningSupplierEntries(f.db), 1);
      expect(await insertOpeningSupplierEntries(f.db), 0);
      final rows = await f.db.select(f.db.supplierLedger).get();
      expect(rows.single.supplierId, a);
      expect(rows.single.kind, 'opening');
      expect(rows.single.amount, 7000);
      expect(rows.single.balanceAfter, 7000);
      expect(rows.single.note, 'Начальный остаток');
    });

    test('a half-migrated v2 file (column already added) still upgrades', () async {
      final dir = Directory.systemTemp.createTempSync('dreampos_mig_half_');
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {}
      });
      final file = File('${dir.path}${Platform.pathSeparator}v2.sqlite');
      final owes = newId();
      final v2 = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
      await v2.into(v2.suppliers).insert(SuppliersCompanion.insert(id: owes, name: 'Должны', balance: const Value(900)));
      // An interrupted earlier upgrade: tables created, cancelled_at added,
      // cancel_reason not yet, no opening rows, user_version still 2.
      for (final sql in [
        'DROP TABLE supplier_ledger',
        'ALTER TABLE supplier_payments DROP COLUMN cancel_reason',
        'PRAGMA user_version = 2',
      ]) {
        await v2.customStatement(sql);
      }
      await v2.close();

      final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
      addTearDown(db.close);
      final rows = await db.select(db.supplierLedger).get();
      expect(rows.single.supplierId, owes);
      expect(rows.single.kind, 'opening');
      expect(rows.single.balanceAfter, 900);
      final cols = await db.customSelect('PRAGMA table_info(supplier_payments)').get();
      expect(cols.map((r) => r.read<String>('name')), containsAll(['cancelled_at', 'cancel_reason']));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.first, 7);
    });

    test('a v2 database is upgraded: tables, columns, indexes, opening entries', () async {
      final dir = Directory.systemTemp.createTempSync('dreampos_mig_');
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {}
      });
      final file = File('${dir.path}${Platform.pathSeparator}v2.sqlite');
      final owes = newId(), zero = newId(), credit = newId();

      // Build the v3 schema, then strip it down to v2.
      final v2 = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
      await v2.into(v2.suppliers).insert(SuppliersCompanion.insert(id: owes, name: 'Должны', balance: const Value(12500)));
      await v2.into(v2.suppliers).insert(SuppliersCompanion.insert(id: zero, name: 'Ноль'));
      await v2.into(v2.suppliers).insert(SuppliersCompanion.insert(id: credit, name: 'Аванс', balance: const Value(-300)));
      for (final sql in [
        'DROP TABLE supplier_ledger',
        'DROP TABLE goods_receipt_items',
        'DROP TABLE goods_receipts',
        'ALTER TABLE supplier_payments DROP COLUMN cancel_reason',
        'ALTER TABLE supplier_payments DROP COLUMN cancelled_at',
        'PRAGMA user_version = 2',
      ]) {
        await v2.customStatement(sql);
      }
      await v2.close();

      final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
      addTearDown(db.close);
      final rows = await db.select(db.supplierLedger).get();
      expect(rows.length, 2);
      final byS = {for (final r in rows) r.supplierId: r};
      expect(byS[owes]!.kind, 'opening');
      expect(byS[owes]!.amount, 12500);
      expect(byS[owes]!.balanceAfter, 12500);
      expect(byS[owes]!.note, 'Начальный остаток');
      expect(byS[credit]!.balanceAfter, -300);
      expect(byS.containsKey(zero), isFalse);

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.first, 7);
      final idx = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'ix_%'")
          .get();
      expect(
          idx.map((r) => r.read<String>('name')),
          containsAll([
            'ix_goods_receipts_created',
            'ix_goods_receipts_supplier',
            'ix_goods_receipts_order',
            'ix_goods_receipt_items_receipt',
            'ix_supplier_ledger_supplier',
          ]));

      // New columns and tables work after the upgrade.
      final svc = SupplierLedgerService(db);
      final pid = await svc.pay(supplierId: owes, amount: 500, method: 'transfer');
      await svc.cancelPayment(pid, reason: 'тест');
      final pay = await (db.select(db.supplierPayments)..where((p) => p.id.equals(pid))).getSingle();
      expect(pay.cancelledAt, isNotNull);
      final sup = await (db.select(db.suppliers)..where((s) => s.id.equals(owes))).getSingle();
      final last = await (db.select(db.supplierLedger)
            ..where((l) => l.supplierId.equals(owes))
            ..orderBy([(l) => OrderingTerm.desc(l.createdAt), (l) => OrderingTerm.desc(l.rowId)])
            ..limit(1))
          .getSingle();
      expect(sup.balance, 12500);
      expect(last.balanceAfter, sup.balance);
      expect((await db.select(db.supplierLedger).get()).where((l) => l.supplierId == owes).fold<int>(0, (a, e) => a + e.amount),
          sup.balance);
    });
  });
}

