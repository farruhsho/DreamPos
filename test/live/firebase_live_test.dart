// LIVE smoke test against a real Firebase TEST project (D-026,
// docs/SYNC_SETUP.md). The rules from firebase/firestore.rules must be
// deployed and Email/Password sign-in enabled.
//
// Skipped unless all four environment variables are set in the shell that runs
// it, so CI and the normal `flutter test` never touch the network:
//   DREAMPOS_FB_PROJECT   the Firebase project id (e.g. dreampos-test-uz26)
//   DREAMPOS_FB_API_KEY   the project's Web API key
//   DREAMPOS_FB_EMAIL     an account of the TEST project (Authentication)
//   DREAMPOS_FB_PASSWORD  its password (typed by the owner; never stored)
//
// Every run creates a NEW store with environment 'test' named
// «Живой тест <timestamp>». Nothing is deleted (the rules forbid deletes).
//
// Anonymous mode (no password anywhere): set DREAMPOS_FB_ANON=1 instead of
// EMAIL/PASSWORD. Requires the Anonymous provider to be enabled temporarily;
// the test gets a refresh token from accounts:signUp and puts it into each
// register's sync_state, exactly where a password sign-in would store it.
//
// Run:  flutter test test/live/firebase_live_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/doc_number.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/firebase_transport.dart';
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
  final project = _env('DREAMPOS_FB_PROJECT');
  final apiKey = _env('DREAMPOS_FB_API_KEY');
  final email = _env('DREAMPOS_FB_EMAIL');
  final password = _env('DREAMPOS_FB_PASSWORD');
  final anon = _env('DREAMPOS_FB_ANON') == '1';
  final missing = [
    if (project == null) 'DREAMPOS_FB_PROJECT',
    if (apiKey == null) 'DREAMPOS_FB_API_KEY',
    if (!anon && email == null) 'DREAMPOS_FB_EMAIL',
    if (!anon && password == null) 'DREAMPOS_FB_PASSWORD',
  ];
  final skip = missing.isEmpty ? null : 'live Firebase test: set ${missing.join(', ')}';

  test('two registers sync through the real Firebase test project', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final endpoint = SyncEndpoint(projectId: project!, apiKey: apiKey!);
    SyncTransport factory(SyncEndpoint e) => FirebaseTransport(e);

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

    // Anonymous: one cloud identity used by both registers (like one owner account).
    String? anonToken;
    if (anon) {
      final client = HttpClient();
      final req = await client.postUrl(Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'returnSecureToken': true}));
      final resp = await req.close();
      final body = jsonDecode(await resp.transform(utf8.decoder).join()) as Map<String, dynamic>;
      client.close();
      expect(resp.statusCode, 200, reason: 'anonymous sign-up: $body');
      anonToken = body['refreshToken'] as String;
    }
    Future<void> signIn(SyncService s, AppDatabase db) async {
      if (!anon) return s.signIn(endpoint: endpoint, email: email!, password: password!).then((_) {});
      for (final e in {SyncKeys.projectId: project, SyncKeys.apiKey: apiKey, SyncKeys.refreshToken: anonToken!}.entries) {
        await db.into(db.syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: e.key, value: e.value));
      }
    }

    await signIn(syncA, a);
    final stamp = DateTime.now().toIso8601String().substring(0, 19);
    final store = await syncA.createStoreAndUpload(name: 'Живой тест $stamp', environment: StoreEnvironment.test);
    expect(store.environment, StoreEnvironment.test);

    // Register B: empty database joins and downloads everything.
    await signIn(syncB, b);
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

    // A re-push of an already stored change is a no-op on the server.
    final t = factory(endpoint);
    if (anon) {
      await t.restoreSession(anonToken!);
    } else {
      await t.signIn(email: email!, password: password!);
    }
    final again = await t.pull(storeId: store.id, since: 0, max: 1);
    final res = await t.push(
        storeId: store.id, deviceId: again.changes.single.deviceId, changes: [again.changes.single]);
    expect(res.accepted, 0);

    // ignore: avoid_print
    print('LIVE OK: store "${store.name}" (${store.id}), registers $codeA and $codeB');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
