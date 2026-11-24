// Gift card advances block of the payments report (D-023): money taken for
// sold certificates by method, minus refunds of voided sales. Never revenue.
import '../../../domain/services/gift_card_service.dart' show GiftSalesByMethod, giftSaleMethods;
import '../../../domain/services/sale_service.dart' show paymentMethodLabel;
import 'period.dart';
import 'report_table.dart';

export '../../../domain/services/gift_card_service.dart' show GiftSalesByMethod, giftSalesByMethod;

const giftSalesReportTitle = 'Продажа сертификатов (аванс, не выручка)';
const giftSalesReportHint =
    'Деньги за проданные сертификаты — аванс. В выручку они попадают при оплате товара сертификатом.';

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
RTable giftSalesTable(GiftSalesByMethod g, ReportPeriod p) {
  final methods = giftReportMethods(g);
  return RTable(
    title: giftSalesReportTitle,
    subtitle: '${p.label} · продано ${g.soldCount}, аннулировано ${g.voidedCount}',
    columns: const [
      RCol('Способ оплаты'),
      RCol('Продано', numeric: true),
      RCol('Аннулировано', numeric: true, tooltip: 'Возвращено покупателям при аннулировании продажи'),
      RCol('Итого', numeric: true),
    ],
    rows: [
      for (final m in methods)
        [
          RCell(paymentMethodLabel(m)),
          RCell.money(g.sold[m] ?? 0),
          RCell.money(g.refunded[m] ?? 0),
          RCell.money((g.sold[m] ?? 0) - (g.refunded[m] ?? 0)),
        ],
    ],
    totals: methods.isEmpty
        ? null
        : [
            const RCell('Итого'),
            RCell.money(g.soldTotal),
            RCell.money(g.refundedTotal),
            RCell.money(g.netTotal),
          ],
  );
}
