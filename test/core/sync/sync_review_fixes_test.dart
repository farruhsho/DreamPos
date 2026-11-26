// Regression tests for the reviewed sync defects (D-025): child-before-parent
// pages, restored / copied databases, device codes after a new store, draft
// PO line sets, unique keys with pending edits, bookkeeping writes vs owner
// edits, void vs return, per-register shifts, gift code collisions,
// over-returns, rejoin, test → production, interrupted store creation and
// U+0000 in text. All against the in-memory FakeSyncServer.
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/sql_functions.dart';
import 'package:dreampos/core/doc_number.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/receipt_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/marketing/marketing_repo.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_sync_server.dart';
import 'sync_harness.dart';

/// Delegates to [inner]; runs [beforeFirstPull] once, right before the first
/// pull (a cashier editing between push and pull).
class HookTransport implements SyncTransport {
  HookTransport(this.inner, {this.beforeFirstPull, this.failRegisterTimes = 0});
  final SyncTransport inner;
  Future<void> Function()? beforeFirstPull;
  int failRegisterTimes;
  int createCalls = 0;

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
  Future<StoreInfo> createStore({required String name, required StoreEnvironment environment, String? storeId}) {
    createCalls++;
    return inner.createStore(name: name, environment: environment, storeId: storeId);
  }

  @override
  Future<DeviceRegistration> registerDevice({required String storeId, required String deviceId, required String name}) {
    if (failRegisterTimes > 0) {
      failRegisterTimes--;
      throw SyncException(SyncErrorKind.network, detail: 'injected');
    }
    return inner.registerDevice(storeId: storeId, deviceId: deviceId, name: name);
  }

  @override
  Future<StoreInfo> storeInfo(String storeId) => inner.storeInfo(storeId);
  @override
  Future<PushResult> push({required String storeId, required String deviceId, required List<SyncChange> changes}) =>
      inner.push(storeId: storeId, deviceId: deviceId, changes: changes);
  @override
  Future<PullResult> pull({required String storeId, required int since, int max = 500}) async {
    final hook = beforeFirstPull;
    beforeFirstPull = null;
    if (hook != null) await hook();
    return inner.pull(storeId: storeId, since: since, max: max);
  }
}

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

  Future<void> setHlc(AppDatabase db, int v) =>
      db.into(db.syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: SyncKeys.hlc, value: '$v'));

  Future<List<SyncConflict>> conflicts(SyncDevice d, String kind) =>
      (d.db.select(d.db.syncConflicts)..where((c) => c.kind.equals(kind))).get();

  group('child row pushed before its parent', () {
    test('a product moved to a category created 600 changes later reaches a register pulling in pages', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final pid = newId();
      await a.db.into(a.db.products).insert(ProductsCompanion.insert(id: pid, name: 'P', price: 100));
      for (var i = 0; i < 600; i++) {
        await a.db.into(a.db.customers).insert(CustomersCompanion.insert(id: newId(), name: 'c$i'));
      }
      final cid = newId();
      await a.db.into(a.db.categories).insert(CategoriesCompanion.insert(id: cid, name: 'Cat'));
      await (a.db.update(a.db.products)..where((p) => p.id.equals(pid))).write(ProductsCompanion(categoryId: Value(cid)));
      await a.syncNow();
      // the parent goes to the server before the child
      final order = [for (final c in server.changesOf((await a.sync.refreshStatus()).storeId!)) c.entityId];
      expect(order.indexOf(cid), lessThan(order.indexOf(pid)));
      await b.syncNow();
      expect((await b.productById(pid)).categoryId, cid);
      await expectConverged(ds);
    });

    test('a page with a child whose parent comes in a later page parks it instead of failing forever', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final storeId = (await a.sync.refreshStatus()).storeId!;
      // Rows that exist only on a third register: the server got the child
      // (product) first and its category later (an older client, or any
      // other order).
      final cid = newId(), pid = newId();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final third = server.client();
      await third.signIn(email: testEmail, password: testPassword);
      final v = DateTime.now().millisecondsSinceEpoch;
      Map<String, Object?> row(Map<String, Object?> m) =>
          {'created_at': now, 'updated_at': now, 'deleted_at': null, ...m};
      // A template row with every column (never pushed: A does not sync again).
      final tmpl = await a.product('tmp', qty: 0);
      final product =
          (await a.db.customSelect('SELECT * FROM products WHERE id = ?', variables: [Variable(tmpl.id)]).getSingle()).data;
      await third.push(storeId: storeId, deviceId: 'third-device', changes: [
        SyncChange(
            changeId: newId(),
            entity: 'products',
            entityId: pid,
            op: SyncOp.upsert,
            version: v,
            deviceId: 'third-device',
            payload: {...product, 'id': pid, 'name': 'Child', 'barcode': null, 'category_id': cid, 'stock_qty': 0.0}),
      ]);
      await third.push(storeId: storeId, deviceId: 'third-device', changes: [
        SyncChange(
            changeId: newId(),
            entity: 'categories',
            entityId: cid,
            op: SyncOp.upsert,
            version: v + 1,
            deviceId: 'third-device',
            payload: row({'id': cid, 'name': 'Parent', 'parent_id': null, 'sort_order': 0, 'color': 0xFF4F46E5})),
      ]);
      // B pulls one change per page: page 1 = the orphan child.
      final small = SyncService(b.db, transportFactory: (_) => server.client(), pullBatchSize: 1);
      await small.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
      final r = await small.syncNow();
      small.dispose();
      expect(r.parked, 0, reason: 'the parked child was applied once its parent arrived');
      expect(await small.parkedCount(), 0);
      expect((await b.productById(pid)).categoryId, cid);
      expect(await SyncAggregates.verifyAll(b.db), isEmpty);
    });
  });

  group('restored backup / copied database', () {
    test('a restored register gets its own pushed sales back, gets a new code, and the store keeps syncing', () async {
      final ds = await devices(1);
      final a = ds[0];
      final dir = Directory.systemTemp.createTempSync('dp_restore');
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // the OS may still hold the file for a moment; it is a temp dir
        }
      });
      AppDatabase fileDb(String p) => AppDatabase(NativeDatabase(File(p), setup: registerSqlFunctions));
      final b = SyncDevice('B', fileDb('${dir.path}/b.sqlite'), server);
      await b.signIn();
      await b.sync.joinStore((await a.sync.refreshStatus()).storeId!);
      await b.openShift();
      final p = await a.product('X', qty: 100);
      await syncAll([a, b]);
      await b.db.customStatement("VACUUM INTO '${dir.path.replaceAll(r'\', '/')}/b_backup.sqlite'");
      final lost = await b.sell(p.id, 1);
      await syncAll([a, b]);
      await b.close();

      final b2 = SyncDevice('B', fileDb('${dir.path}/b_backup.sqlite'), server);
      addTearDown(b2.close);
      await b2.signIn();
      b2.userId = (await (b2.db.select(b2.db.users)..limit(1)).getSingle()).id;
      b2.shift = await (b2.db.select(b2.db.shifts)
            ..where((s) => s.closedAt.isNull() & s.registerId.equals('reg-B')))
          .getSingle();
      // a sale before the first sync after the restore reuses B-1
      final again = await b2.sell(p.id, 1);
      expect(docNo(again.sale.number, again.sale.deviceCode), 'B-1');
      final r = await b2.syncNow();
      expect(r.reidentified, isTrue);
      expect(await b2.db.deviceCode(), isNot('B'));
      final own = await (b2.db.select(b2.db.sales)..where((s) => s.id.equals(lost.sale.id))).getSingleOrNull();
      expect(own, isNotNull, reason: 'own sale pushed after the backup came back');
      // the other register is not blocked, the duplicate number is resolved
      await a.syncNow();
      await syncAll([a, b2]);
      for (final d in [a, b2]) {
        final nos = [for (final s in await d.db.select(d.db.sales).get()) docNo(s.number, s.deviceCode)];
        expect(nos.toSet(), hasLength(nos.length), reason: d.name);
        expect(nos, contains('B-1'));
        expect((await d.productById(p.id)).stockQty, 98, reason: d.name);
      }
      expect(await conflicts(b2, SyncConflictKind.identity), hasLength(1));
      // new documents use the new code and never clash
      final next = await b2.sell(p.id, 1);
      expect(next.sale.deviceCode, await b2.db.deviceCode());
      await syncAll([a, b2]);
      await expectConverged([a, b2]);
    });
  });

  group('device codes and document numbers', () {
    test('disconnect + new store on a register holding other registers documents: checkout works', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('X', qty: 100);
      await syncAll(ds);
      for (var i = 0; i < 3; i++) {
        await a.sell(p.id, 1);
      }
      await b.sell(p.id, 1);
      await syncAll(ds);
      await b.sync.disconnect();
      await b.signIn();
      await b.sync.createStoreAndUpload(name: 'Второй', environment: StoreEnvironment.test);
      expect(await b.db.deviceCode(), 'A');
      final s = await b.sell(p.id, 1);
      expect(docNo(s.sale.number, s.sale.deviceCode), 'A-4');

      // A register joining the new store as B continues after the uploaded B-1.
      final c = SyncDevice.create(server, 'C');
      open.add(c);
      await c.signIn();
      await c.sync.joinStore((await b.sync.refreshStatus()).storeId!);
      expect(await c.db.deviceCode(), 'B');
      await c.openShift();
      final cs = await c.sell(p.id, 1);
      expect(docNo(cs.sale.number, cs.sale.deviceCode), 'B-2');
      await syncAll([b, c]);
      await expectConverged([b, c]);
    });

    test('with sync off the numbering is unchanged', () async {
      final d = SyncDevice.create(server, 'Z');
      open.add(d);
      await d.createOwner();
      await d.openShift();
      final p = await d.product('X', qty: 5);
      final s1 = await d.sell(p.id, 1);
      final s2 = await d.sell(p.id, 1);
      expect([s1.sale.number, s2.sale.number], [1, 2]);
      expect(s2.sale.deviceCode, isNull);
    });
  });

  test('two registers editing one draft purchase order keep one line set (the winning save)', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final s = await a.supplier('S');
    final p1 = await a.product('P1', qty: 0), p2 = await a.product('P2', qty: 0), p3 = await a.product('P3', qty: 0);
    final ra = PurchasingRepo(a.db, a.stock), rb = PurchasingRepo(b.db, b.stock);
    final oid = await ra.saveDraftOrder(supplierId: s.id, lines: [PoLineInput(productId: p1.id, qty: 1, unitCost: 100)]);
    await syncAll(ds);
    await ra.saveDraftOrder(id: oid, supplierId: s.id, lines: [PoLineInput(productId: p2.id, qty: 1, unitCost: 100)]);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await rb.saveDraftOrder(
        id: oid,
        supplierId: s.id,
        lines: [PoLineInput(productId: p3.id, qty: 2, unitCost: 100), PoLineInput(productId: p1.id, qty: 1, unitCost: 50)]);
    await syncAll(ds);
    for (final d in ds) {
      final items =
          await (d.db.select(d.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid) & i.deletedAt.isNull())).get();
      final order = await (d.db.select(d.db.purchaseOrders)..where((o) => o.id.equals(oid))).getSingle();
      expect(items.map((i) => i.productId).toSet(), {p3.id, p1.id}, reason: '${d.name}: B saved last');
      expect(order.total, items.fold<int>(0, (t, i) => t + (i.qty * i.unitCost).round()), reason: d.name);
    }
    await expectConverged(ds);
  });

  test('unique barcode: a pending edit superseded in the same pull does not split the registers', () async {
    final ds = await devices(3);
    final x = ds[0], y = ds[1], w = ds[2];
    final now = DateTime.now().millisecondsSinceEpoch;
    final p = await x.product('P', qty: 0, barcode: '123');
    await x.syncNow();
    await y.syncNow();
    final q = await w.product('Q', qty: 0, barcode: '123');
    await setHlc(w.db, now + 20 * 60000);
    await w.syncNow();
    await setHlc(y.db, now + 10 * 60000);
    await (y.db.update(y.db.products)..where((t) => t.id.equals(p.id)))
        .write(ProductsCompanion(price: const Value(2000), updatedAt: Value(DateTime.now())));
    await y.syncNow();
    final xs = SyncService(x.db,
        transportFactory: (_) => HookTransport(server.client(), beforeFirstPull: () async {
              await (x.db.update(x.db.products)..where((t) => t.id.equals(p.id)))
                  .write(ProductsCompanion(name: const Value('P edited'), updatedAt: Value(DateTime.now())));
            }));
    await xs.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
    await xs.syncNow();
    xs.dispose();
    await syncAll(ds);
    await syncAll(ds);
    final owners = <String, String>{};
    for (final d in ds) {
      owners[d.name] = '${(await d.productById(p.id)).barcode}/${(await d.productById(q.id)).barcode}';
    }
    expect(owners.values.toSet(), hasLength(1), reason: '$owners');
    expect(owners.values.first.split('/').where((b) => b == '123'), hasLength(1));
    await expectConverged(ds);
  });

  group('bookkeeping writes never undo owner edits', () {
    test('a sale on a stale register keeps the new price', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('X', qty: 10);
      await syncAll(ds);
      await (a.db.update(a.db.products)..where((t) => t.id.equals(p.id)))
          .write(ProductsCompanion(price: const Value(2000), updatedAt: Value(DateTime.now())));
      await a.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await b.sell(p.id, 1); // B has not pulled the new price
      await syncAll(ds);
      for (final d in ds) {
        final x = await d.productById(p.id);
        expect(x.price, 2000, reason: d.name);
        expect(x.stockQty, 9, reason: d.name);
      }
      await expectConverged(ds);
    });

    test('a debt sale on a stale register keeps the new debt limit and phone', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('X', qty: 10);
      final c = await a.customer('Иван');
      await syncAll(ds);
      await (a.db.update(a.db.customers)..where((t) => t.id.equals(c.id))).write(
          CustomersCompanion(debtLimit: const Value(0), phone: const Value('+998901112233'), updatedAt: Value(DateTime.now())));
      await a.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await b.sell(p.id, 1, pays: [PaymentInput('debt', 1000)], customerId: c.id);
      await syncAll(ds);
      for (final d in ds) {
        final x = await d.customerById(c.id);
        expect(x.debtLimit, 0, reason: d.name);
        expect(x.phone, '+998901112233', reason: d.name);
        expect(x.debtBalance, 1000, reason: d.name);
        expect(x.visits, 1, reason: d.name);
      }
      await expectConverged(ds);
    });

    test('redeeming a gift card on a stale register does not unblock it', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('X', price: 1000, qty: 10);
      final g = await a.gifts.sell(GiftCardSaleRequest(
          code: 'GIFT0007',
          amount: 5000,
          payments: const [GiftSalePaymentInput('cash', 5000)],
          cashierId: a.userId,
          shiftId: a.shift!.id));
      await syncAll(ds);
      await MarketingRepo(a.db).setGiftBlocked(await a.giftById(g.giftCard.id), true, userId: a.userId);
      await a.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await b.sell(p.id, 1, pays: [PaymentInput('gift_card', 1000, reference: 'GIFT0007')]);
      await syncAll(ds);
      for (final d in ds) {
        final x = await d.giftById(g.giftCard.id);
        expect(x.status, 'blocked', reason: d.name);
        expect(x.balance, 4000, reason: d.name);
      }
      await expectConverged(ds);
    });
  });

  test('void on one register racing a return on another: stays voided, conflict surfaced on both', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('X', qty: 12);
    final c = await a.customer('Иван');
    final s = await a.sell(p.id, 2, pays: [PaymentInput('debt', 2000)], customerId: c.id);
    await syncAll(ds);
    await a.sales.voidSale(s.sale.id, userId: a.userId, reason: 'ошибка', shiftId: a.shift!.id);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final items = await (b.db.select(b.db.saleItems)..where((i) => i.saleId.equals(s.sale.id))).get();
    await b.sales.returnItems(
        saleId: s.sale.id, lines: [ReturnLineInput(items.single.id, 1)], refundMethod: 'debt', userId: b.userId);
    await a.syncNow();
    await b.syncNow();
    await syncAll(ds);
    for (final d in ds) {
      final sale = await (d.db.select(d.db.sales)..where((x) => x.id.equals(s.sale.id))).getSingle();
      expect(sale.status, 'voided', reason: d.name);
      expect(await conflicts(d, SyncConflictKind.voidReturn), hasLength(1), reason: d.name);
    }
    await expectConverged(ds);
  });

  test('the same sale line returned on two registers offline raises an over-return conflict', () async {
    final ds = await devices(2);
    final a = ds[0];
    final p = await a.product('X', qty: 10);
    final s = await a.sell(p.id, 1);
    await syncAll(ds);
    for (final d in ds) {
      final items = await (d.db.select(d.db.saleItems)..where((i) => i.saleId.equals(s.sale.id))).get();
      await d.sales.returnItems(
          saleId: s.sale.id, lines: [ReturnLineInput(items.single.id, 1)], refundMethod: 'cash', userId: d.userId,
          shiftId: d.shift!.id);
    }
    await syncAll(ds);
    for (final d in ds) {
      expect(await conflicts(d, SyncConflictKind.overReturn), hasLength(1), reason: d.name);
      final notes = await d.db.select(d.db.notifications).get();
      expect(notes.where((n) => n.refType == 'sync_conflict' && n.refId == s.sale.id), hasLength(1));
    }
    await expectConverged(ds);
  });

  group('current shift is this register\'s', () {
    test('currentShiftProvider and ShiftService stay on the own shift after sync', () async {
      final ds = await devices(3);
      final a = ds[0], b = ds[1], c = ds[2];
      await b.shifts.close(shiftId: b.shift!.id, userId: b.userId, countedCash: 10000);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await b.openShift();
      await syncAll(ds);
      final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(a.db)]);
      addTearDown(container.dispose);
      final sub = container.listen(currentShiftProvider, (_, _) {});
      addTearDown(sub.close);
      final cur = await container.read(currentShiftProvider.future);
      expect(cur?.id, a.shift!.id);
      expect((await a.shifts.currentShift())?.id, a.shift!.id);

      // C closes its shift and opens a new one through the UI path (no register id).
      await c.shifts.close(shiftId: c.shift!.id, userId: c.userId, countedCash: 10000);
      final again = await c.shifts.open(userId: c.userId, openingCash: 0);
      expect(again.deviceCode, 'C');
      expect(docNo(again.number, again.deviceCode), 'C-2');
    });

    test('«already open» names the shift with its register code', () async {
      final ds = await devices(2);
      final b = ds[1];
      await expectLater(
          b.shifts.open(userId: b.userId, openingCash: 0),
          throwsA(predicate((e) => '$e'.contains('B-1'))));
    });
  });

  test('gift code collision: redemptions stay with their own card', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('X', price: 3000, qty: 10);
    await syncAll(ds);
    final gb = await b.gifts.sell(GiftCardSaleRequest(
        code: 'GIFT0001',
        amount: 5000,
        payments: const [GiftSalePaymentInput('cash', 5000)],
        cashierId: b.userId,
        shiftId: b.shift!.id));
    await b.sell(p.id, 1, price: 3000, pays: [PaymentInput('gift_card', 3000, reference: 'GIFT0001')]);
    await b.syncNow();
    final ga = await a.gifts.sell(GiftCardSaleRequest(
        code: 'GIFT0001',
        amount: 5000,
        payments: const [GiftSalePaymentInput('cash', 5000)],
        cashierId: a.userId,
        shiftId: a.shift!.id)); // A has not pulled B's card yet
    await syncAll(ds);
    for (final d in ds) {
      expect((await d.giftById(gb.giftCard.id)).balance, 2000, reason: d.name);
      expect((await d.giftById(ga.giftCard.id)).balance, 5000, reason: d.name);
      expect(await conflicts(d, SyncConflictKind.uniqueGiftCode), hasLength(1));
    }
    await expectConverged(ds);
  });

  group('connect flows', () {
    test('a disconnected register with data may rejoin its own store (and only that one)', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final storeId = (await b.sync.refreshStatus()).storeId!;
      final p = await a.product('X', qty: 10);
      await syncAll(ds);
      await b.sync.disconnect();
      final offline = await b.sell(p.id, 1); // sold while disconnected
      await b.signIn();
      expect(await b.sync.joinBlockReason(), isNotNull);
      expect(await b.sync.joinBlockReason(storeId: storeId), isNull);
      expect((await b.sync.previousStore())?.id, storeId);
      await b.sync.joinStore(storeId);
      expect(await b.db.deviceCode(), 'B');
      await syncAll(ds);
      expect(await (a.db.select(a.db.sales)..where((s) => s.id.equals(offline.sale.id))).getSingleOrNull(), isNotNull);
      await expectConverged(ds);
    });

    test('a database that was on a test store cannot create a production store', () async {
      final ds = await devices(2);
      final b = ds[1];
      await b.sync.disconnect();
      await b.signIn();
      expect(await b.sync.wasOnTestStore(), isTrue);
      await expectLater(
          b.sync.createStoreAndUpload(name: 'Рабочий', environment: StoreEnvironment.production),
          throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.testData)));
      expect(await b.sync.isConnected(), isFalse);
      // a test store is still allowed
      await b.sync.createStoreAndUpload(name: 'Учебный', environment: StoreEnvironment.test);
      expect(await b.sync.isConnected(), isTrue);
    });

    test('an interrupted «Создать магазин» is resumed, not duplicated', () async {
      final db = SyncDevice.create(server, 'A');
      open.add(db);
      await db.createOwner();
      final hook = HookTransport(server.client(), failRegisterTimes: 1);
      final svc = SyncService(db.db, transportFactory: (_) => hook);
      addTearDown(svc.dispose);
      await svc.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
      await expectLater(svc.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test),
          throwsA(isA<SyncException>()));
      expect(await svc.isConnected(), isFalse);
      final info = await svc.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
      expect(hook.createCalls, 1);
      final c = server.client();
      await c.signIn(email: testEmail, password: testPassword);
      expect((await c.listStores()).map((s) => s.id), [info.id]);
      expect(server.store(info.id).devices, hasLength(1));
    });
  });

  test('U+0000 in text is stripped before push on every register (the server refuses it)', () async {
    final ds = await devices(2);
    final a = ds[0];
    final nul = String.fromCharCode(0);
    final p = await a.product('Milk${nul}X', qty: 0, barcode: '12${nul}3');
    await a.db.setSetting('store_phone', '+998${nul}1');
    await syncAll(ds);
    for (final d in ds) {
      final x = await d.productById(p.id);
      expect(x.name, 'MilkX', reason: d.name);
      expect(x.barcode, '123', reason: d.name);
      expect(await d.db.getSetting('store_phone'), '+9981', reason: d.name);
    }
    final raw = server.client();
    await raw.signIn(email: testEmail, password: testPassword);
    await expectLater(
        raw.push(storeId: (await a.sync.refreshStatus()).storeId!, deviceId: 'x', changes: [
          SyncChange(
              changeId: newId(),
              entity: 'settings',
              entityId: 'k',
              op: SyncOp.upsert,
              version: 1,
              deviceId: 'x',
              payload: {'key': 'k', 'value': 'a${nul}b'}),
        ]),
        throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.server)));
    await expectConverged(ds);
  });

  test('stored receipt notes and errors carry the register code', () async {
    final ds = await devices(2);
    final b = ds[1];
    final p = await b.product('X', qty: 0);
    final sup = await b.supplier('S');
    final r = await b.receipts.post(
        lines: [ReceiptLineInput(productId: p.id, qty: 1, unitCost: 100)], supplierId: sup.id, userId: b.userId);
    final note = await (b.db.select(b.db.supplierLedger)..where((l) => l.refId.equals(r.id))).getSingle();
    expect(note.note, 'Приход №B-1');
    await b.receipts.reverse(r.id, reason: 'ошибка', userId: b.userId);
    await expectLater(b.receipts.reverse(r.id, reason: 'ещё раз', userId: b.userId),
        throwsA(predicate((e) => '$e'.contains('B-1'))));
  });
}
