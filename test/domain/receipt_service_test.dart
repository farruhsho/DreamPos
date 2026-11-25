import 'package:drift/drift.dart' show OrderingTerm, RowIdExtension, Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/receipt_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/domain/services/supplier_service.dart';
import 'package:dreampos/features/inventory/inventory_logic.dart' show ReceiptsFilter, allReceipts, goodsReceiptsProvider;
import 'package:dreampos/features/purchasing/purchasing_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late Fixture f;
  late ReceiptService receipts;
  late StockService stock;
  late SupplierLedgerService ledger;

  setUp(() async {
    f = await Fixture.create();
    stock = StockService(f.db);
    ledger = SupplierLedgerService(f.db);
    receipts = ReceiptService(f.db, stock, ledger);
  });
  tearDown(() => f.db.close());

  Future<Supplier> supplier([String name = 'ООО Поставка']) async {
    final id = newId();
    await f.db.into(f.db.suppliers).insert(SuppliersCompanion.insert(id: id, name: name));
    return reloadSupplier(f, id);
  }

  Future<List<SupplierLedgerEntry>> ledgerOf(String supplierId) => (f.db.select(f.db.supplierLedger)
        ..where((l) => l.supplierId.equals(supplierId))
        ..orderBy([(l) => OrderingTerm.asc(l.createdAt), (l) => OrderingTerm.asc(l.rowId)]))
      .get();

  Future<GoodsReceipt> doc(String id) =>
      (f.db.select(f.db.goodsReceipts)..where((r) => r.id.equals(id))).getSingle();

  group('post', () {
    test('numbers documents sequentially', () async {
      final a = await f.product('A');
      final r1 = await receipts.post(lines: [ReceiptLineInput(productId: a.id, qty: 1, unitCost: 100)]);
      final r2 = await receipts.post(lines: [ReceiptLineInput(productId: a.id, qty: 2, unitCost: 100)]);
      expect(r1.number, 1);
      expect(r2.number, 2);
      expect(r2.total, 200);
      expect((await doc(r2.id)).number, 2);
      expect((await doc(r2.id)).status, 'posted');
    });

    test('stock, weighted average cost, items, movements and audit', () async {
      final s = await supplier();
      final a = await f.product('A', price: 1000, cost: 600, stock: 10);
      final b = await f.product('B', price: 500, cost: 0, stock: 0);
      final r = await receipts.post(
        lines: [
          ReceiptLineInput(productId: a.id, qty: 10, unitCost: 800),
          ReceiptLineInput(productId: b.id, qty: 3, unitCost: 250, newPrice: 450),
        ],
        supplierId: s.id,
        supplierInvoice: ' НК-15 ',
        note: 'срочно',
        userId: f.owner.id,
      );
      expect(r.total, 8000 + 750);
      final ra = await f.reload(a);
      expect(ra.stockQty, 20);
      expect(ra.costPrice, 700);
      final rb = await f.reload(b);
      expect(rb.stockQty, 3);
      expect(rb.costPrice, 250);
      expect(rb.price, 450);

      final d = await doc(r.id);
      expect(d.supplierId, s.id);
      expect(d.supplierInvoice, 'НК-15');
      expect(d.note, 'срочно');
      expect(d.userId, f.owner.id);
      expect(d.total, 8750);

      final items = await (f.db.select(f.db.goodsReceiptItems)..where((i) => i.receiptId.equals(r.id))).get();
      expect(items.length, 2);
      final ib = items.firstWhere((i) => i.productId == b.id);
      expect(ib.oldPrice, 500);
      expect(ib.newPrice, 450);
      final ia = items.firstWhere((i) => i.productId == a.id);
      expect(ia.oldPrice, isNull);
      expect(ia.newPrice, isNull);

      final moves = await f.db.select(f.db.stockMovements).get();
      expect(moves.length, 2);
      expect(moves.every((m) => m.type == 'receipt' && m.refType == 'receipt' && m.refId == r.id), isTrue);
      expect(moves.first.reason, startsWith('Приход №1'));

      final audit = (await f.db.select(f.db.auditLog).get()).map((e) => e.action);
      expect(audit, containsAll(['receipt.post', 'product.price']));
      final dirty = (await f.db.select(f.db.syncOutbox).get()).map((e) => e.entity).toSet();
      expect(dirty, containsAll(['goods_receipts', 'goods_receipt_items', 'supplier_ledger', 'suppliers']));
    });

    test('supplier ledger row; balance equals Σ ledger amounts', () async {
      final s = await supplier();
      final a = await f.product('A', stock: 0);
      final r1 = await receipts.post(supplierId: s.id, lines: [ReceiptLineInput(productId: a.id, qty: 5, unitCost: 1000)]);
      await receipts.post(supplierId: s.id, lines: [ReceiptLineInput(productId: a.id, qty: 2, unitCost: 1500)]);
      final rows = await ledgerOf(s.id);
      expect(rows.map((e) => e.kind), ['receipt', 'receipt']);
      expect(rows.map((e) => e.amount), [5000, 3000]);
      expect(rows.map((e) => e.balanceAfter), [5000, 8000]);
      expect(rows.first.refType, 'goods_receipt');
      expect(rows.first.refId, r1.id);
      // D-021 as relaxed by D-025: cache == Σ amounts.
      expect((await reloadSupplier(f, s.id)).balance, rows.fold<int>(0, (a, e) => a + e.amount));

      // No supplier / zero total -> no ledger row.
      await receipts.post(lines: [ReceiptLineInput(productId: a.id, qty: 1, unitCost: 100)]);
      await receipts.post(supplierId: s.id, lines: [ReceiptLineInput(productId: a.id, qty: 1, unitCost: 0)]);
      expect((await ledgerOf(s.id)).length, 2);
    });

    test('canEditPrices=false ignores new retail prices', () async {
      final a = await f.product('A', price: 1000);
      final r = await receipts.post(
          canEditPrices: false, lines: [ReceiptLineInput(productId: a.id, qty: 1, unitCost: 100, newPrice: 2000)]);
      expect((await f.reload(a)).price, 1000);
      final it = (await f.db.select(f.db.goodsReceiptItems).get()).single;
      expect(it.receiptId, r.id);
      expect(it.newPrice, isNull);
    });

    test('validation is all-or-nothing', () async {
      final s = await supplier();
      final a = await f.product('A', stock: 1);
      final kg = await f.product('Сахар', stock: 0);
      await (f.db.update(f.db.products)..where((p) => p.id.equals(kg.id))).write(const ProductsCompanion(unit: Value('kg')));
      Future<void> bad(List<ReceiptLineInput> lines, {String? supplierId, String? orderId}) => expectLater(
          receipts.post(lines: lines, supplierId: supplierId, orderId: orderId), throwsA(isA<BusinessException>()));

      await bad([]);
      await bad([ReceiptLineInput(productId: a.id, qty: 0, unitCost: 1)]);
      await bad([ReceiptLineInput(productId: a.id, qty: 1.5, unitCost: 1)]);
      await bad([ReceiptLineInput(productId: a.id, qty: 2e7, unitCost: 1)]);
      await bad([ReceiptLineInput(productId: a.id, qty: 1, unitCost: -1)]);
      await bad([ReceiptLineInput(productId: a.id, qty: 1, unitCost: 1, newPrice: 0)]);
      await bad([ReceiptLineInput(productId: 'missing', qty: 1, unitCost: 1)]);
      await bad([
        ReceiptLineInput(productId: a.id, qty: 1, unitCost: 1),
        ReceiptLineInput(productId: a.id, qty: 2, unitCost: 1),
      ]);
      await bad([ReceiptLineInput(productId: a.id, qty: 1, unitCost: 1)], supplierId: 'missing');
      // A valid first line is rolled back when a later one fails.
      await bad([
        ReceiptLineInput(productId: kg.id, qty: 1.25, unitCost: 100),
        ReceiptLineInput(productId: 'missing', qty: 1, unitCost: 1),
      ], supplierId: s.id);
      await (f.db.update(f.db.products)..where((p) => p.id.equals(a.id)))
          .write(ProductsCompanion(deletedAt: Value(DateTime.now())));
      await bad([ReceiptLineInput(productId: a.id, qty: 1, unitCost: 1)]);

      expect((await f.reload(a)).stockQty, 1);
      expect((await f.reload(kg)).stockQty, 0);
      expect(await f.db.select(f.db.goodsReceipts).get(), isEmpty);
      expect(await f.db.select(f.db.stockMovements).get(), isEmpty);
      expect(await f.db.select(f.db.supplierLedger).get(), isEmpty);
      // Fractional qty is fine for weighted goods.
      await receipts.post(lines: [ReceiptLineInput(productId: kg.id, qty: 1.25, unitCost: 100)]);
      expect((await f.reload(kg)).stockQty, 1.25);
    });

    test('order must belong to the supplier and be open', () async {
      final s = await supplier();
      final other = await supplier('Другой');
      final a = await f.product('A', stock: 0);
      final repo = PurchasingRepo(f.db, stock, receipts, ledger);
      final oid = await repo.saveDraftOrder(supplierId: other.id, lines: [PoLineInput(productId: a.id, qty: 5, unitCost: 10)]);
      await expectLater(
          receipts.post(supplierId: s.id, orderId: oid, lines: [ReceiptLineInput(productId: a.id, qty: 1, unitCost: 10)]),
          throwsA(isA<BusinessException>()));
      await repo.cancelOrder(oid);
      await expectLater(
          receipts.post(supplierId: other.id, orderId: oid, lines: [ReceiptLineInput(productId: a.id, qty: 1, unitCost: 10)]),
          throwsA(isA<BusinessException>()));
      expect(await f.db.select(f.db.goodsReceipts).get(), isEmpty);
    });
  });

  group('reverse', () {
    test('restores stock, cost, price, supplier balance; marks document', () async {
      final s = await supplier();
      final a = await f.product('A', price: 1000, cost: 600, stock: 10);
      final r = await receipts.post(
        supplierId: s.id,
        userId: f.owner.id,
        lines: [ReceiptLineInput(productId: a.id, qty: 10, unitCost: 800, newPrice: 1200)],
      );
      expect((await f.reload(a)).costPrice, 700);
      expect((await f.reload(a)).price, 1200);
      expect((await reloadSupplier(f, s.id)).balance, 8000);

      await expectLater(receipts.reverse(r.id, reason: '  '), throwsA(isA<BusinessException>()));
      await receipts.reverse(r.id, reason: 'Ошибка ввода', userId: f.owner.id);

      final p = await f.reload(a);
      expect(p.stockQty, 10);
      expect(p.costPrice, 600, reason: '(700·20 − 800·10) / 10');
      expect(p.price, 1000);
      expect((await reloadSupplier(f, s.id)).balance, 0);

      final d = await doc(r.id);
      expect(d.status, 'reversed');
      expect(d.reversedAt, isNotNull);
      expect(d.reversedBy, f.owner.id);
      expect(d.reverseReason, 'Ошибка ввода');

      final rev = (await (f.db.select(f.db.stockMovements)..where((m) => m.type.equals('receipt_reversal'))).get()).single;
      expect(rev.qty, -10);
      expect(rev.refType, 'receipt');
      expect(rev.refId, r.id);
      expect(rev.unitCost, 800);

      final rows = await ledgerOf(s.id);
      expect(rows.map((e) => e.kind), ['receipt', 'receipt_reversal']);
      expect(rows.last.amount, -8000);
      expect(rows.last.balanceAfter, 0);
      expect((await reloadSupplier(f, s.id)).balance, rows.fold<int>(0, (a, e) => a + e.amount));
      final audit = (await f.db.select(f.db.auditLog).get()).map((e) => e.action);
      expect(audit, contains('receipt.reverse'));
    });

    test('keeps a retail price changed after the receipt; cost kept when stock would be empty', () async {
      final a = await f.product('A', price: 1000, cost: 600, stock: 0);
      final r = await receipts.post(lines: [ReceiptLineInput(productId: a.id, qty: 5, unitCost: 800, newPrice: 1500)]);
      await (f.db.update(f.db.products)..where((p) => p.id.equals(a.id))).write(const ProductsCompanion(price: Value(1700)));
      await receipts.reverse(r.id, reason: 'Возврат поставщику');
      final p = await f.reload(a);
      expect(p.price, 1700);
      expect(p.stockQty, 0);
      expect(p.costPrice, 800, reason: 'S − qty = 0 → cost unchanged');
    });

    test('blocked when the goods were already sold; allowed with negative stock', () async {
      final s = await supplier();
      final a = await f.product('A', price: 1000, cost: 500, stock: 0);
      final r = await receipts.post(supplierId: s.id, lines: [ReceiptLineInput(productId: a.id, qty: 5, unitCost: 500)]);
      await SaleService(f.db).checkout(CheckoutRequest(
        lines: [CheckoutLine(productId: a.id, qty: 3, unitPrice: 1000)],
        payments: [PaymentInput('cash', 3000)],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ));
      await expectLater(receipts.reverse(r.id, reason: 'брак'),
          throwsA(isA<BusinessException>().having((e) => e.message, 'message', startsWith('Недостаточно товара'))));
      expect((await f.reload(a)).stockQty, 2);
      expect((await doc(r.id)).status, 'posted');
      expect((await reloadSupplier(f, s.id)).balance, 2500);
      expect(await (f.db.select(f.db.stockMovements)..where((m) => m.type.equals('receipt_reversal'))).get(), isEmpty);

      await f.db.setSetting('allow_negative_stock', '1');
      await receipts.reverse(r.id, reason: 'брак');
      expect((await f.reload(a)).stockQty, -3);
      expect((await f.reload(a)).costPrice, 500);
      expect((await reloadSupplier(f, s.id)).balance, 0);
    });

    test('refused for a deleted supplier: no hidden balance on it', () async {
      final s = await supplier();
      final a = await f.product('A', cost: 100, stock: 0);
      final r = await receipts.post(supplierId: s.id, lines: [ReceiptLineInput(productId: a.id, qty: 10, unitCost: 100)]);
      await ledger.pay(supplierId: s.id, amount: 1000, method: 'transfer');
      expect((await reloadSupplier(f, s.id)).balance, 0);
      await (f.db.update(f.db.suppliers)..where((t) => t.id.equals(s.id)))
          .write(SuppliersCompanion(deletedAt: Value(DateTime.now())));

      await expectLater(
          receipts.reverse(r.id, reason: 'ошибка'),
          throwsA(isA<BusinessException>()
              .having((e) => e.message, 'message', contains('удалён'))));
      expect((await reloadSupplier(f, s.id)).balance, 0);
      expect((await ledgerOf(s.id)).map((e) => e.kind), ['receipt', 'payment']);
      expect((await doc(r.id)).status, 'posted');
      expect((await f.reload(a)).stockQty, 10);
    });

    test('second reversal is refused', () async {
      final a = await f.product('A', stock: 0);
      final r = await receipts.post(lines: [ReceiptLineInput(productId: a.id, qty: 1, unitCost: 10)]);
      await receipts.reverse(r.id, reason: 'x');
      await expectLater(receipts.reverse(r.id, reason: 'x'),
          throwsA(isA<BusinessException>().having((e) => e.message, 'message', 'Приход №1 уже сторнирован')));
      expect((await f.reload(a)).stockQty, 0);
      await expectLater(receipts.reverse('missing', reason: 'x'), throwsA(isA<BusinessException>()));
    });

    test('PO receipt: receivedQty and status roll back; received value excludes reversed', () async {
      final s = await supplier();
      final a = await f.product('Сок', cost: 0, stock: 0);
      final b = await f.product('Вода', cost: 0, stock: 0);
      final repo = PurchasingRepo(f.db, stock, receipts, ledger);
      final oid = await repo.saveDraftOrder(supplierId: s.id, lines: [
        PoLineInput(productId: a.id, qty: 10, unitCost: 500),
        PoLineInput(productId: b.id, qty: 5, unitCost: 200),
      ]);
      await repo.markOrdered(oid);
      final items = await (f.db.select(f.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid))).get();
      final ia = items.firstWhere((i) => i.productId == a.id);
      final ib = items.firstWhere((i) => i.productId == b.id);

      final first = await repo.receiveOrderDoc(oid, [ReceiveLineInput(itemId: ia.id, qty: 10)], supplierInvoice: 'A-1');
      expect(first.receipt.number, 1);
      expect((await doc(first.receipt.id)).orderId, oid);
      expect((await doc(first.receipt.id)).supplierInvoice, 'A-1');
      final second = await repo.receiveOrderDoc(oid, [ReceiveLineInput(itemId: ib.id, qty: 5)]);
      expect(second.result.fullyReceived, isTrue);
      var o = await (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
      expect(o.status, 'received');
      expect(await repo.receivedValue(oid), 6000);
      expect((await reloadSupplier(f, s.id)).balance, 6000);

      await receipts.reverse(first.receipt.id, reason: 'пересорт');
      o = await (f.db.select(f.db.purchaseOrders)..where((t) => t.id.equals(oid))).getSingle();
      expect(o.status, 'ordered');
      expect(o.receivedAt, isNull);
      final again = {
        for (final i in await (f.db.select(f.db.purchaseOrderItems)..where((i) => i.orderId.equals(oid))).get())
          i.productId: i.receivedQty,
      };
      expect(again[a.id], 0);
      expect(again[b.id], 5);
      expect(await repo.receivedValue(oid), 1000);
      expect((await reloadSupplier(f, s.id)).balance, 1000);
      expect((await f.reload(a)).stockQty, 0);

      // The order can be received again after the reversal.
      await repo.receiveOrder(oid, [ReceiveLineInput(itemId: ia.id, qty: 10, unitCost: 450)]);
      expect(await repo.receivedValue(oid), 5500);
    });
  });

  group('readers', () {
    test('list provider filters; price history ignores reversed receipts', () async {
      final s = await supplier();
      final a = await f.product('A', stock: 0);
      final r1 = await receipts.post(
          supplierId: s.id, supplierInvoice: 'INV-77', lines: [ReceiptLineInput(productId: a.id, qty: 1, unitCost: 100)]);
      final r2 = await receipts.post(lines: [ReceiptLineInput(productId: a.id, qty: 2, unitCost: 300)]);
      await receipts.reverse(r2.id, reason: 'ошибка');

      final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(f.db)]);
      addTearDown(c.dispose);
      Future<List<String>> ids(ReceiptsFilter q) async {
        final sub = c.listen(goodsReceiptsProvider(q), (_, _) {});
        addTearDown(sub.close);
        return (await c.read(goodsReceiptsProvider(q).future)).map((r) => r.receipt.id).toList();
      }

      expect(await ids(allReceipts), [r2.id, r1.id]);
      final all = await c.read(goodsReceiptsProvider(allReceipts).future);
      expect(all.last.lineCount, 1);
      expect(all.last.orderNumber, isNull);
      expect(await ids((from: null, to: null, supplierId: s.id, status: null, search: null)), [r1.id]);
      expect(await ids((from: null, to: null, supplierId: null, status: 'reversed', search: null)), [r2.id]);
      expect(await ids((from: null, to: null, supplierId: null, status: null, search: '№2')), [r2.id]);
      expect(await ids((from: null, to: null, supplierId: null, status: null, search: 'inv-7')), [r1.id]);
      expect(
          await ids((from: DateTime.now().add(const Duration(days: 1)), to: null, supplierId: null, status: null, search: null)),
          isEmpty);

      final sub = c.listen(purReceiptMovementsProvider(30), (_, _) {});
      addTearDown(sub.close);
      final moves = await c.read(purReceiptMovementsProvider(30).future);
      expect(moves.map((m) => m.refId), [r1.id]);
      expect(buildPriceHistory(moves)[a.id]!.single.unitCost, 100);
    });
  });
}

Future<Supplier> reloadSupplier(Fixture f, String id) =>
    (f.db.select(f.db.suppliers)..where((s) => s.id.equals(id))).getSingle();
