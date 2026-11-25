// Regression tests for the third sync review (D-025, schema v7): indexes of
// the aggregate check, order lines received before v3, login bookkeeping as a
// stat part, local users of a joining database, the opening cash suggestion,
// one-time effects finalised on two registers, cancelling another register's
// cash supplier payment. All against the in-memory FakeSyncServer.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/security/pin.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/conflict_text.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/features/inventory/inventory_logic.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:dreampos/features/shifts/shift_logic.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../../support/fake_sync_server.dart';
import 'sync_harness.dart';

TypeMatcher<BusinessException> _err(String message) =>
    isA<BusinessException>().having((e) => e.message, 'message', message);

void main() {
  late FakeSyncServer server;
  final open = <SyncDevice>[];

  setUp(() {
    server = FakeSyncServer()..addUser(testEmail, testPassword);
  });
  tearDown(() async {
    for (final d in open) {
      await d.close();
    }
    open.clear();
  });

  Future<List<SyncDevice>> devices(int n) async {
    final ds = await cluster(n, server: server);
    open.addAll(ds);
    return ds;
  }

  Future<void> expectConverged(List<SyncDevice> ds) async {
    final first = await dump(ds.first.db);
    for (final d in ds.skip(1)) {
      expect(dumpDiff(first, await dump(d.db)), isNull, reason: '${ds.first.name} vs ${d.name}');
    }
    for (final d in ds) {
      expect(await SyncAggregates.verifyAll(d.db), isEmpty, reason: d.name);
      expect(await d.sync.pendingCount(), 0, reason: '${d.name} has unpushed changes');
    }
  }

  Future<User> userById(SyncDevice d, String id) => (d.db.select(d.db.users)..where((u) => u.id.equals(id))).getSingle();

  group('aggregate check indexes (v5 upgrade / «Проверка целостности» on a large store)', () {
    test('return lines and receipt lines are looked up by index, never scanned per line', () async {
      final db = memoryDb();
      addTearDown(db.close);
      for (final (sql, alias) in [
        (SyncAggregates.saleItemsReturnedSql, 'ri'),
        (SyncAggregates.salesSql, 'ri'),
        (SyncAggregates.orderItemsReceivedSql, 'i'),
      ]) {
        final plan = await db.customSelect('EXPLAIN QUERY PLAN $sql').get();
        final details = [for (final r in plan) r.read<String>('detail')];
        expect(details.where((d) => RegExp('^SCAN $alias\\b').hasMatch(d)), isEmpty, reason: details.join('\n'));
        expect(details.where((d) => RegExp('^SEARCH $alias USING').hasMatch(d)), isNotEmpty, reason: details.join('\n'));
      }
    });
  });

  group('order lines received before v3', () {
    test('normalisation adds an opening receipt; a joining register derives the same received qty', () async {
      final a = SyncDevice.create(server, 'A');
      final b = SyncDevice.create(server, 'B');
      open.addAll([a, b]);
      await a.createOwner();
      final sup = await a.supplier('Поставщик');
      final p = await a.product('Товар', qty: 0);
      final oid = newId(), lid = newId();
      // A pre-v3 receive: received_qty only, no receipt document.
      await a.db.into(a.db.purchaseOrders).insert(PurchaseOrdersCompanion.insert(
          id: oid, number: 1, supplierId: sup.id, status: const Value('ordered')));
      await a.db.into(a.db.purchaseOrderItems).insert(PurchaseOrderItemsCompanion.insert(
          id: lid, orderId: oid, productId: p.id, qty: 50, unitCost: 600, receivedQty: const Value(30)));

      final found = await SyncAggregates.normalize(a.db);
      expect(found.map((m) => (m.table, m.column)), [('purchase_order_items', 'received_qty')]);
      expect(await SyncAggregates.verifyAll(a.db), isEmpty);
      expect(await a.db.select(a.db.syncConflicts).get(), isEmpty);
      final doc = await (a.db.select(a.db.goodsReceipts)..where((r) => r.orderId.equals(oid))).getSingle();
      expect((doc.status, doc.total, doc.note), ('posted', 0, syncOpeningNote));
      // no stock or supplier effect, and it cannot be reversed
      expect((await a.productById(p.id)).stockQty, 0);
      expect((await a.supplierById(sup.id)).balance, 0);
      await expectLater(a.receipts.reverse(doc.id, reason: 'x', userId: a.userId),
          throwsA(_err(L.current.errReceiptOpeningNoReversal('${doc.number}'))));
      expect(await SyncAggregates.normalize(a.db), isEmpty, reason: 'idempotent');

      await a.signIn();
      final info = await a.sync.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
      await b.signIn();
      await b.sync.joinStore(info.id);
      await syncAll([a, b]);
      for (final d in [a, b]) {
        final line = await (d.db.select(d.db.purchaseOrderItems)..where((i) => i.id.equals(lid))).getSingle();
        expect(line.receivedQty, 30, reason: d.name);
        expect(remainingQty(line), 20, reason: d.name);
      }
      await expectConverged([a, b]);
    });
  });

  group('login bookkeeping is a stat part (schema v7)', () {
    Future<(SyncDevice, SyncDevice, String)> withCashier() async {
      final ds = await devices(2);
      final a = ds[0];
      final u = await AuthService(a.db).createUser(name: 'Кассир', role: Role.cashier, pin: '4826');
      await syncAll(ds);
      return (ds[0], ds[1], u.id);
    }

    test('a cashier logging in on B does not undo the deactivation made on A', () async {
      final (a, b, uid) = await withCashier();
      await (a.db.update(a.db.users)..where((u) => u.id.equals(uid)))
          .write(UsersCompanion(isActive: const Value(false), updatedAt: Value(DateTime.now())));
      await a.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect((await AuthService(b.db).loginWithPin('4826')).id, uid, reason: 'B has not pulled yet');
      await syncAll([a, b]);
      for (final d in [a, b]) {
        final u = await userById(d, uid);
        expect(u.isActive, isFalse, reason: d.name);
        expect(u.lastLoginAt, isNotNull, reason: '${d.name}: the login itself is kept');
        await expectLater(AuthService(d.db).loginWithPin('4826'), throwsA(isA<BusinessException>()), reason: d.name);
      }
      await expectConverged([a, b]);
    });

    test('a cashier logging in on B does not undo the PIN change made on A', () async {
      final (a, b, uid) = await withCashier();
      await AuthService(a.db).changePin(uid, '7391');
      await a.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await AuthService(b.db).loginWithPin('4826');
      await syncAll([a, b]);
      await expectConverged([a, b]);
      for (final d in [a, b]) {
        await expectLater(AuthService(d.db).loginWithPin('4826'), throwsA(isA<BusinessException>()), reason: d.name);
        expect((await AuthService(d.db).loginWithPin('7391')).id, uid, reason: d.name);
      }
    });

    test('a login is captured as op stat only', () async {
      final (_, b, _) = await withCashier();
      await AuthService(b.db).loginWithPin('4826');
      final ops = await b.db.customSelect("SELECT op FROM sync_outbox WHERE entity = 'users' AND synced_at IS NULL").get();
      expect(ops.map((r) => r.read<String>('op')), ['stat']);
    });
  });

  group('PIN collisions', () {
    test('joining from Settings deactivates the local users; the PIN logs in the same person everywhere', () async {
      final ds = await devices(1);
      final a = ds[0];
      final b = SyncDevice.create(server, 'B');
      open.add(b);
      // B ran the local setup wizard: its owner has the store owner's PIN.
      final local = await AuthService(b.db).createUser(name: 'Local owner', role: Role.owner, pin: '2580');
      await b.signIn();
      await b.sync.joinStore((await a.sync.refreshStatus()).storeId!);
      await syncAll([a, b]);
      await expectConverged([a, b]);

      for (final d in [a, b]) {
        expect((await userById(d, local.id)).isActive, isFalse, reason: d.name);
        expect((await AuthService(d.db).loginWithPin('2580')).name, 'Владелец', reason: d.name);
      }
      final c = await (b.db.select(b.db.syncConflicts)..where((c) => c.kind.equals(SyncConflictKind.joinUsers))).getSingle();
      expect(ConflictText.body(L.current, c), contains('Local owner'));
      expect(await (b.db.select(b.db.notifications)..where((n) => n.refType.equals('sync_conflict'))).get(), isNotEmpty);
    });

    test('a reconnect keeps the local users', () async {
      final ds = await devices(2);
      final b = ds[1];
      final u = await AuthService(b.db).createUser(name: 'Новый', role: Role.cashier, pin: '6153');
      final storeId = (await b.sync.refreshStatus()).storeId!;
      await b.sync.disconnect();
      await b.signIn();
      await b.sync.joinStore(storeId);
      await syncAll(ds);
      for (final d in ds) {
        expect((await userById(d, u.id)).isActive, isTrue, reason: d.name);
      }
    });

    test('a PIN shared by two active users is refused instead of logging in either of them', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final auth = AuthService(db);
      await auth.createUser(name: 'Первый', role: Role.owner, pin: '3917');
      // created on another register before they synced
      final salt = PinHasher.newSalt();
      await db.into(db.users).insert(UsersCompanion.insert(
          id: newId(), name: 'Второй', role: 'cashier', pinHash: PinHasher.hash('3917', salt), pinSalt: salt));
      await expectLater(auth.loginWithPin('3917'),
          throwsA(isA<BusinessException>().having((e) => e.code, 'code', 'pin_conflict')));
      expect((await db.select(db.users).get()).every((u) => u.lastLoginAt == null), isTrue);
    });
  });

  test('the suggested opening cash comes from this register\'s last shift, not another register\'s', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    await b.shifts.close(shiftId: b.shift!.id, userId: b.userId, countedCash: 2000);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await a.shifts.close(shiftId: a.shift!.id, userId: a.userId, countedCash: 987600);
    await syncAll(ds);
    expect(await suggestOpeningCash(b.db), 2000);
    expect(await suggestOpeningCash(a.db), 987600);
  });

  group('one-time effects finalised on two registers offline', () {
    test('a goods receipt reversed on both registers is reversed once', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final sup = await a.supplier('Поставщик');
      final p = await a.product('Товар', qty: 0);
      final r = await a.receipts.post(
          lines: [ReceiptLineInput(productId: p.id, qty: 10, unitCost: 500)], supplierId: sup.id, userId: a.userId);
      await syncAll(ds);
      expect((await b.productById(p.id)).stockQty, 10);
      await a.receipts.reverse(r.id, reason: 'ошибка', userId: a.userId);
      await b.receipts.reverse(r.id, reason: 'ошибка', userId: b.userId);
      await syncAll(ds);
      for (final d in ds) {
        expect((await d.productById(p.id)).stockQty, 0, reason: d.name);
        expect((await d.supplierById(sup.id)).balance, 0, reason: d.name);
        final mv = await (d.db.select(d.db.stockMovements)..where((m) => m.type.equals('receipt_reversal'))).get();
        expect(mv, hasLength(1), reason: d.name);
        final led = await (d.db.select(d.db.supplierLedger)..where((l) => l.kind.equals('receipt_reversal'))).get();
        expect(led, hasLength(1), reason: d.name);
        expect(await (d.db.select(d.db.syncConflicts)..where((c) => c.kind.equals(SyncConflictKind.negativeStock))).get(),
            isEmpty, reason: d.name);
      }
      await expectConverged(ds);
    });

    test('an inventory count completed on both registers corrects the stock once', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('Товар', qty: 10);
      final cid = await InventoryRepo(a.db, a.stock).createCount(scope: CountScope.selected, productIds: [p.id]);
      await a.db.customStatement('UPDATE inventory_count_items SET counted_qty = 7 WHERE count_id = ?', [cid]);
      await syncAll(ds);
      await a.stock.completeCount(cid, userId: a.userId);
      await b.stock.completeCount(cid, userId: b.userId);
      await syncAll(ds);
      for (final d in ds) {
        expect((await d.productById(p.id)).stockQty, 7, reason: d.name);
      }
      await expectConverged(ds);
    });

    test('a supplier payment cancelled on both registers restores the balance once', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final sup = await a.supplier('Поставщик');
      await a.ledger.post(supplierId: sup.id, kind: 'receipt', amount: 5000);
      final pid = await a.ledger.pay(supplierId: sup.id, amount: 3000, method: 'card', userId: a.userId);
      await syncAll(ds);
      await a.ledger.cancelPayment(pid, reason: 'ошибка', userId: a.userId);
      await b.ledger.cancelPayment(pid, reason: 'ошибка', userId: b.userId);
      await syncAll(ds);
      for (final d in ds) {
        expect((await d.supplierById(sup.id)).balance, 5000, reason: d.name);
      }
      await expectConverged(ds);
    });
  });

  test('a cash supplier payment of register A\'s shift cannot be cancelled on register B', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final sup = await a.supplier('Поставщик');
    await a.ledger.post(supplierId: sup.id, kind: 'receipt', amount: 5000);
    final pid = await a.ledger.pay(supplierId: sup.id, amount: 3000, method: 'cash', shiftId: a.shift!.id, userId: a.userId);
    await syncAll(ds);
    final before = (await a.shifts.report(a.shift!.id)).expectedCash;
    await expectLater(
        b.ledger.cancelPayment(pid, reason: 'ошибка', userId: b.userId), throwsA(_err(L.current.errPaymentOtherRegisterShift)));
    await syncAll(ds);
    expect((await a.shifts.report(a.shift!.id)).expectedCash, before);
    await a.ledger.cancelPayment(pid, reason: 'ошибка', userId: a.userId);
    expect((await a.shifts.report(a.shift!.id)).expectedCash, before + 3000);
  });
}
