// SupabaseTransport (D-025, spec §8) against http/testing.dart MockClient:
// sign-in, refresh on 401, the request of every RPC, error mapping,
// HTTPS-only. Plus a contract test: the real SyncService on two in-memory
// databases talks through SupabaseTransport to a PostgREST/GoTrue emulator
// backed by FakeSyncServer. No real server is ever contacted.
import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/supabase_transport.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/domain/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers.dart';
import '../../support/fake_sync_server.dart';
import 'sync_harness.dart' show dump, dumpDiff;

const _url = 'https://proj.example.test';
const _anon = 'anon-test-key';
const _endpoint = SyncEndpoint(url: _url, anonKey: _anon);
const _password = 'pw-never-stored';

http.Response _json(Object? body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, Object?> _tokenBody(String access, String refresh) => {
      'access_token': access,
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': refresh,
      'user': {'id': 'user-1', 'email': 'owner@example.test'},
    };

TypeMatcher<SyncException> _kind(SyncErrorKind k) => isA<SyncException>().having((e) => e.kind, 'kind', k);

/// Recording mock: [respond] decides the response, every request is kept.
class _Mock {
  _Mock(this.respond);
  final FutureOr<http.Response> Function(http.Request r) respond;
  final requests = <http.Request>[];
  late final client = MockClient((r) async {
    requests.add(r);
    return respond(r);
  });

  SupabaseTransport transport({String url = _url, Duration timeout = const Duration(seconds: 20)}) =>
      SupabaseTransport(SyncEndpoint(url: url, anonKey: _anon), client: client, timeout: timeout);

  List<http.Request> rpcCalls(String fn) => [for (final r in requests) if (r.url.path == '/rest/v1/rpc/$fn') r];
}

/// Default handler: password / refresh sign-in succeed, RPCs answer [rpc].
FutureOr<http.Response> Function(http.Request) _server(
    {FutureOr<http.Response> Function(String fn, Map<String, Object?> body, http.Request r)? rpc}) {
  var n = 0;
  return (r) {
    if (r.url.path == '/auth/v1/token') {
      n++;
      return _json(_tokenBody('access-$n', 'refresh-$n'));
    }
    if (r.url.path == '/auth/v1/logout') return http.Response('', 204);
    if (r.url.path.startsWith('/rest/v1/rpc/') && rpc != null) {
      final body = r.body.isEmpty ? <String, Object?>{} : Map<String, Object?>.from(jsonDecode(r.body) as Map);
      return rpc(r.url.pathSegments.last, body, r);
    }
    return _json({'message': 'unexpected'}, 404);
  };
}

void main() {
  group('URL rules (HTTPS only)', () {
    test('https is normalised, trailing slashes dropped', () {
      expect(SupabaseTransport.validateUrl(' https://proj.supabase.co/ ').toString(), 'https://proj.supabase.co');
      expect(SupabaseTransport.validateUrl('https://host.test/base//').toString(), 'https://host.test/base');
    });

    test('http only for localhost / 127.0.0.1', () {
      expect(SupabaseTransport.validateUrl('http://localhost:54321').port, 54321);
      expect(SupabaseTransport.validateUrl('http://127.0.0.1:54321').host, '127.0.0.1');
      expect(() => SupabaseTransport.validateUrl('http://proj.supabase.co'), throwsA(_kind(SyncErrorKind.insecureUrl)));
      expect(() => SupabaseTransport.validateUrl('http://192.168.1.5'), throwsA(_kind(SyncErrorKind.insecureUrl)));
    });

    test('garbage is invalidUrl', () {
      for (final u in ['', 'proj.supabase.co', 'ftp://host.test', 'https://', 'https://u:p@host.test', 'https://h.test?x=1']) {
        expect(() => SupabaseTransport.validateUrl(u), throwsA(_kind(SyncErrorKind.invalidUrl)), reason: u);
      }
    });

    test('an insecure endpoint never sends the password', () async {
      final m = _Mock(_server());
      await expectLater(m.transport(url: 'http://proj.example.test').signIn(email: 'a@b.test', password: _password),
          throwsA(_kind(SyncErrorKind.insecureUrl)));
      expect(m.requests, isEmpty);
    });

    test('a local dev server over http works', () async {
      final m = _Mock(_server());
      await m.transport(url: 'http://127.0.0.1:54321').signIn(email: 'a@b.test', password: _password);
      expect(m.requests.single.url.toString(), 'http://127.0.0.1:54321/auth/v1/token?grant_type=password');
    });
  });

  group('auth', () {
    test('password sign-in: GoTrue request and session', () async {
      final m = _Mock(_server());
      final t = m.transport();
      final s = await t.signIn(email: ' owner@example.test ', password: _password);
      final r = m.requests.single;
      expect(r.method, 'POST');
      expect(r.url.toString(), '$_url/auth/v1/token?grant_type=password');
      expect(r.headers['apikey'], _anon);
      expect(r.headers.containsKey('Authorization'), isFalse);
      expect(r.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(r.body), {'email': 'owner@example.test', 'password': _password});
      expect(s.userId, 'user-1');
      expect(s.email, 'owner@example.test');
      expect(s.refreshToken, 'refresh-1');
      expect(s.accessToken, 'access-1');
      expect(t.session, same(s));
      // Nothing printable holds a secret.
      expect('$s $t', isNot(contains(_password)));
      expect('$s', isNot(contains('refresh-1')));
    });

    test('restoreSession uses grant_type=refresh_token', () async {
      final m = _Mock(_server());
      final s = await m.transport().restoreSession('stored-refresh');
      final r = m.requests.single;
      expect(r.url.toString(), '$_url/auth/v1/token?grant_type=refresh_token');
      expect(r.headers['apikey'], _anon);
      expect(jsonDecode(r.body), {'refresh_token': 'stored-refresh'});
      expect(s.refreshToken, 'refresh-1');
    });

    test('wrong password / rejected refresh token -> auth; detail has no secrets', () async {
      final m = _Mock((r) => _json({'error': 'invalid_grant', 'error_description': 'Invalid login credentials'}, 400));
      Object? err;
      try {
        await m.transport().signIn(email: 'a@b.test', password: _password);
      } catch (e) {
        err = e;
      }
      expect(err, _kind(SyncErrorKind.auth));
      expect('$err ${(err as SyncException).detail}', isNot(contains(_password)));
      await expectLater(m.transport().restoreSession('old'), throwsA(_kind(SyncErrorKind.auth)));
    });

    test('token endpoint 5xx -> server, malformed token -> protocol', () async {
      await expectLater(_Mock((r) => http.Response('oops', 502)).transport().signIn(email: 'a@b.test', password: 'x'),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'HTTP 502')));
      await expectLater(_Mock((r) => _json({'access_token': 'a'})).transport().signIn(email: 'a@b.test', password: 'x'),
          throwsA(_kind(SyncErrorKind.protocol)));
      await expectLater(_Mock((r) => http.Response('<html>', 200)).transport().signIn(email: 'a@b.test', password: 'x'),
          throwsA(_kind(SyncErrorKind.protocol)));
    });

    test('signOut: local scope logout with the access token, errors ignored', () async {
      final m = _Mock(_server());
      final t = m.transport();
      await t.signIn(email: 'a@b.test', password: 'x');
      await t.signOut();
      final r = m.requests.last;
      expect(r.url.toString(), '$_url/auth/v1/logout?scope=local');
      expect(r.headers['Authorization'], 'Bearer access-1');
      expect(t.session, isNull);

      final failing = _Mock((r) => r.url.path == '/auth/v1/logout' ? throw http.ClientException('down') : _json(_tokenBody('a', 'r')));
      final t2 = failing.transport();
      await t2.signIn(email: 'a@b.test', password: 'x');
      await t2.signOut(); // no throw
      expect(t2.session, isNull);
    });

    test('RPC before sign-in -> notSignedIn without a request', () async {
      final m = _Mock(_server());
      await expectLater(m.transport().listStores(), throwsA(_kind(SyncErrorKind.notSignedIn)));
      expect(m.requests, isEmpty);
    });
  });

  group('RPC requests', () {
    late _Mock m;
    late SupabaseTransport t;
    final bodies = <String, Map<String, Object?>>{};

    setUp(() async {
      bodies.clear();
      m = _Mock(_server(rpc: (fn, body, r) {
        bodies[fn] = body;
        return switch (fn) {
          'create_store' => _json('11111111-1111-4111-8111-111111111111'),
          'register_device' => _json('B'),
          'store_info' => _json({'id': 's1', 'name': 'Магазин', 'environment': 'production', 'has_data': true}),
          'list_stores' => _json([
              {'id': 's1', 'name': 'Магазин', 'environment': 'test', 'has_data': false},
              {'id': 's2', 'name': 'Склад', 'environment': 'production', 'has_data': true},
            ]),
          'push_changes' => _json({'accepted': 2, 'max_seq': 42}),
          'pull_changes' => _json([
              {
                'seq': 7,
                'change_id': 'c7',
                'entity': 'products',
                'entity_id': 'p1',
                'op': 'upsert',
                'version': 1732500000000,
                'device_id': 'dev-a',
                'payload': {'id': 'p1', 'name': 'Чай', 'price': 1000, 'stock_qty': 2.5, 'deleted_at': null},
              },
              {
                'seq': 9,
                'change_id': 'c9',
                'entity': 'settings',
                'entity_id': 'store_name',
                'op': 'delete',
                'version': 1732500000001,
                'device_id': 'dev-b',
                'payload': null,
              },
            ]),
          _ => _json({'message': 'unknown'}, 404),
        };
      }));
      t = m.transport();
      await t.signIn(email: 'a@b.test', password: 'x');
    });

    void expectRpcHeaders(String fn) {
      final r = m.rpcCalls(fn).single;
      expect(r.method, 'POST');
      expect(r.url.toString(), '$_url/rest/v1/rpc/$fn');
      expect(r.headers['apikey'], _anon);
      expect(r.headers['Authorization'], 'Bearer access-1');
      expect(r.headers['Content-Type'], startsWith('application/json'));
    }

    test('create_store', () async {
      final s = await t.createStore(name: ' Магазин ', environment: StoreEnvironment.test);
      expectRpcHeaders('create_store');
      expect(bodies['create_store'], {'p_name': 'Магазин', 'p_environment': 'test'});
      expect(s.id, '11111111-1111-4111-8111-111111111111');
      expect(s.name, 'Магазин');
      expect(s.environment, StoreEnvironment.test);
      expect(s.hasData, isFalse);
    });

    test('register_device', () async {
      final r = await t.registerDevice(storeId: 's1', deviceId: 'dev-b', name: 'DreamPOS');
      expectRpcHeaders('register_device');
      expect(bodies['register_device'], {'p_store_id': 's1', 'p_device_id': 'dev-b', 'p_name': 'DreamPOS'});
      expect(r.code, 'B');
      expect(r.deviceId, 'dev-b');
    });

    test('store_info and list_stores', () async {
      final s = await t.storeInfo('s1');
      expectRpcHeaders('store_info');
      expect(bodies['store_info'], {'p_store_id': 's1'});
      expect([s.id, s.name, s.environment, s.hasData], ['s1', 'Магазин', StoreEnvironment.production, true]);

      final list = await t.listStores();
      expectRpcHeaders('list_stores');
      expect(bodies['list_stores'], isEmpty);
      expect(list.map((s) => '${s.id}:${s.environment.wire}:${s.hasData}'), ['s1:test:false', 's2:production:true']);
    });

    test('push_changes sends the SyncChange wire JSON', () async {
      final changes = [
        const SyncChange(
            changeId: 'c1',
            entity: 'sales',
            entityId: 'sale-1',
            op: SyncOp.upsert,
            version: 1732500000000,
            deviceId: 'dev-a',
            payload: {'id': 'sale-1', 'number': 1, 'device_code': 'A', 'total': 1500, 'qty': 1.5, 'deleted_at': null}),
        const SyncChange(
            changeId: 'c2', entity: 'products', entityId: 'p9', op: SyncOp.delete, version: 1732500000001, deviceId: 'dev-a'),
      ];
      final res = await t.push(storeId: 's1', deviceId: 'dev-a', changes: changes);
      expectRpcHeaders('push_changes');
      expect(bodies['push_changes'], {
        'p_store_id': 's1',
        'p_device_id': 'dev-a',
        'p_changes': [
          {
            'change_id': 'c1',
            'entity': 'sales',
            'entity_id': 'sale-1',
            'op': 'upsert',
            'version': 1732500000000,
            'device_id': 'dev-a',
            'payload': {'id': 'sale-1', 'number': 1, 'device_code': 'A', 'total': 1500, 'qty': 1.5, 'deleted_at': null},
          },
          {
            'change_id': 'c2',
            'entity': 'products',
            'entity_id': 'p9',
            'op': 'delete',
            'version': 1732500000001,
            'device_id': 'dev-a',
            'payload': null,
          },
        ],
      });
      expect(res.accepted, 2);
      expect(res.maxSeq, 42);
    });

    test('pull_changes', () async {
      final page = await t.pull(storeId: 's1', since: 6, max: 500);
      expectRpcHeaders('pull_changes');
      expect(bodies['pull_changes'], {'p_store_id': 's1', 'p_since': 6, 'p_max': 500});
      expect(page.changes, hasLength(2));
      final a = page.changes.first;
      expect([a.seq, a.changeId, a.entity, a.entityId, a.op, a.version, a.deviceId],
          [7, 'c7', 'products', 'p1', SyncOp.upsert, 1732500000000, 'dev-a']);
      expect(a.payload, {'id': 'p1', 'name': 'Чай', 'price': 1000, 'stock_qty': 2.5, 'deleted_at': null});
      expect(page.changes.last.op, SyncOp.delete);
      expect(page.changes.last.payload, isNull);
      expect(page.lastSeq, 9);
    });
  });

  group('refresh on 401', () {
    test('expired access token: one refresh, one retry with the new token', () async {
      var rpcCalls = 0;
      final m = _Mock(_server(rpc: (fn, body, r) {
        rpcCalls++;
        if (r.headers['Authorization'] == 'Bearer access-1') return _json({'code': 'PGRST303', 'message': 'JWT expired'}, 401);
        return _json([]);
      }));
      final t = m.transport();
      await t.signIn(email: 'a@b.test', password: 'x');
      final stores = await t.listStores();
      expect(stores, isEmpty);
      expect(rpcCalls, 2);
      final refresh = m.requests.where((r) => r.url.query == 'grant_type=refresh_token').single;
      expect(jsonDecode(refresh.body), {'refresh_token': 'refresh-1'});
      expect(m.requests.last.headers['Authorization'], 'Bearer access-2');
      // Rotated refresh token is exposed for the engine to persist.
      expect(t.session!.refreshToken, 'refresh-2');
    });

    test('still 401 after the refresh -> auth (no loop)', () async {
      var rpcCalls = 0;
      final m = _Mock(_server(rpc: (fn, body, r) {
        rpcCalls++;
        return _json({'code': 'PGRST301'}, 401);
      }));
      final t = m.transport();
      await t.signIn(email: 'a@b.test', password: 'x');
      await expectLater(t.storeInfo('s1'), throwsA(_kind(SyncErrorKind.auth)));
      expect(rpcCalls, 2);
      expect(m.requests.where((r) => r.url.query == 'grant_type=refresh_token'), hasLength(1));
    });

    test('refresh token rejected -> auth', () async {
      var tokenCalls = 0;
      final m = _Mock((r) {
        if (r.url.path == '/auth/v1/token') {
          tokenCalls++;
          return tokenCalls == 1 ? _json(_tokenBody('access-1', 'refresh-1')) : _json({'error': 'invalid_grant'}, 400);
        }
        return _json({'code': 'PGRST303'}, 401);
      });
      final t = m.transport();
      await t.signIn(email: 'a@b.test', password: 'x');
      await expectLater(t.pull(storeId: 's1', since: 0), throwsA(_kind(SyncErrorKind.auth)));
    });

    test('concurrent 401s share one refresh', () async {
      final m = _Mock(_server(rpc: (fn, body, r) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (r.headers['Authorization'] == 'Bearer access-1') return _json({'code': 'PGRST303'}, 401);
        return _json({'id': 's1', 'name': 'M', 'environment': 'test', 'has_data': false});
      }));
      final t = m.transport();
      await t.signIn(email: 'a@b.test', password: 'x');
      final r = await Future.wait([t.storeInfo('s1'), t.storeInfo('s1'), t.storeInfo('s1')]);
      expect(r.map((s) => s.id), ['s1', 's1', 's1']);
      expect(m.requests.where((r) => r.url.query == 'grant_type=refresh_token'), hasLength(1));
    });
  });

  group('error mapping', () {
    Future<SupabaseTransport> signedIn(FutureOr<http.Response> Function(String fn) rpc,
        {Duration timeout = const Duration(seconds: 20)}) async {
      final m = _Mock(_server(rpc: (fn, body, r) => rpc(fn)));
      final t = m.transport(timeout: timeout);
      await t.signIn(email: 'a@b.test', password: 'x');
      return t;
    }

    test('membership: 403 / 42501 / not_member -> forbidden', () async {
      var t = await signedIn((_) => _json({'code': '42501', 'message': 'not_member'}, 403));
      await expectLater(t.pull(storeId: 's1', since: 0), throwsA(_kind(SyncErrorKind.forbidden)));
      t = await signedIn((_) => _json({'code': '42501', 'message': 'permission denied for function push_changes'}, 400));
      await expectLater(t.storeInfo('s1'), throwsA(_kind(SyncErrorKind.forbidden)));
      t = await signedIn((_) => _json({}, 403));
      await expectLater(t.storeInfo('s1'), throwsA(_kind(SyncErrorKind.forbidden)));
    });

    test('store_not_found -> storeNotFound', () async {
      final t = await signedIn((_) => _json({'code': 'P0001', 'message': 'store_not_found'}, 400));
      await expectLater(t.storeInfo('nope'), throwsA(_kind(SyncErrorKind.storeNotFound)));
    });

    test('5xx -> server with the HTTP status only', () async {
      final t = await signedIn((_) => http.Response('upstream secret body', 503));
      Object? err;
      try {
        await t.listStores();
      } catch (e) {
        err = e;
      }
      expect(err, _kind(SyncErrorKind.server));
      expect((err as SyncException).detail, 'HTTP 503');
    });

    test('missing function (SQL not applied) -> server with the PostgREST code', () async {
      final t = await signedIn((_) => _json({'code': 'PGRST202', 'message': 'Could not find the function'}, 404));
      await expectLater(
          t.listStores(), throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', contains('PGRST202'))));
    });

    test('other 4xx keeps our stable message, never the free text', () async {
      final t = await signedIn((_) => _json({'code': '22023', 'message': 'device_not_registered'}, 400));
      await expectLater(
          t.push(storeId: 's1', deviceId: 'd', changes: const []),
          throwsA(_kind(SyncErrorKind.server)
              .having((e) => e.detail, 'detail', 'HTTP 400 22023 device_not_registered (push_changes)')));
      final t2 = await signedIn((_) => _json({'code': '22P02', 'message': 'invalid input syntax for type uuid: "x y"'}, 400));
      await expectLater(t2.storeInfo('x y'),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', isNot(contains('x y')))));
    });

    test('malformed bodies -> protocol', () async {
      var t = await signedIn((_) => http.Response('not json', 200));
      await expectLater(t.listStores(), throwsA(_kind(SyncErrorKind.protocol)));
      t = await signedIn((_) => _json({'unexpected': true}));
      await expectLater(t.listStores(), throwsA(_kind(SyncErrorKind.protocol)));
      t = await signedIn((_) => _json([
            {'seq': 1, 'entity': 'products'}
          ]));
      await expectLater(t.pull(storeId: 's1', since: 0), throwsA(_kind(SyncErrorKind.protocol)));
      t = await signedIn((_) => _json({'accepted': 'many'}));
      await expectLater(t.push(storeId: 's1', deviceId: 'd', changes: const []), throwsA(_kind(SyncErrorKind.protocol)));
      t = await signedIn((_) => _json('lowercase-code'));
      await expectLater(
          t.registerDevice(storeId: 's1', deviceId: 'd', name: 'n'), throwsA(_kind(SyncErrorKind.protocol)));
    });

    test('no connection / timeout -> network (transient)', () async {
      var t = await signedIn((_) => throw http.ClientException('Connection refused'));
      await expectLater(t.listStores(), throwsA(_kind(SyncErrorKind.network).having((e) => e.isTransient, 'transient', true)));
      t = await signedIn((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return _json([]);
      }, timeout: const Duration(milliseconds: 20));
      await expectLater(t.listStores(), throwsA(_kind(SyncErrorKind.network)));
      final down = _Mock((r) => throw http.ClientException('Failed host lookup'));
      await expectLater(down.transport().signIn(email: 'a@b.test', password: _password),
          throwsA(_kind(SyncErrorKind.network).having((e) => '${e.detail}', 'detail', isNot(contains(_password)))));
    });
  });

  group('contract: SyncService over SupabaseTransport', () {
    test('create store, join, edits converge exactly like with FakeSyncServer', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final server = FakeSyncServer()..addUser('owner@example.test', 'secret-pw');
      final emu = _PostgrestEmulator(server);
      SyncTransport factory(SyncEndpoint e) => SupabaseTransport(e, client: emu.client);

      final dbA = memoryDb(), dbB = memoryDb();
      final a = SyncService(dbA, transportFactory: factory);
      final b = SyncService(dbB, transportFactory: factory);
      addTearDown(() async {
        a.dispose();
        b.dispose();
        await dbA.close();
        await dbB.close();
      });

      await AuthService(dbA).createUser(name: 'Владелец', role: Role.owner, pin: '2580');
      final pid = newId();
      await dbA.into(dbA.products).insert(ProductsCompanion.insert(id: pid, name: 'Чай', price: 1000));

      await a.signIn(endpoint: _endpoint, email: 'owner@example.test', password: 'secret-pw');
      final info = await a.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
      expect(await dbA.deviceCode(), 'A');

      await b.signIn(endpoint: _endpoint, email: 'owner@example.test', password: 'secret-pw');
      expect((await b.listStores()).single.hasData, isTrue);
      await b.joinStore(info.id);
      expect(await dbB.deviceCode(), 'B');
      expect(await dbB.getSetting('setup_done'), '1');

      // Tokens expire on the server: every next RPC needs the 401 refresh.
      emu.expireAccessTokens();
      await (dbA.update(dbA.products)..where((p) => p.id.equals(pid))).write(const ProductsCompanion(price: Value(1500)));
      final pidB = newId();
      await dbB.into(dbB.products).insert(ProductsCompanion.insert(id: pidB, name: 'Кофе', price: 2000));
      for (var round = 0; round < 2; round++) {
        await a.syncNow();
        await b.syncNow();
      }
      expect(emu.refreshes, greaterThanOrEqualTo(2));

      expect(dumpDiff(await dump(dbA), await dump(dbB)), isNull);
      final p = await (dbB.select(dbB.products)..where((p) => p.id.equals(pid))).getSingle();
      expect(p.price, 1500);
      expect(await SyncAggregates.verifyAll(dbA), isEmpty);
      expect(await SyncAggregates.verifyAll(dbB), isEmpty);
      expect(await a.pendingCount(), 0);
      expect(await b.pendingCount(), 0);
      expect(server.store(info.id).devices.values.map((d) => d.code).toSet(), {'A', 'B'});
      // Only the refresh token is stored, never the password.
      final state = await dbA.customSelect('SELECT key, value FROM sync_state').get();
      expect(state.map((r) => r.read<String>('value')).join('|'), isNot(contains('secret-pw')));
    });

    test('a refresh token rotated during a sync that then fails is stored: after a restart sync works', () async {
      final server = FakeSyncServer()..addUser('owner@example.test', 'secret-pw');
      final emu = _PostgrestEmulator(server); // rotating refresh tokens (the old one is revoked)
      SyncTransport factory(SyncEndpoint e) => SupabaseTransport(e, client: emu.client);
      final db = memoryDb();
      final a = SyncService(db, transportFactory: factory);
      addTearDown(db.close);
      await AuthService(db).createUser(name: 'Владелец', role: Role.owner, pin: '2580');
      await a.signIn(endpoint: _endpoint, email: 'owner@example.test', password: 'secret-pw');
      await a.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
      Future<String?> stored() async => (await (db.select(db.syncState)..where((s) => s.key.equals(SyncKeys.refreshToken)))
              .getSingleOrNull())
          ?.value;
      final before = await stored();

      emu.expireAccessTokens();
      emu.failRpc.add('push_changes');
      await db.into(db.products).insert(ProductsCompanion.insert(id: newId(), name: 'Чай', price: 1000));
      await expectLater(a.syncNow(), throwsA(_kind(SyncErrorKind.server)));
      expect(emu.refreshes, 1);
      expect(await stored(), allOf(isNotNull, isNot(before)), reason: 'the rotated token is kept after the failure');

      // App restart with the server healthy again: no «sign in again».
      a.dispose();
      emu.failRpc.clear();
      final a2 = SyncService(db, transportFactory: factory);
      addTearDown(a2.dispose);
      await a2.syncNow();
      expect(await a2.pendingCount(), 0);
      expect((await a2.refreshStatus()).signedIn, isTrue);
    });

    test('a failed store listing after a refresh keeps the rotated token too', () async {
      final server = FakeSyncServer()..addUser('owner@example.test', 'secret-pw');
      final emu = _PostgrestEmulator(server);
      SyncTransport factory(SyncEndpoint e) => SupabaseTransport(e, client: emu.client);
      final db = memoryDb();
      final a = SyncService(db, transportFactory: factory);
      addTearDown(() async {
        a.dispose();
        await db.close();
      });
      await a.signIn(endpoint: _endpoint, email: 'owner@example.test', password: 'secret-pw');
      emu.expireAccessTokens();
      emu.failRpc.add('list_stores'); // fails after the refresh
      await expectLater(a.listStores(), throwsA(isA<SyncException>()));
      expect(emu.refreshes, 1);
      final token = (await (db.select(db.syncState)..where((s) => s.key.equals(SyncKeys.refreshToken))).getSingle()).value;
      expect(await server.client().restoreSession(token), isA<SyncSession>(), reason: 'the stored token is the live one');
    });
  });
}

/// GoTrue + PostgREST emulator in front of [FakeSyncServer], speaking the
/// same JSON as supabase/migrations/0001_dreampos_sync.sql.
class _PostgrestEmulator {
  _PostgrestEmulator(this.server);
  final FakeSyncServer server;
  final _byAccess = <String, FakeSyncServer>{};
  var _n = 0;
  var refreshes = 0;

  /// RPCs (function names) that answer 503.
  final failRpc = <String>{};

  late final MockClient client = MockClient(_handle);

  void expireAccessTokens() => _byAccess.clear();

  http.Response _err(SyncException e) => switch (e.kind) {
        SyncErrorKind.forbidden => _json({'code': '42501', 'message': 'not_member'}, 403),
        SyncErrorKind.storeNotFound => _json({'code': 'P0001', 'message': 'store_not_found'}, 400),
        SyncErrorKind.auth || SyncErrorKind.notSignedIn => _json({'code': 'PGRST301'}, 401),
        _ => _json({'code': 'XX000'}, 500),
      };

  Map<String, Object?> _store(StoreInfo s) =>
      {'id': s.id, 'name': s.name, 'environment': s.environment.wire, 'has_data': s.hasData};

  Future<http.Response> _handle(http.Request r) async {
    if (r.headers['apikey'] != _anon) return _json({'message': 'No API key found'}, 401);
    final body = r.body.isEmpty ? <String, Object?>{} : Map<String, Object?>.from(jsonDecode(r.body) as Map);
    if (r.url.path == '/auth/v1/token') {
      final c = server.client();
      final SyncSession s;
      try {
        if (r.url.queryParameters['grant_type'] == 'password') {
          s = await c.signIn(email: body['email'] as String, password: body['password'] as String);
        } else {
          refreshes++;
          s = await c.restoreSession(body['refresh_token'] as String);
        }
      } on SyncException {
        return _json({'error': 'invalid_grant'}, 400);
      }
      final access = 'jwt-${++_n}';
      _byAccess[access] = c;
      return _json({
        'access_token': access,
        'refresh_token': s.refreshToken,
        'user': {'id': s.userId, 'email': s.email},
      });
    }
    if (r.url.path == '/auth/v1/logout') return http.Response('', 204);
    if (!r.url.path.startsWith('/rest/v1/rpc/')) return _json({'code': 'PGRST202'}, 404);
    final auth = r.headers['Authorization'] ?? '';
    final c = _byAccess[auth.replaceFirst('Bearer ', '')];
    if (c == null) return _json({'code': 'PGRST303', 'message': 'JWT expired'}, 401);
    if (failRpc.contains(r.url.pathSegments.last)) return _json({'message': 'Service Unavailable'}, 503);
    try {
      switch (r.url.pathSegments.last) {
        case 'create_store':
          final s = await c.createStore(
              name: body['p_name'] as String, environment: StoreEnvironment.parse(body['p_environment'] as String));
          return _json(s.id);
        case 'register_device':
          final d = await c.registerDevice(
              storeId: body['p_store_id'] as String, deviceId: body['p_device_id'] as String, name: body['p_name'] as String);
          return _json(d.code);
        case 'store_info':
          return _json(_store(await c.storeInfo(body['p_store_id'] as String)));
        case 'list_stores':
          return _json([for (final s in await c.listStores()) _store(s)]);
        case 'push_changes':
          final dev = body['p_device_id'] as String;
          final changes = [
            for (final e in body['p_changes'] as List) SyncChange.fromJson(Map<String, Object?>.from(e as Map)),
          ];
          if (changes.any((ch) => ch.deviceId != dev)) return _json({'code': '22023', 'message': 'device_mismatch'}, 400);
          if (changes.any((ch) => (ch.op == SyncOp.delete) != (ch.payload == null))) {
            return _json({'code': '23514'}, 400);
          }
          final res = await c.push(storeId: body['p_store_id'] as String, deviceId: dev, changes: changes);
          return _json({'accepted': res.accepted, 'max_seq': res.maxSeq});
        case 'pull_changes':
          final page = await c.pull(
              storeId: body['p_store_id'] as String,
              since: (body['p_since'] as num).toInt(),
              max: (body['p_max'] as num).toInt());
          return _json([for (final ch in page.changes) ch.toJson()]);
      }
    } on SyncException catch (e) {
      return _err(e);
    }
    return _json({'code': 'PGRST202'}, 404);
  }
}
