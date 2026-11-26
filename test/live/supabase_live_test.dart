// LIVE smoke test against a real Supabase TEST project (docs/SYNC_SETUP.md).
//
// Skipped unless all four environment variables are set in the shell that runs
// it, so CI and the normal `flutter test` never touch the network:
//   DREAMPOS_SB_URL       https://<project>.supabase.co
//   DREAMPOS_SB_ANON_KEY  the project's anon (public) key
//   DREAMPOS_SB_EMAIL     a cloud account of the TEST project
//   DREAMPOS_SB_PASSWORD  its password (typed by the owner; never stored)
//
// Every run creates a NEW store with environment 'test' named
// «Живой тест <timestamp>». Nothing is deleted (the server never deletes).
//
// Run:  flutter test test/live/supabase_live_test.dart
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/doc_number.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/supabase_transport.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/domain/services/stock_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/sync/sync_harness.dart' show dump, dumpDiff;
import '../helpers.dart';

String? _env(String k) {
  final v = Platform.environment[k]?.trim();
  return (v == null || v.isEmpty) ? null : v;
}

void main() {
  final url = _env('DREAMPOS_SB_URL');
  final anon = _env('DREAMPOS_SB_ANON_KEY');
  final email = _env('DREAMPOS_SB_EMAIL');
  final password = _env('DREAMPOS_SB_PASSWORD');
  final missing = [
    if (url == null) 'DREAMPOS_SB_URL',
    if (anon == null) 'DREAMPOS_SB_ANON_KEY',
    if (email == null) 'DREAMPOS_SB_EMAIL',
    if (password == null) 'DREAMPOS_SB_PASSWORD',
  ];
  final skip = missing.isEmpty ? null : 'live Supabase test: set ${missing.join(', ')}';

  test('two registers sync through the real Supabase test project', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final endpoint = SyncEndpoint(url: url!, anonKey: anon!);
    SyncTransport factory(SyncEndpoint e) => SupabaseTransport(e);

    final a = memoryDb();
    final b = memoryDb();
    final syncA = SyncService(a, transportFactory: factory, deviceName: 'Live A');
    final syncB = SyncService(b, transportFactory: factory, deviceName: 'Live B');
    addTearDown(() async {
      syncA.dispose();
      syncB.dispose();
      await a.close();
      await b.close();
    });

    // Register A: owner + product with 20 pcs, then creates the cloud store.
    final owner = await AuthService(a).createUser(name: 'Владелец', role: Role.owner, pin: '2580');
    final productId = newId();
    await a.into(a.products).insert(ProductsCompanion.insert(id: productId, name: 'Живой тест товар', price: 1000));
    await StockService(a).receive(productId: productId, qty: 20, unitCost: 600, userId: owner.id);

    await syncA.signIn(endpoint: endpoint, email: email!, password: password!);
    final stamp = DateTime.now().toIso8601String().substring(0, 19);
    final store = await syncA.createStoreAndUpload(name: 'Живой тест $stamp', environment: StoreEnvironment.test);
    expect(store.environment, StoreEnvironment.test);

    // Register B: empty database joins and downloads everything.
    await syncB.signIn(endpoint: endpoint, email: email, password: password);
    await syncB.joinStore(store.id);
    final codeA = await a.deviceCode();
    final codeB = await b.deviceCode();
    expect(codeA, isNotNull);
    expect(codeB, isNotNull);
    expect(codeA, isNot(codeB));
    expect((await (b.select(b.users)).get()).map((u) => u.id), contains(owner.id));

    // Each register opens its own shift and sells offline.
    Future<CheckoutResult> sell(AppDatabase db, double qty) async {
      final shift = await ShiftService(db).open(userId: owner.id, openingCash: 0, registerId: 'live-${db.hashCode}');
      return SaleService(db).checkout(CheckoutRequest(
        lines: [CheckoutLine(productId: productId, qty: qty, unitPrice: 1000)],
        payments: [PaymentInput('cash', (qty * 1000).round())],
        cashierId: owner.id,
        shiftId: shift.id,
      ));
    }

    await sell(a, 2);
    await sell(b, 3);

    for (var round = 0; round < 2; round++) {
      await syncA.syncNow();
      await syncB.syncNow();
    }

    for (final db in [a, b]) {
      final p = await (db.select(db.products)..where((t) => t.id.equals(productId))).getSingle();
      expect(p.stockQty, 15, reason: 'stock after 2 + 3 sold on two registers');
      final nos = [for (final s in await db.select(db.sales).get()) docNo(s.number, s.deviceCode)]..sort();
      expect(nos, ['$codeA-1', '$codeB-1']..sort());
      expect(await SyncAggregates.verifyAll(db), isEmpty);
    }
    expect(dumpDiff(await dump(a), await dump(b)), isNull, reason: 'both registers hold identical synced data');

    // Idempotency: another round changes nothing.
    final before = await dump(a);
    await syncA.syncNow();
    await syncB.syncNow();
    expect(dumpDiff(before, await dump(a)), isNull);

    // ignore: avoid_print
    print('LIVE OK: store "${store.name}" (${store.id}), registers $codeA and $codeB');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
