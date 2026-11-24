// X/Z report data and plain-text layout (no PDF dependency).
import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/widgets/widgets.dart' show formatDateTime;
import '../../domain/services/sale_service.dart' show paymentMethodLabel;
import '../../l10n/l10n.dart';
import 'shift_logic.dart';

/// One labelled line of a report.
class ReportLine {
  const ReportLine(this.label, this.value, {this.bold = false, this.indent = false});
  final String label;
  final String value;
  final bool bold;
  final bool indent;
}

class ReportSection {
  const ReportSection(this.title, this.lines);
  final String title;
  final List<ReportLine> lines;
}

/// Everything printed on an X/Z report.
class ZReportData {
  ZReportData({
    required this.figures,
    required this.settings,
    required this.openedByName,
    this.closedByName,
    this.showProfit = false,
  });

  final ShiftFigures figures;
  final Map<String, String> settings;
  final String openedByName;
  final String? closedByName;
  final bool showProfit;

  bool get isClosed => figures.shift.status == 'closed';

  /// Language of the printed report: the store's receipt language
  /// (`receipt_locale`), like receipts and gift slips.
  AppLocalizations get printL10n => L.forReceipt(settings);

  /// «Z-отчёт» / «X-отчёт» in [l] (default: [printL10n]).
  String titleIn([AppLocalizations? l]) {
    final t = l ?? printL10n;
    return isClosed ? t.shiftZReport : t.shiftXReport;
  }

  String get title => titleIn();

  static Future<ZReportData> load(AppDatabase db, String shiftId, {bool showProfit = false}) async {
    final f = await ShiftFigures.load(db, shiftId);
    final settings = {for (final s in await db.select(db.settings).get()) s.key: s.value};
    Future<String> name(String? id) async {
      if (id == null) return '—';
      final u = await (db.select(db.users)..where((t) => t.id.equals(id))).getSingleOrNull();
      return u?.name ?? '—';
    }

    return ZReportData(
      figures: f,
      settings: settings,
      openedByName: await name(f.shift.openedBy),
      closedByName: f.shift.closedBy == null ? null : await name(f.shift.closedBy),
      showProfit: showProfit,
    );
  }

  /// Report sections in [l] (default: [printL10n]; the on-screen view passes
  /// the UI language).
  List<ReportSection> sections([AppLocalizations? l]) {
    final t = l ?? printL10n;
    final r = figures.report;
    final s = figures.shift;
    String m(int v) => Money.format(v);
    final methods = r.byMethod.keys.toList()..sort();
    final refunds = r.refundsByMethod.keys.toList()..sort();
    return [
      ReportSection(t.commonShift, [
        ReportLine(t.shiftZShiftNo, '${s.number}'),
        ReportLine(t.shiftZOpened, '${formatDateTime(s.openedAt)} · $openedByName'),
        if (s.closedAt != null) ReportLine(t.shiftZClosed, '${formatDateTime(s.closedAt!)} · ${closedByName ?? '—'}'),
      ]),
      ReportSection(t.shiftSales, [
        ReportLine(t.shiftZReceipts, '${r.salesCount}'),
        ReportLine(t.shiftZSalesTotal, m(r.salesTotal), bold: true),
        for (final k in methods)
          ReportLine(t.shiftZIncl(paymentMethodLabel(k, t).toLowerCase()), m(r.byMethod[k]!), indent: true),
        ReportLine(t.shiftZDiscounts, m(r.discountTotal)),
        ReportLine(t.shiftZAvgCheck, m(figures.averageCheck)),
        if (r.voidedCount > 0) ReportLine(t.shiftZVoidedReceipts, '${r.voidedCount}'),
      ]),
      ReportSection(t.shiftReturns, [
        ReportLine(t.shiftZReturnsCount, '${r.returnsCount}'),
        ReportLine(t.shiftZReturnsTotal, m(r.returnsTotal), bold: true),
        for (final k in refunds)
          ReportLine(t.shiftZIncl(paymentMethodLabel(k, t).toLowerCase()), m(r.refundsByMethod[k]!), indent: true),
      ]),
      if (r.giftSalesCount > 0 || r.giftVoidsCount > 0)
        ReportSection(t.shiftZGiftCards, [
          ReportLine(t.shiftZSold, '${r.giftSalesCount}'),
          ReportLine(t.shiftZGiftSalesTotal, m(r.giftSalesTotal), bold: true),
          for (final k in _sortedKeys(r.giftSalesByMethod))
            ReportLine(t.shiftZIncl(paymentMethodLabel(k, t).toLowerCase()), m(r.giftSalesByMethod[k]!), indent: true),
          if (r.giftVoidsCount > 0) ...[
            ReportLine(t.shiftZVoided, '${r.giftVoidsCount}'),
            ReportLine(t.shiftZRefundedToBuyers, '−${m(r.giftRefundsTotal)}', bold: true),
            for (final k in _sortedKeys(r.giftRefundsByMethod))
              ReportLine(t.shiftZIncl(paymentMethodLabel(k, t).toLowerCase()), '−${m(r.giftRefundsByMethod[k]!)}',
                  indent: true),
          ],
          ReportLine(t.shiftZCashImpact, _signed(r.giftCashNet, m), bold: true),
          ReportLine(t.shiftZAdvanceNote, '', indent: true),
        ]),
      ReportSection(t.shiftZSummary, [
        ReportLine(t.shiftZNetRevenue, m(figures.netRevenue), bold: true),
        if (showProfit) ReportLine(t.commonCost, m(figures.netCost)),
        if (showProfit) ReportLine(t.shiftGrossProfit, m(figures.grossProfit), bold: true),
      ]),
      ReportSection(t.shiftZCash, [
        ReportLine(t.shiftZOpeningCash, m(s.openingCash)),
        ReportLine(t.shiftZCashSales, m(r.cashSales)),
        ReportLine(t.shiftZCashRefunds, '−${m(r.cashRefunds)}'),
        for (final k in cashKinds)
          if ((figures.movementsByKind[k] ?? 0) > 0) ...[
            ReportLine(cashKindLabel(k, t), '${cashKindIsIn(k) ? '+' : '−'}${m(figures.movementsByKind[k]!)}'),
            // Expense categories belong right under the "Расход" line.
            if (k == 'expense')
              for (final e in figures.expensesByCategory.entries)
                ReportLine(expenseCategoryLabel(e.key, t), m(e.value), indent: true),
          ],
        ReportLine(t.shiftZDebtCash, m(r.debtCollectedCash)),
        if (r.debtCollectedNonCash > 0) ReportLine(t.shiftZDebtNonCash, m(r.debtCollectedNonCash)),
        if (r.supplierCashPaid > 0) ReportLine(t.shiftZSupplierPaid, '−${m(r.supplierCashPaid)}'),
        if (r.giftCashNet != 0)
          ReportLine(t.shiftZGiftCash, _signed(r.giftCashNet, m)),
        ReportLine(t.shiftExpectedInDrawer, m(figures.expectedForDiff), bold: true),
        if (s.countedCash != null) ReportLine(t.shiftZActual, m(s.countedCash!), bold: true),
        if (figures.difference != null)
          ReportLine(
            figures.difference! < 0
                ? t.shiftShortage
                : figures.difference! > 0
                ? t.shiftSurplus
                : t.shiftDifference,
            m(figures.difference!),
            bold: true,
          ),
        if ((s.note ?? '').isNotEmpty) ReportLine(t.commonNote, s.note!),
      ]),
    ];
  }

  static List<String> _sortedKeys(Map<String, int> m) =>
      [for (final e in m.entries) if (e.value != 0) e.key]..sort();

  static String _signed(int v, String Function(int) m) => v == 0 ? m(0) : '${v < 0 ? '−' : '+'}${m(v.abs())}';

  /// Monospace layout for receipt printers, in [printL10n].
  String toText({int width = 42}) {
    final t = printL10n;
    final b = StringBuffer();
    String center(String t) {
      if (t.length >= width) return t;
      final pad = (width - t.length) ~/ 2;
      return '${' ' * pad}$t';
    }

    void row(String l, String v) {
      final space = width - l.length - v.length;
      if (space >= 1) {
        b.writeln('$l${' ' * space}$v');
      } else {
        b.writeln(l);
        b.writeln(v.padLeft(width));
      }
    }

    final store = settings['store_name'];
    if (store != null && store.isNotEmpty) b.writeln(center(store));
    b.writeln(center(titleIn(t).toUpperCase()));
    b.writeln(center(t.shiftZPrinted(formatDateTime(DateTime.now()))));
    for (final sec in sections(t)) {
      b.writeln('-' * width);
      b.writeln(sec.title.toUpperCase());
      for (final l in sec.lines) {
        row(l.indent ? '  ${l.label}' : l.label, l.value);
      }
    }
    b.writeln('-' * width);
    if (isClosed) {
      b.writeln();
      b.writeln('${t.shiftZCashierSign}: ______________');
      b.writeln();
      b.writeln('${t.shiftZReceivedSign}: ______________');
    }
    return L.printable(b.toString());
  }
}
