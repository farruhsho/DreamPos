// «Сертификаты» section of the X/Z report (D-023): screen, text and PDF all
// render ZReportData.sections(), so the data layer is tested here.
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/shifts/report_data.dart';
import 'package:dreampos/features/shifts/shift_logic.dart';
import 'package:dreampos/features/shifts/z_report_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Fixture f;
  setUp(() async => f = await Fixture.create());
  tearDown(() => f.db.close());

  ReportSection? giftSection(ZReportData z) => z.sections().where((s) => s.title == 'Сертификаты').firstOrNull;
  String value(ReportSection s, String label) => s.lines.firstWhere((l) => l.label == label).value;

  test('no gift sales -> no section and no cash line', () async {
    final fig = await ShiftFigures.load(f.db, f.shift.id);
    final z = ZReportData(figures: fig, settings: const {}, openedByName: 'Owner');
    expect(giftSection(z), isNull);
    expect(z.toText(), isNot(contains('СЕРТИФИКАТЫ')));
    expect(z.toText(), isNot(contains('Сертификаты (нал., аванс)')));
  });

  test('section shows sold, by method, voided and the cash effect; expected cash matches', () async {
    final gifts = GiftCardService(f.db);
    await gifts.sell(GiftCardSaleRequest(
      code: 'GIFTAAAA01',
      amount: 10000,
      payments: const [GiftSalePaymentInput('cash', 4000), GiftSalePaymentInput('card', 6000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    final v = await gifts.sell(GiftCardSaleRequest(
      code: 'GIFTAAAA02',
      amount: 3000,
      payments: const [GiftSalePaymentInput('cash', 3000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    await gifts.voidSale(v.saleId, reason: 'Ошибка', userId: f.owner.id, shiftId: f.shift.id);

    final fig = await ShiftFigures.load(f.db, f.shift.id);
    final r = fig.report;
    expect(r.giftCashNet, 4000 + 3000 - 3000);
    expect(fig.expectedCash, 10000 + 4000, reason: 'opening + gift cash net');
    expect(fig.expectedForDiff, r.expectedCash);
    expect(fig.netRevenue, 0, reason: 'gift advances are not revenue');

    final z = ZReportData(figures: fig, settings: const {}, openedByName: 'Owner');
    final s = giftSection(z)!;
    expect(value(s, 'Продано'), '2');
    expect(value(s, 'Сумма продаж (аванс)'), contains('13'));
    expect(s.lines.where((l) => l.indent).map((l) => l.label), containsAll(['в т.ч. наличные', 'в т.ч. карта']));
    expect(value(s, 'Аннулировано'), '1');
    expect(value(s, 'Возвращено покупателям'), startsWith('−'));
    expect(value(s, 'Влияние на кассу (нал.)'), startsWith('+'));

    // section order: after «Возвраты», before «Итог»
    final titles = z.sections().map((x) => x.title).toList();
    expect(titles.indexOf('Сертификаты'), titles.indexOf('Возвраты') + 1);

    final cash = z.sections().firstWhere((x) => x.title == 'Касса (наличные)');
    expect(cash.lines.any((l) => l.label == 'Сертификаты (нал., аванс)'), isTrue);

    final text = z.toText();
    expect(text, contains('СЕРТИФИКАТЫ'));
    expect(text, contains('аванс, не входит в выручку'));
    for (final line in text.split('\n')) {
      expect(line.length, lessThanOrEqualTo(42), reason: line);
    }
  });

  test('a sale voided in a later shift shows as a refund there and lowers its expected cash', () async {
    final gifts = GiftCardService(f.db);
    final s1 = await gifts.sell(GiftCardSaleRequest(
      code: 'GIFTBBBB01',
      amount: 5000,
      payments: const [GiftSalePaymentInput('cash', 5000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    final svc = ShiftService(f.db);
    await svc.close(shiftId: f.shift.id, userId: f.owner.id, countedCash: 15000);
    final shift2 = await svc.open(userId: f.owner.id, openingCash: 15000);
    await gifts.voidSale(s1.saleId, reason: 'Передумал', userId: f.owner.id, shiftId: shift2.id);

    final fig1 = await ShiftFigures.load(f.db, f.shift.id);
    expect(fig1.difference, 0, reason: 'a later void does not change a closed shift');
    final z1 = ZReportData(figures: fig1, settings: const {}, openedByName: 'Owner');
    expect(z1.title, 'Z-отчёт');
    expect(giftSection(z1)!.lines.any((l) => l.label == 'Аннулировано'), isFalse);

    final fig2 = await ShiftFigures.load(f.db, shift2.id);
    expect(fig2.expectedCash, 15000 - 5000);
    final z2 = ZReportData(figures: fig2, settings: const {}, openedByName: 'Owner');
    final s2 = giftSection(z2)!;
    expect(value(s2, 'Продано'), '0');
    expect(value(s2, 'Аннулировано'), '1');
    expect(value(s2, 'Влияние на кассу (нал.)'), startsWith('−'));
  });

  test('Z PDF builds with the section', () async {
    await GiftCardService(f.db).sell(GiftCardSaleRequest(
      code: 'GIFTCCCC01',
      amount: 2000,
      payments: const [GiftSalePaymentInput('transfer', 2000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    final z = await ZReportData.load(f.db, f.shift.id);
    expect(giftSection(z), isNotNull);
    expect(z.figures.report.giftCashNet, 0);
    expect(z.sections().firstWhere((x) => x.title == 'Касса (наличные)').lines.any((l) => l.label.startsWith('Сертификаты')),
        isFalse, reason: 'no cash effect -> no cash line');
    expect(await buildZReportA4Pdf(z), isNotEmpty);
    expect(await buildZReportRollPdf(z), isNotEmpty);
  });
}
