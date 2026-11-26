// FakeSyncServer semantics (same as the Firestore backend, spec §7) and the
// transport DTOs / errors.
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_sync_server.dart';

void main() {
  const email = 'owner@example.test';
  late FakeSyncServer server;
  late FakeSyncServer t;

  setUp(() async {
    server = FakeSyncServer()..addUser(email, 'pw');
    t = server.client();
    await t.signIn(email: email, password: 'pw');
  });

  SyncChange change(String id, {int version = 1, String device = 'd1', String? changeId}) => SyncChange(
        changeId: changeId ?? 'c-$id-$version',
        entity: 'products',
        entityId: id,
        op: SyncOp.upsert,
        version: version,
        deviceId: device,
        payload: {'id': id, 'name': 'Чай', 'stock_qty': 1.5, 'price': 100, 'deleted_at': null},
      );

  test('device codes: A … Z, AA, AB; next free code; idempotent per device', () async {
    expect([for (final i in [0, 1, 25, 26, 27, 51, 52, 701, 702]) deviceCodeForIndex(i)],
        ['A', 'B', 'Z', 'AA', 'AB', 'AZ', 'BA', 'ZZ', 'AAA']);
    final st = await t.createStore(name: 'М', environment: StoreEnvironment.test);
    final codes = [
      for (var i = 0; i < 28; i++) (await t.registerDevice(storeId: st.id, deviceId: 'dev$i', name: 'n')).code,
    ];
    expect(codes.take(3), ['A', 'B', 'C']);
    expect(codes[25], 'Z');
    expect(codes[26], 'AA');
    expect(codes[27], 'AB');
    expect((await t.registerDevice(storeId: st.id, deviceId: 'dev1', name: 'n')).code, 'B');
  });

  test('push is idempotent on change_id; seq is global and ordered; pull pages by since/max', () async {
    final st = await t.createStore(name: 'М', environment: StoreEnvironment.test);
    expect((await t.storeInfo(st.id)).hasData, isFalse);
    final r1 = await t.push(storeId: st.id, deviceId: 'd1', changes: [change('p1'), change('p2')]);
    expect(r1.accepted, 2);
    final r2 = await t.push(storeId: st.id, deviceId: 'd1', changes: [change('p1'), change('p3')]);
    expect(r2.accepted, 1);
    expect(r2.maxSeq, 3);
    expect((await t.storeInfo(st.id)).hasData, isTrue);
    final page = await t.pull(storeId: st.id, since: 0, max: 2);
    expect(page.changes.map((c) => c.seq), [1, 2]);
    expect(page.lastSeq, 2);
    final rest = await t.pull(storeId: st.id, since: 2);
    expect(rest.changes.map((c) => c.entityId), ['p3']);
    expect(rest.changes.single.payload!['stock_qty'], 1.5);
    expect(rest.changes.single.payload!.containsKey('deleted_at'), isTrue);
    expect((await t.pull(storeId: st.id, since: 3)).changes, isEmpty);
  });

  test('membership: other users cannot read or write a store', () async {
    final st = await t.createStore(name: 'М', environment: StoreEnvironment.production);
    server.addUser('x@example.test', 'pw');
    final other = server.client();
    await other.signIn(email: 'x@example.test', password: 'pw');
    expect(await other.listStores(), isEmpty);
    for (final call in <Future<Object?> Function()>[
      () => other.storeInfo(st.id),
      () => other.registerDevice(storeId: st.id, deviceId: 'd', name: 'n'),
      () => other.push(storeId: st.id, deviceId: 'd', changes: [change('p')]),
      () => other.pull(storeId: st.id, since: 0),
    ]) {
      await expectLater(call(), throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.forbidden)));
    }
    server.addMember(st.id, 'x@example.test');
    expect((await other.listStores()).single.environment, StoreEnvironment.production);
  });

  test('sessions: wrong password, refresh-token rotation, revoked tokens, offline', () async {
    await expectLater(server.client().signIn(email: email, password: 'bad'),
        throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.auth)));
    final token = t.session!.refreshToken;
    final c2 = server.client();
    final s2 = await c2.restoreSession(token);
    expect(s2.refreshToken, isNot(token));
    await expectLater(server.client().restoreSession(token), throwsA(isA<SyncException>()));
    server.offline = true;
    await expectLater(c2.listStores(), throwsA(isA<SyncException>().having((e) => e.isTransient, 'transient', isTrue)));
    server.offline = false;
    expect(await c2.listStores(), isEmpty);
  });

  test('injected failures: before accept stores nothing, after accept stores the batch', () async {
    final st = await t.createStore(name: 'М', environment: StoreEnvironment.test);
    server.failNextPush = FakeFailure.beforeAccept;
    await expectLater(t.push(storeId: st.id, deviceId: 'd', changes: [change('a')]), throwsA(isA<SyncException>()));
    expect(server.maxSeq, 0);
    server.failNextPush = FakeFailure.afterAccept;
    await expectLater(t.push(storeId: st.id, deviceId: 'd', changes: [change('a')]), throwsA(isA<SyncException>()));
    expect(server.maxSeq, 1);
    expect((await t.push(storeId: st.id, deviceId: 'd', changes: [change('a')])).accepted, 0);
  });

  test('SyncChange JSON round trip; missing fields are a protocol error', () {
    final c = change('p9', version: 42);
    final back = SyncChange.fromJson(c.toJson());
    expect(back.changeId, c.changeId);
    expect(back.version, 42);
    expect(back.payload, c.payload);
    expect(() => SyncChange.fromJson({'entity': 'x'}),
        throwsA(isA<SyncException>().having((e) => e.kind, 'kind', SyncErrorKind.protocol)));
  });

  test('SyncException messages are localized in all four languages', () {
    for (final lang in supportedLanguageCodes) {
      final l = L.of(lang);
      for (final k in SyncErrorKind.values) {
        expect(SyncException(k).messageIn(l), isNotEmpty, reason: '$lang $k');
      }
      expect(StoreEnvironment.test.labelIn(l), isNotEmpty);
    }
    expect(SyncException(SyncErrorKind.network).message, 'Нет связи с сервером синхронизации. Проверьте интернет.');
    expect(SyncException(SyncErrorKind.server, detail: 'HTTP 500').message, 'Ошибка сервера синхронизации. (HTTP 500)');
    expect(SyncException(SyncErrorKind.auth, detail: 'secret-ish').message, isNot(contains('secret')));
    expect(SyncException(SyncErrorKind.forbidden).messageIn(L.of('en')), 'No access to this store.');
  });
}
