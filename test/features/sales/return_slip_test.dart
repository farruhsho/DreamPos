import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/features/sales/return_slip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('return slip PDF renders with bundled fonts', () async {
    final f = await Fixture.create();
    addTearDown(f.db.close);
    final sales = SaleService(f.db);
    final a = await f.product('Товар');
    final sale = (await sales.checkout(
      CheckoutRequest(
        lines: [CheckoutLine(productId: a.id, qty: 1, unitPrice: 1000)],
        payments: [PaymentInput('cash', 1000)],
        cashierId: f.owner.id,
        shiftId: f.shift.id,
      ),
    )).sale;
    final it = await (f.db.select(f.db.saleItems)..where((i) => i.saleId.equals(sale.id))).getSingle();
    final ret = await sales.returnItems(
      saleId: sale.id,
      lines: [ReturnLineInput(it.id, 1)],
      refundMethod: 'cash',
      userId: f.owner.id,
      shiftId: f.shift.id,
      reason: 'Брак',
      restock: false,
    );
    final data = await ReturnSlipData.load(f.db, ret.id);
    expect(data.lines.single.$1, 'Товар');
    final bytes = await buildReturnSlipPdf(data);
    expect(bytes.length, greaterThan(1000));
    expect((await f.reload(a)).stockQty, 9, reason: 'restock off keeps stock unchanged');
  });
}
