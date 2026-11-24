// Gift card advances block of the payments report (D-023): money taken for
// sold certificates by method, minus refunds of voided sales. Never revenue.
import '../../../domain/services/gift_card_service.dart' show GiftSalesByMethod, giftSaleMethods;
import '../../../domain/services/sale_service.dart' show paymentMethodLabel;
import '../../../l10n/l10n.dart';
import 'period.dart';
import 'report_table.dart';

export '../../../domain/services/gift_card_service.dart' show GiftSalesByMethod, giftSalesByMethod;

String get giftSalesReportTitle => L.current.repGiftSalesTitle;
String get giftSalesReportHint => L.current.repGiftSalesHint;

/// Methods to show: the standard ones first, then anything unexpected.
List<String> giftReportMethods(GiftSalesByMethod g) {
  final keys = {...g.sold.keys, ...g.refunded.keys}
      .where((k) => (g.sold[k] ?? 0) != 0 || (g.refunded[k] ?? 0) != 0)
      .toSet();
  return [
    for (final m in giftSaleMethods)
      if (keys.contains(m)) m,
    ...(keys.difference(giftSaleMethods.toSet()).toList()..sort()),
  ];
}

/// Table for screen and CSV/PDF export.
RTable giftSalesTable(GiftSalesByMethod g, ReportPeriod p, [AppLocalizations? l]) {
  final t = l ?? L.current;
  final methods = giftReportMethods(g);
  return RTable(
    title: t.repGiftSalesTitle,
    subtitle: t.repGiftSalesSubtitle(p.labelIn(t), '${g.soldCount}', '${g.voidedCount}'),
    columns: [
      RCol(t.commonPaymentMethod),
      RCol(t.repColSold, numeric: true),
      RCol(t.repColVoided, numeric: true, tooltip: t.repGiftVoidedTooltip),
      RCol(t.commonTotal, numeric: true),
    ],
    rows: [
      for (final m in methods)
        [
          RCell(paymentMethodLabel(m, t)),
          RCell.money(g.sold[m] ?? 0),
          RCell.money(g.refunded[m] ?? 0),
          RCell.money((g.sold[m] ?? 0) - (g.refunded[m] ?? 0)),
        ],
    ],
    totals: methods.isEmpty
        ? null
        : [
            RCell(t.commonTotal),
            RCell.money(g.soldTotal),
            RCell.money(g.refundedTotal),
            RCell.money(g.netTotal),
          ],
  );
}
