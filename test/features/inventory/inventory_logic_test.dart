import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/inventory/inventory_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late Fixture f;
  late InventoryRepo repo;
  late StockService stock;

  setUp(() async {
    f = await Fixture.create();
    stock = StockService(f.db);
    repo = InventoryRepo(f.db, stock);
  });
  tearDown(() => f.db.close());

  Future<Supplier> supplier() async {
    final id = newId();
    await f.db.into(f.db.suppliers).insert(SuppliersCompanion.insert(id: id, name: 'Поставщик', balance: const Value(1000)));
    return (f.db.select(f.db.suppliers)..where((s) => s.id.equals(id))).getSingle();
  }

  group('stock overview', () {
    test('valuation counts only positive stock; filters', () async {
      final a = await f.product('A', price: 1000, cost: 600, stock: 10);
      final b = await f.product('B', price: 500, cost: 300, stock: -2);
      final c = await f.product('C', stock: 0);
      await (f.db.update(f.db.products)..where((p) => p.id.equals(a.id))).write(const ProductsCompanion(minStock: Value(10)));
      final all = await f.db.select(f.db.products).get();
      final v = StockValuation.of(all);
      expect(v.positions, 3);
      expect(v.costValue, 6000);
      expect(v.retailValue, 10000);
      expect(v.lowCount, 1);
      expect(v.outCount, 1);
      expect(v.negativeCount, 1);
      expect(all.where((p) => matchesStockFilter(p, StockFilter.negative)).single.id, b.id);
      expect(all.where((p) => matchesStockFilter(p, StockFilter.out)).single.id, c.id);
    });

    test('qty validation respects units', () {
      expect(validateQty(1.5, 'pcs'), isNotNull);
      expect(validateQty(1.5, 'kg'), isNull);
      expect(validateQty(0, 'pcs'), isNotNull);
      expect(validateQty(0, 'pcs', allowZero: true), isNull);
      expect(validateQty(null, 'pcs'), isNotNull);
    });
  });

  group('receipt document', () {
    test('posts lines, recalculates cost, raises supplier debt and price', () async {
      final s = await supplier();
      final a = await f.product('A', price: 1000, cost: 600, stock: 10);
      final b = await f.product('B', price: 500, cost: 0, stock: 0);
      final doc = await repo.postReceipt(
        lines: [
          ReceiptLine(product: a, qty: 10, unitCost: 800),
          ReceiptLine(product: b, qty: 3, unitCost: 250, newPrice: 450),
        ],
        supplierId: s.id,
        userId: f.owner.id,
        note: 'Накладная 15',
      );
      final ra = await f.reload(a);
      expect(ra.stockQty, 20);
      expect(ra.costPrice, 700); // weighted average
      final rb = await f.reload(b);
      expect(rb.stockQty, 3);
      expect(rb.price, 450);
      final rs = await (f.db.select(f.db.suppliers)..where((t) => t.id.equals(s.id))).getSingle();
      expect(rs.balance, 1000 + 8000 + 750);
      final moves = await (f.db.select(f.db.stockMovements)..where((m) => m.refId.equals(doc))).get();
      expect(moves.length, 2);
      expect(moves.every((m) => m.type == 'receipt' && m.refType == 'manual'), isTrue);
      expect(moves.first.reason, contains('Поставщик'));
      final audit = await f.db.select(f.db.auditLog).get();
      expect(audit.map((e) => e.action), containsAll(['stock.receipt', 'product.price']));
    });

    test('is all-or-nothing on invalid lines', () async {
      final a = await f.product('A', stock: 1);
      await expectLater(
          repo.postReceipt(lines: [ReceiptLine(product: a, qty: 1.5, unitCost: 10)]), throwsA(isA<BusinessException>()));
      await expectLater(repo.postReceipt(lines: []), throwsA(isA<BusinessException>()));
      expect((await f.reload(a)).stockQty, 1);
    });

    test('failure inside the transaction rolls back stock and supplier debt', () async {
      final s = await supplier();
      final a = await f.product('A', cost: 100, stock: 1);
      // A product row that does not exist in the DB makes StockService fail
      // on the second line, after the first one was already posted.
      final ghost = a.copyWith(id: 'missing', name: 'Призрак');
      await expectLater(
          repo.postReceipt(supplierId: s.id, lines: [
            ReceiptLine(product: a, qty: 5, unitCost: 100),
            ReceiptLine(product: ghost, qty: 1, unitCost: 100),
          ]),
          throwsA(anything));
      expect((await f.reload(a)).stockQty, 1);
      final sup = await (f.db.select(f.db.suppliers)..where((t) => t.id.equals(s.id))).getSingle();
      expect(sup.balance, 1000);
      expect(await f.db.select(f.db.stockMovements).get(), isEmpty);
    });

    test('without supplier no balance changes; a deleted supplier is refused', () async {
      final s = await supplier();
      final a = await f.product('A', cost: 100, stock: 0);
      await repo.postReceipt(lines: [ReceiptLine(product: a, qty: 2, unitCost: 150)]);
      expect((await f.reload(a)).stockQty, 2);
      expect((await f.reload(a)).costPrice, 150);
      expect((await (f.db.select(f.db.suppliers)..where((t) => t.id.equals(s.id))).getSingle()).balance, 1000);

      await (f.db.update(f.db.suppliers)..where((t) => t.id.equals(s.id)))
          .write(SuppliersCompanion(deletedAt: Value(DateTime.now())));
      await expectLater(
          repo.postReceipt(supplierId: s.id, lines: [ReceiptLine(product: a, qty: 1, unitCost: 150)]),
          throwsA(isA<BusinessException>()));
      expect((await f.reload(a)).stockQty, 2);
    });
  });

  group('write-off', () {
    test('goes through StockService: movement, audit, cannot exceed stock', () async {
      final a = await f.product('A', cost: 250, stock: 3);
      await stock.writeOff(productId: a.id, qty: 2, reason: 'Брак', userId: f.owner.id);
      expect((await f.reload(a)).stockQty, 1);
      final m = (await f.db.select(f.db.stockMovements).get()).single;
      expect(m.type, 'writeoff');
      expect(m.qty, -2);
      expect(lineValue(-m.qty, m.unitCost), 500);
      expect(movementLabel(m.type), 'Списание');
      await expectLater(stock.writeOff(productId: a.id, qty: 5, reason: 'Порча'), throwsA(isA<BusinessException>()));
      expect((await f.reload(a)).stockQty, 1);
    });
  });

  group('stocktake', () {
    test('completion posts differences against CURRENT stock', () async {
      final a = await f.product('Apple', cost: 100, stock: 10);
      final b = await f.product('Banana', cost: 50, stock: 5);
      final c = await f.product('Cherry', cost: 10, stock: 7);
      final id = await repo.createCount(scope: CountScope.all, userId: f.owner.id);
      final count = await (f.db.select(f.db.inventoryCounts)..where((t) => t.id.equals(id))).getSingle();
      expect(count.number, 1);
      expect(count.status, 'draft');

      var lines = await repo.loadLines(id);
      expect(lines.length, 3);
      expect(lines.first.item.expectedQty, 10);
      String item(Product p) => lines.firstWhere((l) => l.item.productId == p.id).item.id;

      await repo.saveCounted(id, {item(a): 8, item(b): 7});
      // A sale of 2 apples happens during the count.
      await SaleService(f.db).checkout(CheckoutRequest(
        lines: [CheckoutLine(productId: a.id, qty: 2, unitPrice: 1000)],
        payments: [PaymentInput('cash', 2000)],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ));

      lines = await repo.loadLines(id);
      final la = lines.firstWhere((l) => l.item.productId == a.id);
      expect(la.stockChanged, isTrue);
      expect(la.currentQty, 8);
      expect(la.diff, 0); // counted 8 vs current 8 (not vs snapshot 10)
      final s = CountSummary.of(lines);
      expect(s.counted, 2);
      expect(s.uncounted, 1);
      expect(s.surplusLines, 1);
      expect(s.surplusValue, 100); // banana +2 * 50
      expect(s.shortageLines, 0);
      expect(s.changedSinceStart, 1);

      await repo.completeCount(id, userId: f.owner.id, pending: {item(c): 6});
      expect((await f.reload(a)).stockQty, 8);
      expect((await f.reload(b)).stockQty, 7);
      expect((await f.reload(c)).stockQty, 6);
      final moves = await (f.db.select(f.db.stockMovements)..where((m) => m.refId.equals(id))).get();
      expect(moves.map((m) => m.productId).toSet(), {b.id, c.id}); // no movement for zero diff
      expect(moves.every((m) => m.type == 'inventory'), isTrue);
      final done = await (f.db.select(f.db.inventoryCounts)..where((t) => t.id.equals(id))).getSingle();
      expect(done.status, 'completed');

      await expectLater(repo.saveCounted(id, {item(a): 1}), throwsA(isA<BusinessException>()));      await expectLater(repo.completeCount(id), throwsA(isA<BusinessException>()));
      await expectLater(repo.cancelCount(id), throwsA(isA<BusinessException>()));
    });

    test('by category, selected, add item while scanning, cancel', () async {
      final catId = newId();
      await f.db.into(f.db.categories).insert(CategoriesCompanion.insert(id: catId, name: 'Фрукты'));
      final a = await f.product('Apple', categoryId: catId);
      final b = await f.product('Bread');
      final byCat = await repo.createCount(scope: CountScope.category, categoryId: catId);
      expect((await repo.loadLines(byCat)).map((l) => l.item.productId), [a.id]);
      await repo.addCountItem(byCat, b, counted: 1);
      expect((await repo.loadLines(byCat)).length, 2);

      final sel = await repo.createCount(scope: CountScope.selected, productIds: [b.id]);
      expect((await repo.loadLines(sel)).single.item.productId, b.id);
      final numbers = (await f.db.select(f.db.inventoryCounts).get()).map((c) => c.number).toSet();
      expect(numbers, {1, 2});

      await repo.cancelCount(sel, userId: f.owner.id);
      await expectLater(repo.completeCount(sel), throwsA(isA<BusinessException>()));
      expect((await f.reload(b)).stockQty, 10);
    });

    test('complete with nothing counted is refused', () async {
      await f.product('A');
      final id = await repo.createCount(scope: CountScope.all);
      await expectLater(repo.completeCount(id), throwsA(isA<BusinessException>()));
    });
  });
}
