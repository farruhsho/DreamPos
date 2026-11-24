import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/inventory/inventory_logic.dart';
import 'package:dreampos/features/inventory/inventory_pdf.dart';
import 'package:dreampos/features/inventory/inventory_screen.dart';
import 'package:dreampos/features/inventory/receipt_document.dart';
import 'package:dreampos/features/inventory/receipt_documents_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../helpers.dart';

class _LoggedIn extends SessionNotifier {
  _LoggedIn(this.u);
  final User u;
  @override
  Session? build() => Session(u);
}

Finder _tab(String label) => find.descendant(of: find.byType(AppBar), matching: find.text(label));

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.ensureVisible(_tab(label));
  await tester.pump();
  await tester.tap(_tab(label));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester, [int rounds = 10]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _Data {
  _Data(this.f, this.milk, this.bread, this.supplierId);
  final Fixture f;
  final Product milk;
  final Product bread;
  final String supplierId;
  AppDatabase get db => f.db;
}

Future<_Data> _seed() async {
  final f = await Fixture.create();
  final milk = await f.product('Молоко 1л', price: 12000, cost: 9000, stock: 2);
  await (f.db.update(
    f.db.products,
  )..where((t) => t.id.equals(milk.id))).write(const ProductsCompanion(barcode: Value('4780001')));
  final bread = await f.product('Хлеб', price: 4000, cost: 2500, stock: 30);
  final sid = newId();
  await f.db.into(f.db.suppliers).insert(SuppliersCompanion.insert(id: sid, name: 'Молочный завод'));
  return _Data(f, await f.reload(milk), bread, sid);
}

InventoryRepo _repo(AppDatabase db) => InventoryRepo(db, StockService(db));

Future<void> _pump(WidgetTester tester, _Data d, Size size, {Widget? home, User? user}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(d.db),
        sessionProvider.overrideWith(() => _LoggedIn(user ?? d.f.owner)),
      ],
      child: MaterialApp(home: home ?? const InventoryScreen()),
    ),
  );
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester, _Data d) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
  await d.db.close();
}

void main() {
  testWidgets('receipt form: invoice field, «Приход №N проведён», open and reverse the document', (tester) async {
    final d = (await tester.runAsync(_seed))!;
    await _pump(tester, d, const Size(1440, 900));
    await _openTab(tester, 'Приход');
    expect(find.text('Новый приход'), findsOneWidget);
    expect(find.text('Документы'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Сканируйте штрихкод или введите артикул'), '4780001');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '№ накладной поставщика'), 'НК-778');
    await tester.tap(find.text('Провести приход'));
    await _settle(tester);
    await tester.tap(find.text('Провести'));
    await _settle(tester, 20);

    final r = (await tester.runAsync(() => d.db.select(d.db.goodsReceipts).getSingle()))!;
    expect(r.number, 1);
    expect(r.supplierInvoice, 'НК-778');
    expect(find.textContaining('Приход №1 проведён'), findsOneWidget);
    // Form cleared, invoice too.
    expect(find.text('Документ пуст'), findsOneWidget);
    expect(find.text('НК-778'), findsNothing);

    // «Открыть» from the toast opens the document.
    await tester.tap(find.text('Открыть'));
    await _settle(tester);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Приход №1'), findsOneWidget);
    expect(find.text('НК-778'), findsOneWidget);
    expect(find.text('Молоко 1л'), findsOneWidget);
    expect(find.text('Проведён'), findsOneWidget);
    expect(find.text('Ручной приход'), findsOneWidget);

    // Reversal needs a reason.
    await tester.tap(find.text('Сторнировать'));
    await _settle(tester);
    expect(find.text('Сторнировать приход №1?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Сторнировать').last);
    await _settle(tester);
    expect(find.text('Укажите причину сторно'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Причина сторно *'), 'Ошибка ввода');
    await tester.tap(find.widgetWithText(FilledButton, 'Сторнировать').last);
    await _settle(tester, 20);

    final after = (await tester.runAsync(() => d.db.select(d.db.goodsReceipts).getSingle()))!;
    expect(after.status, ReceiptStatus.reversed);
    expect(after.reverseReason, 'Ошибка ввода');
    final milk = (await tester.runAsync(() => d.f.reload(d.milk)))!;
    expect(milk.stockQty, 2);
    expect(find.text('Сторнирован'), findsOneWidget);
    expect(find.textContaining('Причина: Ошибка ввода'), findsOneWidget);
    // Already reversed: no reversal button any more.
    expect(find.text('Сторнировать'), findsNothing);
    expect(tester.takeException(), isNull);
    await _dispose(tester, d);
  });

  testWidgets('documents list: table, filters, search, opens detail', (tester) async {
    final d = (await tester.runAsync(_seed))!;
    await tester.runAsync(() async {
      final repo = _repo(d.db);
      await repo.postReceipt(
        lines: [ReceiptLine(product: d.milk, qty: 5, unitCost: 9000)],
        supplierId: d.supplierId,
        supplierInvoice: 'INV-100',
      );
      final second = await repo.postReceipt(lines: [ReceiptLine(product: d.bread, qty: 10, unitCost: 2500)]);
      await repo.reverseReceipt(second, reason: 'Дубль');
    });
    await _pump(tester, d, const Size(1440, 900));
    await _openTab(tester, 'Приход');
    await tester.tap(find.text('Документы'));
    await _settle(tester);

    expect(find.text('№1'), findsOneWidget);
    expect(find.text('№2'), findsOneWidget);
    expect(find.text('INV-100'), findsOneWidget);
    expect(find.text('Молочный завод'), findsOneWidget);
    expect(find.text('Без поставщика'), findsOneWidget);
    expect(find.text('Сторнирован'), findsOneWidget);
    expect(find.textContaining('Документов: 2'), findsOneWidget);

    // Status filter.
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Все'));
    await _settle(tester);
    await tester.tap(find.text('Сторнирован').last);
    await _settle(tester);
    expect(find.text('№1'), findsNothing);
    expect(find.text('№2'), findsOneWidget);
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Сторнирован'));
    await _settle(tester);
    await tester.tap(find.text('Все').last);
    await _settle(tester);

    // Search by part of the invoice.
    await tester.enterText(find.widgetWithText(TextField, 'Поиск: № прихода или накладной'), 'inv-1');
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);
    expect(find.text('№1'), findsOneWidget);
    expect(find.text('№2'), findsNothing);

    // Nothing matches -> empty state.
    await tester.enterText(find.widgetWithText(TextField, 'Поиск: № прихода или накладной'), '999');
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);
    expect(find.text('Документов нет'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Поиск: № прихода или накладной'), '№1');
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);
    expect(find.text('№2'), findsNothing);
    await tester.tap(find.text('Молочный завод'));
    await _settle(tester);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Приход №1'), findsOneWidget);
    expect(find.text('Молочный завод'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _dispose(tester, d);
  });

  testWidgets('phone: cards list and full-screen detail', (tester) async {
    final d = (await tester.runAsync(_seed))!;
    await tester.runAsync(
      () => _repo(d.db).postReceipt(
        lines: [
          ReceiptLine(product: d.milk, qty: 5, unitCost: 9000, newPrice: 13000),
          ReceiptLine(product: d.bread, qty: 3, unitCost: 2500),
        ],
        supplierId: d.supplierId,
        supplierInvoice: 'A-1',
      ),
    );
    await _pump(tester, d, const Size(390, 844));
    await _openTab(tester, 'Приход');
    expect(find.widgetWithText(TextFormField, '№ накладной'), findsOneWidget);
    await tester.tap(find.text('Документы'));
    await _settle(tester);
    expect(find.text('Приход №1'), findsOneWidget);
    expect(find.text('2 позиции'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Приход №1'));
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Документ прихода'), findsOneWidget); // page app bar
    expect(find.textContaining('Розничная цена:'), findsOneWidget);
    expect(find.text('Печать'), findsOneWidget);
    expect(find.text('Сторнировать'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester, d);
  });

  testWidgets('movements: receipt rows show «Приход №N» and open the document', (tester) async {
    final d = (await tester.runAsync(_seed))!;
    await tester.runAsync(
      () => _repo(d.db).postReceipt(lines: [ReceiptLine(product: d.milk, qty: 4, unitCost: 9000)]),
    );
    await _pump(tester, d, const Size(1440, 900));
    await _openTab(tester, 'Движения');
    expect(find.textContaining('Приход №1'), findsOneWidget);
    await tester.tap(find.textContaining('Приход №1'));
    await _settle(tester);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Приход №1'), findsOneWidget);
    await _dispose(tester, d);
  });

  testWidgets('detail without stock permission has no reversal; missing id shows not found', (tester) async {
    final d = (await tester.runAsync(_seed))!;
    final id = (await tester.runAsync(
      () => _repo(d.db).postReceipt(lines: [ReceiptLine(product: d.milk, qty: 1, unitCost: 9000)]),
    ))!;
    final cashier = (await tester.runAsync(
      () => AuthService(d.db).createUser(name: 'Кассир', role: Role.cashier, pin: '1357'),
    ))!;
    await _pump(
      tester,
      d,
      const Size(1024, 768),
      user: cashier,
      home: Scaffold(body: ReceiptDocumentView(receiptId: id, fullPage: true)),
    );
    expect(find.text('Приход №1'), findsOneWidget);
    expect(find.text('Печать'), findsOneWidget);
    expect(find.text('Сторнировать'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await _pump(tester, d, const Size(1024, 768), home: const Scaffold(body: ReceiptDocumentView(receiptId: 'nope', fullPage: true)));
    expect(find.text('Документ не найден'), findsOneWidget);
    await _dispose(tester, d);
  });

  test('receiptsFilterFor: periods and custom range end are inclusive days', () {
    final now = DateTime(2026, 11, 24, 15, 30);
    final week = receiptsFilterFor(period: ReceiptPeriod.week, now: now);
    expect(week.from, DateTime(2026, 11, 18));
    expect(week.to, isNull);
    final custom = receiptsFilterFor(
      period: ReceiptPeriod.custom,
      range: DateTimeRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 10)),
      search: '  ',
      status: 'posted',
    );
    expect(custom.from, DateTime(2026, 11, 1));
    expect(custom.to, DateTime(2026, 11, 11));
    expect(custom.search, isNull);
    expect(custom.status, 'posted');
    expect(receiptsFilterFor(period: ReceiptPeriod.all), allReceipts);
  });

  test('receipt PDF builds with bundled Cyrillic fonts', () async {
    final f = await Fixture.create();
    final p = await f.product('Сыр', price: 50000, cost: 40000, stock: 0);
    final id = await _repo(f.db).postReceipt(
      lines: [ReceiptLine(product: p, qty: 2, unitCost: 40000, newPrice: 55000)],
      supplierInvoice: 'Ф-1',
    );
    await _repo(f.db).reverseReceipt(id, reason: 'Ошибка');
    final r = await (f.db.select(f.db.goodsReceipts)..where((t) => t.id.equals(id))).getSingle();
    final items = await f.db.select(f.db.goodsReceiptItems).get();
    final lines = receiptDocLines(items, {p.id: p});
    expect(lines.single.priceChanged, isTrue);
    expect(lines.single.total, 80000);
    pw.Font font(String file) => pw.Font.ttf(ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync()));
    final bytes = await buildReceiptPdf(
      receipt: r,
      lines: lines,
      storeName: 'Магазин',
      supplierName: 'Поставщик',
      orderNumber: 7,
      authorName: 'Owner',
      reversedByName: 'Owner',
      theme: pw.ThemeData.withFont(base: font('Roboto-Regular.ttf'), bold: font('Roboto-Bold.ttf')),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    await f.db.close();
  });
}
