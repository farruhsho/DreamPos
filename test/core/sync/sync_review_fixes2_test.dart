// Regression tests for the second sync review (D-025): gift card refunds on a
// void, restored / copied databases (who reidentifies, the open shift, a
// failed registration), gift sale voids on two registers, a draft purchase
// order received while edited elsewhere, the current shift after a new store,
// the gift card cache query plan and `updated_at` after a superseded edit.
// All against the in-memory FakeSyncServer.
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/sql_functions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/marketing/marketing_repo.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_sync_server.dart';
import 'sync_harness.dart';

/// Delegates to [inner]; `registerDevice` fails [failRegisterTimes] times.
class _FlakyRegister implements SyncTransport {
  _FlakyRegister(this.inner, {this.failRegisterTimes = 0});
  final SyncTransport inner;
  int failRegisterTimes;

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
  Future<StoreInfo> createStore({required String name, required StoreEnvironment environment, String? storeId}) =>
      inner.createStore(name: name, environment: environment, storeId: storeId);
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
  Future<PullResult> pull({required String storeId, required int since, int max = 500}) =>
      inner.pull(storeId: storeId, since: since, max: max);
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

  Future<GiftSaleResult> sellGift(SyncDevice d, String code, int amount) => d.gifts.sell(GiftCardSaleRequest(
      code: code,
      amount: amount,
      payments: [GiftSalePaymentInput('cash', amount)],
      cashierId: d.userId,
      shiftId: d.shift!.id));

  /// Register A (in memory) + register B on a file in a temp dir, B with an
  /// open shift; returns (a, b, dir, fileDb).
  Future<(SyncDevice, SyncDevice, Directory, AppDatabase Function(String))> withFileRegister() async {
    final ds = await devices(1);
    final a = ds[0];
    final dir = Directory.systemTemp.createTempSync('dp_reid');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // the OS may still hold the file for a moment; it is a temp dir
      }
    });
    AppDatabase fileDb(String p) => AppDatabase(NativeDatabase(File(p), setup: registerSqlFunctions));
    final b = SyncDevice('B', fileDb('${dir.path}/b.sqlite'), server);
    open.add(b);
    await b.signIn();
    await b.sync.joinStore((await a.sync.refreshStatus()).storeId!);
    await b.openShift();
    await syncAll([a, b]);
    return (a, b, dir, fileDb);
  }

  String backupPath(Directory dir, String name) => '${dir.path.replaceAll(r'\', '/')}/$name';

  /// Opens a copy of [b]'s file as a second register sharing its identity.
  Future<SyncDevice> openCopy(String path, AppDatabase Function(String) fileDb) async {
    final b2 = SyncDevice('B', fileDb(path), server);
    open.add(b2);
    await b2.signIn();
    b2.userId = (await (b2.db.select(b2.db.users)..limit(1)).getSingle()).id;
    b2.shift = await b2.shifts.currentShift();
    return b2;
  }

  group('gift card refund on a void', () {
    test('a sale paid by a card whose gift sale was voided elsewhere: the card stays blocked with 0 everywhere',
        () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('X', price: 2300, qty: 10);
      final g = await sellGift(a, 'GIFT1234', 3000);
      await syncAll(ds);
      final s = await b.sell(p.id, 1, price: 2300, pays: [PaymentInput('gift_card', 2300, reference: 'GIFT1234')]);
      await a.gifts.voidSale(g.saleId, reason: 'ошибка', userId: a.userId, shiftId: a.shift!.id);
      await syncAll(ds);
      await b.sales.voidSale(s.sale.id, userId: b.userId, reason: 'ошибка', shiftId: b.shift!.id);
      await syncAll(ds);
      for (final d in ds) {
        final x = await d.giftById(g.giftCard.id);
        expect((x.status, x.balance), ('blocked', 0), reason: d.name);
      }
      await expectConverged(ds);
    });

    test('voiding a sale paid by a blocked card keeps it blocked (also on the other register)', () async {
      final ds = await devices(2);
      final a = ds[0];
      final p = await a.product('X', price: 1000, qty: 10);
      final g = await sellGift(a, 'GIFT5555', 3000);
      final s = await a.sell(p.id, 1, pays: [PaymentInput('gift_card', 1000, reference: 'GIFT5555')]);
      await MarketingRepo(a.db).setGiftBlocked(await a.giftById(g.giftCard.id), true, userId: a.userId);
      await syncAll(ds);
      await a.sales.voidSale(s.sale.id, userId: a.userId, reason: 'ошибка', shiftId: a.shift!.id);
      await syncAll(ds);
      for (final d in ds) {
        final x = await d.giftById(g.giftCard.id);
        expect((x.status, x.balance), ('blocked', 3000), reason: d.name);
      }
      await expectConverged(ds);
    });
  });

  group('restored backup / copied database', () {
    test('a copy that syncs first moves to a new code; the original keeps its code and gets no conflict', () async {
      final (a, b, dir, fileDb) = await withFileRegister();
      final p = await a.product('X', qty: 100);
      await syncAll([a, b]);
      await b.db.customStatement("VACUUM INTO '${backupPath(dir, 'copy.sqlite')}'");
      final b2 = await openCopy('${dir.path}/copy.sqlite', fileDb);

      await b.sell(p.id, 1);
      final rb = await b.syncNow();
      await b2.sell(p.id, 1);
      final rc = await b2.syncNow();
      final rb2 = await b.syncNow();
      expect(rb.reidentified || rb2.reidentified, isFalse, reason: 'the original register keeps its identity');
      expect(await b.db.deviceCode(), 'B');
      expect(await conflicts(b, SyncConflictKind.identity), isEmpty);
      expect(rc.reidentified, isTrue);
      expect(await b2.db.deviceCode(), isNot('B'));
      await syncAll([a, b, b2]);
      await expectConverged([a, b, b2]);
    });

    test('after a restore the open shift stays the current shift (POS, providers, closing)', () async {
      final (a, b, dir, fileDb) = await withFileRegister();
      final p = await a.product('X', qty: 100);
      await syncAll([a, b]);
      final shiftId = b.shift!.id;
      await b.db.customStatement("VACUUM INTO '${backupPath(dir, 'backup.sqlite')}'");
      await b.sell(p.id, 1);
      await syncAll([a, b]);
      await b.close();
      open.remove(b);

      final b2 = await openCopy('${dir.path}/backup.sqlite', fileDb);
      expect(b2.shift?.id, shiftId);
      final r = await b2.syncNow();
      expect(r.reidentified, isTrue);
      expect(await b2.db.deviceCode(), isNot('B'));
      expect((await b2.shifts.currentShift())?.id, shiftId);
      final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(b2.db)]);
      addTearDown(container.dispose);
      final sub = container.listen(currentShiftProvider, (_, _) {});
      addTearDown(sub.close);
      expect((await container.read(currentShiftProvider.future))?.id, shiftId);
      await expectLater(b2.shifts.open(userId: b2.userId, openingCash: 0), throwsA(anything),
          reason: 'no second shift while the restored one is open');
      // the restored shift can be closed, and the next one has the new code
      await b2.shifts.close(shiftId: shiftId, userId: b2.userId, countedCash: 10000);
      final next = await b2.shifts.open(userId: b2.userId, openingCash: 0);
      expect(next.deviceCode, await b2.db.deviceCode());
      await syncAll([a, b2]);
      await expectConverged([a, b2]);
    });

    test('a reidentification whose registration failed is done on the next sync', () async {
      final (a, b, dir, fileDb) = await withFileRegister();
      final p = await a.product('X', qty: 100);
      await syncAll([a, b]);
      await b.db.customStatement("VACUUM INTO '${backupPath(dir, 'backup.sqlite')}'");
      await b.sell(p.id, 1);
      await syncAll([a, b]);
      await b.close();
      open.remove(b);

      final db2 = fileDb('${dir.path}/backup.sqlite');
      final hook = _FlakyRegister(server.client(), failRegisterTimes: 1);
      final svc = SyncService(db2, transportFactory: (_) => hook);
      addTearDown(() async {
        svc.dispose();
        await db2.close();
      });
      final oldId = await svc.deviceId();
      await expectLater(svc.syncNow(), throwsA(isA<SyncException>()));
      expect(await db2.deviceCode(), 'B');
      final r = await svc.syncNow();
      expect(r.reidentified, isTrue);
      expect(await db2.deviceCode(), isNot('B'));
      expect(await svc.deviceId(), isNot(oldId));
    });
  });

  group('gift card sale voids racing on two registers', () {
    test('the same gift sale voided on both registers raises a double-void conflict on both', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final g = await sellGift(a, 'GIFT7777', 3000);
      await syncAll(ds);
      await a.gifts.voidSale(g.saleId, reason: 'ошибка', userId: a.userId, shiftId: a.shift!.id);
      // B's void strictly later than A's: within the same millisecond B's
      // own void loses on B (device id tie-break) and is never pushed, so
      // only B could know about the second refund.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await b.gifts.voidSale(g.saleId, reason: 'ошибка', userId: b.userId, shiftId: b.shift!.id);
      await syncAll(ds);
      for (final d in ds) {
        expect(await conflicts(d, SyncConflictKind.doubleVoid), hasLength(1), reason: d.name);
        final notes = await d.db.select(d.db.notifications).get();
        expect(notes.where((n) => n.refType == 'sync_conflict' && n.refId == g.saleId), hasLength(1), reason: d.name);
      }
      await expectConverged(ds);
    });

    test('a card spent on one register while its sale is voided on another raises a void-redeem conflict', () async {
      final ds = await devices(2);
      final a = ds[0], b = ds[1];
      final p = await a.product('X', price: 2300, qty: 10);
      final g = await sellGift(a, 'GIFT8888', 3000);
      await syncAll(ds);
      await b.sell(p.id, 1, price: 2300, pays: [PaymentInput('gift_card', 2300, reference: 'GIFT8888')]);
      await a.gifts.voidSale(g.saleId, reason: 'ошибка', userId: a.userId, shiftId: a.shift!.id);
      await syncAll(ds);
      for (final d in ds) {
        expect(await conflicts(d, SyncConflictKind.voidRedeem), hasLength(1), reason: d.name);
        expect((await d.giftById(g.giftCard.id)).balance, 0, reason: d.name);
      }
      await expectConverged(ds);
    });
  });

  test('a draft order received on one register while edited on another stays received with its lines', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final s = await a.supplier('S');
    final p1 = await a.product('P1', qty: 0), p2 = await a.product('P2', qty: 0);
    final ra = PurchasingRepo(a.db, a.stock), rb = PurchasingRepo(b.db, b.stock);
    final oid = await ra.saveDraftOrder(supplierId: s.id, lines: [PoLineInput(productId: p1.id, qty: 5, unitCost: 100)]);
    await syncAll(ds);
    final line = await (b.db.select(b.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid))).getSingle();
    await rb.receiveOrder(oid, [ReceiveLineInput(itemId: line.id, qty: 5)]);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await ra.saveDraftOrder(id: oid, supplierId: s.id, lines: [
      PoLineInput(productId: p1.id, qty: 5, unitCost: 100),
      PoLineInput(productId: p2.id, qty: 2, unitCost: 100),
    ]);
    await b.syncNow();
    await a.syncNow();
    await syncAll(ds);
    for (final d in ds) {
      final o = await (d.db.select(d.db.purchaseOrders)..where((x) => x.id.equals(oid))).getSingle();
      expect(o.status, isNot('draft'), reason: d.name);
      final items = await (d.db.select(d.db.purchaseOrderItems)
            ..where((i) => i.orderId.equals(oid) & i.deletedAt.isNull()))
          .get();
      expect(items.map((i) => (i.productId, i.receivedQty)), [(p1.id, 5.0)], reason: d.name);
      expect((await d.productById(p1.id)).stockQty, 5, reason: d.name);
      expect((await d.supplierById(s.id)).balance, 500, reason: d.name);
    }
    await expectConverged(ds);
  });

  test('after disconnect + new store the current shift is the own one, never another register\'s', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('X', qty: 100);
    for (var i = 0; i < 3; i++) {
      await a.sell(p.id, 1);
    }
    await syncAll(ds);
    await b.sync.disconnect();
    await b.signIn();
    await b.sync.createStoreAndUpload(name: 'Второй', environment: StoreEnvironment.test);
    expect(await b.db.deviceCode(), 'A');
    final cur = await b.shifts.currentShift();
    expect(cur?.id, b.shift!.id);
    expect(cur?.deviceCode, 'A');
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(b.db)]);
    addTearDown(container.dispose);
    final sub = container.listen(currentShiftProvider, (_, _) {});
    addTearDown(sub.close);
    expect((await container.read(currentShiftProvider.future))?.id, b.shift!.id);
    final foreign = await (b.db.select(b.db.shifts)..where((s) => s.id.equals(a.shift!.id))).getSingle();
    expect(foreign.deviceCode, isNot('A'));
    expect((await b.shifts.report(b.shift!.id)).salesTotal, 0);
  });

  test('the gift card cache check looks redemptions up by index, not by scanning every payment', () async {
    final ds = await devices(1);
    final plan = await ds[0].db.customSelect('EXPLAIN QUERY PLAN ${SyncAggregates.giftCardsSql}').get();
    final details = [for (final r in plan) r.read<String>('detail')];
    expect(details.where((d) => RegExp(r'^SCAN p\b').hasMatch(d)), isEmpty, reason: details.join('\n'));
    expect(details.where((d) => d.contains('ix_sale_payments_gift')), hasLength(2), reason: details.join('\n'));
  });

  test('an own edit superseded by a remote one does not leave a different updated_at behind', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('X', qty: 0);
    await syncAll(ds);
    await (b.db.update(b.db.products)..where((t) => t.id.equals(p.id)))
        .write(ProductsCompanion(price: const Value(1500), updatedAt: Value(DateTime.now())));
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await (a.db.update(a.db.products)..where((t) => t.id.equals(p.id)))
        .write(ProductsCompanion(name: const Value('X2'), updatedAt: Value(DateTime.now())));
    // B's clock-ordered version is ahead (it pulled a later change): its
    // older edit wins over A's pending one.
    await setHlc(b.db, DateTime.now().millisecondsSinceEpoch + 60000);
    await b.syncNow();
    await a.syncNow();
    await syncAll(ds);
    for (final d in ds) {
      final x = await d.productById(p.id);
      expect((x.name, x.price), ('X', 1500), reason: d.name);
    }
    await expectConverged(ds);
  });
}
