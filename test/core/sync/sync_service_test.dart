// Sync engine (D-025, spec §2, §3, §5, §6, §9, §10) with several in-memory
// databases, the real domain services and FakeSyncServer.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/doc_number.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/receipt_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_sync_server.dart';
import 'sync_harness.dart';

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

  SyncDevice fresh(String name) {
    final d = SyncDevice.create(server, name);
    open.add(d);
    return d;
  }

  Future<void> expectConverged(List<SyncDevice> ds) async {
    final first = await dump(ds.first.db);
    for (final d in ds.skip(1)) {
      final other = await dump(d.db);
      expect(dumpDiff(first, other), isNull, reason: '${ds.first.name} vs ${d.name}');
    }
    for (final d in ds) {
      expect(await SyncAggregates.verifyAll(d.db), isEmpty, reason: d.name);
      expect(await d.sync.pendingCount(), 0, reason: '${d.name} has unpushed changes');
    }
  }

  Future<int> unsyncedOutbox(SyncDevice d) async =>
      (await (d.db.select(d.db.syncOutbox)..where((o) => o.syncedAt.isNull())).get()).length;

  test('create store + join: codes A/B, data appears on B, no echo, status idle', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    expect(await a.db.deviceCode(), 'A');
    expect(await b.db.deviceCode(), 'B');
    expect(a.sync.status.phase, SyncPhase.idle);
    expect(b.sync.status.storeName, 'Магазин');
    expect(b.sync.status.environment, StoreEnvironment.test);
    expect(b.sync.status.deviceCode, 'B');
    expect(await b.db.getSetting('setup_done'), '1');

    final p = await a.product('Чай', qty: 10);
    await a.syncNow();
    expect(await b.db.select(b.db.products).get(), isEmpty);
    final r = await b.syncNow();
    expect(r.applied, greaterThan(0));
    final onB = await b.productById(p.id);
    expect(onB.name, 'Чай');
    expect(onB.stockQty, 10);
    // applying did not write to B's outbox (no echo)
    expect(await unsyncedOutbox(b), 0);
    expect(b.sync.status.pending, 0);
    await expectConverged(ds);
  });

  test('sales on A and B offline: both present, stock = initial − both, numbers A-1 / B-1', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('Хлеб', qty: 20);
    await syncAll(ds);

    final sa = await a.sell(p.id, 3);
    final sb = await b.sell(p.id, 5);
    expect(docNo(sa.sale.number, sa.sale.deviceCode), 'A-1');
    expect(docNo(sb.sale.number, sb.sale.deviceCode), 'B-1');
    await syncAll(ds);

    for (final d in ds) {
      expect((await d.productById(p.id)).stockQty, 12, reason: d.name);
      final sales = await d.db.select(d.db.sales).get();
      expect({for (final s in sales) docNo(s.number, s.deviceCode)}, {'A-1', 'B-1'});
    }
    await expectConverged(ds);
  });

  test('concurrent edits of one row converge by LWW (later version wins on every device)', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('Сахар');
    await syncAll(ds);

    await (a.db.update(a.db.products)..where((t) => t.id.equals(p.id)))
        .write(ProductsCompanion(name: const Value('Сахар A'), price: const Value(1100), updatedAt: Value(DateTime.now())));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await (b.db.update(b.db.products)..where((t) => t.id.equals(p.id)))
        .write(ProductsCompanion(name: const Value('Сахар B'), updatedAt: Value(DateTime.now())));
    // A pushes first, B second: B's version is higher (HLC after pulling A).
    await a.syncNow();
    await b.syncNow();
    await a.syncNow();
    for (final d in ds) {
      final x = await d.productById(p.id);
      expect(x.name, 'Сахар B', reason: d.name);
      expect(x.price, 1000, reason: 'whole-row LWW: B never saw A\'s price (${d.name})');
    }
    await expectConverged(ds);
  });

  test('three devices: sales, returns, void, debt, bonus, receipts, supplier payments converge', () async {
    final ds = await devices(3);
    final a = ds[0], b = ds[1], c = ds[2];
    await a.db.setSetting('loyalty_enabled', '1');
    await a.db.setSetting('loyalty_earn_percent', '5');
    final p = await a.product('Молоко', qty: 50);
    final cust = await a.customer('Иван');
    final sup = await a.supplier('ООО Поставщик');
    await syncAll(ds);

    final s1 = await b.sell(p.id, 4, pays: [PaymentInput('cash', 1000), PaymentInput('debt', 3000)], customerId: cust.id);
    final items = await (b.db.select(b.db.saleItems)..where((i) => i.saleId.equals(s1.sale.id))).get();
    await b.sales.returnItems(
        saleId: s1.sale.id, lines: [ReturnLineInput(items.single.id, 1)], refundMethod: 'debt', userId: b.userId);
    final s2 = await c.sell(p.id, 2, customerId: cust.id);
    await c.sales.voidSale(s2.sale.id, userId: c.userId, reason: 'ошибка', shiftId: c.shift!.id);
    await syncAll(ds); // A sees the debt made on B
    await a.customers.payDebt(customerId: cust.id, amount: 500, method: 'cash', userId: a.userId, shiftId: a.shift!.id);
    await a.receipts.post(
        lines: [ReceiptLineInput(productId: p.id, qty: 10, unitCost: 500)], supplierId: sup.id, userId: a.userId);
    await syncAll(ds); // B and C see the debt to the supplier
    await b.ledger.pay(supplierId: sup.id, amount: 1000, method: 'transfer', userId: b.userId);
    await c.ledger.pay(supplierId: sup.id, amount: 700, method: 'card', userId: c.userId);
    await syncAll(ds);

    for (final d in ds) {
      expect((await d.productById(p.id)).stockQty, 50 - 4 + 1 + 10, reason: d.name);
      expect((await d.customerById(cust.id)).debtBalance, 3000 - 1000 - 500, reason: d.name);
      final s = await d.supplierById(sup.id);
      final sum = await d.db.customSelect('SELECT SUM(amount) AS s FROM supplier_ledger WHERE supplier_id = ?',
          variables: [Variable(sup.id)]).getSingle();
      expect(s.balance, sum.read<int>('s'), reason: '${d.name}: balance == Σ ledger');
      expect(s.balance, 5000 - 1000 - 700, reason: d.name);
    }
    await expectConverged(ds);
  });

  test('gift card spent twice offline: negative balance, conflict row and notification on both', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('Подарок', price: 5000, qty: 10);
    final g = await a.gifts.sell(GiftCardSaleRequest(
        code: 'GIFT0001',
        amount: 5000,
        payments: const [GiftSalePaymentInput('cash', 5000)],
        cashierId: a.userId,
        shiftId: a.shift!.id));
    await syncAll(ds);

    await a.sell(p.id, 1, price: 5000, pays: [PaymentInput('gift_card', 5000, reference: 'GIFT0001')]);
    await b.sell(p.id, 1, price: 5000, pays: [PaymentInput('gift_card', 5000, reference: 'GIFT0001')]);
    await syncAll(ds);

    for (final d in ds) {
      expect((await d.giftById(g.giftCard.id)).balance, -5000, reason: d.name);
      final conflicts = await d.db.select(d.db.syncConflicts).get();
      expect(conflicts.where((c) => c.kind == SyncConflictKind.negativeGiftBalance && c.entityId == g.giftCard.id),
          hasLength(1),
          reason: d.name);
      final notes = await d.db.select(d.db.notifications).get();
      expect(notes.where((n) => n.title.startsWith('Конфликт синхронизации: сертификат GIFT0001')), hasLength(1));
    }
    await expectConverged(ds);
  });

  test('negative stock after two offline sales is surfaced, never blocked', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('Последний', qty: 1);
    await syncAll(ds);
    await a.sell(p.id, 1);
    await b.sell(p.id, 1);
    await syncAll(ds);
    for (final d in ds) {
      expect((await d.productById(p.id)).stockQty, -1);
      expect((await d.db.select(d.db.syncConflicts).get()).map((c) => c.kind), contains(SyncConflictKind.negativeStock));
    }
    await expectConverged(ds);
  });

  test('barcode collision: the lower version loses the barcode, conflict + notification', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final pa = await a.product('Товар A', barcode: '4600000000017');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final pb = await b.product('Товар B', barcode: '4600000000017');
    await a.syncNow(); // A's version is lower
    await b.syncNow();
    await a.syncNow();
    for (final d in ds) {
      expect((await d.productById(pa.id)).barcode, isNull, reason: d.name);
      expect((await d.productById(pb.id)).barcode, '4600000000017', reason: d.name);
      final k = await d.db.select(d.db.syncConflicts).get();
      expect(k.where((c) => c.kind == SyncConflictKind.uniqueBarcode && c.entityId == pa.id), hasLength(1), reason: d.name);
      final n = await d.db.select(d.db.notifications).get();
      expect(n.where((x) => x.title == 'Конфликт синхронизации: штрихкод 4600000000017'), hasLength(1));
    }
    await expectConverged(ds);
  });

  test('customer card collision: lower version loses the card number', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final ca = await a.customer('Анна', card: 'C-100');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final cb = await b.customer('Борис', card: 'C-100');
    await syncAll(ds);
    for (final d in ds) {
      expect((await d.customerById(ca.id)).cardNumber, isNull);
      expect((await d.customerById(cb.id)).cardNumber, 'C-100');
    }
    await expectConverged(ds);
  });

  test('delete propagation: soft delete and hard delete', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('Удаляемый', qty: 0);
    final promoId = newId();
    await a.db.into(a.db.promotions).insert(PromotionsCompanion.insert(id: promoId, name: 'Акция', type: 'percent', value: 10));
    await syncAll(ds);
    expect(await b.db.select(b.db.promotions).get(), hasLength(1));

    await (a.db.update(a.db.products)..where((t) => t.id.equals(p.id)))
        .write(ProductsCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    await (b.db.delete(b.db.promotions)..where((t) => t.id.equals(promoId))).go();
    await syncAll(ds);
    for (final d in ds) {
      expect((await d.productById(p.id)).deletedAt, isNotNull, reason: d.name);
      expect(await d.db.select(d.db.promotions).get(), isEmpty, reason: d.name);
    }
    final ops = server.changesOf(a.sync.status.storeId!).where((c) => c.entityId == promoId).map((c) => c.op);
    expect(ops, contains(SyncOp.delete));
    await expectConverged(ds);
  });

  test('re-push after «accepted, response lost» is idempotent (same change ids and versions)', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('Сыр', qty: 5);
    final before = server.maxSeq;
    server.failNextPush = FakeFailure.afterAccept;
    await expectLater(a.syncNow(), throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.network)));
    expect(a.sync.status.phase, SyncPhase.offline);
    expect(a.sync.status.nextRetryAt, isNotNull);
    final accepted = server.maxSeq - before;
    expect(accepted, greaterThan(0));
    expect(await unsyncedOutbox(a), greaterThan(0), reason: 'not confirmed: still pending');

    await a.syncNow();
    expect(server.maxSeq - before, accepted, reason: 'the retry inserted nothing new');
    expect(a.sync.status.phase, SyncPhase.idle);
    expect(a.sync.status.lastError, isNull);
    await b.syncNow();
    expect((await b.productById(p.id)).stockQty, 5);
    await expectConverged(ds);
  });

  test('failure before accept: retried, nothing lost', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('Масло', qty: 7);
    server.failNextPush = FakeFailure.beforeAccept;
    await expectLater(a.syncNow(), throwsA(isA<SyncException>()));
    await syncAll(ds);
    expect((await b.productById(p.id)).stockQty, 7);
    await expectConverged(ds);
  });

  test('crash mid-batch rolls back the whole batch; cursor unchanged; next sync applies it', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    for (var i = 0; i < 3; i++) {
      await a.product('Товар $i', qty: 3);
    }
    await a.syncNow();
    final cursor = await b.sync.pullCursor();
    final productsBefore = (await b.db.select(b.db.products).get()).length;
    b.sync.debugBeforeApply = (i, c) async {
      if (i == 4) throw StateError('crash');
    };
    await expectLater(b.syncNow(), throwsA(isA<SyncException>()));
    expect(await b.sync.pullCursor(), cursor);
    expect((await b.db.select(b.db.products).get()).length, productsBefore, reason: 'rolled back');
    expect(await b.db.select(b.db.syncFlags).getSingle().then((f) => f.applying), 0);
    expect(b.sync.status.phase, SyncPhase.error);

    b.sync.debugBeforeApply = null;
    await b.syncNow();
    expect((await b.db.select(b.db.products).get()).length, productsBefore + 3);
    await expectConverged(ds);
  });

  test('pull cursor persists across service instances; own changes skipped but advance the cursor', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    await a.product('Рис', qty: 2);
    await syncAll(ds);
    expect(await a.sync.pullCursor(), server.maxSeq, reason: 'own changes advanced A\'s cursor');
    expect(await b.sync.pullCursor(), server.maxSeq);

    await a.product('Гречка', qty: 2);
    await a.syncNow();
    final again = SyncService(b.db, transportFactory: (_) => server.client());
    addTearDown(again.dispose);
    await again.init();
    expect(again.status.phase, SyncPhase.idle);
    final r = await again.syncNow();
    expect(r.pulled, lessThan(10), reason: 'only the new changes were pulled, not the whole history');
    expect(await b.db.select(b.db.products).get(), hasLength(2));
  });

  test('settings sync except device-local keys', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    await a.db.setSetting('store_name', 'Лавка');
    await a.db.setSetting('theme_mode', 'dark'); // local
    await a.db.setSetting('sync_whatever', 'x'); // local by prefix
    await syncAll(ds);
    expect(await b.db.getSetting('store_name'), 'Лавка');
    expect(await b.db.getSetting('theme_mode'), isNull);
    expect(await b.db.getSetting('sync_whatever'), isNull);
    expect(await b.db.getSetting('device_code'), 'B');
    await expectConverged(ds);
  });

  test('first upload contains every pre-existing row and synced setting', () async {
    final a = fresh('A');
    await a.createOwner();
    await a.db.setSetting('store_name', 'До синхронизации');
    await a.db.setSetting('theme_mode', 'dark');
    a.shift = await a.shifts.open(userId: a.userId, openingCash: 0);
    final p = await a.product('Старый товар', qty: 4);
    final s = await a.sell(p.id, 1);
    expect(s.sale.deviceCode, isNull, reason: 'sync off: number stays bare');
    await a.signIn();
    final info = await a.sync.createStoreAndUpload(name: 'Первый', environment: StoreEnvironment.test);
    final entities = server.changesOf(info.id).map((c) => c.entity).toSet();
    expect(entities, containsAll(['users', 'products', 'stock_movements', 'shifts', 'sales', 'sale_items', 'settings']));
    expect(server.changesOf(info.id).where((c) => c.entity == 'settings').map((c) => c.entityId),
        allOf(contains('store_name'), isNot(contains('theme_mode')), isNot(contains('device_code'))));

    final b = fresh('B');
    await b.signIn();
    await b.sync.joinStore(info.id);
    expect(await b.db.getSetting('store_name'), 'До синхронизации');
    final sales = await b.db.select(b.db.sales).get();
    expect(docNo(sales.single.number, sales.single.deviceCode), '1');
    await expectConverged([a, b]);
  });

  test('join refused for a database with business data; reason available before trying', () async {
    final ds = await devices(1);
    final store = ds.first.sync.status.storeId!;
    final b = fresh('B');
    await b.createOwner(); // users alone are not business data
    expect(await b.sync.joinBlockReason(), isNull);
    await b.product('Свой товар', qty: 0);
    expect(await b.sync.joinBlockReason(), contains('две базы не объединяются'));
    await b.signIn();
    await expectLater(
        b.sync.joinStore(store), throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.notEmpty)));
    expect(await b.sync.isConnected(), isFalse);
    expect(await b.db.deviceCode(), isNull);
  });

  test('demo database: refused by a production store, accepted by a test store', () async {
    final prod = server.seedStore('Боевой', StoreEnvironment.production, ownerEmail: testEmail);
    final test = server.seedStore('Тест', StoreEnvironment.test, ownerEmail: testEmail);
    final d = fresh('D');
    await d.db.setSetting('demo_mode', '1');
    await d.signIn();
    await expectLater(d.sync.createStoreAndUpload(name: 'X', environment: StoreEnvironment.production),
        throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.environmentMismatch)));
    await expectLater(d.sync.joinStore(prod.id),
        throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.environmentMismatch)));
    expect(server.store(prod.id).devices, isEmpty);
    expect(SyncException(SyncErrorKind.environmentMismatch).message,
        'Демо-база может подключаться только к тестовому магазину.');
    await d.sync.joinStore(test.id);
    expect(d.sync.status.environment, StoreEnvironment.test);
    expect(d.sync.status.isTestStore, isTrue);
  });

  test('not a member: forbidden', () async {
    server.addUser('other@example.test', 'pw');
    final st = server.seedStore('Чужой', StoreEnvironment.test, ownerEmail: 'other@example.test');
    final d = fresh('D');
    await d.signIn();
    await expectLater(
        d.sync.joinStore(st.id), throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.forbidden)));
  });

  test('wrong password and revoked session map to auth errors; password is never stored', () async {
    final d = fresh('D');
    await expectLater(d.sync.signIn(endpoint: testEndpoint, email: testEmail, password: 'nope'),
        throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.auth)));
    final ds = await devices(1);
    final a = ds.first;
    final state = await a.db.select(a.db.syncState).get();
    expect(state.map((s) => s.value), isNot(contains(testPassword)));
    server.revokeAllSessions();
    // a new service instance must restore the session from the refresh token
    final again = SyncService(a.db, transportFactory: (_) => server.client());
    addTearDown(again.dispose);
    await again.init();
    await expectLater(again.syncNow(), throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.auth)));
    expect(again.status.phase, SyncPhase.error);
    expect(again.status.signedIn, isFalse);
  });

  test('offline: status offline with backoff, recovers', () async {
    final ds = await devices(2);
    final a = ds[0];
    await a.product('Офлайн', qty: 1);
    server.offline = true;
    await expectLater(a.syncNow(), throwsA(isA<SyncException>()));
    expect(a.sync.status.phase, SyncPhase.offline);
    expect(a.sync.status.pending, greaterThan(0));
    expect(a.sync.status.lastError!.kind, SyncErrorKind.network);
    server.offline = false;
    await a.syncNow();
    expect(a.sync.status.phase, SyncPhase.idle);
    expect(a.sync.status.pending, 0);
    expect(a.sync.status.lastSyncAt, isNotNull);
  });

  test('disconnect keeps data and device code, clears tokens and cursor; reconnect to the same store', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final p = await a.product('Остаётся', qty: 3);
    await syncAll(ds);
    final storeId = b.sync.status.storeId!;
    await b.sync.disconnect();
    expect(b.sync.status.phase, SyncPhase.off);
    expect(await b.db.deviceCode(), 'B');
    expect(await b.sync.pullCursor(), 0);
    final keys = {for (final s in await b.db.select(b.db.syncState).get()) s.key};
    expect(keys, isNot(contains(SyncKeys.refreshToken)));
    expect(keys, isNot(contains(SyncKeys.connected)));
    expect((await b.productById(p.id)).stockQty, 3);
    await expectLater(b.syncNow(), throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.notConfigured)));

    // work offline while disconnected, then reconnect (non-empty DB, same store)
    final sb = await b.sell(p.id, 1);
    expect(sb.sale.deviceCode, 'B');
    await b.signIn();
    await b.sync.joinStore(storeId);
    expect(await b.db.deviceCode(), 'B');
    await syncAll(ds);
    expect((await a.productById(p.id)).stockQty, 2);
    await expectConverged(ds);
  });

  test('outbox cleanup removes only synced rows older than 7 days', () async {
    final ds = await devices(1);
    final a = ds.first;
    await a.product('Старьё', qty: 1);
    await a.syncNow();
    final synced = await (a.db.select(a.db.syncOutbox)..where((o) => o.syncedAt.isNotNull())).get();
    expect(synced, isNotEmpty);
    await a.db.customStatement('UPDATE sync_outbox SET synced_at = synced_at - 8 * 86400');
    await a.product('Новое', qty: 0); // unsynced rows stay
    final unsynced = await unsyncedOutbox(a);
    expect(await a.sync.cleanupOutbox(), synced.length);
    expect(await unsyncedOutbox(a), unsynced);
  });

  test('device codes go A, B, C and the server stays consistent', () async {
    final ds = await devices(3);
    expect([for (final d in ds) await d.db.deviceCode()], ['A', 'B', 'C']);
    final store = server.store(ds.first.sync.status.storeId!);
    expect(store.devices.values.map((d) => d.code).toSet(), {'A', 'B', 'C'});
    // re-registering is idempotent per device id
    final t = server.client();
    await t.signIn(email: testEmail, password: testPassword);
    final again = await t.registerDevice(storeId: store.id, deviceId: await ds[1].sync.deviceId(), name: 'x');
    expect(again.code, 'B');
  });

  test('supplier ledger with payments and cancellation on two devices: balance == Σ ledger', () async {
    final ds = await devices(2);
    final a = ds[0], b = ds[1];
    final sup = await a.supplier('Оптовик');
    final p = await a.product('Мука', qty: 0);
    await a.receipts.post(lines: [ReceiptLineInput(productId: p.id, qty: 10, unitCost: 1000)], supplierId: sup.id, userId: a.userId);
    await syncAll(ds);
    final pay = await a.ledger.pay(supplierId: sup.id, amount: 2000, method: 'card', userId: a.userId);
    await b.ledger.pay(supplierId: sup.id, amount: 1500, method: 'transfer', userId: b.userId);
    await syncAll(ds);
    await b.ledger.cancelPayment(pay, reason: 'дубль', userId: b.userId);
    await syncAll(ds);
    for (final d in ds) {
      expect((await d.supplierById(sup.id)).balance, 10000 - 1500, reason: d.name);
    }
    await expectConverged(ds);
  });

  test('small push/pull pages: parents before children across page boundaries (FKs enforced)', () async {
    final a = SyncDevice.create(server, 'A', pushBatchSize: 3, pullBatchSize: 4);
    open.add(a);
    await a.createOwner();
    a.shift = await a.shifts.open(userId: a.userId, openingCash: 0);
    final cust = await a.customer('Мария');
    for (var i = 0; i < 4; i++) {
      final p = await a.product('Товар $i', qty: 5);
      final s = await a.sell(p.id, 2, pays: [PaymentInput('cash', 1000), PaymentInput('debt', 1000)], customerId: cust.id);
      final it = await (a.db.select(a.db.saleItems)..where((x) => x.saleId.equals(s.sale.id))).getSingle();
      await a.sales.returnItems(saleId: s.sale.id, lines: [ReturnLineInput(it.id, 1)], refundMethod: 'cash',
          userId: a.userId, shiftId: a.shift!.id);
    }
    await a.signIn();
    final info = await a.sync.createStoreAndUpload(name: 'Страницы', environment: StoreEnvironment.test);
    expect(server.pushCalls, greaterThan(10));
    final b = SyncDevice.create(server, 'B', pushBatchSize: 3, pullBatchSize: 4);
    open.add(b);
    await b.signIn();
    await b.sync.joinStore(info.id);
    expect(await b.sync.pullCursor(), server.maxSeq);
    expect((await b.customerById(cust.id)).debtBalance, 4 * 1000);
    await expectConverged([a, b]);
  });

  test('join interrupted by a network error is finished by the next sync (setup_done only then)', () async {
    final ds = await devices(1);
    await ds.first.product('Есть', qty: 1);
    await ds.first.syncNow();
    final b = fresh('B');
    await b.signIn();
    server.failNextPull = true;
    await expectLater(b.sync.joinStore(ds.first.sync.status.storeId!), throwsA(isA<SyncException>()));
    expect(await b.sync.isConnected(), isTrue);
    expect(await b.db.getSetting('setup_done'), isNull);
    await b.syncNow();
    expect(await b.db.getSetting('setup_done'), '1');
    expect(await b.db.select(b.db.products).get(), hasLength(1));
  });
}
