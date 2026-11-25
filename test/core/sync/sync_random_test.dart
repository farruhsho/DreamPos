// Seeded randomized convergence (spec «Tests»): 3 devices, >= 200 random
// operations (300 attempts) through the real domain services with random sync points. At the
// end every device has identical synced data and verifyAll is empty.
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/domain/errors.dart';
import 'package:dreampos/domain/services/gift_card_service.dart';
import 'package:dreampos/domain/services/receipt_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_sync_server.dart';
import 'sync_harness.dart';

void main() {
  for (final seed in [20261125, 7]) {
    test('randomized convergence, seed $seed: 3 devices, 300 random operations', () async {
      final server = FakeSyncServer()..addUser(testEmail, testPassword);
      final ds = await cluster(3, server: server);
      addTearDown(() async {
        for (final d in ds) {
          await d.close();
        }
      });
      final rnd = Random(seed);
      await ds[0].db.setSetting('loyalty_enabled', '1');
      await ds[0].db.setSetting('loyalty_earn_percent', '5');
      await ds[0].db.setSetting('loyalty_max_redeem_percent', '100');
      await ds[0].db.setSetting('allow_negative_stock', '1');
      await syncAll(ds);

      final stats = <String, int>{};
      var ok = 0, refused = 0, syncs = 0;
      var giftSeq = 0;

      T pick<T>(List<T> xs) => xs[rnd.nextInt(xs.length)];
      Future<List<T>> rows<T>(SyncDevice d, Future<List<T>> Function(AppDatabase db) q) => q(d.db);

      Future<void> op(SyncDevice d) async {
        final db = d.db;
        final products = await rows(d, (db) => (db.select(db.products)..where((p) => p.deletedAt.isNull())).get());
        final customers = await rows(d, (db) => (db.select(db.customers)..where((c) => c.deletedAt.isNull())).get());
        final suppliers = await rows(d, (db) => db.select(db.suppliers).get());
        final kind = rnd.nextInt(16);
        String name = 'noop';
        switch (kind) {
          case 0:
            name = 'product';
            await d.product('Товар ${d.name}${rnd.nextInt(100000)}', price: 500 + rnd.nextInt(20) * 100, qty: 5.0 + rnd.nextInt(20));
          case 1 || 2 || 3:
            if (products.isEmpty) break;
            name = 'sale';
            final p = pick(products);
            final qty = (1 + rnd.nextInt(3)).toDouble();
            final total = (qty * p.price).round();
            final c = customers.isEmpty || rnd.nextBool() ? null : pick(customers);
            final pays = <PaymentInput>[];
            if (c != null && rnd.nextInt(3) == 0) {
              final debt = total ~/ 2;
              pays.addAll([PaymentInput('debt', debt), PaymentInput('cash', total - debt)]);
            } else if (c != null && c.bonusBalance > 0 && rnd.nextBool()) {
              final b = min(c.bonusBalance, total);
              pays.addAll([PaymentInput('bonus', b), PaymentInput('cash', total - b)]);
            } else {
              pays.add(PaymentInput('cash', total));
            }
            await d.sell(p.id, qty, price: p.price, pays: pays, customerId: c?.id);
          case 4:
            name = 'return';
            final sales = await (db.select(db.sales)..where((s) => s.status.isIn(['completed', 'partially_returned']))).get();
            if (sales.isEmpty) break;
            final s = pick(sales);
            final items = await (db.select(db.saleItems)..where((i) => i.saleId.equals(s.id))).get();
            final it = items.firstWhere((i) => i.qty - i.returnedQty > 0, orElse: () => items.first);
            await d.sales.returnItems(
                saleId: s.id,
                lines: [ReturnLineInput(it.id, 1)],
                refundMethod: s.customerId != null && rnd.nextBool() ? 'debt' : 'cash',
                userId: d.userId,
                shiftId: d.shift!.id);
          case 5:
            name = 'void';
            final sales = await (db.select(db.sales)..where((s) => s.status.equals('completed'))).get();
            if (sales.isEmpty) break;
            await d.sales.voidSale(pick(sales).id, userId: d.userId, reason: 'ошибка', shiftId: d.shift!.id);
          case 6:
            name = 'customer';
            await d.customer('Клиент ${d.name}${rnd.nextInt(100000)}');
          case 7:
            if (customers.isEmpty) break;
            final c = pick(customers);
            if (c.debtBalance > 0) {
              name = 'payDebt';
              await d.customers.payDebt(
                  customerId: c.id,
                  amount: 1 + rnd.nextInt(c.debtBalance),
                  method: 'cash',
                  userId: d.userId,
                  shiftId: d.shift!.id);
            } else {
              name = 'bonus';
              await d.customers.adjustBonus(customerId: c.id, delta: 100 + rnd.nextInt(5) * 100, userId: d.userId, reason: 'подарок');
            }
          case 8:
            name = 'supplier';
            await d.supplier('Поставщик ${d.name}${rnd.nextInt(100000)}');
          case 9:
            if (suppliers.isEmpty || products.isEmpty) break;
            name = 'receipt';
            await d.receipts.post(
                lines: [ReceiptLineInput(productId: pick(products).id, qty: 1.0 + rnd.nextInt(10), unitCost: 300 + rnd.nextInt(5) * 100)],
                supplierId: pick(suppliers).id,
                userId: d.userId);
          case 10:
            if (suppliers.isEmpty) break;
            final s = pick(suppliers);
            if (rnd.nextBool()) {
              final pays = await (db.select(db.supplierPayments)..where((p) => p.cancelledAt.isNull())).get();
              if (pays.isEmpty) break;
              name = 'cancelPayment';
              await d.ledger.cancelPayment(pick(pays).id, reason: 'отмена', userId: d.userId);
            } else {
              name = 'supplierPay';
              await d.ledger.pay(
                  supplierId: s.id, amount: 100 + rnd.nextInt(10) * 100, method: 'transfer', userId: d.userId, allowOverpay: true);
            }
          case 11:
            final receipts = await (db.select(db.goodsReceipts)..where((r) => r.status.equals('posted'))).get();
            if (receipts.isEmpty) break;
            name = 'reverseReceipt';
            await d.receipts.reverse(pick(receipts).id, reason: 'ошибка', userId: d.userId);
          case 12:
            name = 'giftSell';
            final amount = 1000 + rnd.nextInt(5) * 1000;
            await d.gifts.sell(GiftCardSaleRequest(
                code: 'G${d.name}${giftSeq++}X$seed',
                amount: amount,
                payments: [GiftSalePaymentInput(rnd.nextBool() ? 'cash' : 'card', amount)],
                cashierId: d.userId,
                shiftId: d.shift!.id));
          case 13:
            final cards = await (db.select(db.giftCards)..where((g) => g.status.equals('active'))).get();
            if (cards.isEmpty || products.isEmpty) break;
            name = 'giftRedeem';
            final g = pick(cards);
            final p = pick(products);
            final amount = min(g.balance, p.price);
            if (amount <= 0) break;
            await d.sell(p.id, 1, price: p.price, pays: [
              PaymentInput('gift_card', amount, reference: g.code),
              if (p.price > amount) PaymentInput('cash', p.price - amount),
            ]);
          case 14:
            if (products.isEmpty) break;
            final p = pick(products);
            switch (rnd.nextInt(4)) {
              case 0:
                name = 'writeOff';
                await d.stock.writeOff(productId: p.id, qty: 1, reason: 'бой', userId: d.userId);
              case 1:
                name = 'setStock';
                await d.stock.setStock(productId: p.id, newQty: rnd.nextInt(30).toDouble(), reason: 'пересчёт', userId: d.userId);
              case 2:
                name = 'editPrice';
                await (db.update(db.products)..where((t) => t.id.equals(p.id))).write(ProductsCompanion(
                    price: Value(500 + rnd.nextInt(30) * 100), name: Value('${p.name}*'), updatedAt: Value(DateTime.now())));
              default:
                name = 'deleteProduct';
                await (db.update(db.products)..where((t) => t.id.equals(p.id)))
                    .write(ProductsCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
            }
          default:
            name = 'setting';
            await db.setSetting(pick(['receipt_footer', 'store_phone', 'store_address']), 'v${rnd.nextInt(1000)}');
        }
        stats[name] = (stats[name] ?? 0) + 1;
      }

      for (var i = 0; i < 300; i++) {
        final d = pick(ds);
        try {
          await op(d);
          ok++;
        } on BusinessException {
          refused++;
        }
        if (rnd.nextInt(6) == 0) {
          await pick(ds).syncNow();
          syncs++;
        }
      }
      await syncAll(ds);

      final first = await dump(ds[0].db);
      for (final d in ds.skip(1)) {
        expect(dumpDiff(first, await dump(d.db)), isNull, reason: 'A vs ${d.name} (seed $seed, $stats)');
      }
      for (final d in ds) {
        expect(await SyncAggregates.verifyAll(d.db), isEmpty, reason: '${d.name} seed $seed');
        expect(await d.sync.pendingCount(), 0);
      }
      // the run did real work
      expect(ok - (stats['noop'] ?? 0), greaterThanOrEqualTo(200), reason: 'ok=$ok refused=$refused $stats');
      expect(syncs, greaterThan(10));
      expect((first['sales'] ?? []).length, greaterThan(10));
      expect({for (final r in first['sales']!) r['device_code']}, containsAll(['A', 'B', 'C']));
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
