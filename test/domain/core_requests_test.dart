import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:dreampos/app/background_jobs.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/db_location.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/settings/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late Fixture f;
  setUp(() async => f = await Fixture.create());
  tearDown(() => f.db.close());

  test('verifyApprover does not log in and throttles failures separately', () async {
    final auth = AuthService(f.db);
    final before = (await (f.db.select(f.db.users)..where((u) => u.id.equals(f.owner.id))).getSingle())
        .lastLoginAt;
    final u = await auth.verifyApprover('2580');
    expect(u.id, f.owner.id);
    final after = (await (f.db.select(f.db.users)..where((u) => u.id.equals(f.owner.id))).getSingle())
        .lastLoginAt;
    expect(after, before);
    final logins = await (f.db.select(f.db.auditLog)..where((a) => a.action.equals('auth.login'))).get();
    expect(logins, isEmpty);
    for (var i = 0; i < AuthService.maxAttempts; i++) {
      await expectLater(auth.verifyApprover('9999'), throwsA(isA<BusinessException>()));
    }
    await expectLater(auth.verifyApprover('2580'),
        throwsA(isA<BusinessException>().having((e) => e.code, 'code', 'throttle')));
    // normal login is unaffected by approval failures
    expect((await auth.loginWithPin('2580')).id, f.owner.id);
  });

  test('createUser stores plan and commission', () async {
    final u = await AuthService(f.db).createUser(
        name: 'Seller', role: Role.cashier, pin: '4826', salesPlan: 500000, commissionPercent: 1.5);
    expect(u.salesPlan, 500000);
    expect(u.commissionPercent, 1.5);
  });

  test('gift card code is normalised at checkout', () async {
    final p = await f.product('Bag', price: 3000, stock: 5);
    await f.db.into(f.db.giftCards).insert(GiftCardsCompanion.insert(
        id: newId(), code: 'ABCD2345EFGH', initialAmount: 5000, balance: 5000));
    await SaleService(f.db).checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 3000)],
      payments: [PaymentInput('gift_card', 3000, reference: ' abcd-2345 efgh ')],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    expect((await f.db.select(f.db.giftCards).getSingle()).balance, 2000);
  });

  test('shift gross profit nets out returns at cost', () async {
    final p = await f.product('X', price: 1000, cost: 600, stock: 10);
    final sales = SaleService(f.db);
    final res = await sales.checkout(CheckoutRequest(
      lines: [CheckoutLine(productId: p.id, qty: 2, unitPrice: 1000)],
      payments: [PaymentInput('cash', 2000)],
      cashierId: f.owner.id,
      shiftId: f.shift.id,
    ));
    final item = (await f.db.select(f.db.saleItems).get()).single;
    await sales.returnItems(
        saleId: res.sale.id, lines: [ReturnLineInput(item.id, 1)], refundMethod: 'cash',
        userId: f.owner.id, shiftId: f.shift.id);
    final rep = await ShiftService(f.db).report(f.shift.id);
    expect(rep.returnedCost, 600);
    expect(rep.grossProfit, 400); // one unit kept: 1000 - 600
  });

  test('auto backup runs only when enabled and due', () async {
    final tmp = await Directory.systemTemp.createTemp('dp_bk');
    addTearDown(() => tmp.delete(recursive: true));
    final svc = BackupService(f.db, () async => tmp, dbPath: () async => '${tmp.path}/x.sqlite');
    final now = DateTime(2026, 11, 24, 12);
    expect(await runAutoBackupIfDue(f.db, now: now, service: svc), isFalse);
    await f.db.setSetting('auto_backup_daily', '1');
    expect(await runAutoBackupIfDue(f.db, now: now, service: svc), isTrue);
    expect(await runAutoBackupIfDue(f.db, now: now.add(const Duration(hours: 2)), service: svc), isFalse);
    expect(await runAutoBackupIfDue(f.db, now: now.add(const Duration(hours: 25)), service: svc), isTrue);
    final files = await svc.list();
    expect(files.length, 2);
    expect(await DbLocation.isSqliteFile(files.first.file), isTrue);
  });

  test('isSqliteFile rejects garbage', () async {
    final tmp = await Directory.systemTemp.createTemp('dp_rs');
    addTearDown(() => tmp.delete(recursive: true));
    final f2 = File('${tmp.path}/bad.sqlite')..writeAsStringSync('not a database' * 20);
    expect(await DbLocation.isSqliteFile(f2), isFalse);
    expect(Value(1).present, isTrue);
  });

  test('cash rounding rounds down only for cash-only payments, lines stay exact', () async {
    await f.db.setSetting('cash_rounding', '100');
    final a = await f.product('A', price: 1234, stock: 10);
    final b = await f.product('B', price: 2345, stock: 10);
    final sales = SaleService(f.db);
    CheckoutRequest req(List<PaymentInput> pays) => CheckoutRequest(
          lines: [
            CheckoutLine(productId: a.id, qty: 1, unitPrice: 1234),
            CheckoutLine(productId: b.id, qty: 1, unitPrice: 2345),
          ],
          payments: pays,
          cashierId: f.owner.id,
          shiftId: f.shift.id,
          applyCashRounding: true,
        );
    final q = await sales.quote(req([PaymentInput('cash', 4000)]));
    expect(q.total, 3500);
    expect(q.roundingDiscount, 79);
    final res = await sales.checkout(req([PaymentInput('cash', 4000)]));
    expect(res.sale.total, 3500);
    expect(res.changeDue, 500);
    final items = await (f.db.select(f.db.saleItems)..where((i) => i.saleId.equals(res.sale.id))).get();
    expect(items.fold<int>(0, (s, i) => s + i.total), 3500);
    // card payment: no rounding
    final res2 = await sales.checkout(req([PaymentInput('card', 3579)]));
    expect(res2.sale.total, 3579);
  });
}
