// Regression tests for the fourth sync review (D-025): partial-return
// rounding, shift history order, purchase order lines of a crossed draft
// edit, inventory counts reverting to draft, effect rows pulled before their
// document, unique-key collisions judged differently, warranty write-off on
// two registers, duplicate numbers of every numbered document after a
// restore, deterministic soft-delete stamps, malformed / wrongly typed /
// out-of-range remote changes, and the refresh token in backups. All against
// the in-memory FakeSyncServer.
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/sql_functions.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/conflict_text.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/inventory/inventory_logic.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:dreampos/features/settings/backup_service.dart';
import 'package:dreampos/features/shifts/shift_logic.dart';
import 'package:dreampos/features/warranty/warranty_logic.dart';
import 'package:dreampos/features/warranty/warranty_repository.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_sync_server.dart';
import 'sync_harness.dart';

/// Delegates to [inner]; the [failAt]-th push call (1-based) fails with a
/// network error before the server stores anything.
class _FailNthPush implements SyncTransport {
  _FailNthPush(this.inner, {required this.failAt});
  final SyncTransport inner;
  final int failAt;
  int pushes = 0;

  @override
  Future<SyncSession> signIn({required String email, required String password}) =>
      inner.signIn(email: email, password: password);
  @override
  Future<SyncSession> restoreSession(String refreshToken) => inner.restoreSession(refreshToken);
  @override
  SyncSession? get session => inner.session;
  @override
  Future<void> signOut() => inner.signOut();
  @override
  Future<List<StoreInfo>> listStores() => inner.listStores();
  @override
  Future<StoreInfo> createStore({required String name, required StoreEnvironment environment}) =>
      inner.createStore(name: name, environment: environment);
  @override
  Future<DeviceRegistration> registerDevice({required String storeId, required String deviceId, required String name}) =>
      inner.registerDevice(storeId: storeId, deviceId: deviceId, name: name);
  @override
  Future<StoreInfo> storeInfo(String storeId) => inner.storeInfo(storeId);
  @override
  Future<PushResult> push({required String storeId, required String deviceId, required List<SyncChange> changes}) {
    if (++pushes == failAt) throw SyncException(SyncErrorKind.network, detail: 'injected');
    return inner.push(storeId: storeId, deviceId: deviceId, changes: changes);
  }

  @override
  Future<PullResult> pull({required String storeId, required int since, int max = 500}) =>
      inner.pull(storeId: storeId, since: since, max: max);
}

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

  Future<List<SyncConflict>> conflicts(SyncDevice d, String kind) =>
      (d.db.select(d.db.syncConflicts)..where((c) => c.kind.equals(kind))).get();

  Future<String> storeIdOf(SyncDevice d) async => (await d.sync.refreshStatus()).storeId!;

  group('partial returns refund exactly the line total', () {
    Future<(Sale, SaleItem)> saleOf1000(SyncDevice a) async {
      final p = await a.product('Товар', price: 334, qty: 10);
      final sale = (await a.sales.checkout(CheckoutRequest(
        lines: [CheckoutLine(productId: p.id, qty: 3, unitPrice: 334)],
        payments: [PaymentInput('cash', 1000)],
        manualOrderDiscountAmount: 2,
        cashierId: a.userId,
        shiftId: a.shift!.id,
      )))
          .sale;
      expect(sale.total, 1000);
      final item = await (a.db.select(a.db.saleItems)..where((i) => i.saleId.equals(sale.id))).getSingle();
      return (sale, item);
    }

    test('three single-unit returns on one register', () async {
      final ds = await devices(1);
      final a = ds[0];
      final (sale, item) = await saleOf1000(a);
      for (var i = 0; i < 3; i++) {
        await a.sales.returnItems(
            saleId: sale.id, lines: [ReturnLineInput(item.id, 1)], refundMethod: 'cash', userId: a.userId, shiftId: a.shift!.id);
      }
      final s = await (a.db.select(a.db.sales)..where((x) => x.id.equals(sale.id))).getSingle();
      expect((s.refundedTotal, s.status), (1000, 'returned'));
      final amounts = (await a.db.select(a.db.returnItems).get()).map((r) => r.amount).toList()..sort();
      expect(amounts, [333, 333, 334]);
    });

    test('single-unit returns on three registers (the last on the register that sold)', () async {
      final ds = await devices(3);
      final a = ds[0], b = ds[1], c = ds[2];
      final (sale, item) = await saleOf1000(a);
      await syncAll(ds);
      for (final d in [b, c, a]) {
        await d.sales.returnItems(
            saleId: sale.id, lines: [ReturnLineInput(item.id, 1)], refundMethod: 'cash', userId: d.userId, shiftId: d.shift!.id);
        await syncAll(ds);
      }
      for (final d in ds) {
        final s = await (d.db.select(d.db.sales)..where((x) => x.id.equals(sale.id))).getSingle();
        expect((s.refundedTotal, s.status), (1000, 'returned'), reason: d.name);
      }
      await expectConverged(ds);
    });

    test('1 + 2 still refunds the whole line', () async {
      final ds = await devices(1);
      final a = ds[0];
      final (sale, item) = await saleOf1000(a);
      for (final q in [1.0, 2.0]) {
        await a.sales.returnItems(
            saleId: sale.id, lines: [ReturnLineInput(item.id, q)], refundMethod: 'cash', userId: a.userId, shiftId: a.shift!.id);
      }
      final s = await (a.db.select(a.db.sales)..where((x) => x.id.equals(sale.id))).getSingle();
      expect(s.refundedTotal, 1000);
    });
  });

  test('shift history is newest first across registers (numbers are per register)', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    for (var i = 0; i < 5; i++) {
      await a.shifts.close(shiftId: a.shift!.id, userId: a.userId, countedCash: 10000);
      await a.openShift();
    }
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await b.shifts.close(shiftId: b.shift!.id, userId: b.userId, countedCash: 10000);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await b.openShift();
    await syncAll(ds);
    final rows = await watchShiftHistory(b.db, limit: 3).first;
    expect(rows.first.shift.id, b.shift!.id, reason: rows.map((r) => '${r.shift.deviceCode}-${r.shift.number}').join(', '));
    expect(rows.first.shift.deviceCode, 'B');
  });

  group('purchase order lines', () {
    Future<(SyncDevice, SyncDevice, PurchasingRepo, PurchasingRepo, String, String, String)> crossed(int n) async {
      final ds = await devices(n);
      final a = ds[0], b = ds[1];
      final s = await a.supplier('Поставщик');
      final p1 = await a.product('P1', qty: 0), p2 = await a.product('P2', qty: 0);
      final ra = PurchasingRepo(a.db, a.stock), rb = PurchasingRepo(b.db, b.stock);
      // 1. A: draft [P1]; everybody has it
      final oid = await ra.saveDraftOrder(supplierId: s.id, lines: [PoLineInput(productId: p1.id, qty: 5, unitCost: 100)]);
      await syncAll(ds);
      // 2. B sends the order offline (lines r1)
      await rb.markOrdered(oid);
      // 3. A edits the draft (r2) and pushes it
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await ra.saveDraftOrder(id: oid, supplierId: s.id, lines: [PoLineInput(productId: p2.id, qty: 7, unitCost: 100)]);
      await a.syncNow();
      // 4. A sends it before hearing of B's send
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await ra.markOrdered(oid);
      return (a, b, ra, rb, oid, p1.id, p2.id);
    }

    Future<List<PurchaseOrderItem>> lines(SyncDevice d, String oid) =>
        (d.db.select(d.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid) & i.deletedAt.isNull())).get();

    test('a draft edit crossing two offline «send order» keeps the winning lines on every register', () async {
      final (a, b, _, rb, oid, _, p2) = await crossed(2);
      // 5. B hears of A's draft (loses to B's «ordered»), then 6. A's newer «ordered» (r2) wins
      await b.syncNow();
      await a.syncNow();
      await syncAll([a, b]);
      for (final d in [a, b]) {
        final o = await (d.db.select(d.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
        expect(o.status, 'ordered', reason: d.name);
        final ls = await lines(d, oid);
        expect(ls.map((l) => (l.productId, l.qty, l.linesRev)), [(p2, 7.0, o.linesRev)], reason: d.name);
      }
      // B can receive it
      final line = (await lines(b, oid)).single;
      await rb.receiveOrder(oid, [ReceiveLineInput(itemId: line.id, qty: 7)]);
      await syncAll([a, b]);
      await expectConverged([a, b]);
    });

    test('lines hidden by a losing revision get the same deleted_at on every register', () async {
      final (a, b, _, _, oid, _, _) = await crossed(3);
      final c = open.last;
      // the registers apply the trim at different moments
      await b.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await c.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await a.syncNow();
      await syncAll([a, b, c]);
      final hidden = await b.db.customSelect(
          'SELECT COUNT(*) AS n FROM purchase_order_items WHERE order_id = ? AND deleted_at IS NOT NULL',
          variables: [Variable.withString(oid)]).getSingle();
      expect(hidden.read<int>('n'), greaterThan(0), reason: 'the losing r1 line is kept hidden');
      await expectConverged([a, b, c]);
    });
  });

  group('inventory counts', () {
    test('a count completed on A stays completed after a later draft edit on B; completing again is refused', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('Товар', qty: 10);
      final ia = InventoryRepo(a.db, a.stock), ib = InventoryRepo(b.db, b.stock);
      final cid = await ia.createCount(scope: CountScope.selected, productIds: [p.id]);
      await syncAll(ds);
      final item = await (a.db.select(a.db.inventoryCountItems)..where((i) => i.countId.equals(cid))).getSingle();
      await ia.saveCounted(cid, {item.id: 7});
      await a.stock.completeCount(cid, userId: a.userId);
      await a.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await ib.saveCounted(cid, {item.id: 6});
      await b.syncNow();
      await syncAll(ds);
      for (final d in ds) {
        final c = await (d.db.select(d.db.inventoryCounts)..where((t) => t.id.equals(cid))).getSingle();
        expect(c.status, 'completed', reason: d.name);
        expect((await d.productById(p.id)).stockQty, 7, reason: d.name);
        await expectLater(d.stock.completeCount(cid, userId: d.userId), throwsA(_err(L.current.errCountClosed)),
            reason: d.name);
      }
      await expectConverged(ds);
    });

    test('a count cancelled on B while completed on A ends completed (its stock correction exists)', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('Товар', qty: 10);
      final ia = InventoryRepo(a.db, a.stock), ib = InventoryRepo(b.db, b.stock);
      final cid = await ia.createCount(scope: CountScope.selected, productIds: [p.id]);
      final item = await (a.db.select(a.db.inventoryCountItems)..where((i) => i.countId.equals(cid))).getSingle();
      await ia.saveCounted(cid, {item.id: 4});
      await syncAll(ds);
      await a.stock.completeCount(cid, userId: a.userId);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await ib.cancelCount(cid);
      await syncAll(ds);
      for (final d in ds) {
        final c = await (d.db.select(d.db.inventoryCounts)..where((t) => t.id.equals(cid))).getSingle();
        expect((c.status, c.completedAt != null), ('completed', true), reason: d.name);
        expect((await d.productById(p.id)).stockQty, 4, reason: d.name);
      }
      await expectConverged(ds);
    });
  });

  test('a completion superseded by a newer cancel elsewhere is still pushed (sticky value)', () async {
    final ds = await devices(3);
    final a = ds[0], b = ds[1];
    final p = await a.product('Товар', qty: 10);
    final ia = InventoryRepo(a.db, a.stock);
    final cid = await ia.createCount(scope: CountScope.selected, productIds: [p.id]);
    final item = await (a.db.select(a.db.inventoryCountItems)..where((i) => i.countId.equals(cid))).getSingle();
    await ia.saveCounted(cid, {item.id: 6});
    await syncAll(ds);
    await a.stock.completeCount(cid, userId: a.userId);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await InventoryRepo(b.db, b.stock).cancelCount(cid);
    await b.syncNow();
    await syncAll(ds);
    for (final d in ds) {
      final c = await (d.db.select(d.db.inventoryCounts)..where((t) => t.id.equals(cid))).getSingle();
      expect(c.status, 'completed', reason: d.name);
      expect((await d.productById(p.id)).stockQty, 6, reason: d.name);
    }
    await expectConverged(ds);
  });

  group('effect rows pulled before their document', () {
    test('a reversal pushed in small batches never leaves another register able to reverse again', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final sup = await a.supplier('Поставщик');
      final p = await a.product('Товар', qty: 10);
      final r = await a.receipts.post(
          lines: [ReceiptLineInput(productId: p.id, qty: 3, unitCost: 500)], supplierId: sup.id, userId: a.userId);
      await syncAll(ds);
      expect((await b.productById(p.id)).stockQty, 13);
      await a.receipts.reverse(r.id, reason: 'ошибка', userId: a.userId);
      // A pushes one entity per call; the network drops on the 3rd call.
      final flaky = _FailNthPush(server.client(), failAt: 3);
      final small = SyncService(a.db, transportFactory: (_) => flaky, pushBatchSize: 1);
      addTearDown(small.dispose);
      await small.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
      await expectLater(small.syncNow(), throwsA(isA<SyncException>()));
      await b.syncNow();
      final doc = await (b.db.select(b.db.goodsReceipts)..where((t) => t.id.equals(r.id))).getSingle();
      final reversals =
          await (b.db.select(b.db.stockMovements)..where((m) => m.type.equals('receipt_reversal'))).get();
      if (reversals.isNotEmpty) expect(doc.status, ReceiptStatus.reversed, reason: 'the header goes first');
      await expectLater(b.receipts.reverse(r.id, reason: 'ошибка', userId: b.userId), throwsA(isA<BusinessException>()));
      await small.syncNow();
      await syncAll(ds);
      for (final d in ds) {
        expect((await d.productById(p.id)).stockQty, 10, reason: d.name);
      }
      await expectConverged(ds);
    });

    test('an effect row already here refuses the document with a message, not a database error', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final sup = await a.supplier('Поставщик');
      final p = await a.product('Товар', qty: 10);
      final r = await a.receipts.post(
          lines: [ReceiptLineInput(productId: p.id, qty: 3, unitCost: 500)], supplierId: sup.id, userId: a.userId);
      final cid = await InventoryRepo(a.db, a.stock).createCount(scope: CountScope.selected, productIds: [p.id]);
      await a.db.customStatement('UPDATE inventory_count_items SET counted_qty = 5 WHERE count_id = ?', [cid]);
      await a.ledger.post(supplierId: sup.id, kind: 'receipt', amount: 5000);
      final pid = await a.ledger.pay(supplierId: sup.id, amount: 3000, method: 'card', userId: a.userId);
      await syncAll(ds);
      final ri = await (b.db.select(b.db.goodsReceiptItems)..where((i) => i.receiptId.equals(r.id))).getSingle();
      final ci = await (b.db.select(b.db.inventoryCountItems)..where((i) => i.countId.equals(cid))).getSingle();
      // the effect rows of A's (not yet arrived) reversal / completion / cancel
      await b.db.withSyncSuppressed(() async {
        for (final (id, type) in [
          (effectId('receipt_reversal', ri.id), 'receipt_reversal'),
          (effectId('inventory_count', ci.id), 'inventory'),
        ]) {
          await b.db.into(b.db.stockMovements).insert(
              StockMovementsCompanion.insert(id: id, productId: p.id, type: type, qty: -1, qtyAfter: 0));
        }
        await b.db.into(b.db.supplierLedger).insert(SupplierLedgerCompanion.insert(
            id: effectId('payment_cancel', pid), supplierId: sup.id, kind: 'payment_cancel', amount: 0, balanceAfter: 0));
      });
      final done = _err(L.current.errEffectDoneElsewhere);
      await expectLater(b.receipts.reverse(r.id, reason: 'ошибка', userId: b.userId), throwsA(done));
      await expectLater(b.stock.completeCount(cid, userId: b.userId), throwsA(done));
      await expectLater(b.ledger.cancelPayment(pid, reason: 'ошибка', userId: b.userId), throwsA(done));
      final doc = await (b.db.select(b.db.goodsReceipts)..where((t) => t.id.equals(r.id))).getSingle();
      expect(doc.status, ReceiptStatus.posted, reason: 'rolled back');
    });
  });

  group('unique keys judged differently by two registers', () {
    test('barcode: every register ends with the same values', () async {
      final ds = await devices(4);
      final a = ds[0], b = ds[1];
      // 1. B: Y with 777, pushed
      final y = await b.product('Y', barcode: '777');
      await b.syncNow();
      // 2. A (not pulled): X with 777, newer → Y loses on A; X pushed
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final x = await a.product('X', barcode: '777');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await a.syncNow();
      // 3. B edits Y (newer than X): X loses on B; B's push is lost
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await (b.db.update(b.db.products)..where((t) => t.id.equals(y.id)))
          .write(ProductsCompanion(name: const Value('Y2'), updatedAt: Value(DateTime.now())));
      server.failNextPush = FakeFailure.beforeAccept;
      await expectLater(b.syncNow(), throwsA(isA<SyncException>()));
      // 4. the owner fixes the reported conflict on B
      await (b.db.update(b.db.products)..where((t) => t.id.equals(y.id)))
          .write(ProductsCompanion(barcode: const Value('888'), updatedAt: Value(DateTime.now())));
      await syncAll(ds);
      await syncAll(ds);
      final values = {for (final d in ds) d.name: ((await d.productById(x.id)).barcode, (await d.productById(y.id)).barcode)};
      expect(values.values.toSet(), hasLength(1), reason: '$values');
      expect(values['A']!.$2, '888');
      await expectConverged(ds);
    });

    test('customer card: the cleared value reaches every register', () async {
      final ds = await devices(3);
      final a = ds[0], b = ds[1];
      final y = await b.customer('Y', card: 'C-1');
      await b.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await a.customer('X', card: 'C-1');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await a.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await (b.db.update(b.db.customers)..where((t) => t.id.equals(y.id)))
          .write(CustomersCompanion(name: const Value('Y2'), updatedAt: Value(DateTime.now())));
      server.failNextPush = FakeFailure.beforeAccept;
      await expectLater(b.syncNow(), throwsA(isA<SyncException>()));
      await (b.db.update(b.db.customers)..where((t) => t.id.equals(y.id)))
          .write(CustomersCompanion(cardNumber: const Value('C-2'), updatedAt: Value(DateTime.now())));
      await syncAll(ds);
      await syncAll(ds);
      await expectConverged(ds);
    });
  });

  test('a warranty replacement done on two registers offline writes the unit off once', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('Товар', qty: 10);
    final sale = (await a.sell(p.id, 1)).sale;
    final item = await (a.db.select(a.db.saleItems)..where((i) => i.saleId.equals(sale.id))).getSingle();
    final claim = await WarrantyRepository(a.db).createClaim(saleItemId: item.id, problem: 'не включается', userId: a.userId);
    await syncAll(ds);
    expect((await b.productById(p.id)).stockQty, 9);
    for (final d in ds) {
      await WarrantyRepository(d.db)
          .changeStatus(claimId: claim.id, to: WStatus.replaced, note: 'замена', userId: d.userId, writeOff: true, stock: d.stock);
    }
    await syncAll(ds);
    for (final d in ds) {
      expect((await d.productById(p.id)).stockQty, 8, reason: d.name);
      expect(await (d.db.select(d.db.stockMovements)..where((m) => m.type.equals('writeoff'))).get(), hasLength(1),
          reason: d.name);
    }
    await expectConverged(ds);
  });

  group('restored backup', () {
    test('a return made before the first sync after a restore never shares a number', () async {
      final ds = await devices(1);
      final a = ds[0];
      final dir = Directory.systemTemp.createTempSync('dp_dupnum');
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // the OS may still hold the file for a moment
        }
      });
      AppDatabase fileDb(String p) => AppDatabase(NativeDatabase(File(p), setup: registerSqlFunctions));
      final b = SyncDevice('B', fileDb('${dir.path}/b.sqlite'), server);
      open.add(b);
      await b.signIn();
      await b.sync.joinStore(await storeIdOf(a));
      await b.openShift();
      await syncAll([a, b]);
      final p = await b.product('Товар', qty: 10);
      final sale = (await b.sell(p.id, 3)).sale;
      final item = await (b.db.select(b.db.saleItems)..where((i) => i.saleId.equals(sale.id))).getSingle();
      await b.syncNow();
      final backup = '${dir.path.replaceAll(r'\', '/')}/backup.sqlite';
      await b.db.customStatement("VACUUM INTO '$backup'");
      await b.sales.returnItems(
          saleId: sale.id, lines: [ReturnLineInput(item.id, 1)], refundMethod: 'cash', userId: b.userId, shiftId: b.shift!.id);
      await b.syncNow();
      await b.close();
      open.remove(b);

      final b2 = SyncDevice('B', fileDb(backup), server);
      open.add(b2);
      await b2.signIn();
      b2.userId = (await (b2.db.select(b2.db.users)..limit(1)).getSingle()).id;
      b2.shift = await b2.shifts.currentShift();
      await b2.sales.returnItems(
          saleId: sale.id, lines: [ReturnLineInput(item.id, 1)], refundMethod: 'cash', userId: b2.userId, shiftId: b2.shift!.id);
      await syncAll([a, b2]);
      await syncAll([a, b2]);
      for (final d in [a, b2]) {
        for (final t in AppDatabase.numberedDocumentTables.values) {
          final dup = await d.db
              .customSelect("SELECT ifnull(device_code, '') AS c, number, COUNT(*) AS n FROM $t "
                  'GROUP BY 1, 2 HAVING COUNT(*) > 1')
              .get();
          expect(dup.map((r) => r.data), isEmpty, reason: '${d.name} $t');
        }
      }
      // the restored register renamed its own newer return and pushed that
      expect(await conflicts(b2, SyncConflictKind.uniqueNumber), isNotEmpty);
      final codes = [for (final r in await a.db.select(a.db.returns).get()) r.deviceCode];
      expect(codes.where((c) => c != null && c.startsWith('B~')), hasLength(1), reason: '$codes');
      // the restored register's open shift is still its current shift
      expect((await b2.shifts.currentShift())?.id, b2.shift!.id);
      await expectConverged([a, b2]);
    });

    test('a backup does not contain the cloud refresh token', () async {
      final ds = await devices(2);
      final b = ds[1];
      final dir = Directory.systemTemp.createTempSync('dp_backup_token');
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // the OS may still hold the file for a moment
        }
      });
      final svc = BackupService(b.db, () async => dir, dbPath: () async => '${dir.path}/live.sqlite');
      final info = await svc.create();
      final copy = AppDatabase(NativeDatabase(info.file, setup: registerSqlFunctions));
      addTearDown(copy.close);
      final keys = [for (final r in await copy.customSelect('SELECT key FROM sync_state').get()) r.read<String>('key')];
      expect(keys, isNot(contains(SyncKeys.refreshToken)));
      expect(keys, isNot(contains(SyncKeys.pushInflight)));
      expect(keys, containsAll([SyncKeys.deviceId, SyncKeys.storeId, SyncKeys.pullCursor]));
      final token = (await b.db.customSelect("SELECT value FROM sync_state WHERE key = 'refresh_token'").getSingle())
          .read<String>('value');
      expect(String.fromCharCodes(await info.file.readAsBytes()).contains(token), isFalse, reason: 'not left in free pages');
      // the live database keeps syncing
      await b.syncNow();
    });
  });

  group('malformed remote changes never block the sync', () {
    SyncChange raw(String entity, Map<String, Object?>? payload, {int? version, SyncOp op = SyncOp.upsert, String? id}) =>
        SyncChange(
          changeId: newId(),
          entity: entity,
          entityId: id ?? newId(),
          op: op,
          version: version ?? DateTime.now().millisecondsSinceEpoch,
          deviceId: newId(),
          payload: payload,
        );

    test('a change missing a required column or with an object value is skipped and reported', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final sid = await storeIdOf(a);
      server.injectRaw(sid, raw('products', {'price': 5}));
      server.injectRaw(sid, raw('categories', {
        'name': {'x': 1}
      }));
      final mine = await b.product('Свой');
      for (var i = 0; i < 2; i++) {
        final r = await b.syncNow();
        expect(r.rejected, i == 0 ? 2 : 0);
      }
      expect(await b.sync.pendingCount(), 0, reason: 'B pushed its own changes');
      await a.syncNow();
      expect((await a.productById(mine.id)).name, 'Свой');
      final rejected = await conflicts(b, SyncConflictKind.rejected);
      expect(rejected, hasLength(2));
      expect(ConflictText.title(L.current, rejected.first), L.current.syncConflictKindRejected);
      expect(ConflictText.body(L.current, rejected.first), isNotNull);
    });

    test('a wrongly typed value is rejected; typed reads of the table keep working', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('Товар', price: 1000, qty: 0);
      await syncAll(ds);
      server.injectRaw(await storeIdOf(a), raw('products', {'name': 'Evil', 'price': 'abc'}));
      server.injectRaw(await storeIdOf(a), raw('products', {'id': p.id, 'name': 'Товар', 'price': 'abc'}, id: p.id,
          version: DateTime.now().millisecondsSinceEpoch + 1000));
      server.injectRaw(await storeIdOf(a), raw('settings', {'key': 'store_phone', 'value': [1]}, id: 'store_phone'));
      final r = await b.syncNow();
      expect(r.rejected, 3);
      expect(await b.db.select(b.db.products).get(), isNotEmpty);
      expect((await b.productById(p.id)).price, 1000);
    });

    test('a whole double is taken for an integer column', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final id = newId();
      server.injectRaw(await storeIdOf(a), raw('products', {'id': id, 'name': 'Ok', 'price': 1500.0, 'is_active': true}, id: id));
      expect((await b.syncNow()).rejected, 0);
      final p = await b.productById(id);
      expect((p.price, p.isActive), (1500, true));
    });

    test('a version beyond the bound is rejected and never poisons the clock', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final z = await a.product('Z', price: 100, qty: 0);
      await syncAll(ds);
      server.injectRaw(
          await storeIdOf(a), raw('products', {'id': z.id, 'name': 'Z', 'price': 200}, id: z.id, version: 0x7fffffffffffffff));
      await syncAll(ds);
      await (b.db.update(b.db.products)..where((t) => t.id.equals(z.id)))
          .write(ProductsCompanion(price: const Value(300), updatedAt: Value(DateTime.now())));
      await syncAll(ds);
      for (final d in ds) {
        expect((await d.productById(z.id)).price, 300, reason: d.name);
        final hlc = await d.db.customSelect("SELECT value FROM sync_state WHERE key = 'hlc'").getSingle();
        expect(int.parse(hlc.read<String>('value')), lessThanOrEqualTo(maxSyncVersion), reason: d.name);
      }
      await expectConverged(ds);
    });

    test('the server refuses such changes from a client', () async {
      final ds = await devices(1);
      final a = ds[0];
      final t = server.client();
      await t.signIn(email: testEmail, password: testPassword);
      final dev = newId();
      await t.registerDevice(storeId: await storeIdOf(a), deviceId: dev, name: 'x');
      for (final c in [
        raw('products', {'id': 'x', 'v': {'a': 1}}),
        raw('products', {'id': 'x', 'v': [1]}),
        raw('products', {'id': 'x'}, version: -1),
        raw('products', {'id': 'x'}, version: maxSyncVersion + 1),
      ]) {
        final change = SyncChange(
            changeId: c.changeId, entity: c.entity, entityId: c.entityId, op: c.op, version: c.version, deviceId: dev, payload: c.payload);
        await expectLater(t.push(storeId: await storeIdOf(a), deviceId: dev, changes: [change]), throwsA(isA<SyncException>()));
      }
    });
  });
}
