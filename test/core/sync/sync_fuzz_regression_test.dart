// Seeded fuzz regression (fourth sync review, D-025): 4 registers, random
// operations through the real domain services — sales, partial returns,
// voids, barcodes and customer cards from small pools (collisions), draft
// purchase orders edited / sent / received / cancelled on several registers,
// inventory counts, goods receipts and their reversal, warranty replacements
// with a write-off — with random sync points and injected network faults
// (push lost before / after the server stored it, pull lost). One register
// pushes in batches of 2. The seeds are the ones on which the review's fuzz
// harness found divergences and crashes.
//
// Invariants at the end: identical synced data on every register, caches
// derivable (`verifyAll`), nothing pending, no duplicate document number, no
// rejected change, and no failure other than a BusinessException (a refused
// operation) or a SyncException (an injected fault) along the way.
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/inventory/inventory_logic.dart';
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:dreampos/features/warranty/warranty_logic.dart';
import 'package:dreampos/features/warranty/warranty_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_sync_server.dart';
import 'sync_harness.dart';

const _ops = 500;
const _faultRate = 0.2;

Future<void> _run(int seed) async {
  final server = FakeSyncServer()..addUser(testEmail, testPassword);
  final ds = await cluster(3, server: server);
  // a fourth register that pushes in batches of 2 (documents split from
  // their effect rows across batches)
  final d4 = SyncDevice.create(server, 'D', pushBatchSize: 2);
  ds.add(d4);
  addTearDown(() async {
    for (final d in ds) {
      await d.close();
    }
  });
  await d4.signIn();
  await d4.sync.joinStore((await ds[0].sync.refreshStatus()).storeId!);
  await d4.openShift();
  await ds[0].db.setSetting('allow_negative_stock', '1');
  await syncAll(ds);

  final rnd = Random(seed);
  T pick<T>(List<T> xs) => xs[rnd.nextInt(xs.length)];
  String? code(String prefix) => rnd.nextInt(3) == 0 ? null : '$prefix${rnd.nextInt(4)}';
  // The screens refuse a barcode / card already used on this register (the
  // collisions come from other registers offline).
  Future<String?> freeCode(SyncDevice d, String table, String column, String prefix) async {
    final c = code(prefix);
    if (c == null) return null;
    final used = await d.db
        .customSelect('SELECT 1 FROM $table WHERE $column = ? AND deleted_at IS NULL', variables: [Variable.withString(c)])
        .get();
    if (used.isNotEmpty) throw BusinessException('taken');
    return c;
  }

  final stats = <String, int>{};
  var refused = 0, faults = 0;

  Future<String> op(SyncDevice d) async {
    final db = d.db;
    final inv = InventoryRepo(db, d.stock, d.receipts);
    final pur = PurchasingRepo(db, d.stock, d.receipts, d.ledger);
    final products = await (db.select(db.products)..where((p) => p.deletedAt.isNull())).get();
    final suppliers = await (db.select(db.suppliers)..where((s) => s.deletedAt.isNull())).get();
    switch (rnd.nextInt(21)) {
      case 0:
        await d.product('Товар ${d.name}${rnd.nextInt(100000)}', price: 300 + rnd.nextInt(10) * 100, qty: 5, barcode: await freeCode(d, 'products', 'barcode', '46'));
        return 'product';
      case 1:
        if (products.isEmpty) return 'noop';
        final p = pick(products);
        await (db.update(db.products)..where((t) => t.id.equals(p.id))).write(ProductsCompanion(
            name: Value('${p.name}*'),
            barcode: Value(await freeCode(d, 'products', 'barcode', '46')),
            updatedAt: Value(DateTime.now())));
        return 'editProduct';
      case 2 || 3:
        if (products.isEmpty) return 'noop';
        final p = pick(products);
        final qty = (1 + rnd.nextInt(3)).toDouble();
        final total = (qty * p.price).round();
        final discount = rnd.nextBool() ? rnd.nextInt(3) : 0;
        await d.sales.checkout(CheckoutRequest(
          lines: [CheckoutLine(productId: p.id, qty: qty, unitPrice: p.price)],
          payments: [PaymentInput('cash', total - discount)],
          manualOrderDiscountAmount: discount,
          cashierId: d.userId,
          shiftId: d.shift!.id,
        ));
        return 'sale';
      case 4:
        final items = await db
            .customSelect("SELECT i.id, i.sale_id FROM sale_items i JOIN sales s ON s.id = i.sale_id "
                "WHERE s.status IN ('completed', 'partially_returned') AND i.qty - i.returned_qty >= 1")
            .get();
        if (items.isEmpty) return 'noop';
        final it = pick(items);
        await d.sales.returnItems(
            saleId: it.read<String>('sale_id'),
            lines: [ReturnLineInput(it.read<String>('id'), 1)],
            refundMethod: 'cash',
            userId: d.userId,
            shiftId: d.shift!.id);
        return 'return';
      case 5:
        final sales = await (db.select(db.sales)..where((s) => s.status.equals('completed'))).get();
        if (sales.isEmpty) return 'noop';
        await d.sales.voidSale(pick(sales).id, userId: d.userId, reason: 'ошибка', shiftId: d.shift!.id);
        return 'void';
      case 6:
        await d.customer('Клиент ${d.name}${rnd.nextInt(100000)}', card: await freeCode(d, 'customers', 'card_number', 'C'));
        return 'customer';
      case 7:
        if (suppliers.isEmpty) {
          await d.supplier('Поставщик ${d.name}${rnd.nextInt(1000)}');
          return 'supplier';
        }
        if (products.isEmpty) return 'noop';
        await pur.saveDraftOrder(
            supplierId: pick(suppliers).id,
            lines: [PoLineInput(productId: pick(products).id, qty: 1.0 + rnd.nextInt(5), unitCost: 200)]);
        return 'poDraft';
      case 8:
        final drafts = await (db.select(db.purchaseOrders)..where((o) => o.status.equals('draft'))).get();
        if (drafts.isEmpty || products.isEmpty) return 'noop';
        final o = pick(drafts);
        final ps = {for (var i = 0; i < 1 + rnd.nextInt(2); i++) pick(products).id};
        await pur.saveDraftOrder(
            id: o.id,
            supplierId: o.supplierId,
            lines: [for (final p in ps) PoLineInput(productId: p, qty: 1.0 + rnd.nextInt(5), unitCost: 200)]);
        return 'poEdit';
      case 9:
        final drafts = await (db.select(db.purchaseOrders)..where((o) => o.status.equals('draft'))).get();
        if (drafts.isEmpty) return 'noop';
        await pur.markOrdered(pick(drafts).id);
        return 'poSend';
      case 10:
        final lines = await db
            .customSelect("SELECT i.id, i.order_id, i.qty - i.received_qty AS rest FROM purchase_order_items i "
                "JOIN purchase_orders o ON o.id = i.order_id WHERE o.status = 'ordered' AND i.deleted_at IS NULL "
                'AND i.qty - i.received_qty > 0')
            .get();
        if (lines.isEmpty) return 'noop';
        final l = pick(lines);
        await pur.receiveOrder(l.read<String>('order_id'), [ReceiveLineInput(itemId: l.read<String>('id'), qty: 1)]);
        return 'poReceive';
      case 11:
        final os = await (db.select(db.purchaseOrders)..where((o) => o.status.isIn(['draft', 'ordered']))).get();
        if (os.isEmpty) return 'noop';
        await pur.cancelOrder(pick(os).id, reason: 'отмена');
        return 'poCancel';
      case 12:
        if (products.isEmpty) return 'noop';
        await inv.createCount(scope: CountScope.selected, productIds: [pick(products).id]);
        return 'countCreate';
      case 13:
        final items = await db
            .customSelect('SELECT i.id, i.count_id FROM inventory_count_items i JOIN inventory_counts c '
                "ON c.id = i.count_id WHERE c.status = 'draft'")
            .get();
        if (items.isEmpty) return 'noop';
        final it = pick(items);
        await inv.saveCounted(it.read<String>('count_id'), {it.read<String>('id'): rnd.nextInt(12).toDouble()});
        return 'countSave';
      case 14 || 15:
        final counts = await (db.select(db.inventoryCounts)..where((c) => c.status.equals('draft'))).get();
        if (counts.isEmpty) return 'noop';
        final c = pick(counts);
        if (rnd.nextInt(3) == 0) {
          await inv.cancelCount(c.id);
          return 'countCancel';
        }
        await d.stock.completeCount(c.id, userId: d.userId);
        return 'countComplete';
      case 16:
        if (suppliers.isEmpty || products.isEmpty) return 'noop';
        await d.receipts.post(
            lines: [ReceiptLineInput(productId: pick(products).id, qty: 1.0 + rnd.nextInt(5), unitCost: 200)],
            supplierId: pick(suppliers).id,
            userId: d.userId);
        return 'receipt';
      case 17:
        final rs = await (db.select(db.goodsReceipts)..where((r) => r.status.equals(ReceiptStatus.posted))).get();
        if (rs.isEmpty) return 'noop';
        await d.receipts.reverse(pick(rs).id, reason: 'ошибка', userId: d.userId);
        return 'reverse';
      case 18:
        final items = await db
            .customSelect("SELECT i.id FROM sale_items i JOIN sales s ON s.id = i.sale_id WHERE s.status <> 'voided' "
                'AND NOT EXISTS (SELECT 1 FROM warranty_claims w WHERE w.sale_item_id = i.id)')
            .get();
        if (items.isEmpty) return 'noop';
        await WarrantyRepository(db).createClaim(saleItemId: pick(items).read<String>('id'), problem: 'брак', userId: d.userId);
        return 'claim';
      case 19:
        final claims = await (db.select(db.warrantyClaims)..where((w) => w.status.isIn(WStatus.open))).get();
        if (claims.isEmpty) return 'noop';
        await WarrantyRepository(db).changeStatus(
            claimId: pick(claims).id, to: WStatus.replaced, note: 'замена', userId: d.userId, writeOff: true, stock: d.stock);
        return 'replace';
      default:
        await db.setSetting(pick(['receipt_footer', 'store_phone']), 'v${rnd.nextInt(1000)}');
        return 'setting';
    }
  }

  for (var i = 0; i < _ops; i++) {
    final d = pick(ds);
    try {
      final name = await op(d);
      stats[name] = (stats[name] ?? 0) + 1;
    } on BusinessException {
      refused++;
    } on Object catch (e, st) {
      fail('seed $seed op #$i on ${d.name}: $e\n$st');
    }
    if (rnd.nextInt(4) == 0) {
      final s = pick(ds);
      if (rnd.nextDouble() < _faultRate) {
        faults++;
        switch (rnd.nextInt(3)) {
          case 0:
            server.failNextPush = FakeFailure.beforeAccept;
          case 1:
            server.failNextPush = FakeFailure.afterAccept;
          default:
            server.failNextPull = true;
        }
      }
      try {
        await s.syncNow();
      } on SyncException catch (e) {
        if (!e.isTransient) fail('seed $seed sync #$i on ${s.name}: $e');
      }
      server
        ..failNextPush = null
        ..failNextPull = false;
    }
  }
  for (var round = 0; round < 3; round++) {
    await syncAll(ds);
  }

  final first = await dump(ds[0].db);
  for (final d in ds.skip(1)) {
    expect(dumpDiff(first, await dump(d.db)), isNull, reason: 'A vs ${d.name} (seed $seed, $stats)');
  }
  for (final d in ds) {
    expect(await SyncAggregates.verifyAll(d.db), isEmpty, reason: '${d.name} seed $seed');
    expect(await d.sync.pendingCount(), 0, reason: '${d.name} seed $seed');
    expect(await d.sync.parkedCount(), 0, reason: '${d.name} seed $seed');
    for (final t in AppDatabase.numberedDocumentTables.values) {
      final dup = await d.db
          .customSelect("SELECT ifnull(device_code, '') AS c, number FROM $t GROUP BY 1, 2 HAVING COUNT(*) > 1")
          .get();
      expect(dup.map((r) => r.data), isEmpty, reason: '${d.name} $t seed $seed');
    }
    expect(await (d.db.select(d.db.syncConflicts)..where((c) => c.kind.equals(SyncConflictKind.rejected))).get(),
        isEmpty, reason: '${d.name} seed $seed');
  }
  // the run did real work
  expect(stats.entries.where((e) => e.key != 'noop').fold<int>(0, (s, e) => s + e.value), greaterThan(_ops ~/ 2),
      reason: '$stats refused=$refused');
  expect(faults, greaterThan(0));
}

void main() {
  for (final seed in [1, 4, 5, 11, 20, 40, 50, 64, 67, 73]) {
    test('fuzz regression, seed $seed: 4 registers, $_ops operations, network faults', () => _run(seed),
        timeout: const Timeout(Duration(minutes: 2)));
  }
}
