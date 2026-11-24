// X/Z report data and plain-text layout (no PDF dependency).
import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/widgets/widgets.dart' show formatDateTime;
import '../../domain/services/sale_service.dart' show paymentMethodLabel;
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
  String get title => isClosed ? 'Z-отчёт' : 'X-отчёт';

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

  List<ReportSection> sections() {
    final r = figures.report;
    final s = figures.shift;
    String m(int v) => Money.format(v);
    final methods = r.byMethod.keys.toList()..sort();
    final refunds = r.refundsByMethod.keys.toList()..sort();
    return [
      ReportSection('Смена', [
        ReportLine('Смена №', '${s.number}'),
        ReportLine('Открыта', '${formatDateTime(s.openedAt)} · $openedByName'),
        if (s.closedAt != null) ReportLine('Закрыта', '${formatDateTime(s.closedAt!)} · ${closedByName ?? '—'}'),
      ]),
      ReportSection('Продажи', [
        ReportLine('Чеков', '${r.salesCount}'),
        ReportLine('Сумма продаж', m(r.salesTotal), bold: true),
        for (final k in methods)
          ReportLine('в т.ч. ${paymentMethodLabel(k).toLowerCase()}', m(r.byMethod[k]!), indent: true),
        ReportLine('Скидки', m(r.discountTotal)),
        ReportLine('Средний чек', m(figures.averageCheck)),
        if (r.voidedCount > 0) ReportLine('Аннулировано чеков', '${r.voidedCount}'),
      ]),
      ReportSection('Возвраты', [
        ReportLine('Возвратов', '${r.returnsCount}'),
        ReportLine('Сумма возвратов', m(r.returnsTotal), bold: true),
        for (final k in refunds)
          ReportLine('в т.ч. ${paymentMethodLabel(k).toLowerCase()}', m(r.refundsByMethod[k]!), indent: true),
      ]),
      if (r.giftSalesCount > 0 || r.giftVoidsCount > 0)
        ReportSection('Сертификаты', [
          ReportLine('Продано', '${r.giftSalesCount}'),
          ReportLine('Сумма продаж (аванс)', m(r.giftSalesTotal), bold: true),
          for (final k in _sortedKeys(r.giftSalesByMethod))
            ReportLine('в т.ч. ${paymentMethodLabel(k).toLowerCase()}', m(r.giftSalesByMethod[k]!), indent: true),
          if (r.giftVoidsCount > 0) ...[
            ReportLine('Аннулировано', '${r.giftVoidsCount}'),
            ReportLine('Возвращено покупателям', '−${m(r.giftRefundsTotal)}', bold: true),
            for (final k in _sortedKeys(r.giftRefundsByMethod))
              ReportLine('в т.ч. ${paymentMethodLabel(k).toLowerCase()}', '−${m(r.giftRefundsByMethod[k]!)}', indent: true),
          ],
          ReportLine('Влияние на кассу (нал.)', _signed(r.giftCashNet, m), bold: true),
          const ReportLine('аванс, не входит в выручку', '', indent: true),
        ]),
      ReportSection('Итог', [
        ReportLine('Выручка (за вычетом возвратов)', m(figures.netRevenue), bold: true),
        if (showProfit) ReportLine('Себестоимость', m(figures.netCost)),
        if (showProfit) ReportLine('Валовая прибыль', m(figures.grossProfit), bold: true),
      ]),
      ReportSection('Касса (наличные)', [
        ReportLine('Размен на начало', m(s.openingCash)),
        ReportLine('Наличные продажи', m(r.cashSales)),
        ReportLine('Наличные возвраты', '−${m(r.cashRefunds)}'),
        for (final k in cashKinds)
          if ((figures.movementsByKind[k] ?? 0) > 0) ...[
            ReportLine(cashKindLabel(k), '${cashKindIsIn(k) ? '+' : '−'}${m(figures.movementsByKind[k]!)}'),
            // Expense categories belong right under the "Расход" line.
            if (k == 'expense')
              for (final e in figures.expensesByCategory.entries) ReportLine(e.key, m(e.value), indent: true),
          ],
        ReportLine('Погашение долгов (нал.)', m(r.debtCollectedCash)),
        if (r.debtCollectedNonCash > 0) ReportLine('Погашение долгов (безнал.)', m(r.debtCollectedNonCash)),
        if (r.supplierCashPaid > 0) ReportLine('Оплаты поставщикам', '−${m(r.supplierCashPaid)}'),
        if (r.giftCashNet != 0)
          ReportLine('Сертификаты (нал., аванс)', _signed(r.giftCashNet, m)),
        ReportLine('Ожидается в кассе', m(figures.expectedForDiff), bold: true),
        if (s.countedCash != null) ReportLine('Фактически', m(s.countedCash!), bold: true),
        if (figures.difference != null)
          ReportLine(
            figures.difference! < 0
                ? 'Недостача'
                : figures.difference! > 0
                ? 'Излишек'
                : 'Расхождение',
            m(figures.difference!),
            bold: true,
          ),
        if ((s.note ?? '').isNotEmpty) ReportLine('Примечание', s.note!),
      ]),
    ];
  }

  static List<String> _sortedKeys(Map<String, int> m) =>
      [for (final e in m.entries) if (e.value != 0) e.key]..sort();

  static String _signed(int v, String Function(int) m) => v == 0 ? m(0) : '${v < 0 ? '−' : '+'}${m(v.abs())}';

  /// Monospace layout for receipt printers.
  String toText({int width = 42}) {
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
    b.writeln(center(title.toUpperCase()));
    b.writeln(center('Печать: ${formatDateTime(DateTime.now())}'));
    for (final sec in sections()) {
      b.writeln('-' * width);
      b.writeln(sec.title.toUpperCase());
      for (final l in sec.lines) {
        row(l.indent ? '  ${l.label}' : l.label, l.value);
      }
    }
    b.writeln('-' * width);
    if (isClosed) {
      b.writeln();
      b.writeln('Кассир: ______________');
      b.writeln();
      b.writeln('Принял: ______________');
    }
    return b.toString();
  }
}
