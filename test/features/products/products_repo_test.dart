import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/products/product_logic.dart';
import 'package:dreampos/features/products/products_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late Fixture f;
  late ProductsRepo repo;

  setUp(() async {
    Money.currency = const CurrencyConfig();
    f = await Fixture.create();
    repo = ProductsRepo(f.db);
  });
  tearDown(() => f.db.close());

  Future<List<AuditEntry>> audits(String action) =>
      (f.db.select(f.db.auditLog)..where((a) => a.action.equals(action))).get();

  group('barcode uniqueness', () {
    test('isBarcodeTaken ignores deleted products and self', () async {
      final id = await repo.saveProduct(ProductDraft(name: 'A', price: 100, barcode: '4006381333931'),
          userId: f.owner.id);
      expect(await repo.isBarcodeTaken('4006381333931'), isTrue);
      expect(await repo.isBarcodeTaken('4006381333931', excludeId: id), isFalse);
      expect(await repo.isBarcodeTaken(' '), isFalse);
      await repo.deleteProduct(id, userId: f.owner.id);
      expect(await repo.isBarcodeTaken('4006381333931'), isFalse);
    });

    test('saveProduct rejects a duplicate barcode with a friendly message', () async {
      await repo.saveProduct(ProductDraft(name: 'Молоко', price: 100, barcode: '123'));
      expect(
        () => repo.saveProduct(ProductDraft(name: 'Кефир', price: 100, barcode: '123')),
        throwsA(isA<BusinessException>()
            .having((e) => e.message, 'message', contains('«Молоко»'))),
      );
    });

    test('validation: name required, price >= 0', () async {
      expect(() => repo.saveProduct(ProductDraft(name: '  ', price: 1)), throwsA(isA<BusinessException>()));
      expect(() => repo.saveProduct(ProductDraft(name: 'X', price: -1)), throwsA(isA<BusinessException>()));
    });

    test('nextInternalBarcode is sequential, valid and skips used codes', () async {
      final a = await repo.nextInternalBarcode();
      expect(a, Ean13.internal(1));
      await repo.saveProduct(ProductDraft(name: 'A', price: 1, barcode: a));
      final b = await repo.nextInternalBarcode();
      expect(b, Ean13.internal(2));
      expect(Ean13.isValid(b), isTrue);
    });

    test('suggestSku = max numeric sku + 1', () async {
      expect(await repo.suggestSku(), '00001');
      await repo.saveProduct(ProductDraft(name: 'A', price: 1, sku: '00041'));
      await repo.saveProduct(ProductDraft(name: 'B', price: 1, sku: 'X-99'));
      expect(await repo.suggestSku(), '00042');
    });
  });

  group('save', () {
    test('new product with initial stock goes through StockService.receive', () async {
      final id = await repo.saveProduct(
          ProductDraft(name: 'Сахар', price: 15000, costPrice: 11000, unit: 'kg', initialStock: 12.5),
          userId: f.owner.id);
      final p = await (f.db.select(f.db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(p.stockQty, 12.5);
      expect(p.costPrice, 11000);
      final mv = await f.db.select(f.db.stockMovements).getSingle();
      expect(mv.type, 'receipt');
      expect(mv.reason, 'Начальный остаток');
      expect(mv.qty, 12.5);
      expect(mv.unitCost, 11000);
      expect(await audits('product.create'), hasLength(1));
      final outbox = await f.db.select(f.db.syncOutbox).get();
      expect(outbox.where((o) => o.entityId == id), isNotEmpty);
    });

    test('update writes only changes, audits price change and never touches stock', () async {
      final p0 = await f.product('Хлеб', price: 3000, cost: 2000, stock: 7);
      final d = ProductDraft.fromProduct(p0)
        ..price = 3500
        ..initialStock = 100; // ignored for existing products
      // Concurrent receipt changed stock after the editor was opened.
      await StockService(f.db).receive(productId: p0.id, qty: 3, unitCost: 2000);
      await repo.saveProduct(d, existing: p0, userId: f.owner.id);
      final p = await f.reload(p0);
      expect(p.price, 3500);
      expect(p.stockQty, 10, reason: 'stock is not overwritten by the editor');
      final a = await audits('product.price');
      expect(a.single.details, '${Money.format(3000)} → ${Money.format(3500)}');
      expect(a.single.entityId, p0.id);
    });

    test('stale editor snapshot does not overwrite cost recalculated by a concurrent receipt', () async {
      final p0 = await f.product('Сахар', price: 15000, cost: 10000, stock: 10);
      // Editor opened with p0; meanwhile another register receives goods at 12000.
      await StockService(f.db).receive(productId: p0.id, qty: 10, unitCost: 12000);
      final d = ProductDraft.fromProduct(p0)..name = 'Сахар-песок';
      await repo.saveProduct(d, existing: p0, userId: f.owner.id);
      final p = await f.reload(p0);
      expect(p.name, 'Сахар-песок');
      expect(p.costPrice, 11000, reason: 'weighted average from the receipt is kept');
      expect(p.stockQty, 20);
      expect(await audits('product.cost'), isEmpty);
    });

    test('price change of an existing product without editPrices is rejected', () async {
      final p0 = await f.product('A', price: 1000);
      expect(
          () => repo.saveProduct(ProductDraft.fromProduct(p0)..price = 2000,
              existing: p0, canEditPrices: false),
          throwsA(isA<BusinessException>()));
      // Other fields can still be edited.
      await repo.saveProduct(ProductDraft.fromProduct(p0)..name = 'B', existing: p0, canEditPrices: false);
      expect((await f.reload(p0)).name, 'B');
    });

    test('unit cannot become whole while stock is fractional; fractional initial stock for pcs rejected', () async {
      final id = await repo.saveProduct(ProductDraft(name: 'Рис', price: 1, unit: 'kg', initialStock: 2.5));
      final p0 = await (f.db.select(f.db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(() => repo.saveProduct(ProductDraft.fromProduct(p0)..unit = 'pcs', existing: p0),
          throwsA(isA<BusinessException>()));
      expect(() => repo.saveProduct(ProductDraft(name: 'Хлеб', price: 1, initialStock: 1.5)),
          throwsA(isA<BusinessException>()));
    });

    test('no-op save writes no audit', () async {
      final p0 = await f.product('A');
      await repo.saveProduct(ProductDraft.fromProduct(p0), existing: p0);
      expect(await audits('product.update'), isEmpty);
    });
  });

  group('delete / archive', () {
    test('product with movements can only be archived', () async {
      final p = await f.product('A', stock: 0);
      await StockService(f.db).receive(productId: p.id, qty: 1, unitCost: 1);
      expect(await repo.hasHistory(p.id), isTrue);
      expect(() => repo.deleteProduct(p.id), throwsA(isA<BusinessException>()));
      await repo.setActive({p.id}, false, userId: f.owner.id);
      expect((await f.reload(p)).isActive, isFalse);
      expect(await audits('product.archive'), hasLength(1));
    });

    test('product without history is soft-deleted', () async {
      final p = await f.product('B');
      await repo.deleteProduct(p.id);
      final r = await f.reload(p);
      expect(r.deletedAt, isNotNull);
    });
  });

  group('categories', () {
    test('delete requires moving products; moves them and soft-deletes', () async {
      final a = await repo.saveCategory(name: 'Напитки', color: 1);
      final b = await repo.saveCategory(name: 'Соки', color: 2);
      final p = await f.product('Сок', categoryId: a);
      expect(() => repo.deleteCategory(a), throwsA(isA<BusinessException>()));
      await repo.deleteCategory(a, moveTo: b);
      expect((await f.reload(p)).categoryId, b);
      final cat = await (f.db.select(f.db.categories)..where((c) => c.id.equals(a))).getSingle();
      expect(cat.deletedAt, isNotNull);
      await repo.deleteCategory(b, moveToNone: true);
      expect((await f.reload(p)).categoryId, isNull);
    });

    test('duplicate names rejected (case-insensitive); reorder', () async {
      final a = await repo.saveCategory(name: 'Хлеб', color: 1);
      expect(() => repo.saveCategory(name: 'хлеб', color: 1), throwsA(isA<BusinessException>()));
      final b = await repo.saveCategory(name: 'Молоко', color: 1);
      await repo.reorderCategories([b, a]);
      final list = await repo.watchCategories().first;
      expect(list.map((c) => c.id), [b, a]);
    });
  });

  group('bulk', () {
    test('bulk price change: rounding, audit per product', () async {
      final a = await f.product('A', price: 12345);
      final b = await f.product('B', price: 10000);
      final map = {
        for (final p in [a, b]) p.id: applyPercentChange(p.price, 10, step: 100),
      };
      final n = await repo.applyPrices(map, userId: f.owner.id, note: '+10%');
      expect(n, 2);
      expect((await f.reload(a)).price, 13600); // 13579.5 -> 13580 -> 13600
      expect((await f.reload(b)).price, 11000);
      expect(await audits('product.price'), hasLength(2));
      expect(await audits('product.bulk_price'), hasLength(1));
    });

    test('bulk category and active', () async {
      final c = await repo.saveCategory(name: 'C', color: 1);
      final a = await f.product('A');
      final b = await f.product('B');
      await repo.setCategory({a.id, b.id}, c);
      expect((await f.reload(a)).categoryId, c);
      await repo.setActive({a.id, b.id}, false);
      expect((await f.reload(b)).isActive, isFalse);
    });
  });

  group('queries', () {
    test('search is case-insensitive for Cyrillic, by sku and barcode', () async {
      await repo.saveProduct(ProductDraft(name: 'Молоко 1л', price: 1, sku: 'ML-1', barcode: '4006381333931'));
      await repo.saveProduct(ProductDraft(name: 'Кефир', price: 1));
      Future<List<String>> names(String s) async =>
          (await repo.listProducts(ProductQuery(search: s))).map((p) => p.name).toList();
      expect(await names('молоко'), ['Молоко 1л']);
      expect(await names('МОЛОКО'), ['Молоко 1л']);
      expect(await names('ml-1'), ['Молоко 1л']);
      expect(await names('3339'), ['Молоко 1л']);
      expect(await names('кеф'), ['Кефир']);
    });

    test('stock / active filters and margin sort', () async {
      final ok = await f.product('OK', stock: 10, price: 1000, cost: 900);
      await (f.db.update(f.db.products)..where((t) => t.id.equals(ok.id)))
          .write(const ProductsCompanion(minStock: Value(2)));
      final low = await f.product('Low', stock: 1, price: 1000, cost: 100);
      await (f.db.update(f.db.products)..where((t) => t.id.equals(low.id)))
          .write(const ProductsCompanion(minStock: Value(2)));
      await f.product('Out', stock: 0, price: 1000, cost: 500);
      await f.product('Neg', stock: -2, price: 1000, cost: 1200);
      final arch = await f.product('Arch', stock: 5);
      await repo.setActive({arch.id}, false);

      Future<List<String>> names(ProductQuery q) async =>
          (await repo.listProducts(q)).map((p) => p.name).toList();
      expect(await names(const ProductQuery(stock: StockFilter.low)), ['Low']);
      expect(await names(const ProductQuery(stock: StockFilter.out)), ['Neg', 'Out']);
      expect(await names(const ProductQuery(stock: StockFilter.negative)), ['Neg']);
      expect(await names(const ProductQuery(stock: StockFilter.inStock)), ['Low', 'OK']);
      expect(await names(const ProductQuery(active: ActiveFilter.archived)), ['Arch']);
      expect(await names(const ProductQuery(sort: ProductSort.margin, descending: true)),
          ['Low', 'Out', 'OK', 'Neg']);
      expect(await names(const ProductQuery(limit: 2)), hasLength(2));
      expect(await repo.watchCount(const ProductQuery(limit: 2).unlimited).first, 4);
    });

    test('findByCode: barcode first, then exact SKU; deleted ignored', () async {
      final a = await repo.saveProduct(ProductDraft(name: 'A', price: 1, barcode: '4006381333931', sku: 'X1'));
      await repo.saveProduct(ProductDraft(name: 'B', price: 1, sku: '4006381333931'));
      expect((await repo.findByCode('4006381333931'))!.id, a);
      expect((await repo.findByCode(' X1 '))!.name, 'A');
      expect(await repo.findByCode('X'), isNull);
      await repo.deleteProduct(a);
      expect((await repo.findByCode('4006381333931'))!.name, 'B');
    });

    test('"in stock" includes untracked goods; "negative" only tracked', () async {
      final svc = await f.product('Пакет', stock: -1);
      await (f.db.update(f.db.products)..where((t) => t.id.equals(svc.id)))
          .write(const ProductsCompanion(trackStock: Value(false)));
      await f.product('Есть', stock: 3);
      Future<List<String>> names(ProductQuery q) async =>
          (await repo.listProducts(q)).map((p) => p.name).toList();
      expect(await names(const ProductQuery(stock: StockFilter.inStock)), ['Есть', 'Пакет']);
      expect(await names(const ProductQuery(stock: StockFilter.negative)), isEmpty);
      expect(await names(const ProductQuery(stock: StockFilter.out)), isEmpty);
    });

    test('stats: sold qty & revenue for 30 days, last receipt', () async {
      final p = await f.product('Milk', price: 1500, cost: 1000, stock: 0);
      await StockService(f.db).receive(productId: p.id, qty: 10, unitCost: 1000);
      await SaleService(f.db).checkout(CheckoutRequest(
        lines: [CheckoutLine(productId: p.id, qty: 2, unitPrice: 1500)],
        payments: [PaymentInput('cash', 3000)],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ));
      final s = await repo.watchStats(p.id).first;
      expect(s.soldQty, 2);
      expect(s.revenue, 3000);
      expect(s.receipts, 1);
      expect(s.lastReceiptAt, isNotNull);
      final moves = await repo.watchMovements(p.id).first;
      expect(moves.map((m) => m.type).toSet(), {'receipt', 'sale'});
    });
  });

  group('import / export', () {
    test('plan + apply: creates categories, initial stock, updates by barcode', () async {
      await repo.saveProduct(ProductDraft(name: 'Old', price: 100, barcode: '111', costPrice: 50));
      const text = 'name;barcode;sku;category;price;cost;unit;stock\n'
          'Молоко;222;M1;Молочные;12000;9000;шт;5\n'
          'Новое имя;111;;Молочные;150;;шт;99\n'
          ';333;;;1;;;\n';
      final parsed = parseImport(text, currency: const CurrencyConfig());
      final plan = await repo.planImport(parsed.rows, updateExisting: true);
      expect(plan.map((x) => x.action), [ImportAction.create, ImportAction.update, ImportAction.skip]);
      final res = await repo.applyImport(plan, userId: f.owner.id);
      expect(res.created, 1);
      expect(res.updated, 1);
      expect(res.skipped, 1);
      expect(res.categoriesCreated, 1);
      final all = await repo.listProducts(const ProductQuery(limit: 0));
      final milk = all.firstWhere((p) => p.barcode == '222');
      expect(milk.stockQty, 5);
      expect(milk.costPrice, 9000);
      final old = all.firstWhere((p) => p.barcode == '111');
      expect(old.name, 'Новое имя');
      expect(old.price, 150);
      expect(old.stockQty, 0, reason: 'stock of existing products is not changed by import');
      expect(milk.categoryId, old.categoryId);
    });

    test('without update option an existing barcode is skipped; no price update without right', () async {
      await repo.saveProduct(ProductDraft(name: 'Old', price: 100, barcode: '111'));
      final parsed = parseImport('Old2;111;;;999', currency: const CurrencyConfig());
      final skip = await repo.planImport(parsed.rows, updateExisting: false);
      expect(skip.single.action, ImportAction.skip);
      final upd = await repo.planImport(parsed.rows, updateExisting: true);
      await repo.applyImport(upd, canEditPrices: false);
      final p = (await repo.listProducts(const ProductQuery())).single;
      expect(p.name, 'Old2');
      expect(p.price, 100);
    });

    test('update by barcode keeps the unit when the unit cell is empty', () async {
      await repo.saveProduct(ProductDraft(name: 'Рис', price: 100, barcode: '555', unit: 'kg'));
      final parsed = parseImport('name;barcode;price;unit\nРис девзира;555;120;', currency: const CurrencyConfig());
      expect(parsed.rows.single.unitGiven, isFalse);
      await repo.applyImport(await repo.planImport(parsed.rows, updateExisting: true));
      final p = (await repo.listProducts(const ProductQuery())).single;
      expect(p.unit, 'kg');
      expect(p.name, 'Рис девзира');
      expect(p.price, 120);
    });

    test('export CSV parses back with the importer', () async {
      final c = await repo.saveCategory(name: 'Бакалея; сухие', color: 1);
      await repo.saveProduct(ProductDraft(
          name: 'Рис "Девзира"', price: 25000, costPrice: 20000, barcode: '4006381333931', categoryId: c,
          unit: 'kg', initialStock: 3.5));
      final csv = await repo.exportCsv(const ProductQuery());
      final back = parseImport(csv, currency: const CurrencyConfig());
      expect(back.hasHeader, isTrue);
      final r = back.rows.single;
      expect(r.isValid, isTrue, reason: r.errors.join());
      expect(r.name, 'Рис "Девзира"');
      expect(r.category, 'Бакалея; сухие');
      expect(r.price, 25000);
      expect(r.cost, 20000);
      expect(r.unit, 'kg');
      expect(r.stock, 3.5);
      final noCost = await repo.exportCsv(const ProductQuery(), includeCost: false);
      expect(noCost.split('\r\n').first, isNot(contains('cost')));
    });
  });
}
