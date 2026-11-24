import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/analytics.dart';
import 'data/gift_sales_report.dart';
import 'data/insights.dart';
import 'data/period.dart';
import 'data/report_queries.dart';

class ReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.preset(PeriodPreset.week);

  void set(ReportPeriod p) => state = p;
  void preset(PeriodPreset p) => state = ReportPeriod.preset(p);
}

/// Period selected on the Reports screen (kept while navigating away).
final reportPeriodProvider =
    NotifierProvider<ReportPeriodNotifier, ReportPeriod>(ReportPeriodNotifier.new);

final summaryProvider = StreamProvider.autoDispose.family<SalesSummary, ReportPeriod>(
    (ref, p) => watchSalesSummary(ref.watch(databaseProvider), p));

final byDayProvider = StreamProvider.autoDispose.family<List<DayPoint>, ReportPeriod>(
    (ref, p) => watchByDay(ref.watch(databaseProvider), p));

final byHourProvider = StreamProvider.autoDispose.family<List<HourCell>, ReportPeriod>(
    (ref, p) => watchByHour(ref.watch(databaseProvider), p));

final byProductProvider = StreamProvider.autoDispose.family<List<ProductRow>, ReportPeriod>(
    (ref, p) => watchByProduct(ref.watch(databaseProvider), p));

// Providers whose rows carry localized fallbacks ("Без категории", …) also
// watch the UI language so the texts follow a language switch.
final byCategoryProvider = StreamProvider.autoDispose.family<List<CategoryRow>, ReportPeriod>((ref, p) {
  ref.watch(uiLocaleProvider);
  return watchByCategory(ref.watch(databaseProvider), p);
});

final byStaffProvider = StreamProvider.autoDispose
    .family<List<StaffRow>, (ReportPeriod, StaffGrouping)>(
        (ref, a) {
  ref.watch(uiLocaleProvider);
  return watchByStaff(ref.watch(databaseProvider), a.$1, a.$2);
});

final paymentsProvider = StreamProvider.autoDispose.family<List<PaymentRow>, ReportPeriod>(
    (ref, p) => watchPayments(ref.watch(databaseProvider), p));

/// Gift card advances for the payments report (live; D-023).
final giftSalesReportProvider = StreamProvider.autoDispose.family<GiftSalesByMethod, ReportPeriod>((ref, p) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect('SELECT 1', readsFrom: {db.giftCardSales, db.giftCardSalePayments})
      .watch()
      .asyncMap((_) => giftSalesByMethod(db, p.start, p.end));
});

final debtsProvider = StreamProvider.autoDispose.family<DebtSummary, ReportPeriod>(
    (ref, p) => watchDebts(ref.watch(databaseProvider), p));

final stockValueProvider = StreamProvider.autoDispose<List<StockValueRow>>((ref) {
  ref.watch(uiLocaleProvider);
  return watchStockValue(ref.watch(databaseProvider));
});

final deadStockProvider = StreamProvider.autoDispose<List<DeadStockRow>>(
    (ref) => deadStockQuery(ref.watch(databaseProvider)).watch());

final writeOffsProvider = StreamProvider.autoDispose.family<List<WriteOffRow>, ReportPeriod>((ref, p) {
  ref.watch(uiLocaleProvider);
  return watchWriteOffs(ref.watch(databaseProvider), p);
});

/// Live demand forecast; [horizon] = days to cover when reordering.
final forecastProvider = StreamProvider.autoDispose.family<List<Forecast>, int>((ref, horizon) {
  final now = DateTime.now();
  return demandQuery(ref.watch(databaseProvider), now: now)
      .watch()
      .map((rows) => forecastAll(rows, now: now, horizonDays: horizon));
});

/// Rule-based insights (recomputed on demand via ref.invalidate).
final insightsDataProvider = FutureProvider.autoDispose<InsightData>(
    (ref) => loadInsightData(ref.watch(databaseProvider)));
