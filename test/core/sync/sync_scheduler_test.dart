// Scheduler (spec §9: periodic + debounced after local writes, backoff) and
// the Riverpod providers.
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../../support/fake_sync_server.dart';
import 'sync_harness.dart';

const _fast = SyncSchedule(
  period: Duration(milliseconds: 300),
  debounce: Duration(milliseconds: 60),
  backoffMin: Duration(milliseconds: 100),
  backoffMax: Duration(milliseconds: 400),
);

Future<void> waitFor(Future<bool> Function() cond, {Duration timeout = const Duration(seconds: 5)}) async {
  final end = DateTime.now().add(timeout);
  while (!await cond()) {
    if (DateTime.now().isAfter(end)) fail('condition not reached in $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('backoff 30 s → 5 min', () {
    const s = SyncSchedule();
    expect([for (final f in [1, 2, 3, 4, 5, 6, 20]) s.backoff(f).inSeconds], [30, 60, 120, 240, 300, 300, 300]);
  });

  test('the scheduler never runs while sync is not configured', () async {
    final db = memoryDb();
    final s = SyncService(db, schedulerEnabled: true, schedule: _fast, transportFactory: (_) => FakeSyncServer());
    addTearDown(() async {
      s.dispose();
      await db.close();
    });
    await s.init();
    expect(s.status.phase, SyncPhase.off);
    expect(s.schedulerRunning, isFalse);
    expect(runningInFlutterTest, isTrue);
  });

  test('debounced sync after a local write, periodic pull, backoff, stop on disconnect', () async {
    final server = FakeSyncServer()..addUser(testEmail, testPassword);
    final db = memoryDb();
    final s = SyncService(db, schedulerEnabled: true, schedule: _fast, transportFactory: (_) => server.client());
    addTearDown(() async {
      s.dispose();
      await db.close();
    });
    await s.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
    final info = await s.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
    expect(s.schedulerRunning, isTrue);
    final seq0 = server.maxSeq;

    // local write → pushed by the debounced trigger
    await db.into(db.categories).insert(CategoriesCompanion.insert(id: newId(), name: 'Напитки'));
    await waitFor(() async => server.maxSeq > seq0);
    await waitFor(() async => await s.pendingCount() == 0);

    // another register pushes; the periodic tick pulls it
    final b = SyncDevice.create(server, 'B');
    addTearDown(b.close);
    await b.signIn();
    await b.sync.joinStore(info.id);
    final catId = newId();
    await b.db.into(b.db.categories).insert(CategoriesCompanion.insert(id: catId, name: 'Хлеб'));
    await b.syncNow();
    await waitFor(() async => (await (db.select(db.categories)..where((c) => c.id.equals(catId))).get()).isNotEmpty);

    // offline: status offline, retry time set; recovers after the backoff
    server.offline = true;
    await (db.update(db.categories)..where((c) => c.id.equals(catId))).write(const CategoriesCompanion(name: Value('Хлеб!')));
    await waitFor(() async => s.status.phase == SyncPhase.offline);
    expect(s.status.nextRetryAt, isNotNull);
    server.offline = false;
    await waitFor(() async => s.status.phase == SyncPhase.idle && s.status.pending == 0);

    await s.disconnect();
    expect(s.schedulerRunning, isFalse);
    expect(s.status.phase, SyncPhase.off);
  });

  test('providers: off by default, scheduler disabled in tests, factory hook plugs a transport', () async {
    final server = FakeSyncServer()..addUser(testEmail, testPassword);
    final db = memoryDb();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncTransportFactoryProvider.overrideWithValue((_) => server.client()),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    expect(container.read(syncSchedulerEnabledProvider), isFalse);
    final sub = container.listen(syncStatusProvider, (_, _) {});
    addTearDown(sub.close);
    expect(container.read(syncStatusProvider).phase, SyncPhase.off);
    expect(container.read(syncTransportProvider), isNull);

    final svc = container.read(syncServiceProvider);
    expect(svc.schedulerEnabled, isFalse);
    await svc.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
    await svc.createStoreAndUpload(name: 'Тестовый', environment: StoreEnvironment.test);
    await waitFor(() async => container.read(syncStatusProvider).phase == SyncPhase.idle);
    final st = container.read(syncStatusProvider);
    expect(st.storeName, 'Тестовый');
    expect(st.deviceCode, 'A');
    expect(st.environment, StoreEnvironment.test);
    expect(st.lastSyncAt, isNotNull);
    expect(container.read(syncTransportProvider), isNotNull);
    expect(svc.schedulerRunning, isFalse);
  });

  test('without a transport factory sign-in reports «not configured»', () async {
    final db = memoryDb();
    final s = SyncService(db);
    addTearDown(() async {
      s.dispose();
      await db.close();
    });
    await expectLater(s.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword),
        throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.notConfigured)));
  });
}
