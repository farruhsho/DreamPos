// FirebaseTransport (D-026, docs/specs/firebase-sync.md) against
// http/testing.dart MockClient: endpoint validation, Identity Toolkit /
// Secure Token sign-in and refresh, error mapping, Firestore value coding,
// the REST requests of every operation, transactions (idempotent push,
// contention retry, chunking), and contract tests: the real SyncService on
// in-memory databases talks through FirebaseTransport to an in-memory
// Firestore REST emulator (below) that also enforces the semantics of
// firebase/firestore.rules. No real server is ever contacted.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers.dart';
import 'sync_harness.dart' show dump, dumpDiff;

const _project = 'dreampos-unit-test';
const _apiKey = 'AIzaUnitTestKey_0123456789';
const _endpoint = SyncEndpoint(projectId: _project, apiKey: _apiKey);
const _email = 'owner@example.test';
const _password = 'pw-never-stored';
const _root = 'projects/$_project/databases/(default)/documents';
const _fsBase = 'https://firestore.googleapis.com/v1/$_root';

http.Response _json(Object? body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// Google API error body.
http.Response _gerr(int code, String status, {String message = '', List<String> reasons = const []}) => _json({
      'error': {
        'code': code,
        'message': message,
        'status': status,
        'details': [
          for (final r in reasons) {'@type': 'type.googleapis.com/google.rpc.ErrorInfo', 'reason': r},
        ],
      },
    }, code);

/// Identity Toolkit error body (`message` is the error code).
http.Response _authErr(String message, [int code = 400]) => _json({
      'error': {
        'code': code,
        'message': message,
        'errors': [
          {'message': message, 'domain': 'global', 'reason': 'invalid'},
        ],
      },
    }, code);

String _jwt(Map<String, Object?> claims) {
  String part(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'RS256'})}.${part(claims)}.sig';
}

TypeMatcher<SyncException> _kind(SyncErrorKind k) => isA<SyncException>().having((e) => e.kind, 'kind', k);

FirebaseTransport _transport(http.Client client,
        {SyncEndpoint endpoint = _endpoint,
        Duration timeout = const Duration(seconds: 20),
        DateTime Function()? clock}) =>
    FirebaseTransport(endpoint,
        client: client, timeout: timeout, clock: clock, retryDelay: (_) => const Duration(milliseconds: 1));

void main() {
  group('endpoint validation', () {
    test('project id format', () {
      for (final ok in ['dreampos-test-uz26', 'abcdef', 'a12345', 'my-shop-1']) {
        expect(FirebaseTransport.validateProjectId(' $ok '), ok);
      }
      for (final bad in [
        '',
        'abc',
        'Dreampos-test',
        '1dreampos',
        'dreampos-',
        'https://dreampos.firebaseapp.com',
        'dreampos test',
        'a' * 31,
      ]) {
        expect(() => FirebaseTransport.validateProjectId(bad), throwsA(_kind(SyncErrorKind.invalidProject)), reason: bad);
      }
    });

    test('api key: non-empty, key characters only', () {
      expect(FirebaseTransport.validateApiKey(' $_apiKey '), _apiKey);
      expect(() => FirebaseTransport.validateApiKey('  '), throwsA(_kind(SyncErrorKind.notConfigured)));
      expect(() => FirebaseTransport.validateApiKey('AIza bad key'), throwsA(_kind(SyncErrorKind.invalidApiKey)));
      expect(() => FirebaseTransport.validateApiKey('AIza?key=x&y'), throwsA(_kind(SyncErrorKind.invalidApiKey)));
    });

    test('an invalid endpoint never sends the password', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      await expectLater(
          _transport(emu.client, endpoint: const SyncEndpoint(projectId: 'http://x', apiKey: _apiKey))
              .signIn(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.invalidProject)));
      await expectLater(
          _transport(emu.client, endpoint: const SyncEndpoint(projectId: _project, apiKey: ''))
              .signIn(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.notConfigured)));
      expect(emu.requests, isEmpty);
    });

    test('every request goes over https to the Google hosts', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      await t.createStore(name: 'M', environment: StoreEnvironment.test);
      await t.restoreSession(t.session!.refreshToken);
      await t.listStores();
      expect(emu.requests.map((r) => r.url.scheme).toSet(), {'https'});
      expect(emu.requests.map((r) => r.url.host).toSet(),
          {'identitytoolkit.googleapis.com', 'securetoken.googleapis.com', 'firestore.googleapis.com'});
    });
  });

  group('auth', () {
    test('password sign-in: Identity Toolkit request and session', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      final s = await t.signIn(email: ' $_email ', password: _password);
      final r = emu.requests.single;
      expect(r.method, 'POST');
      expect(r.url.toString(),
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey');
      expect(r.headers.containsKey('Authorization'), isFalse);
      expect(r.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(r.body), {'email': _email, 'password': _password, 'returnSecureToken': true});
      expect(s.userId, emu.uidOf(_email));
      expect(s.email, _email);
      expect(s.refreshToken, isNotEmpty);
      expect(s.accessToken, isNotEmpty);
      expect(t.session, same(s));
      // Nothing printable holds a secret.
      expect('$s $t', isNot(contains(_password)));
      expect('$s $t', isNot(contains(s.refreshToken)));
      expect('$t', isNot(contains(_apiKey)));
    });

    test('restoreSession: Secure Token form request, rotated token, e-mail from the ID token', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final first = await _transport(emu.client).signIn(email: _email, password: _password);
      emu.requests.clear();
      final t = _transport(emu.client);
      final s = await t.restoreSession(first.refreshToken);
      final r = emu.requests.single;
      expect(r.url.toString(), 'https://securetoken.googleapis.com/v1/token?key=$_apiKey');
      expect(r.headers['Content-Type'], startsWith('application/x-www-form-urlencoded'));
      expect(Uri.splitQueryString(r.body), {'grant_type': 'refresh_token', 'refresh_token': first.refreshToken});
      expect(s.refreshToken, isNot(first.refreshToken), reason: 'the emulator rotates refresh tokens');
      expect(s.userId, first.userId);
      expect(s.email, _email);
      // The old token is gone.
      await expectLater(_transport(emu.client).restoreSession(first.refreshToken), throwsA(_kind(SyncErrorKind.auth)));
    });

    test('sign-in errors map to clear kinds; no secret in the detail', () async {
      final cases = <String, SyncErrorKind>{
        'EMAIL_NOT_FOUND': SyncErrorKind.auth,
        'INVALID_PASSWORD': SyncErrorKind.auth,
        'INVALID_LOGIN_CREDENTIALS': SyncErrorKind.auth,
        'INVALID_EMAIL': SyncErrorKind.auth,
        'USER_DISABLED': SyncErrorKind.accountDisabled,
        'TOO_MANY_ATTEMPTS_TRY_LATER : Access to this account has been temporarily disabled':
            SyncErrorKind.tooManyAttempts,
        'OPERATION_NOT_ALLOWED': SyncErrorKind.signInDisabled,
        'PASSWORD_LOGIN_DISABLED': SyncErrorKind.signInDisabled,
        'CONFIGURATION_NOT_FOUND': SyncErrorKind.signInDisabled,
      };
      for (final e in cases.entries) {
        final t = _transport(MockClient((r) async => _authErr(e.key)));
        Object? err;
        try {
          await t.signIn(email: _email, password: _password);
        } catch (x) {
          err = x;
        }
        expect(err, _kind(e.value), reason: e.key);
        expect('$err ${(err as SyncException).detail}', isNot(contains(_password)));
        expect(err.detail ?? '', isNot(contains('temporarily')), reason: 'no free text');
      }
    });

    test('the emulator maps a wrong password and a disabled sign-in too', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      await expectLater(
          _transport(emu.client).signIn(email: _email, password: 'nope'), throwsA(_kind(SyncErrorKind.auth)));
      await expectLater(
          _transport(emu.client).signIn(email: 'x@example.test', password: 'nope'), throwsA(_kind(SyncErrorKind.auth)));
      emu.emailSignInEnabled = false;
      await expectLater(_transport(emu.client).signIn(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.signInDisabled)));
    });

    test('invalid API key -> invalidApiKey', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client, endpoint: const SyncEndpoint(projectId: _project, apiKey: 'AIzaWrongKey_000'));
      await expectLater(t.signIn(email: _email, password: _password), throwsA(_kind(SyncErrorKind.invalidApiKey)));
      await expectLater(t.restoreSession('whatever'), throwsA(_kind(SyncErrorKind.invalidApiKey)));
    });

    test('refresh errors: rejected token -> auth, disabled user -> accountDisabled', () async {
      await expectLater(_transport(MockClient((r) async => _authErr('INVALID_REFRESH_TOKEN'))).restoreSession('old'),
          throwsA(_kind(SyncErrorKind.auth)));
      await expectLater(_transport(MockClient((r) async => _authErr('TOKEN_EXPIRED'))).restoreSession('old'),
          throwsA(_kind(SyncErrorKind.auth)));
      await expectLater(_transport(MockClient((r) async => _authErr('USER_DISABLED'))).restoreSession('old'),
          throwsA(_kind(SyncErrorKind.accountDisabled)));
      await expectLater(_transport(MockClient((r) async => _json({'error': 'invalid_grant'}, 400))).restoreSession('o'),
          throwsA(_kind(SyncErrorKind.auth)));
    });

    test('token endpoint 5xx -> server, malformed -> protocol, offline / timeout -> network', () async {
      await expectLater(_transport(MockClient((r) async => http.Response('oops', 502))).signIn(email: _email, password: 'x'),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'HTTP 502')));
      await expectLater(
          _transport(MockClient((r) async => _json({'idToken': 'a'}))).signIn(email: _email, password: 'x'),
          throwsA(_kind(SyncErrorKind.protocol)));
      await expectLater(
          _transport(MockClient((r) async => http.Response('<html>', 200))).signIn(email: _email, password: 'x'),
          throwsA(_kind(SyncErrorKind.protocol)));
      await expectLater(
          _transport(MockClient((r) async => throw http.ClientException('Failed host lookup')))
              .signIn(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.network).having((e) => '${e.detail}', 'detail', isNot(contains(_password)))));
      await expectLater(
          _transport(MockClient((r) async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            return _json({});
          }), timeout: const Duration(milliseconds: 20))
              .signIn(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.network).having((e) => e.isTransient, 'transient', true)));
    });

    test('signOut drops the session locally; calls before sign-in -> notSignedIn without a request', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      await expectLater(t.listStores(), throwsA(_kind(SyncErrorKind.notSignedIn)));
      await expectLater(t.pull(storeId: 's1', since: 0), throwsA(_kind(SyncErrorKind.notSignedIn)));
      expect(emu.requests, isEmpty);
      await t.signIn(email: _email, password: _password);
      await t.signOut();
      expect(t.session, isNull);
      await expectLater(t.storeInfo('s1'), throwsA(_kind(SyncErrorKind.notSignedIn)));
      expect(emu.requests, hasLength(1));
    });
  });

  group('Firestore values', () {
    test('integers travel as strings, big versions survive', () {
      expect(FirebaseTransport.encodeValue(7258118400000), {'integerValue': '7258118400000'});
      expect(FirebaseTransport.decodeValue({'integerValue': '7258118400000'}), 7258118400000);
      expect(FirebaseTransport.decodeValue({'integerValue': 42}), 42);
      expect(FirebaseTransport.encodeValue(null), {'nullValue': null});
      expect(FirebaseTransport.encodeValue(true), {'booleanValue': true});
      expect(FirebaseTransport.encodeValue(1.5), {'doubleValue': 1.5});
      expect(FirebaseTransport.encodeValue('Чай'), {'stringValue': 'Чай'});
      expect(FirebaseTransport.encodeValue(DateTime.utc(2026, 11, 26, 10)), {'timestampValue': '2026-11-26T10:00:00.000Z'});
      expect(FirebaseTransport.decodeValue({'doubleValue': 2}), 2.0);
      expect(FirebaseTransport.decodeValue({'doubleValue': 'NaN'}), isNaN);
      expect(FirebaseTransport.decodeValue({'nullValue': null}), isNull);
      expect(FirebaseTransport.decodeValue({'timestampValue': '2026-11-26T10:00:00Z'}), '2026-11-26T10:00:00Z');
      expect(
          FirebaseTransport.decodeValue({
            'mapValue': {
              'fields': {
                'a': {'integerValue': '1'},
                'b': {
                  'arrayValue': {
                    'values': [
                      {'stringValue': 'x'},
                      {'booleanValue': false},
                    ],
                  },
                },
              },
            },
          }),
          {
            'a': 1,
            'b': ['x', false],
          });
      expect(() => FirebaseTransport.encodeValue(const {'a': 1}), throwsArgumentError);
      expect(() => FirebaseTransport.decodeValue({'geoPointValue': {}}), throwsFormatException);
    });
  });

  group('requests', () {
    late _FirestoreEmulator emu;
    late FirebaseTransport t;

    setUp(() async {
      emu = _FirestoreEmulator()..addUser(_email, _password);
      t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      emu.requests.clear();
    });

    test('createStore: one commit of store + member + index, all create-only', () async {
      final s = await t.createStore(name: ' Магазин ', environment: StoreEnvironment.test);
      final r = emu.requests.single;
      expect(r.url.toString(), '$_fsBase:commit');
      expect(r.headers['Authorization'], 'Bearer ${t.session!.accessToken}');
      final body = jsonDecode(r.body) as Map;
      expect(body.containsKey('transaction'), isFalse);
      final writes = body['writes'] as List;
      expect([for (final w in writes) (w['update']['name'] as String).replaceFirst('$_root/', '')], [
        'stores/${s.id}',
        'stores/${s.id}/members/${t.session!.userId}',
        'users/${t.session!.userId}/stores/${s.id}',
      ]);
      for (final w in writes) {
        expect(w['currentDocument'], {'exists': false});
      }
      expect(writes[0]['update']['fields'], {
        'name': {'stringValue': 'Магазин'},
        'environment': {'stringValue': 'test'},
        'createdBy': {'stringValue': t.session!.userId},
        'nextSeq': {'integerValue': '0'},
        'nextCode': {'integerValue': '0'},
        'hasData': {'booleanValue': false},
      });
      expect(writes[0]['updateTransforms'], [
        {'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'},
      ]);
      expect([s.name, s.environment, s.hasData], ['Магазин', StoreEnvironment.test, false]);
      expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(s.id), isTrue);
      expect(emu.fields('stores/${s.id}')['createdAt'], isA<String>());
    });

    test('storeInfo / listStores read the store documents', () async {
      final a = await t.createStore(name: 'Магазин', environment: StoreEnvironment.test);
      final b = await t.createStore(name: 'Склад', environment: StoreEnvironment.production);
      emu.pageSize = 1; // the list is paged
      final list = await t.listStores();
      expect(list.map((s) => '${s.name}:${s.environment.wire}:${s.hasData}').toSet(),
          {'Магазин:test:false', 'Склад:production:false'});
      expect(emu.requests.where((r) => r.url.path.endsWith('/users/${t.session!.userId}/stores')), hasLength(2));
      emu.requests.clear();
      final info = await t.storeInfo(b.id);
      expect(emu.requests.single.method, 'GET');
      expect(emu.requests.single.url.toString(), '$_fsBase/stores/${b.id}');
      expect([info.id, info.name, info.environment], [b.id, 'Склад', StoreEnvironment.production]);
      expect(a.id, isNot(b.id));
    });

    test('registerDevice: A, B, idempotent per device, codes after Z continue with AA', () async {
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      expect((await t.registerDevice(storeId: s.id, deviceId: 'dev-a', name: 'Касса 1')).code, 'A');
      expect((await t.registerDevice(storeId: s.id, deviceId: 'dev-b', name: 'Касса 2')).code, 'B');
      emu.requests.clear();
      expect((await t.registerDevice(storeId: s.id, deviceId: 'dev-a', name: 'Касса 1')).code, 'A');
      expect(emu.requests.map((r) => r.url.path.split(':').last), ['beginTransaction', 'batchGet', 'rollback'],
          reason: 'nothing written for a known device');
      expect(emu.fields('stores/${s.id}/codes/B'), {'deviceId': 'dev-b'});
      expect(emu.fields('stores/${s.id}/devices/dev-b')['name'], 'Касса 2');
      expect(emu.fields('stores/${s.id}')['nextCode'], 2);
      emu.patch('stores/${s.id}', {'nextCode': 26});
      expect((await t.registerDevice(storeId: s.id, deviceId: 'dev-c', name: 'n')).code, 'AA');
      expect(emu.fields('stores/${s.id}')['nextCode'], 27);
    });

    test('push: seq from nextSeq in one transaction, payload as one JSON string, idempotent re-push', () async {
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      await t.registerDevice(storeId: s.id, deviceId: 'dev-a', name: 'A');
      final changes = [
        const SyncChange(
            changeId: 'c1',
            entity: 'sales',
            entityId: 'sale-1',
            op: SyncOp.upsert,
            version: 1732500000000,
            deviceId: 'dev-a',
            payload: {'id': 'sale-1', 'number': 1, 'total': 1500, 'qty': 1.5, 'note': 'Чай', 'deleted_at': null}),
        const SyncChange(
            changeId: 'c2', entity: 'products', entityId: 'p9', op: SyncOp.delete, version: 7258118400000, deviceId: 'dev-a'),
      ];
      emu.requests.clear();
      final res = await t.push(storeId: s.id, deviceId: 'dev-a', changes: changes);
      expect([res.accepted, res.maxSeq], [2, 2]);
      expect(emu.requests.map((r) => r.url.path.split(':').last), ['beginTransaction', 'batchGet', 'commit']);
      final batchGet = jsonDecode(emu.requests[1].body) as Map;
      expect(batchGet['transaction'], isNotEmpty);
      expect((batchGet['documents'] as List).map((d) => (d as String).replaceFirst('$_root/', '')), [
        'stores/${s.id}',
        'stores/${s.id}/devices/dev-a',
        'stores/${s.id}/changes/c1',
        'stores/${s.id}/changes/c2',
      ]);
      final commit = jsonDecode(emu.requests[2].body) as Map;
      expect(commit['transaction'], batchGet['transaction']);
      final w = commit['writes'] as List;
      expect(w, hasLength(4));
      expect(w[0]['update']['fields'], {
        'seq': {'integerValue': '1'},
        'deviceId': {'stringValue': 'dev-a'},
        'entity': {'stringValue': 'sales'},
        'entityId': {'stringValue': 'sale-1'},
        'op': {'stringValue': 'upsert'},
        'version': {'integerValue': '1732500000000'},
        'payload': {
          'stringValue': jsonEncode({'id': 'sale-1', 'number': 1, 'total': 1500, 'qty': 1.5, 'note': 'Чай', 'deleted_at': null}),
        },
      });
      expect(w[0]['currentDocument'], {'exists': false});
      expect(w[1]['update']['fields']['payload'], {'nullValue': null});
      expect(w[1]['update']['fields']['version'], {'integerValue': '7258118400000'});
      expect(w[2]['updateMask'], {
        'fieldPaths': ['nextSeq', 'hasData'],
      });
      expect(w[3]['updateMask'], {
        'fieldPaths': ['lastSeenAt'],
      });
      expect((w[3]['update']['fields']['lastSeenAt'] as Map).keys, ['timestampValue']);
      expect(emu.fields('stores/${s.id}'), containsPair('nextSeq', 2));
      expect((await t.storeInfo(s.id)).hasData, isTrue);

      // The answer was lost: the same batch again (plus a new change).
      final again = await t.push(storeId: s.id, deviceId: 'dev-a', changes: [
        ...changes,
        const SyncChange(
            changeId: 'c3', entity: 'products', entityId: 'p1', op: SyncOp.upsert, version: 3, deviceId: 'dev-a', payload: {'id': 'p1'}),
      ]);
      expect([again.accepted, again.maxSeq], [1, 3]);
      expect(emu.fields('stores/${s.id}/changes/c3')['seq'], 3);
      emu.requests.clear();
      final none = await t.push(storeId: s.id, deviceId: 'dev-a', changes: changes);
      expect([none.accepted, none.maxSeq], [0, 3]);
      expect(emu.requests.map((r) => r.url.path.split(':').last), ['beginTransaction', 'batchGet', 'rollback']);

      final page = await t.pull(storeId: s.id, since: 0);
      expect(page.changes.map((c) => '${c.seq}:${c.changeId}'), ['1:c1', '2:c2', '3:c3']);
      expect(page.changes.first.payload,
          {'id': 'sale-1', 'number': 1, 'total': 1500, 'qty': 1.5, 'note': 'Чай', 'deleted_at': null});
      expect(page.changes.first.version, 1732500000000);
      expect(page.changes[1].op, SyncOp.delete);
      expect(page.changes[1].payload, isNull);
      expect(page.changes[1].version, 7258118400000);
    });

    test('pull: runQuery seq > since ordered by seq with a limit', () async {
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      await t.registerDevice(storeId: s.id, deviceId: 'dev-a', name: 'A');
      await t.push(storeId: s.id, deviceId: 'dev-a', changes: [
        for (var i = 1; i <= 5; i++)
          SyncChange(
              changeId: 'c$i', entity: 'products', entityId: 'p$i', op: SyncOp.upsert, version: i, deviceId: 'dev-a', payload: {'id': 'p$i'}),
      ]);
      emu.requests.clear();
      final page = await t.pull(storeId: s.id, since: 2, max: 2);
      final r = emu.requests.single;
      expect(r.url.toString(), '$_fsBase/stores/${s.id}:runQuery');
      expect(jsonDecode(r.body), {
        'structuredQuery': {
          'from': [
            {'collectionId': 'changes'},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'seq'},
              'op': 'GREATER_THAN',
              'value': {'integerValue': '2'},
            },
          },
          'orderBy': [
            {
              'field': {'fieldPath': 'seq'},
              'direction': 'ASCENDING',
            },
          ],
          'limit': 2,
        },
      });
      expect(page.changes.map((c) => c.seq), [3, 4]);
      expect(page.lastSeq, 4);
      expect((await t.pull(storeId: s.id, since: 5)).changes, isEmpty);
      await t.pull(storeId: s.id, since: 0, max: 100000);
      expect((jsonDecode(emu.requests.last.body) as Map)['structuredQuery']['limit'], FirebaseTransport.maxPullPage);
    });

    test('push refuses a bad batch before sending anything', () async {
      SyncChange ch({String dev = 'dev-a', int version = 1, Map<String, Object?>? payload = const {'id': 'p'}, String id = 'c1'}) =>
          SyncChange(
              changeId: id,
              entity: 'products',
              entityId: 'p',
              op: payload == null ? SyncOp.delete : SyncOp.upsert,
              version: version,
              deviceId: dev,
              payload: payload);
      for (final bad in [
        ch(dev: 'other'),
        ch(version: 7258118400001),
        ch(version: -1),
        ch(payload: {
          'nested': {'a': 1},
        }),
        ch(id: 'bad/id'),
      ]) {
        await expectLater(t.push(storeId: 's1', deviceId: 'dev-a', changes: [bad]), throwsA(_kind(SyncErrorKind.server)));
      }
      expect(emu.requests, isEmpty);
    });

    test('push of an unregistered device -> server device_not_registered', () async {
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      await expectLater(
          t.push(storeId: s.id, deviceId: 'dev-x', changes: const [
            SyncChange(changeId: 'c1', entity: 'e', entityId: 'i', op: SyncOp.delete, version: 1, deviceId: 'dev-x'),
          ]),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'device_not_registered')));
    });

    test('a big push is split into commits of at most 400 writes', () async {
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      await t.registerDevice(storeId: s.id, deviceId: 'dev-a', name: 'A');
      emu.requests.clear();
      final res = await t.push(storeId: s.id, deviceId: 'dev-a', changes: [
        for (var i = 0; i < 1000; i++)
          SyncChange(
              changeId: 'c$i', entity: 'products', entityId: 'p$i', op: SyncOp.upsert, version: i, deviceId: 'dev-a', payload: {'id': 'p$i'}),
      ]);
      expect([res.accepted, res.maxSeq], [1000, 1000]);
      final commits = [for (final r in emu.requests) if (r.url.path.endsWith(':commit')) jsonDecode(r.body) as Map];
      expect(commits.map((c) => (c['writes'] as List).length), [400, 400, 206]);
      final page = await t.pull(storeId: s.id, since: 0, max: 1000);
      expect(page.changes.map((c) => c.seq), [for (var i = 1; i <= 1000; i++) i]);
      expect(page.changes.map((c) => c.changeId), [for (var i = 0; i < 1000; i++) 'c$i']);
    });

    test('contention: ABORTED commits are retried in a new transaction, then give up', () async {
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      await t.registerDevice(storeId: s.id, deviceId: 'dev-a', name: 'A');
      const c = SyncChange(changeId: 'c1', entity: 'e', entityId: 'i', op: SyncOp.delete, version: 1, deviceId: 'dev-a');
      emu.abortCommits = 2;
      emu.requests.clear();
      expect((await t.push(storeId: s.id, deviceId: 'dev-a', changes: const [c])).accepted, 1);
      expect(emu.requests.where((r) => r.url.path.endsWith(':beginTransaction')), hasLength(3));

      emu.abortCommits = 100;
      await expectLater(
          t.push(storeId: s.id, deviceId: 'dev-a', changes: const [
            SyncChange(changeId: 'c2', entity: 'e', entityId: 'i', op: SyncOp.delete, version: 2, deviceId: 'dev-a'),
          ]),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', contains('ABORTED'))));
      expect(emu.requests.where((r) => r.url.path.endsWith(':beginTransaction')), hasLength(3 + FirebaseTransport.maxAttempts));
    });

    test('a concurrent register writing between read and commit: the retry takes the next seq', () async {
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      await t.registerDevice(storeId: s.id, deviceId: 'dev-a', name: 'A');
      await t.registerDevice(storeId: s.id, deviceId: 'dev-b', name: 'B');
      final other = _transport(emu.client);
      await other.signIn(email: _email, password: _password);
      var raced = false;
      emu.beforeCommit = () async {
        if (raced) return;
        raced = true;
        emu.beforeCommit = null;
        await other.push(storeId: s.id, deviceId: 'dev-b', changes: const [
          SyncChange(changeId: 'b1', entity: 'e', entityId: 'x', op: SyncOp.delete, version: 1, deviceId: 'dev-b'),
        ]);
      };
      final res = await t.push(storeId: s.id, deviceId: 'dev-a', changes: const [
        SyncChange(changeId: 'a1', entity: 'e', entityId: 'y', op: SyncOp.delete, version: 1, deviceId: 'dev-a'),
      ]);
      expect(res.maxSeq, 2);
      final page = await t.pull(storeId: s.id, since: 0);
      expect(page.changes.map((c) => '${c.seq}:${c.changeId}'), ['1:b1', '2:a1']);
    });
  });

  group('tokens', () {
    test('expired ID token: one refresh, one retry with the new token; rotated token exposed', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      final first = await t.signIn(email: _email, password: _password);
      emu.expireAccessTokens();
      emu.requests.clear();
      expect(await t.listStores(), isEmpty);
      expect(emu.requests.map((r) => r.url.host), [
        'firestore.googleapis.com',
        'securetoken.googleapis.com',
        'firestore.googleapis.com',
      ]);
      expect(emu.requests.last.headers['Authorization'], 'Bearer ${t.session!.accessToken}');
      expect(t.session!.refreshToken, isNot(first.refreshToken));
      expect(emu.refreshes, 1);
    });

    test('still 401 after the refresh -> auth (no loop)', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      emu.rejectAllTokens = true;
      await expectLater(t.storeInfo('s1'), throwsA(_kind(SyncErrorKind.auth)));
      expect(emu.refreshes, 1);
    });

    test('refresh token rejected -> auth', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      emu.expireAccessTokens();
      emu.revokeRefreshTokens();
      await expectLater(t.pull(storeId: 's1', since: 0), throwsA(_kind(SyncErrorKind.auth)));
    });

    test('concurrent 401s share one refresh', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      emu.expireAccessTokens();
      emu.delay = const Duration(milliseconds: 5);
      final r = await Future.wait([t.storeInfo(s.id), t.storeInfo(s.id), t.storeInfo(s.id)]);
      expect(r.map((s) => s.name), ['M', 'M', 'M']);
      expect(emu.refreshes, 1);
    });

    test('an ID token about to expire is refreshed before the request', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      var now = DateTime(2026, 11, 26, 10);
      final t = _transport(emu.client, clock: () => now);
      await t.signIn(email: _email, password: _password);
      emu.requests.clear();
      now = now.add(const Duration(minutes: 59, seconds: 30));
      await t.listStores();
      expect(emu.requests.map((r) => r.url.host), ['securetoken.googleapis.com', 'firestore.googleapis.com']);
      emu.requests.clear();
      await t.listStores();
      expect(emu.requests.map((r) => r.url.host), ['firestore.googleapis.com']);
    });
  });

  group('error mapping', () {
    Future<FirebaseTransport> signedIn(FutureOr<http.Response> Function(http.Request r) firestore,
        {Duration timeout = const Duration(seconds: 20)}) async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(MockClient((r) async => r.url.host == 'firestore.googleapis.com' ? firestore(r) : emu.handle(r)),
          timeout: timeout);
      await t.signIn(email: _email, password: _password);
      return t;
    }

    test('PERMISSION_DENIED -> forbidden; NOT_FOUND store -> storeNotFound', () async {
      var t = await signedIn((_) => _gerr(403, 'PERMISSION_DENIED', message: 'Missing or insufficient permissions.'));
      await expectLater(t.pull(storeId: 's1', since: 0), throwsA(_kind(SyncErrorKind.forbidden)));
      await expectLater(t.storeInfo('s1'), throwsA(_kind(SyncErrorKind.forbidden)));
      t = await signedIn((_) => _gerr(404, 'NOT_FOUND', message: 'Document not found'));
      await expectLater(t.storeInfo('nope'), throwsA(_kind(SyncErrorKind.storeNotFound)));
    });

    test('a refused createStore is a server (rules) problem, not «not a member»', () async {
      final t = await signedIn((_) => _gerr(403, 'PERMISSION_DENIED'));
      await expectLater(t.createStore(name: 'M', environment: StoreEnvironment.test),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', contains('PERMISSION_DENIED'))));
    });

    test('project problems keep a stable code, never free text', () async {
      var t = await signedIn(
          (_) => _gerr(404, 'NOT_FOUND', message: 'The database (default) does not exist for project secret-name'));
      await expectLater(
          t.storeInfo('s1'),
          throwsA(_kind(SyncErrorKind.server)
              .having((e) => e.detail, 'detail', 'HTTP 404 NO_DATABASE (store_info)')
              .having((e) => e.detail, 'no text', isNot(contains('secret')))));
      t = await signedIn((_) => _gerr(403, 'PERMISSION_DENIED', reasons: ['SERVICE_DISABLED']));
      await expectLater(t.listStores(),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', contains('SERVICE_DISABLED'))));
      t = await signedIn((_) => _gerr(429, 'RESOURCE_EXHAUSTED', message: 'Quota exceeded.'));
      await expectLater(t.pull(storeId: 's1', since: 0),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'HTTP 429 RESOURCE_EXHAUSTED (pull_changes)')));
      t = await signedIn((_) => http.Response('upstream secret body', 503));
      await expectLater(
          t.listStores(), throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'HTTP 503')));
    });

    test('malformed bodies -> protocol', () async {
      var t = await signedIn((_) => http.Response('not json', 200));
      await expectLater(t.listStores(), throwsA(_kind(SyncErrorKind.protocol)));
      t = await signedIn((_) => _json({'unexpected': true}));
      await expectLater(t.pull(storeId: 's1', since: 0), throwsA(_kind(SyncErrorKind.protocol)));
      t = await signedIn((_) => _json([
            {
              'document': {
                'name': '$_root/stores/s1/changes/c1',
                'fields': {
                  'seq': {'integerValue': '1'},
                },
              },
            },
          ]));
      await expectLater(t.pull(storeId: 's1', since: 0), throwsA(_kind(SyncErrorKind.protocol)));
      t = await signedIn((_) => _json({
            'name': '$_root/stores/s1',
            'fields': {
              'name': {'integerValue': '5'},
            },
          }));
      await expectLater(t.storeInfo('s1'), throwsA(_kind(SyncErrorKind.protocol)));
    });

    test('no connection / timeout -> network (transient)', () async {
      var t = await signedIn((_) => throw http.ClientException('Connection refused'));
      await expectLater(t.listStores(), throwsA(_kind(SyncErrorKind.network).having((e) => e.isTransient, 'transient', true)));
      t = await signedIn((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return _json({});
      }, timeout: const Duration(milliseconds: 50));
      await expectLater(t.listStores(), throwsA(_kind(SyncErrorKind.network)));
    });
  });

  group('rules semantics (emulated)', () {
    test('another account sees nothing of a store it is not a member of', () async {
      final emu = _FirestoreEmulator()
        ..addUser(_email, _password)
        ..addUser('stranger@example.test', 'pw2');
      final owner = _transport(emu.client);
      await owner.signIn(email: _email, password: _password);
      final s = await owner.createStore(name: 'M', environment: StoreEnvironment.test);
      final stranger = _transport(emu.client);
      await stranger.signIn(email: 'stranger@example.test', password: 'pw2');
      expect(await stranger.listStores(), isEmpty);
      await expectLater(stranger.storeInfo(s.id), throwsA(_kind(SyncErrorKind.forbidden)));
      await expectLater(stranger.pull(storeId: s.id, since: 0), throwsA(_kind(SyncErrorKind.forbidden)));
      await expectLater(stranger.registerDevice(storeId: s.id, deviceId: 'd', name: 'n'),
          throwsA(_kind(SyncErrorKind.forbidden)));
      await expectLater(stranger.storeInfo('00000000-0000-4000-8000-000000000000'),
          throwsA(_kind(SyncErrorKind.storeNotFound)));

      // Added by the owner in the console (member + index documents).
      emu.addMember(s.id, emu.uidOf('stranger@example.test'));
      expect((await stranger.listStores()).single.id, s.id);
      expect((await stranger.registerDevice(storeId: s.id, deviceId: 'd', name: 'n')).code, 'A');
    });

    test('a listed store the account lost access to is left out', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      final a = await t.createStore(name: 'A', environment: StoreEnvironment.test);
      final b = await t.createStore(name: 'B', environment: StoreEnvironment.test);
      emu.removeDoc('stores/${a.id}/members/${t.session!.userId}');
      expect((await t.listStores()).map((s) => s.id), [b.id]);
    });

    test('the emulator refuses what the rules refuse', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      final tok = t.session!.accessToken!;
      Future<int> commit(List<Map<String, Object?>> writes) async {
        final r = await emu.client.post(Uri.parse('$_fsBase:commit'),
            headers: {'Authorization': 'Bearer $tok'}, body: jsonEncode({'writes': writes}));
        return r.statusCode;
      }

      Map<String, Object?> upd(String path, Map<String, Object?> fields) => {
            'update': {
              'name': '$_root/$path',
              'fields': {for (final e in fields.entries) e.key: FirebaseTransport.encodeValue(e.value)},
            },
            'updateMask': {'fieldPaths': fields.keys.toList()},
          };
      expect(await commit([upd('stores/${s.id}', {'environment': 'production'})]), 403, reason: 'environment fixed');
      expect(await commit([upd('stores/${s.id}', {'nextSeq': -1})]), 403, reason: 'nextSeq only grows');
      // A change outside the allocated range.
      await t.registerDevice(storeId: s.id, deviceId: 'dev-a', name: 'A');
      expect(
          await commit([
            {
              'update': {
                'name': '$_root/stores/${s.id}/changes/x1',
                'fields': {
                  'seq': {'integerValue': '5'},
                  'deviceId': {'stringValue': 'dev-a'},
                  'entity': {'stringValue': 'e'},
                  'entityId': {'stringValue': 'i'},
                  'op': {'stringValue': 'delete'},
                  'version': {'integerValue': '1'},
                  'payload': {'nullValue': null},
                },
              },
              'updateTransforms': [
                {'fieldPath': 'receivedAt', 'setToServerValue': 'REQUEST_TIME'},
              ],
            },
          ]),
          403);
      // Integers must be strings on the wire.
      expect(
          await commit([
            {
              'update': {
                'name': '$_root/stores/${s.id}',
                'fields': {
                  'nextSeq': {'integerValue': 5},
                },
              },
              'updateMask': {
                'fieldPaths': ['nextSeq'],
              },
            },
          ]),
          400);
    });
  });

  group('contract: SyncService over FirebaseTransport', () {
    test('create store, join, sales on two registers converge; tokens expire on the way', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final emu = _FirestoreEmulator()..addUser(_email, 'secret-pw');
      SyncTransport factory(SyncEndpoint e) => _transport(emu.client, endpoint: e);

      final dbA = memoryDb(), dbB = memoryDb();
      final a = SyncService(dbA, transportFactory: factory, deviceName: 'Касса A');
      final b = SyncService(dbB, transportFactory: factory, deviceName: 'Касса B');
      addTearDown(() async {
        a.dispose();
        b.dispose();
        await dbA.close();
        await dbB.close();
      });

      final owner = await AuthService(dbA).createUser(name: 'Владелец', role: Role.owner, pin: '2580');
      final pid = newId();
      await dbA.into(dbA.products).insert(ProductsCompanion.insert(id: pid, name: 'Чай', price: 1000));
      await StockService(dbA).receive(productId: pid, qty: 20, unitCost: 600, userId: owner.id);

      await a.signIn(endpoint: _endpoint, email: _email, password: 'secret-pw');
      final info = await a.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
      expect(await dbA.deviceCode(), 'A');

      await b.signIn(endpoint: _endpoint, email: _email, password: 'secret-pw');
      final listed = (await b.listStores()).single;
      expect([listed.id, listed.hasData], [info.id, isTrue]);
      await b.joinStore(info.id);
      expect(await dbB.deviceCode(), 'B');
      expect(await dbB.getSetting('setup_done'), '1');

      Future<void> sell(AppDatabase db, double qty) async {
        final shift = await ShiftService(db).open(userId: owner.id, openingCash: 0, registerId: 'reg-${db.hashCode}');
        await SaleService(db).checkout(CheckoutRequest(
          lines: [CheckoutLine(productId: pid, qty: qty, unitPrice: 1000)],
          payments: [PaymentInput('cash', (qty * 1000).round())],
          cashierId: owner.id,
          shiftId: shift.id,
        ));
      }

      // Tokens expire on the server: the next calls need the 401 refresh.
      emu.expireAccessTokens();
      await sell(dbA, 2);
      await sell(dbB, 3);
      await (dbA.update(dbA.products)..where((p) => p.id.equals(pid))).write(const ProductsCompanion(price: Value(1500)));
      for (var round = 0; round < 2; round++) {
        await a.syncNow();
        await b.syncNow();
      }
      expect(emu.refreshes, greaterThanOrEqualTo(2));

      for (final db in [dbA, dbB]) {
        final p = await (db.select(db.products)..where((p) => p.id.equals(pid))).getSingle();
        expect(p.stockQty, 15, reason: 'stock after 2 + 3 sold on two registers');
        expect(p.price, 1500);
        final nos = [for (final s in await db.select(db.sales).get()) docNo(s.number, s.deviceCode)]..sort();
        expect(nos, ['A-1', 'B-1']);
        expect(await SyncAggregates.verifyAll(db), isEmpty);
      }
      expect(dumpDiff(await dump(dbA), await dump(dbB)), isNull);
      expect(await a.pendingCount(), 0);
      expect(await b.pendingCount(), 0);

      // Server side: a gap-free log, counters and registers.
      final seqs = emu.changeSeqs(info.id);
      expect(seqs, [for (var i = 1; i <= seqs.length; i++) i]);
      expect(emu.fields('stores/${info.id}'), allOf(containsPair('nextSeq', seqs.length), containsPair('nextCode', 2)));
      expect(emu.docIds('stores/${info.id}/codes'), {'A', 'B'});
      expect(emu.fields('stores/${info.id}/devices/${await a.deviceId()}')['name'], 'Касса A');

      // Idempotency: another round changes nothing, neither here nor there.
      final before = await dump(dbA);
      final n = seqs.length;
      await a.syncNow();
      await b.syncNow();
      expect(dumpDiff(before, await dump(dbA)), isNull);
      expect(emu.changeSeqs(info.id), hasLength(n));

      // Only the refresh token is stored, never the password.
      final state = await dbA.customSelect('SELECT key, value FROM sync_state').get();
      final values = state.map((r) => r.read<String>('value')).join('|');
      expect(values, isNot(contains('secret-pw')));
      expect({for (final r in state) r.read<String>('key'): r.read<String>('value')},
          allOf(containsPair(SyncKeys.projectId, _project), containsPair(SyncKeys.apiKey, _apiKey)));
    });

    test('a push whose answer was lost is re-sent without duplicates', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final emu = _FirestoreEmulator()..addUser(_email, 'secret-pw');
      SyncTransport factory(SyncEndpoint e) => _transport(emu.client, endpoint: e);
      final db = memoryDb();
      final a = SyncService(db, transportFactory: factory);
      addTearDown(() async {
        a.dispose();
        await db.close();
      });
      await AuthService(db).createUser(name: 'Владелец', role: Role.owner, pin: '2580');
      await a.signIn(endpoint: _endpoint, email: _email, password: 'secret-pw');
      final info = await a.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
      final n = emu.changeSeqs(info.id).length;

      await db.into(db.products).insert(ProductsCompanion.insert(id: newId(), name: 'Чай', price: 1000));
      emu.loseNextCommitAnswer = true;
      await expectLater(a.syncNow(), throwsA(_kind(SyncErrorKind.network)));
      expect(emu.changeSeqs(info.id), hasLength(n + 1), reason: 'stored although the answer was lost');
      expect(await a.pendingCount(), 1);
      await a.syncNow();
      expect(emu.changeSeqs(info.id), hasLength(n + 1), reason: 'the retry is idempotent');
      expect(await a.pendingCount(), 0);
    });

    test('a refresh token rotated during a sync that then fails is stored: after a restart sync works', () async {
      final emu = _FirestoreEmulator()..addUser(_email, 'secret-pw');
      SyncTransport factory(SyncEndpoint e) => _transport(emu.client, endpoint: e);
      final db = memoryDb();
      final a = SyncService(db, transportFactory: factory);
      addTearDown(db.close);
      await AuthService(db).createUser(name: 'Владелец', role: Role.owner, pin: '2580');
      await a.signIn(endpoint: _endpoint, email: _email, password: 'secret-pw');
      await a.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
      Future<String?> stored() async => (await (db.select(db.syncState)..where((s) => s.key.equals(SyncKeys.refreshToken)))
              .getSingleOrNull())
          ?.value;
      final before = await stored();

      emu.expireAccessTokens();
      emu.failOps.add('commit');
      await db.into(db.products).insert(ProductsCompanion.insert(id: newId(), name: 'Чай', price: 1000));
      await expectLater(a.syncNow(), throwsA(_kind(SyncErrorKind.server)));
      expect(emu.refreshes, 1);
      expect(await stored(), allOf(isNotNull, isNot(before)), reason: 'the rotated token is kept after the failure');

      // App restart with the server healthy again: no «sign in again».
      a.dispose();
      emu.failOps.clear();
      final a2 = SyncService(db, transportFactory: factory);
      addTearDown(a2.dispose);
      await a2.syncNow();
      expect(await a2.pendingCount(), 0);
      expect((await a2.refreshStatus()).signedIn, isTrue);
    });

    test('a failed store listing after a refresh keeps the rotated token too', () async {
      final emu = _FirestoreEmulator()..addUser(_email, 'secret-pw');
      SyncTransport factory(SyncEndpoint e) => _transport(emu.client, endpoint: e);
      final db = memoryDb();
      final a = SyncService(db, transportFactory: factory);
      addTearDown(() async {
        a.dispose();
        await db.close();
      });
      await a.signIn(endpoint: _endpoint, email: _email, password: 'secret-pw');
      emu.expireAccessTokens();
      emu.failOps.add('list');
      await expectLater(a.listStores(), throwsA(isA<SyncException>()));
      expect(emu.refreshes, 1);
      final token = (await (db.select(db.syncState)..where((s) => s.key.equals(SyncKeys.refreshToken))).getSingle()).value;
      expect(emu.refreshTokenValid(token), isTrue, reason: 'the stored token is the live one');
    });

    test('wrong account settings surface as clear errors through the engine', () async {
      final emu = _FirestoreEmulator()..addUser(_email, 'secret-pw');
      SyncTransport factory(SyncEndpoint e) => _transport(emu.client, endpoint: e);
      final db = memoryDb();
      final a = SyncService(db, transportFactory: factory);
      addTearDown(() async {
        a.dispose();
        await db.close();
      });
      emu.emailSignInEnabled = false;
      await expectLater(a.signIn(endpoint: _endpoint, email: _email, password: 'secret-pw'),
          throwsA(_kind(SyncErrorKind.signInDisabled)));
      emu.emailSignInEnabled = true;
      await expectLater(
          a.signIn(endpoint: const SyncEndpoint(projectId: _project, apiKey: 'AIzaOtherProjectKey'), email: _email, password: 'secret-pw'),
          throwsA(_kind(SyncErrorKind.invalidApiKey)));
      final rows = await db.select(db.syncState).get();
      expect(rows.where((r) => r.key == SyncKeys.projectId), isEmpty, reason: 'nothing stored after a failed sign-in');
    });
  });

  group('review: streamed errors, key of another project, idempotent create', () {
    /// The emulator, with [rewrite] replacing the answer of every Firestore
    /// request whose path ends with `:[op]`.
    FirebaseTransport over(_FirestoreEmulator emu, String op, http.Response Function(http.Response real) rewrite) =>
        _transport(MockClient((r) async {
          final res = await emu.handle(r);
          return r.url.path.endsWith(':$op') ? rewrite(res) : res;
        }));

    http.Response streamError(int code, String status, [List<Object?> before = const []]) => _json([
          ...before,
          {
            'error': {'code': code, 'status': status, 'message': 'stream failed'},
          },
        ]);

    Future<(_FirestoreEmulator, StoreInfo)> storeWithDevice() async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test);
      await t.registerDevice(storeId: s.id, deviceId: 'dev-a', name: 'A');
      await t.push(storeId: s.id, deviceId: 'dev-a', changes: [
        for (var i = 1; i <= 3; i++)
          SyncChange(
              changeId: 'c$i', entity: 'products', entityId: 'p$i', op: SyncOp.upsert, version: i, deviceId: 'dev-a', payload: {'id': 'p$i'}),
      ]);
      return (emu, s);
    }

    test('an error element in a batchGet answer is a server error, never «store not found»', () async {
      final (emu, s) = await storeWithDevice();
      var t = over(emu, 'batchGet', (_) => streamError(503, 'UNAVAILABLE'));
      await t.signIn(email: _email, password: _password);
      await expectLater(t.registerDevice(storeId: s.id, deviceId: 'dev-b', name: 'B'),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'HTTP 503')));
      // After the store document, before the device: not «device not registered».
      t = over(emu, 'batchGet', (real) => streamError(503, 'UNAVAILABLE', [(jsonDecode(real.body) as List).first]));
      await t.signIn(email: _email, password: _password);
      await expectLater(
          t.push(storeId: s.id, deviceId: 'dev-a', changes: [
            const SyncChange(
                changeId: 'c9', entity: 'products', entityId: 'p9', op: SyncOp.upsert, version: 9, deviceId: 'dev-a', payload: {'id': 'p9'}),
          ]),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'HTTP 503')));
      // A cut-off answer (a requested document neither found nor missing).
      t = over(emu, 'batchGet', (real) => _json([(jsonDecode(real.body) as List).first]));
      await t.signIn(email: _email, password: _password);
      await expectLater(t.registerDevice(storeId: s.id, deviceId: 'dev-b', name: 'B'), throwsA(_kind(SyncErrorKind.protocol)));
      expect(emu.changeSeqs(s.id), [1, 2, 3], reason: 'nothing written');
      expect(emu.docIds('stores/${s.id}/devices'), {'dev-a'});
    });

    test('an ABORTED error element in a batchGet answer is contention: the transaction is retried', () async {
      final (emu, s) = await storeWithDevice();
      var failures = 1;
      final t = over(emu, 'batchGet', (real) => failures-- > 0 ? streamError(409, 'ABORTED') : real);
      await t.signIn(email: _email, password: _password);
      final reg = await t.registerDevice(storeId: s.id, deviceId: 'dev-b', name: 'B');
      expect(reg.code, 'B');
    });

    test('an error element after the first changes of a runQuery fails the pull, no short page', () async {
      final (emu, s) = await storeWithDevice();
      var t = over(emu, 'runQuery',
          (real) => streamError(504, 'DEADLINE_EXCEEDED', [(jsonDecode(real.body) as List).first]));
      await t.signIn(email: _email, password: _password);
      await expectLater(t.pull(storeId: s.id, since: 0),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'HTTP 504')));
      // An RPC code (4) instead of the HTTP one: mapped by the status.
      t = over(emu, 'runQuery', (_) => streamError(4, 'DEADLINE_EXCEEDED'));
      await t.signIn(email: _email, password: _password);
      await expectLater(t.pull(storeId: s.id, since: 0),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'HTTP 504')));
      t = over(emu, 'runQuery', (_) => streamError(401, 'UNAUTHENTICATED'));
      await t.signIn(email: _email, password: _password);
      await expectLater(t.pull(storeId: s.id, since: 0), throwsA(_kind(SyncErrorKind.auth)));
      // Without an error element the same page is complete.
      t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      expect((await t.pull(storeId: s.id, since: 0)).changes.map((c) => c.seq), [1, 2, 3]);
    });

    test('a sync whose pull answer ends with an error is not recorded as a success', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final emu = _FirestoreEmulator()..addUser(_email, 'secret-pw');
      var cut = false;
      SyncTransport factory(SyncEndpoint e) => _transport(MockClient((r) async {
            final res = await emu.handle(r);
            if (!cut || !r.url.path.endsWith(':runQuery')) return res;
            final list = jsonDecode(res.body) as List;
            return streamError(503, 'UNAVAILABLE', list.where((x) => (x as Map)['document'] != null).take(1).toList());
          }), endpoint: e);
      final db = memoryDb();
      final a = SyncService(db, transportFactory: factory);
      addTearDown(() async {
        a.dispose();
        await db.close();
      });
      await AuthService(db).createUser(name: 'Владелец', role: Role.owner, pin: '2580');
      await a.signIn(endpoint: _endpoint, email: _email, password: 'secret-pw');
      await a.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
      cut = true;
      await expectLater(a.syncNow(), throwsA(_kind(SyncErrorKind.server)));
      cut = false;
      await a.syncNow();
    });

    test('a Web API key of another project: sign-in stops with projectMismatch before any Firestore call', () async {
      final emu = _FirestoreEmulator()
        ..addUser(_email, _password)
        ..tokenProject = 'some-other-project';
      final t = _transport(emu.client);
      await expectLater(t.signIn(email: _email, password: _password), throwsA(_kind(SyncErrorKind.projectMismatch)));
      expect(t.session, isNull);
      expect(emu.requests.map((r) => r.url.host), ['identitytoolkit.googleapis.com']);
      expect(SyncException(SyncErrorKind.projectMismatch).message, isNotEmpty);

      // A stored session restored with such a key: the same, not «sign in again».
      emu.tokenProject = _project;
      final ok = _transport(emu.client);
      final s = await ok.signIn(email: _email, password: _password);
      emu.tokenProject = 'some-other-project';
      await expectLater(t.restoreSession(s.refreshToken), throwsA(_kind(SyncErrorKind.projectMismatch)));
      expect(t.session, isNull);

      // A token without an audience is malformed.
      final bad = _transport(MockClient((r) async => _json({
            'idToken': _jwt({'user_id': 'u1'}),
            'refreshToken': 'rt',
            'localId': 'u1',
            'expiresIn': '3600',
          })));
      await expectLater(bad.signIn(email: _email, password: _password), throwsA(_kind(SyncErrorKind.protocol)));
    });

    test('createStore with a caller id: a retry after a lost answer returns the same store', () async {
      final emu = _FirestoreEmulator()..addUser(_email, _password);
      final t = _transport(emu.client);
      await t.signIn(email: _email, password: _password);
      emu.loseNextCommitAnswer = true;
      await expectLater(t.createStore(name: 'M', environment: StoreEnvironment.test, storeId: 'store-1'),
          throwsA(_kind(SyncErrorKind.network)));
      final s = await t.createStore(name: 'M', environment: StoreEnvironment.test, storeId: 'store-1');
      expect(s.id, 'store-1');
      expect((await t.listStores()).map((s) => s.id), ['store-1']);
      expect(emu.docIds('stores'), {'store-1'});

      // The rules may refuse the member create (403) before the precondition.
      final strict = over(emu, 'commit', (real) => real.statusCode == 409 ? _gerr(403, 'PERMISSION_DENIED') : real);
      await strict.signIn(email: _email, password: _password);
      expect((await strict.createStore(name: 'M', environment: StoreEnvironment.test, storeId: 'store-1')).id, 'store-1');

      // Someone else's id is never taken over.
      emu.addUser('other@example.test', 'pw2');
      final other = _transport(emu.client);
      await other.signIn(email: 'other@example.test', password: 'pw2');
      await expectLater(other.createStore(name: 'M', environment: StoreEnvironment.test, storeId: 'store-1'),
          throwsA(_kind(SyncErrorKind.forbidden)));
      // Same account, different name: not the same create.
      await expectLater(t.createStore(name: 'N', environment: StoreEnvironment.test, storeId: 'store-1'),
          throwsA(_kind(SyncErrorKind.forbidden)));
      expect(emu.docIds('stores'), {'store-1'});
    });

    test('«Создать магазин» whose create answer was lost: the retry makes no second store', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final emu = _FirestoreEmulator()..addUser(_email, 'secret-pw');
      SyncTransport factory(SyncEndpoint e) => _transport(emu.client, endpoint: e);
      final db = memoryDb();
      final a = SyncService(db, transportFactory: factory);
      addTearDown(() async {
        a.dispose();
        await db.close();
      });
      await AuthService(db).createUser(name: 'Владелец', role: Role.owner, pin: '2580');
      await a.signIn(endpoint: _endpoint, email: _email, password: 'secret-pw');
      emu.loseNextCommitAnswer = true;
      await expectLater(a.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test),
          throwsA(_kind(SyncErrorKind.network)));
      expect(emu.docIds('stores'), hasLength(1), reason: 'the create reached the cloud');
      final info = await a.createStoreAndUpload(name: 'Магазин', environment: StoreEnvironment.test);
      expect(emu.docIds('stores'), {info.id}, reason: 'no empty twin');
      expect(await a.isConnected(), isTrue);

      // A create that never reached the cloud is simply sent again.
      final db2 = memoryDb();
      final b = SyncService(db2, transportFactory: factory);
      addTearDown(() async {
        b.dispose();
        await db2.close();
      });
      await AuthService(db2).createUser(name: 'Владелец', role: Role.owner, pin: '2580');
      await b.signIn(endpoint: _endpoint, email: _email, password: 'secret-pw');
      emu.failOps.add('commit');
      await expectLater(b.createStoreAndUpload(name: 'Склад', environment: StoreEnvironment.test),
          throwsA(_kind(SyncErrorKind.server)));
      emu.failOps.clear();
      final second = await b.createStoreAndUpload(name: 'Склад', environment: StoreEnvironment.test);
      expect(emu.docIds('stores'), {info.id, second.id});
    });
  });
}

// ===========================================================================
// In-memory Firestore REST + Identity Toolkit + Secure Token emulator.
//
// Implements what FirebaseTransport uses: signInWithPassword, token refresh
// (rotating refresh tokens), GET document, list collection (paged),
// beginTransaction / batchGet / commit / rollback (optimistic: a commit
// whose read documents changed since the read is ABORTED), runQuery
// (single field filter + order + limit). Preconditions (exists) and update
// masks / REQUEST_TIME transforms are applied, and every read and write is
// checked against the semantics of firebase/firestore.rules.
// ===========================================================================

class _Doc {
  _Doc(this.fields, this.version);
  final Map<String, Object?> fields; // encoded Firestore values
  final int version;
}

class _Tx {
  final reads = <String, int>{}; // path -> version read (0 = missing)
}

class _Denied implements Exception {}

class _BadRequest implements Exception {}

class _FirestoreEmulator {
  final _docs = <String, _Doc>{};
  final _users = <String, ({String uid, String password})>{}; // email ->
  final _refresh = <String, String>{}; // refresh token -> uid
  final _idTokens = <String, String>{}; // ID token -> uid
  final _tx = <String, _Tx>{};
  final requests = <http.Request>[];
  var _n = 0;
  var _version = 0;
  var refreshes = 0;
  bool emailSignInEnabled = true;
  bool rejectAllTokens = false;

  /// Project that issues the ID tokens (`aud` claim): another one simulates
  /// a Web API key of a different project.
  String tokenProject = _project;

  /// Page size of collection lists.
  int pageSize = 300;

  /// The next N commits answer 409 ABORTED.
  int abortCommits = 0;

  /// The next commit is applied but its answer is lost (network error).
  bool loseNextCommitAnswer = false;

  /// Operations answering 503: 'commit', 'batchGet', 'beginTransaction',
  /// 'runQuery', 'get', 'list'.
  final failOps = <String>{};
  Duration? delay;

  /// Called at the start of every commit (simulate a concurrent writer).
  Future<void> Function()? beforeCommit;

  late final MockClient client = MockClient((r) async {
    requests.add(r);
    if (delay != null) await Future<void>.delayed(delay!);
    return handle(r);
  });

  void addUser(String email, String password) => _users[email] = (uid: 'uid${_users.length + 1}x', password: password);
  String uidOf(String email) => _users[email]!.uid;

  void expireAccessTokens() => _idTokens.clear();
  void revokeRefreshTokens() => _refresh.clear();
  bool refreshTokenValid(String t) => _refresh.containsKey(t);

  Map<String, Object?> fields(String path) => _dec(_docs[path]!.fields);
  Set<String> docIds(String collection) => {
        for (final p in _docs.keys)
          if (p.startsWith('$collection/') && !p.substring(collection.length + 1).contains('/'))
            p.substring(collection.length + 1),
      };
  List<int> changeSeqs(String storeId) =>
      [for (final id in docIds('stores/$storeId/changes')) fields('stores/$storeId/changes/$id')['seq']! as int]..sort();

  void patch(String path, Map<String, Object?> values) => _docs[path] = _Doc(
      {..._docs[path]!.fields, for (final e in values.entries) e.key: FirebaseTransport.encodeValue(e.value)}, ++_version);
  void removeDoc(String path) => _docs.remove(path);

  /// What the owner does in the console to add another account.
  void addMember(String storeId, String uid) {
    final store = fields('stores/$storeId');
    _docs['stores/$storeId/members/$uid'] = _Doc({'role': FirebaseTransport.encodeValue('admin')}, ++_version);
    _docs['users/$uid/stores/$storeId'] = _Doc({
      'name': FirebaseTransport.encodeValue(store['name']),
      'environment': FirebaseTransport.encodeValue(store['environment']),
    }, ++_version);
  }

  static Map<String, Object?> _dec(Map<String, Object?> f) =>
      {for (final e in f.entries) e.key: FirebaseTransport.decodeValue(e.value)};

  String _issue(String uid, String email) {
    final id = _jwt({
      'iss': 'https://securetoken.google.com/$tokenProject',
      'aud': tokenProject,
      'user_id': uid,
      'email': email,
      'n': ++_n,
    });
    _idTokens[id] = uid;
    return id;
  }

  String _emailOf(String uid) => _users.entries.firstWhere((e) => e.value.uid == uid).key;

  Future<http.Response> handle(http.Request r) async {
    switch (r.url.host) {
      case 'identitytoolkit.googleapis.com':
        if (r.url.queryParameters['key'] != _apiKey) {
          return _gerr(400, 'INVALID_ARGUMENT',
              message: 'API key not valid. Please pass a valid API key.', reasons: ['API_KEY_INVALID']);
        }
        if (!emailSignInEnabled) return _authErr('OPERATION_NOT_ALLOWED');
        final body = jsonDecode(r.body) as Map;
        final u = _users[body['email']];
        if (u == null || u.password != body['password']) return _authErr('INVALID_LOGIN_CREDENTIALS');
        final refresh = 'rt-${++_n}';
        _refresh[refresh] = u.uid;
        return _json({
          'kind': 'identitytoolkit#VerifyPasswordResponse',
          'localId': u.uid,
          'email': body['email'],
          'idToken': _issue(u.uid, body['email'] as String),
          'refreshToken': refresh,
          'expiresIn': '3600',
          'registered': true,
        });
      case 'securetoken.googleapis.com':
        if (r.url.queryParameters['key'] != _apiKey) {
          return _gerr(400, 'INVALID_ARGUMENT',
              message: 'API key not valid. Please pass a valid API key.', reasons: ['API_KEY_INVALID']);
        }
        refreshes++;
        final form = Uri.splitQueryString(r.body);
        final uid = _refresh.remove(form['refresh_token']); // rotating
        if (form['grant_type'] != 'refresh_token' || uid == null) return _authErr('INVALID_REFRESH_TOKEN');
        final next = 'rt-${++_n}';
        _refresh[next] = uid;
        return _json({
          'access_token': 'ignored',
          'expires_in': '3600',
          'token_type': 'Bearer',
          'refresh_token': next,
          'id_token': _issue(uid, _emailOf(uid)),
          'user_id': uid,
          'project_id': '123',
        });
      case 'firestore.googleapis.com':
        return _firestore(r);
    }
    return _json({}, 404);
  }

  Future<http.Response> _firestore(http.Request r) async {
    const prefix = '/v1/$_root';
    final path = r.url.path;
    if (!path.startsWith(prefix)) return _gerr(404, 'NOT_FOUND', message: 'The database (default) does not exist');
    final auth = (r.headers['Authorization'] ?? '').replaceFirst('Bearer ', '');
    final uid = rejectAllTokens ? null : _idTokens[auth];
    if (uid == null) return _gerr(401, 'UNAUTHENTICATED', message: 'Request had invalid authentication credentials.');
    final rest = path.substring(prefix.length);
    try {
      if (r.method == 'GET') {
        final rel = rest.substring(1);
        final depth = rel.split('/').length;
        if (depth.isEven) {
          if (failOps.contains('get')) return _gerr(503, 'UNAVAILABLE');
          if (!_canRead(uid, rel)) throw _Denied();
          final d = _docs[rel];
          if (d == null) return _gerr(404, 'NOT_FOUND', message: 'Document "$rel" not found.');
          return _json(_wire(rel, d));
        }
        if (failOps.contains('list')) return _gerr(503, 'UNAVAILABLE');
        if (!_canList(uid, rel)) throw _Denied();
        final ids = docIds(rel).toList()..sort();
        final start = int.tryParse(r.url.queryParameters['pageToken'] ?? '') ?? 0;
        final size = math.min(pageSize, int.tryParse(r.url.queryParameters['pageSize'] ?? '') ?? pageSize);
        final page = ids.skip(start).take(size).toList();
        return _json({
          if (page.isNotEmpty) 'documents': [for (final id in page) _wire('$rel/$id', _docs['$rel/$id']!)],
          if (start + size < ids.length) 'nextPageToken': '${start + size}',
        });
      }
      final body = jsonDecode(r.body) as Map;
      if (rest == ':beginTransaction') {
        if (failOps.contains('beginTransaction')) return _gerr(503, 'UNAVAILABLE');
        final id = base64.encode(utf8.encode('tx-${++_n}'));
        _tx[id] = _Tx();
        return _json({'transaction': id});
      }
      if (rest == ':rollback') {
        _tx.remove(body['transaction']);
        return _json({});
      }
      if (rest == ':batchGet') {
        if (failOps.contains('batchGet')) return _gerr(503, 'UNAVAILABLE');
        final tx = _tx[body['transaction']];
        if (tx == null) return _gerr(400, 'INVALID_ARGUMENT');
        final out = <Object?>[];
        for (final name in body['documents'] as List) {
          final rel = (name as String).substring(_root.length + 1);
          if (!_canRead(uid, rel)) throw _Denied();
          final d = _docs[rel];
          tx.reads[rel] = d?.version ?? 0;
          out.add(d == null ? {'missing': name, 'readTime': 't'} : {'found': _wire(rel, d), 'readTime': 't'});
        }
        return _json(out);
      }
      if (rest == ':commit') return await _commit(uid, body);
      if (rest.endsWith(':runQuery')) {
        if (failOps.contains('runQuery')) return _gerr(503, 'UNAVAILABLE');
        final parent = rest.substring(1, rest.length - ':runQuery'.length);
        final q = body['structuredQuery'] as Map;
        final coll = '$parent/${(q['from'] as List).single['collectionId']}';
        if (!_canList(uid, coll)) throw _Denied();
        final filter = (q['where'] as Map)['fieldFilter'] as Map;
        expect(filter['op'], 'GREATER_THAN');
        final value = filter['value'] as Map;
        if (value['integerValue'] is! String) throw _BadRequest();
        final since = FirebaseTransport.decodeValue(value)! as int;
        final field = (filter['field'] as Map)['fieldPath'] as String;
        final docs = [
          for (final id in docIds(coll))
            if ((fields('$coll/$id')[field] as int) > since) '$coll/$id',
        ]..sort((a, b) => (fields(a)[field] as int).compareTo(fields(b)[field] as int));
        final limited = docs.take(q['limit'] as int).toList();
        if (limited.isEmpty) {
          return _json([
            {'readTime': 't'},
          ]);
        }
        return _json([
          for (final p in limited) {'document': _wire(p, _docs[p]!), 'readTime': 't'},
        ]);
      }
      return _gerr(400, 'INVALID_ARGUMENT');
    } on _Denied {
      return _gerr(403, 'PERMISSION_DENIED', message: 'Missing or insufficient permissions.');
    } on _BadRequest {
      return _gerr(400, 'INVALID_ARGUMENT', message: 'Invalid value');
    }
  }

  Map<String, Object?> _wire(String rel, _Doc d) =>
      {'name': '$_root/$rel', 'fields': d.fields, 'createTime': 't', 'updateTime': 't${d.version}'};

  static void _checkEncoding(Object? v) {
    if (v is! Map) throw _BadRequest();
    if (v.containsKey('integerValue') && v['integerValue'] is! String) throw _BadRequest();
  }

  Future<http.Response> _commit(String uid, Map body) async {
    final hook = beforeCommit;
    if (hook != null) await hook();
    if (failOps.contains('commit')) return _gerr(503, 'UNAVAILABLE');
    final txId = body['transaction'] as String?;
    _Tx? tx;
    if (txId != null) {
      tx = _tx.remove(txId);
      if (tx == null) return _gerr(400, 'INVALID_ARGUMENT', message: 'transaction');
    }
    if (abortCommits > 0) {
      abortCommits--;
      return _gerr(409, 'ABORTED', message: 'Transaction lock timeout.');
    }
    if (tx != null) {
      for (final e in tx.reads.entries) {
        if ((_docs[e.key]?.version ?? 0) != e.value) return _gerr(409, 'ABORTED', message: 'contention');
      }
    }
    final after = Map<String, _Doc>.of(_docs);
    final written = <String>[];
    for (final w in body['writes'] as List) {
      final u = (w as Map)['update'] as Map;
      final rel = (u['name'] as String).substring(_root.length + 1);
      final pre = w['currentDocument'] as Map?;
      if (pre?['exists'] == false && after.containsKey(rel)) return _gerr(409, 'ALREADY_EXISTS');
      if (pre?['exists'] == true && !after.containsKey(rel)) return _gerr(404, 'NOT_FOUND');
      final f = Map<String, Object?>.from(u['fields'] as Map? ?? const {});
      for (final v in f.values) {
        _checkEncoding(v);
      }
      final mask = w['updateMask'] as Map?;
      final Map<String, Object?> next;
      if (mask != null) {
        next = Map.of(after[rel]?.fields ?? const {});
        for (final p in (mask['fieldPaths'] as List? ?? const [])) {
          if (f.containsKey(p)) {
            next[p as String] = f[p];
          } else {
            next.remove(p);
          }
        }
      } else {
        next = f;
      }
      for (final t in (w['updateTransforms'] as List? ?? const [])) {
        expect((t as Map)['setToServerValue'], 'REQUEST_TIME');
        next[t['fieldPath'] as String] = {'timestampValue': '2026-11-26T10:00:00.000000Z'};
      }
      after[rel] = _Doc(next, ++_version);
      written.add(rel);
    }
    try {
      for (final rel in written) {
        _checkWrite(uid, rel, after);
      }
    } on _Denied {
      return _gerr(403, 'PERMISSION_DENIED', message: 'Missing or insufficient permissions.');
    }
    _docs
      ..clear()
      ..addAll(after);
    if (loseNextCommitAnswer) {
      loseNextCommitAnswer = false;
      throw http.ClientException('connection reset after commit');
    }
    return _json({
      'writeResults': [for (final _ in written) {'updateTime': 't'}],
      'commitTime': 't',
    });
  }

  // ------------------------------------------------- firestore.rules (Dart)

  bool _member(String storeId, String uid, [Map<String, _Doc>? state]) =>
      (state ?? _docs).containsKey('stores/$storeId/members/$uid');

  bool _canRead(String uid, String rel) {
    final s = rel.split('/');
    if (s[0] == 'stores' && s.length == 2) return !_docs.containsKey(rel) || _member(s[1], uid);
    if (s[0] == 'stores' && s.length == 4) return _member(s[1], uid);
    if (s[0] == 'users' && s.length == 4 && s[2] == 'stores') return s[1] == uid;
    return false;
  }

  bool _canList(String uid, String coll) {
    final s = coll.split('/');
    if (s[0] == 'stores' && s.length == 3) return _member(s[1], uid);
    if (s[0] == 'users' && s.length == 3 && s[2] == 'stores') return s[1] == uid;
    return false;
  }

  static bool _isTime(Object? v) => v is String && DateTime.tryParse(v) != null;

  void _checkWrite(String uid, String rel, Map<String, _Doc> after) {
    void need(bool ok) {
      if (!ok) throw _Denied();
    }

    Map<String, Object?>? before(String p) => _docs[p] == null ? null : _dec(_docs[p]!.fields);
    Map<String, Object?>? post(String p) => after[p] == null ? null : _dec(after[p]!.fields);
    final s = rel.split('/');
    final old = before(rel);
    final now = post(rel)!;
    Set<String> changed() => {
          for (final k in {...old!.keys, ...now.keys})
            if (jsonEncode(old[k]) != jsonEncode(now[k])) k,
        };
    if (s[0] == 'users') {
      need(s.length == 4 && s[2] == 'stores' && old == null && s[1] == uid);
      need(after.containsKey('stores/${s[3]}/members/$uid'));
      need(now['environment'] == post('stores/${s[3]}')?['environment']);
      return;
    }
    need(s[0] == 'stores');
    final storeId = s[1];
    final store = 'stores/$storeId';
    if (s.length == 2) {
      if (old == null) {
        need(now.keys.toSet().containsAll(
                ['name', 'environment', 'createdBy', 'createdAt', 'nextSeq', 'nextCode', 'hasData']) &&
            now.length == 7);
        need(now['createdBy'] == uid && now['nextSeq'] == 0 && now['nextCode'] == 0 && now['hasData'] == false);
        need(['test', 'production'].contains(now['environment']) && _isTime(now['createdAt']));
        need(after.containsKey('$store/members/$uid') && after.containsKey('users/$uid/stores/$storeId'));
      } else {
        need(_member(storeId, uid));
        need({'nextSeq', 'nextCode', 'hasData'}.containsAll(changed()));
        need((now['nextSeq'] as int) >= (old['nextSeq'] as int));
        need((now['nextCode'] as int) >= (old['nextCode'] as int));
        need(now['hasData'] == true || old['hasData'] == false);
      }
      return;
    }
    final kind = s[2];
    final id = s[3];
    switch (kind) {
      case 'members':
        need(old == null && id == uid && before(store) == null && post(store)?['createdBy'] == uid);
        need(now['role'] == 'owner' && _isTime(now['addedAt']));
      case 'devices':
        need(_member(storeId, uid));
        if (old == null) {
          need(RegExp(r'^[A-Z]{1,4}$').hasMatch(now['code'] as String) && _isTime(now['lastSeenAt']));
          need(post('$store/codes/${now['code']}')?['deviceId'] == id);
        } else {
          need(changed().every((k) => k == 'lastSeenAt') && _isTime(now['lastSeenAt']));
        }
      case 'codes':
        need(old == null && _member(storeId, uid));
        need(post('$store/devices/${now['deviceId']}')?['code'] == id);
        need(post(store)!['nextCode'] == (before(store)!['nextCode'] as int) + 1);
      case 'changes':
        need(old == null && _member(storeId, uid));
        final seq = now['seq'];
        need(seq is int && seq > (before(store)!['nextSeq'] as int) && seq <= (post(store)!['nextSeq'] as int));
        need(_docs.containsKey('$store/devices/${now['deviceId']}'));
        final version = now['version'];
        need(version is int && version >= 0 && version <= maxSyncVersion);
        need((now['op'] == 'upsert' && now['payload'] is String) || (now['op'] == 'delete' && now['payload'] == null));
        need(_isTime(now['receivedAt']));
      default:
        need(false);
    }
  }
}
