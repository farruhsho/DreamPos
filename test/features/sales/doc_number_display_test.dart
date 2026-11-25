// Document numbers with register codes (D-025, spec §5): with device_code
// 'A' lists, details, printed receipts and searches show/accept «A-15»;
// a bare «15» still matches every register's №15.
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/printing/receipt.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/doc_number_sql.dart';
import 'package:dreampos/features/inventory/inventory_logic.dart';
import 'package:dreampos/features/sales/sales_logic.dart';
import 'package:dreampos/features/sales/sales_queries.dart';
import 'package:dreampos/features/sales/sales_screen.dart';
import 'package:dreampos/features/warranty/warranty_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

class _LoggedIn extends SessionNotifier {
  _LoggedIn(this.user);
  final User user;
  @override
  Session? build() => Session(user);
}

Future<Sale> _sell(Fixture f, Product p) async => (await SaleService(f.db).checkout(
  CheckoutRequest(
    lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: p.price)],
    payments: [PaymentInput('cash', p.price)],
    cashierId: f.owner.id,
    shiftId: f.shift.id,
  ),
)).sale;

/// Two sales numbered 1: one on register A (this one) and one that came
/// from register B (renumbered in place, as the pull would store it).
Future<({Fixture f, Sale a, Sale b})> _twoRegisters() async {
  final f = await Fixture.create();
  await f.db.setSetting('device_code', 'A');
  final p = await f.product('Наушники', price: 25000, stock: 5);
  final a = await _sell(f, p);
  final b0 = await _sell(f, p);
  await f.db.customUpdate(
    "UPDATE sales SET number = 1, device_code = 'B' WHERE id = ?",
    variables: [Variable.withString(b0.id)],
    updates: {f.db.sales},
  );
  final b = await (f.db.select(f.db.sales)..where((s) => s.id.equals(b0.id))).getSingle();
  return (f: f, a: a, b: b);
}

void main() {
  test('docNo / parseDocNo helpers used by the screens', () {
    expect(docNo(15, null), '15');
    expect(docNo(15, 'A'), 'A-15');
    expect(docNoMatches(15, 'A', 'a-15'), isTrue);
    expect(docNoMatches(15, 'A', '15'), isTrue);
    expect(docNoMatches(15, 'A', 'B-15'), isFalse);
    expect(docNoMatches(15, null, '№15'), isTrue);
    expect(docNoMatches(15, null, 'A-15'), isFalse);
    expect(docNoWhere('s', 'Сыр'), isNull);
    expect(deviceCodeOf({'device_code': ' A '}), 'A');
    expect(deviceCodeOf({'device_code': ''}), isNull);
    expect(deviceCodeOf(null), isNull);
  });

  test('new documents carry the code; receipt text prints «ЧЕК №A-1»', () async {
    final r = await _twoRegisters();
    expect(r.a.deviceCode, 'A');
    expect(r.a.number, 1);
    final text = (await ReceiptData.load(r.f.db, r.a.id)).toText();
    expect(text, contains('ЧЕК №A-1'));
    final copy = (await ReceiptData.load(r.f.db, r.a.id, copy: true)).toText();
    expect(copy, contains('КОПИЯ ЧЕК №A-1'));
    await r.f.db.close();
  });

  test('without a code the receipt text is unchanged', () async {
    final f = await Fixture.create();
    final p = await f.product('Сыр');
    final s = await _sell(f, p);
    expect(s.deviceCode, isNull);
    final text = (await ReceiptData.load(f.db, s.id)).toText();
    expect(text, contains('ЧЕК №${s.number}'));
    expect(text, isNot(contains('-${s.number}')));
    await f.db.close();
  });

  test('sales search: «1» finds both registers, «A-1» / «b1» one', () async {
    final r = await _twoRegisters();
    Future<Set<String>> ids(String q) async =>
        (await watchSales(r.f.db, SalesFilter(period: Period.all, query: q)).first).map((x) => x.sale.id).toSet();
    expect(await ids('1'), {r.a.id, r.b.id});
    expect(await ids('№1'), {r.a.id, r.b.id});
    expect(await ids('A-1'), {r.a.id});
    expect(await ids('b1'), {r.b.id});
    expect(await ids('C-1'), isEmpty);

    expect((await findSaleByDocNo(r.f.db, 'B-1'))?.id, r.b.id);
    expect((await findSaleByDocNo(r.f.db, 'a-1'))?.id, r.a.id);
    expect(await findSaleByDocNo(r.f.db, 'Z-1'), isNull);
    expect(await findSaleByNumber(r.f.db, 1), isNotNull);
    await r.f.db.close();
  });

  test('returns list shows and searches «A-1»', () async {
    final r = await _twoRegisters();
    final items = await (r.f.db.select(r.f.db.saleItems)..where((i) => i.saleId.equals(r.a.id))).get();
    final ret = await SaleService(r.f.db).returnItems(
      saleId: r.a.id,
      lines: [ReturnLineInput(items.single.id, 1)],
      refundMethod: 'cash',
      userId: r.f.owner.id,
      shiftId: r.f.shift.id,
    );
    expect(ret.deviceCode, 'A');
    Future<List<ReturnRow>> rows(String q) =>
        watchReturns(r.f.db, ReturnsFilter(period: Period.all, query: q)).first;
    final all = await rows('');
    expect(all.single.saleNo, 'A-1');
    expect(docNo(all.single.ret.number, all.single.ret.deviceCode), 'A-${ret.number}');
    expect(await rows('A-1'), hasLength(1));
    expect(await rows('B-1'), isEmpty);
    await r.f.db.close();
  });

  test('warranty: receipt lookup and search by «B-1»', () async {
    final r = await _twoRegisters();
    final repo = WarrantyRepository(r.f.db);
    expect((await repo.findSale(1, code: 'B'))!.sale.id, r.b.id);
    expect((await repo.findSale(1, code: 'A'))!.sale.id, r.a.id);
    final item = await (r.f.db.select(r.f.db.saleItems)..where((i) => i.saleId.equals(r.b.id))).getSingle();
    final claim = await repo.createClaim(saleItemId: item.id, problem: 'Не включается', userId: r.f.owner.id);
    expect(claim.deviceCode, 'A');
    final rows = await watchClaims(r.f.db, const ClaimsFilter(query: 'B-1')).first;
    expect(rows.single.saleNo, 'B-1');
    expect(await watchClaims(r.f.db, const ClaimsFilter(query: 'C-1')).first, isEmpty);
    expect(await watchClaims(r.f.db, const ClaimsFilter(query: '1')).first, hasLength(1));
    await r.f.db.close();
  });

  test('goods receipts: search and reference numbers carry the code', () async {
    final f = await Fixture.create();
    await f.db.setSetting('device_code', 'A');
    final p = await f.product('Сыр', stock: 0);
    final id = await InventoryRepo(f.db, StockService(f.db)).postReceipt(
      lines: [ReceiptLine(product: p, qty: 2, unitCost: 500)],
    );
    Future<List<ReceiptListRow>> rows(String q) =>
        watchGoodsReceipts(f.db, (from: null, to: null, supplierId: null, status: null, search: q)).first;
    expect((await rows('A-1')).single.receipt.id, id);
    expect((await rows('1')).single.receipt.id, id);
    expect(await rows('B-1'), isEmpty);
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(f.db)]);
    addTearDown(container.dispose);
    final sub = container.listen(goodsReceiptNumbersProvider, (_, _) {});
    addTearDown(sub.close);
    final numbers = await container.read(goodsReceiptNumbersProvider.future);
    expect(numbers[id], 'A-1');
    await f.db.close();
  });

  testWidgets('sales screen: list «№A-1» and detail «Чек №A-1»', (tester) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    late ({Fixture f, Sale a, Sale b}) r;
    await tester.runAsync(() async => r = await _twoRegisters());
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(r.f.db),
          sessionProvider.overrideWith(() => _LoggedIn(r.f.owner)),
        ],
        child: const MaterialApp(home: SalesScreen()),
      ),
    );
    await _settle(tester);
    expect(find.text('№A-1'), findsOneWidget);
    expect(find.text('№B-1'), findsOneWidget);

    await tester.tap(find.text('№A-1'));
    await _settle(tester);
    expect(find.text('Чек №A-1'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'b-1');
    await _settle(tester, rounds: 10);
    expect(find.text('№B-1'), findsOneWidget);
    expect(find.text('№A-1'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester, rounds: 2);
    await tester.runAsync(r.f.db.close);
  });
}

Future<void> _settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}
