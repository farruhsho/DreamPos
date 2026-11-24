import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:dreampos/features/warranty/warranty_logic.dart';
import 'package:dreampos/features/warranty/warranty_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  group('workflow rules', () {
    test('allowed transitions', () {
      expect(canTransition(WStatus.received, WStatus.inRepair), isTrue);
      expect(canTransition(WStatus.received, WStatus.rejected), isTrue);
      expect(canTransition(WStatus.inRepair, WStatus.replaced), isTrue);
      expect(canTransition(WStatus.inRepair, WStatus.refunded), isTrue);
      for (final s in WStatus.resolved) {
        expect(canTransition(s, WStatus.returnedToClient), isTrue, reason: s);
        expect(canTransition(s, WStatus.inRepair), isFalse, reason: s);
      }
      expect(canTransition(WStatus.received, WStatus.returnedToClient), isFalse);
      expect(canTransition(WStatus.inRepair, WStatus.received), isFalse);
      expect(nextStatuses(WStatus.returnedToClient), isEmpty);
      expect(isClosed(WStatus.returnedToClient), isTrue);
      expect(resolutionRequired(WStatus.rejected), isTrue);
      expect(resolutionRequired(WStatus.inRepair), isFalse);
    });

    test('warranty state counts the whole last day', () {
      final until = DateTime(2026, 5, 10);
      expect(warrantyState(null, DateTime(2026)), WarrantyState.none);
      expect(warrantyState(until, DateTime(2026, 5, 10, 23, 59)), WarrantyState.active);
      expect(warrantyState(until, DateTime(2026, 5, 11)), WarrantyState.expired);
    });
  });

  group('repository', () {
    late Fixture f;
    late WarrantyRepository repo;
    setUp(() async {
      f = await Fixture.create();
      repo = WarrantyRepository(f.db);
    });
    tearDown(() => f.db.close());

    Future<(Sale, SaleItem, Product, Customer)> sold({int warrantyMonths = 12}) async {
      final p = await f.product('Смартфон', price: 300000, stock: 3);
      await (f.db.update(
        f.db.products,
      )..where((t) => t.id.equals(p.id))).write(ProductsCompanion(warrantyMonths: Value(warrantyMonths)));
      final c = await f.customer('Алишер');
      final r = await SaleService(f.db).checkout(
        CheckoutRequest(
          lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 300000)],
          payments: [PaymentInput('card', 300000)],
          cashierId: f.owner.id,
          shiftId: f.shift.id,
          customerId: c.id,
        ),
      );
      final it = await (f.db.select(f.db.saleItems)..where((i) => i.saleId.equals(r.sale.id))).getSingle();
      return (r.sale, it, p, c);
    }

    test('create by receipt: numbering, lookup, audit and search', () async {
      final (sale, item, p, c) = await sold();
      final found = (await repo.findSale(sale.number))!;
      expect(found.items.single.id, item.id);
      expect(found.customer!.id, c.id);
      expect(warrantyState(found.items.single.warrantyUntil, DateTime.now()), WarrantyState.active);
      expect(await repo.findSale(9999), isNull);

      final c1 = await repo.createClaim(
        saleItemId: item.id,
        customerId: c.id,
        serialNumber: ' IMEI-123 ',
        problem: 'Не заряжается',
        userId: f.owner.id,
      );
      final c2 = await repo.createClaim(productId: p.id, problem: 'Трещина экрана', userId: f.owner.id);
      expect(c1.number, 1);
      expect(c2.number, 2);
      expect(c1.productId, p.id, reason: 'product taken from the sale item');
      expect(c1.serialNumber, 'IMEI-123');
      expect(c1.status, WStatus.received);

      final audit = await (f.db.select(f.db.auditLog)..where((a) => a.action.equals('warranty.create'))).get();
      expect(audit, hasLength(2));

      final bySerial = await watchClaims(f.db, const ClaimsFilter(query: 'imei')).first;
      expect(bySerial.single.claim.id, c1.id);
      expect(bySerial.single.saleNumber, sale.number);
      expect(bySerial.single.customerName, 'Алишер');
      expect(bySerial.single.warrantyUntil, isNotNull);
      final byCustomer = await watchClaims(f.db, const ClaimsFilter(query: 'алишер')).first;
      expect(byCustomer.single.claim.id, c1.id);
      final byReceipt = await watchClaims(f.db, ClaimsFilter(query: '${sale.number}')).first;
      expect(byReceipt.map((r) => r.claim.id), contains(c1.id));
      final byProduct = await watchClaims(f.db, const ClaimsFilter(query: 'смартфон')).first;
      expect(byProduct, hasLength(2));
    });

    test('open claim for the same sold item is detected', () async {
      final (_, item, _, c) = await sold();
      expect(await repo.openClaimFor(item.id), isNull);
      final claim = await repo.createClaim(
        saleItemId: item.id,
        customerId: c.id,
        problem: 'Не включается',
        userId: f.owner.id,
      );
      expect((await repo.openClaimFor(item.id))!.id, claim.id);
      await repo.changeStatus(claimId: claim.id, to: WStatus.rejected, userId: f.owner.id, note: 'Нет дефекта');
      expect(await repo.openClaimFor(item.id), isNull, reason: 'decided claims are not "open"');
    });

    test('in-repair note does not become the resolution', () async {
      final p = await f.product('B');
      final c = await repo.createClaim(productId: p.id, problem: 'Шумит', userId: f.owner.id);
      await repo.changeStatus(claimId: c.id, to: WStatus.inRepair, userId: f.owner.id, note: 'СЦ, 7 дней');
      final w = await (f.db.select(f.db.warrantyClaims)..where((x) => x.id.equals(c.id))).getSingle();
      expect(w.resolution, isNull);
    });

    test('validation', () async {
      expect(() => repo.createClaim(problem: 'x', userId: f.owner.id), throwsA(isA<BusinessException>()));
      final p = await f.product('A');
      expect(
        () => repo.createClaim(productId: p.id, problem: '  ', userId: f.owner.id),
        throwsA(isA<BusinessException>()),
      );
    });

    test('status transitions are enforced, audited and need a resolution', () async {
      final p = await f.product('A');
      final c = await repo.createClaim(productId: p.id, problem: 'Шумит', userId: f.owner.id);
      Future<WarrantyClaim> reload() => (f.db.select(f.db.warrantyClaims)..where((w) => w.id.equals(c.id))).getSingle();

      expect(
        () => repo.changeStatus(claimId: c.id, to: WStatus.returnedToClient, userId: f.owner.id),
        throwsA(isA<BusinessException>()),
      );
      await repo.changeStatus(claimId: c.id, to: WStatus.inRepair, userId: f.owner.id, note: 'СЦ Samsung');
      expect((await reload()).status, WStatus.inRepair);

      expect(
        () => repo.changeStatus(claimId: c.id, to: WStatus.rejected, userId: f.owner.id),
        throwsA(isA<BusinessException>()),
        reason: 'resolution required',
      );
      await repo.changeStatus(claimId: c.id, to: WStatus.rejected, userId: f.owner.id, note: 'Следы удара');
      await repo.changeStatus(
        claimId: c.id,
        to: WStatus.returnedToClient,
        userId: f.owner.id,
        note: 'Выдано лично клиенту',
      );
      final done = await reload();
      expect(done.status, WStatus.returnedToClient);
      expect(done.resolution, 'Следы удара', reason: 'a hand-over note must not overwrite the decision');
      expect(
        () => repo.changeStatus(claimId: c.id, to: WStatus.inRepair, userId: f.owner.id),
        throwsA(isA<BusinessException>()),
      );

      final hist = await watchClaimHistory(f.db, c.id).first;
      expect(hist.map((h) => h.$1.action), [
        'warranty.create',
        'warranty.status',
        'warranty.status',
        'warranty.status',
      ]);
      expect(hist[1].$1.details, contains('received→in_repair'));
      expect(hist[1].$2, 'Owner');
    });

    test('replacement writes off one unit; failure rolls back the status', () async {
      final p = await f.product('A', stock: 1);
      final stock = StockService(f.db);
      final c = await repo.createClaim(productId: p.id, problem: 'Брак', userId: f.owner.id);
      await repo.changeStatus(
        claimId: c.id,
        to: WStatus.replaced,
        userId: f.owner.id,
        note: 'Замена',
        writeOff: true,
        stock: stock,
      );
      expect((await f.reload(p)).stockQty, 0);
      final mv = await (f.db.select(f.db.stockMovements)..where((m) => m.productId.equals(p.id))).get();
      expect(mv.single.reason, 'Гарантийная замена');
      expect(mv.single.type, 'writeoff');

      // no stock left: second replacement must fail and keep the status
      final c2 = await repo.createClaim(productId: p.id, problem: 'Брак 2', userId: f.owner.id);
      await expectLater(
        repo.changeStatus(
          claimId: c2.id,
          to: WStatus.replaced,
          userId: f.owner.id,
          note: 'Замена',
          writeOff: true,
          stock: stock,
        ),
        throwsA(isA<BusinessException>()),
      );
      final after = await (f.db.select(f.db.warrantyClaims)..where((w) => w.id.equals(c2.id))).getSingle();
      expect(after.status, WStatus.received);
      expect((await f.reload(p)).stockQty, 0);

      expect(
        () => repo.changeStatus(claimId: c2.id, to: WStatus.inRepair, userId: f.owner.id, writeOff: true, stock: stock),
        throwsA(isA<BusinessException>()),
        reason: 'write-off only on replacement',
      );
    });

    test('group filters', () async {
      final p = await f.product('A');
      final a = await repo.createClaim(productId: p.id, problem: 'a', userId: f.owner.id);
      final b = await repo.createClaim(productId: p.id, problem: 'b', userId: f.owner.id);
      await repo.changeStatus(claimId: b.id, to: WStatus.refunded, userId: f.owner.id, note: 'деньги');
      Future<List<String>> ids(ClaimGroup g) async =>
          (await watchClaims(f.db, ClaimsFilter(group: g)).first).map((r) => r.claim.id).toList();
      expect(await ids(ClaimGroup.all), hasLength(2));
      expect(await ids(ClaimGroup.open), [a.id]);
      expect(await ids(ClaimGroup.resolved), [b.id]);
      expect(await ids(ClaimGroup.closed), isEmpty);
    });
  });
}
