import 'package:drift/drift.dart' show Value;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/reports/data/analytics.dart';
import 'package:dreampos/features/reports/data/insights.dart';
import 'package:dreampos/features/reports/data/period.dart';
import 'package:dreampos/features/reports/data/report_queries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late Fixture f;
  late SaleService sales;
  late Product a, b;
  final d = DateTime(2026, 11, 20, 12, 30);
  final dayD = ReportPeriod(DateTime(2026, 11, 20), DateTime(2026, 11, 21));

  Future<Sale> sell(Product p, double qty, {required DateTime at, String method = 'cash'}) async {
    final r = await sales.checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: p.id, qty: qty, unitPrice: p.price)],
      payments: [PaymentInput(method, (p.price * qty).round())],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
      now: at,
    ));
    return r.sale;
  }

  Future<void> returnOne(Sale s, {required DateTime at, bool restock = true}) async {
    final items = await (f.db.select(f.db.saleItems)..where((i) => i.saleId.equals(s.id))).get();
    await sales.returnItems(
      saleId: s.id,
      lines: [ReturnLineInput(items.first.id, 1)],
      refundMethod: 'cash',
      userId: f.owner.id,
      shiftId: f.shift.id,
      restock: restock,
      now: at,
    );
  }

  setUp(() async {
    f = await Fixture.create();
    sales = SaleService(f.db);
    a = await f.product('Молоко', price: 1000, cost: 600, stock: 50);
    b = await f.product('Сыр', price: 5000, cost: 3000, stock: 50);

    // Day D-1: A×3 (3000, cost 1800)
    final s4 = await sell(a, 3, at: d.subtract(const Duration(days: 1)));
    // Day D: A×2 cash, B×1 card, A×1 voided
    final s1 = await sell(a, 2, at: d);
    await sell(b, 1, at: d, method: 'card');
    final s3 = await sell(a, 1, at: d);
    await sales.voidSale(s3.id, userId: f.owner.id, reason: 'ошибка', shiftId: f.shift.id);
    // Returns on D: 1×A from s1 (restocked), 1×A from yesterday's s4 (not restocked)
    await returnOne(s1, at: d.add(const Duration(hours: 1)));
    await returnOne(s4, at: d.add(const Duration(hours: 2)), restock: false);
  });
  tearDown(() => f.db.close());

  test('summary: voids excluded, returns subtracted by return date, profit uses restock', () async {
    final s = await salesSummaryQuery(f.db, dayD).getSingle();
    expect(s.receipts, 2);
    expect(s.voids, 1);
    expect(s.gross, 7000);
    expect(s.returnsTotal, 2000);
    expect(s.returnsCount, 2);
    expect(s.net, 5000);
    expect(s.cost, 4200);
    expect(s.returnsCost, 600, reason: 'only the restocked return gives cost back');
    expect(s.profit, 1400);
    expect(s.avgCheck, 3500);

    final prev = await salesSummaryQuery(f.db, dayD.previous).getSingle();
    expect(prev.gross, 3000);
    expect(prev.returnsTotal, 0, reason: 'return of yesterday sale counts on the return day');
  });

  test('live stream updates after a new sale', () async {
    final stream = watchSalesSummary(f.db, dayD);
    expect((await stream.first).gross, 7000);
    await sell(b, 1, at: d.add(const Duration(minutes: 5)));
    expect((await watchSalesSummary(f.db, dayD).first).gross, 12000);
  });

  test('by day is zero-filled and nets returns', () async {
    final p = ReportPeriod(DateTime(2026, 11, 18), DateTime(2026, 11, 21));
    final days = await watchByDay(f.db, p).first;
    expect(days.length, 3);
    expect(days[0].gross, 0);
    expect(days[1].gross, 3000);
    expect(days[1].receipts, 1);
    expect(days[2].gross, 7000);
    expect(days[2].returns, 2000);
    expect(days[2].net, 5000);
    expect(days[2].cost, 4200 - 600);
  });

  test('by hour groups receipts by local hour and weekday', () async {
    final cells = await watchByHour(f.db, dayD).first;
    expect(cells.length, 1);
    expect(cells.single.hour, 12);
    expect(cells.single.weekday, d.weekday);
    expect(cells.single.receipts, 2);
  });

  test('by product / category nets returns', () async {
    final rows = await byProductQuery(f.db, dayD).get();
    final ra = rows.firstWhere((r) => r.id == a.id);
    final rb = rows.firstWhere((r) => r.id == b.id);
    expect(ra.qty, 0);
    expect(ra.revenue, 0);
    expect(ra.cost, 600, reason: 'non-restocked unit stays as cost');
    expect(rb.revenue, 5000);
    expect(rb.profit, 2000);
    expect(rows.first.id, b.id, reason: 'sorted by revenue desc');

    final cats = await byCategoryQuery(f.db, dayD).get();
    expect(cats.single.name, 'Без категории');
    expect(cats.single.revenue, 5000);
    expect(cats.single.products, 2);
  });

  test('staff report attributes returns and voids to the cashier', () async {
    final rows = await watchByStaff(f.db, dayD, StaffGrouping.cashier).first;
    final r = rows.single;
    expect(r.name, 'Owner');
    expect(r.receipts, 2);
    expect(r.revenue, 7000);
    expect(r.returnsTotal, 2000);
    expect(r.returnsCount, 2);
    expect(r.voids, 1);
    expect(r.net, 5000);
  });

  test('payments: voided payments excluded, refunds by method', () async {
    final rows = await paymentsQuery(f.db, dayD).get();
    final cash = rows.firstWhere((r) => r.method == 'cash');
    final card = rows.firstWhere((r) => r.method == 'card');
    expect(cash.paid, 2000);
    expect(cash.refunded, 2000);
    expect(card.paid, 5000);
    expect(card.refunded, 0);
  });

  test('debts issued vs collected', () async {
    final c = await f.customer('Клиент', debtLimit: 100000);
    await sales.checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: b.id, qty: 1, unitPrice: 5000)],
      payments: [PaymentInput('debt', 5000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
      customerId: c.id,
      now: d,
    ));
    // payDebt writes "now" timestamps; query a period that includes now.
    final now = DateTime.now();
    final wide = ReportPeriod(DateTime(2026, 1, 1), DateTime(now.year + 1, 1, 1));
    final s = await watchDebts(f.db, wide).first;
    expect(s.issued, 5000);
    expect(s.outstanding, 5000);
    expect(s.debtors, 1);
  });

  test('stock valuation, dead stock and write-offs', () async {
    final c = await f.product('Старый товар', price: 2000, cost: 1000, stock: 4);
    await (f.db.update(f.db.products)..where((p) => p.id.equals(c.id)))
        .write(ProductsCompanion(createdAt: Value(DateTime(2025, 1, 1))));
    await StockService(f.db).writeOff(productId: a.id, qty: 2, reason: 'Брак', userId: f.owner.id);

    final value = await watchStockValue(f.db).first;
    final total = value.single;
    final aStock = (await f.reload(a)).stockQty;
    final bStock = (await f.reload(b)).stockQty;
    expect(total.costValue, (aStock * 600 + bStock * 3000 + 4 * 1000).round());
    expect(total.retailValue, (aStock * 1000 + bStock * 5000 + 4 * 2000).round());

    final dead = await deadStockQuery(f.db, now: DateTime(2026, 12, 1)).get();
    expect(dead.map((r) => r.id), [c.id], reason: 'A/B were created recently and/or sold');
    expect(dead.single.value, 4000);

    final now = DateTime.now();
    final wo = await watchWriteOffs(
            f.db, ReportPeriod(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day + 1)))
        .first;
    expect(wo.single.reason, 'Брак');
    expect(wo.single.qty, 2);
    expect(wo.single.cost, 1200);
  });

  test('demand query nets returned quantities and skips voids', () async {
    final rows = await demandQuery(f.db, now: d.add(const Duration(days: 1))).get();
    final ra = rows.firstWhere((r) => r.id == a.id);
    // sold: 3 (D-1) + 2 (D), returned 1 + 1, voided 1 excluded
    expect(ra.sold28, 3);
  });

  group('ABC', () {
    test('boundaries: item reaching exactly 80% is A, 95% is B', () {
      final r = abcClassify([
        const MapEntry('p1', 50),
        const MapEntry('p2', 30),
        const MapEntry('p3', 15),
        const MapEntry('p4', 5),
      ]);
      expect(r['p1'], AbcClass.a);
      expect(r['p2'], AbcClass.a); // cumulative before = 50% (< 80%)
      expect(r['p3'], AbcClass.b); // cumulative before = 80% → not A
      expect(r['p4'], AbcClass.c); // cumulative before = 95% → C
    });

    test('top seller is always A; zero/negative revenue is C', () {
      final r = abcClassify([
        const MapEntry('big', 990),
        const MapEntry('small', 10),
        const MapEntry('zero', 0),
        const MapEntry('neg', -5),
      ]);
      expect(r['big'], AbcClass.a);
      expect(r['small'], AbcClass.c);
      expect(r['zero'], AbcClass.c);
      expect(r['neg'], AbcClass.c);
    });

    test('crossing the line keeps the item in the upper class', () {
      final r = abcClassify([
        const MapEntry('x', 70),
        const MapEntry('y', 20), // before = 70% → A (crosses 80%)
        const MapEntry('z', 6), // before = 90% → B
        const MapEntry('w', 4), // before = 96% → C
      ]);
      expect([r['x'], r['y'], r['z'], r['w']], [AbcClass.a, AbcClass.a, AbcClass.b, AbcClass.c]);
    });
  });

  group('forecast', () {
    final now = DateTime(2026, 11, 20, 10);
    DemandRow row({double stock = 10, double min = 0, double sold28 = 28, double sold7 = 7, int ageDays = 100, String unit = 'pcs'}) =>
        DemandRow(
          id: 'x',
          name: 'X',
          unit: unit,
          stock: stock,
          minStock: min,
          costPrice: 100,
          createdAt: now.subtract(Duration(days: ageDays)),
          sold28: sold28,
          sold7: sold7,
        );

    test('moving average, cover, reorder', () {
      final fc = computeForecast(row(stock: 10, min: 2), now: now, horizonDays: 14);
      expect(fc.windowDays, 28);
      expect(fc.avgDaily, 1);
      expect(fc.daysOfCover, 10);
      expect(fc.stockoutDate, now.add(const Duration(days: 10)));
      expect(fc.reorderQty, 6); // 1×14 + 2 − 10
      expect(fc.reorderCost, 600);
      expect(fc.atRisk, isFalse);
    });

    test('risk within 7 days and rounding up for pieces', () {
      final fc = computeForecast(row(stock: 5, sold28: 29), now: now, horizonDays: 14);
      expect(fc.atRisk, isTrue);
      expect(fc.reorderQty, 10); // 29/28×14 = 14.5 − 5 = 9.5 → 10
    });

    test('new products use their age (min 7 days) as the window', () {
      expect(computeForecast(row(sold28: 20, ageDays: 10), now: now).avgDaily, 2);
      expect(computeForecast(row(sold28: 14, ageDays: 2), now: now).avgDaily, 2);
    });

    test('weighted goods round to 0.1, no demand → no cover', () {
      final kg = computeForecast(row(stock: 1, sold28: 9.8, unit: 'kg'), now: now, horizonDays: 14);
      expect(kg.reorderQty, closeTo(3.9, 1e-9)); // 0.35×14 = 4.9 − 1
      final none = computeForecast(row(sold28: 0, sold7: 0), now: now);
      expect(none.daysOfCover, isNull);
      expect(none.reorderQty, 0);
      expect(none.atRisk, isFalse);
    });

    test('forecastAll sorts by urgency', () {
      final list = forecastAll([
        row(stock: 100),
        row(stock: 2),
        row(stock: 50, sold28: 0),
      ], now: now);
      expect(list.first.row.stock, 2);
      expect(list.last.hasDemand, isFalse);
    });
  });

  group('insights', () {
    test('rules fire with explainable numbers', () {
      final data = InsightData(
        now: d,
        week: const SalesSummary(receipts: 10, gross: 112000),
        prevWeek: const SalesSummary(receipts: 10, gross: 100000),
        month: const SalesSummary(receipts: 40, gross: 400000, subtotal: 500000, discounts: 100000),
        categories: const [
          CategoryRow('c1', 'Молочка', 10, 100000, 50000, 3),
          CategoryRow('c2', 'Хлеб', 10, 100000, 90000, 3),
        ],
        products: const [
          ProductRow(id: 'p1', name: 'Кефир', revenue: 10000, cost: 9800),
          ProductRow(id: 'p2', name: 'Сок', revenue: 10000, cost: 11000),
        ],
        hours: [
          for (var i = 0; i < 5; i++) const HourCell(1, 10, 2, 1000),
          const HourCell(2, 18, 20, 10000),
          const HourCell(3, 19, 15, 10000),
        ],
        inactiveCustomers: 12,
        overdueDebtors: 2,
        overdueDebt: 50000,
      );
      final list = buildInsights(data);
      final ids = list.map((i) => i.id).toSet();
      expect(ids, containsAll(<String>[
        'revenue_up',
        'category_profit',
        'margin_p1',
        'margin_p2',
        'inactive_customers',
        'discounts',
        'peak_hours',
        'overdue_debts',
      ]));
      expect(list.firstWhere((i) => i.id == 'revenue_up').title, contains('12%'));
      expect(list.firstWhere((i) => i.id == 'peak_hours').title, contains('18–20'));
      expect(list.firstWhere((i) => i.id == 'discounts').title, contains('20%'));
      expect(list.first.severity, InsightSeverity.critical, reason: 'loss-making product first');
      // cost-sensitive rules hidden without Perm.viewCost
      final noCost = buildInsights(data, withCost: false).map((i) => i.id);
      expect(noCost, isNot(contains('category_profit')));
      expect(noCost, isNot(contains('margin_p1')));
    });

    test('stockout insight from forecasts', () {
      final now = DateTime(2026, 11, 20);
      final fc = computeForecast(
          DemandRow(
              id: 'z',
              name: 'Хлеб',
              unit: 'pcs',
              stock: 3,
              minStock: 0,
              costPrice: 100,
              createdAt: DateTime(2026, 1, 1),
              sold28: 28,
              sold7: 7),
          now: now);
      final list = buildInsights(InsightData(now: now, forecasts: [fc]));
      expect(list.single.title, 'Товар Хлеб закончится через 3 дня');
      expect(list.single.route, '/purchasing');
    });

    test('loadInsightData runs against the database', () async {
      final data = await loadInsightData(f.db, now: d.add(const Duration(hours: 3)));
      expect(data.week.gross, 10000);
      expect(data.forecasts, isNotEmpty);
      expect(buildInsights(data), isA<List<Insight>>());
    });
  });

  group('period presets', () {
    final now = DateTime(2026, 11, 20, 15); // Friday
    test('presets are calendar based', () {
      expect(ReportPeriod.preset(PeriodPreset.today, now: now).start, DateTime(2026, 11, 20));
      expect(ReportPeriod.preset(PeriodPreset.yesterday, now: now).end, DateTime(2026, 11, 20));
      expect(ReportPeriod.preset(PeriodPreset.week, now: now).start, DateTime(2026, 11, 16));
      expect(ReportPeriod.preset(PeriodPreset.month, now: now).start, DateTime(2026, 11, 1));
      final lm = ReportPeriod.preset(PeriodPreset.lastMonth, now: now);
      expect([lm.start, lm.end], [DateTime(2026, 10, 1), DateTime(2026, 11, 1)]);
      expect(ReportPeriod.preset(PeriodPreset.quarter, now: now).start, DateTime(2026, 10, 1));
      expect(ReportPeriod.preset(PeriodPreset.year, now: now).start, DateTime(2026, 1, 1));
      expect(ReportPeriod.preset(PeriodPreset.week, now: now).dayCount, 5);
      expect(ReportPeriod.days(DateTime(2026, 11, 1), DateTime(2026, 11, 3)).previous.start,
          DateTime(2026, 10, 29));
    });
  });
}
