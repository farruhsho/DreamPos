import 'package:dreampos/features/warranty/warranty_act.dart';
import 'package:dreampos/features/warranty/warranty_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('claim acceptance act PDF renders with bundled fonts', () async {
    final f = await Fixture.create();
    addTearDown(f.db.close);
    final p = await f.product('Телевизор');
    final c = await f.customer('Дилноза');
    final claim = await WarrantyRepository(f.db).createClaim(
      productId: p.id,
      customerId: c.id,
      serialNumber: 'TV-001',
      problem: 'Нет изображения',
      userId: f.owner.id,
    );
    final row = (await watchClaim(f.db, claim.id).first)!;
    expect(row.productName, 'Телевизор');
    expect(row.customerName, 'Дилноза');
    expect(row.userName, 'Owner');
    final bytes = await buildClaimActPdf(row, {'store_name': 'Магазин', 'store_phone': '+998 90 000 00 00'});
    expect(bytes.length, greaterThan(1000));
  });
}
