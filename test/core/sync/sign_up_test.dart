// Registering the owner account from the app («Создать аккаунт владельца»):
// FirebaseTransport.signUp against http/testing.dart MockClient (request,
// session, every error mapping), FakeSyncServer.signUp semantics and
// SyncService.signUp (persistence like signIn, never the password, guards).
// No real server is ever contacted and no real account is created.
import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/sync/firebase_transport.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/core/sync/transport.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers.dart';
import '../../support/fake_sync_server.dart';
import 'sync_harness.dart' show testEmail, testPassword, testEndpoint;

const _project = 'dreampos-unit-test';
const _apiKey = 'AIzaUnitTestKey_0123456789';
const _endpoint = SyncEndpoint(projectId: _project, apiKey: _apiKey);
const _email = 'owner@example.test';
const _password = 'new-owner-secret-42';
const _signUpUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey';

http.Response _json(Object? body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

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

/// Successful `accounts:signUp` answer of [project].
http.Response _signUpOk({String project = _project, String email = _email, String uid = 'uid-new-owner'}) => _json({
      'kind': 'identitytoolkit#SignupNewUserResponse',
      'idToken': _jwt({'aud': project, 'sub': uid, 'email': email}),
      'email': email,
      'refreshToken': 'refresh-token-of-new-owner',
      'expiresIn': '3600',
      'localId': uid,
    });

TypeMatcher<SyncException> _kind(SyncErrorKind k) => isA<SyncException>().having((e) => e.kind, 'kind', k);

FirebaseTransport _transport(http.Client client,
        {SyncEndpoint endpoint = _endpoint, Duration timeout = const Duration(seconds: 20)}) =>
    FirebaseTransport(endpoint, client: client, timeout: timeout, retryDelay: (_) => const Duration(milliseconds: 1));

/// Every value in every table of [db] as one string (to look for secrets).
Future<String> _everything(AppDatabase db) async {
  final tables = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
      .get();
  final out = StringBuffer();
  for (final t in tables) {
    final name = t.read<String>('name');
    for (final row in await db.customSelect('SELECT * FROM "$name"').get()) {
      out.writeln('$name ${row.data}');
    }
  }
  return out.toString();
}

Future<Map<String, String>> _syncState(AppDatabase db) async {
  final rows = await db.select(db.syncState).get();
  return {for (final r in rows) r.key: r.value};
}

void main() {
  setUp(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  group('FirebaseTransport.signUp', () {
    test('accounts:signUp request and session (no Authorization, password only in the body)', () async {
      final requests = <http.Request>[];
      final t = _transport(MockClient((r) async {
        requests.add(r);
        return _signUpOk();
      }));
      final s = await t.signUp(email: ' $_email ', password: _password);
      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.toString(), _signUpUrl);
      expect(r.url.toString(), isNot(contains(_password)));
      expect(r.headers.containsKey('Authorization'), isFalse);
      expect(r.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(r.body), {'email': _email, 'password': _password, 'returnSecureToken': true});
      expect(s.userId, 'uid-new-owner');
      expect(s.email, _email);
      expect(s.refreshToken, 'refresh-token-of-new-owner');
      expect(s.accessToken, isNotEmpty);
      expect(t.session, same(s));
      expect('$s $t', isNot(contains(_password)));
      expect('$s $t', isNot(contains(s.refreshToken)));
    });

    test('an invalid project id or key never sends the password', () async {
      final requests = <http.Request>[];
      final client = MockClient((r) async {
        requests.add(r);
        return _signUpOk();
      });
      await expectLater(
          _transport(client, endpoint: const SyncEndpoint(projectId: 'http://x', apiKey: _apiKey))
              .signUp(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.invalidProject)));
      await expectLater(
          _transport(client, endpoint: const SyncEndpoint(projectId: _project, apiKey: ''))
              .signUp(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.notConfigured)));
      await expectLater(
          _transport(client, endpoint: const SyncEndpoint(projectId: _project, apiKey: 'AIza bad key'))
              .signUp(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.invalidApiKey)));
      expect(requests, isEmpty);
    });

    test('sign-up errors map to their own kinds; no secret or free text in the detail', () async {
      final cases = <String, SyncErrorKind>{
        'EMAIL_EXISTS': SyncErrorKind.emailExists,
        'WEAK_PASSWORD : Password should be at least 6 characters': SyncErrorKind.weakPassword,
        'MISSING_PASSWORD': SyncErrorKind.weakPassword,
        'INVALID_EMAIL': SyncErrorKind.invalidEmail,
        'MISSING_EMAIL': SyncErrorKind.invalidEmail,
        // «Enable create (sign-up)» off.
        'ADMIN_ONLY_OPERATION': SyncErrorKind.signUpDisabled,
        // The Email/Password provider is off: name that, not sign-up
        // (Identity Toolkit: "Password sign-in is disabled for this project").
        'OPERATION_NOT_ALLOWED': SyncErrorKind.signInDisabled,
        'PASSWORD_LOGIN_DISABLED': SyncErrorKind.signInDisabled,
        'CONFIGURATION_NOT_FOUND': SyncErrorKind.signInDisabled,
        // The project's password policy, not just "too short".
        'PASSWORD_DOES_NOT_MEET_REQUIREMENTS : Missing password requirements: '
                '[Password must contain an upper case character]':
            SyncErrorKind.passwordPolicy,
        'TOO_MANY_ATTEMPTS_TRY_LATER : We have blocked all requests from this device due to unusual activity':
            SyncErrorKind.signUpTooManyAttempts,
        'USER_DISABLED': SyncErrorKind.accountDisabled,
        'API key not valid. Please pass a valid API key.': SyncErrorKind.invalidApiKey,
      };
      for (final e in cases.entries) {
        final t = _transport(MockClient((r) async => _authErr(e.key)));
        Object? err;
        try {
          await t.signUp(email: _email, password: _password);
        } catch (x) {
          err = x;
        }
        expect(err, _kind(e.value), reason: e.key);
        final ex = err as SyncException;
        expect('$ex ${ex.detail}', isNot(contains(_password)));
        expect(ex.detail ?? '', isNot(contains('Password should')), reason: 'no free text');
        expect(ex.detail ?? '', isNot(contains('unusual')), reason: 'no free text');
        expect(ex.detail ?? '', isNot(contains('Missing')), reason: 'no free text');
        expect(t.session, isNull);
      }
    });

    test('5xx -> server, malformed -> protocol, offline / timeout -> network', () async {
      await expectLater(
          _transport(MockClient((r) async => http.Response('oops', 503))).signUp(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.server).having((e) => e.detail, 'detail', 'HTTP 503')));
      await expectLater(
          _transport(MockClient((r) async => _json({'idToken': 'a'}))).signUp(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.protocol)));
      await expectLater(
          _transport(MockClient((r) async => http.Response('<html>', 200))).signUp(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.protocol)));
      await expectLater(
          _transport(MockClient((r) async => throw http.ClientException('Failed host lookup')))
              .signUp(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.network).having((e) => '${e.detail}', 'detail', isNot(contains(_password)))));
      await expectLater(
          _transport(MockClient((r) async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            return _signUpOk();
          }), timeout: const Duration(milliseconds: 20))
              .signUp(email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.network).having((e) => e.isTransient, 'transient', true)));
    });

    test('a key of another project -> projectMismatch, no session, the stray account is deleted', () async {
      final requests = <http.Request>[];
      final ok = _signUpOk(project: 'some-other-project');
      final idToken = (jsonDecode(ok.body) as Map)['idToken'] as String;
      final t = _transport(MockClient((r) async {
        requests.add(r);
        return r.url.path.endsWith('accounts:signUp') ? _signUpOk(project: 'some-other-project') : _json({});
      }));
      await expectLater(t.signUp(email: _email, password: _password), throwsA(_kind(SyncErrorKind.projectMismatch)));
      expect(t.session, isNull);
      expect(requests, hasLength(2));
      final del = requests.last;
      expect(del.method, 'POST');
      expect(del.url.toString(), 'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$_apiKey');
      expect(jsonDecode(del.body), {'idToken': idToken});
      expect(del.body, isNot(contains(_password)));
    });

    test('projectMismatch stays the error when deleting the stray account fails', () async {
      for (final fail in <Future<http.Response> Function()>[
        () async => throw http.ClientException('offline'),
        () async => _authErr('INVALID_ID_TOKEN'),
        () async => http.Response('oops', 500),
      ]) {
        var deletes = 0;
        final t = _transport(MockClient((r) async {
          if (r.url.path.endsWith('accounts:signUp')) return _signUpOk(project: 'some-other-project');
          deletes++;
          return fail();
        }));
        await expectLater(
            t.signUp(email: _email, password: _password), throwsA(_kind(SyncErrorKind.projectMismatch)));
        expect(deletes, 1);
        expect(t.session, isNull);
      }
    });

    test('a matching project never deletes anything', () async {
      final paths = <String>[];
      final t = _transport(MockClient((r) async {
        paths.add(r.url.path);
        return _signUpOk();
      }));
      await t.signUp(email: _email, password: _password);
      expect(paths, ['/v1/accounts:signUp']);
    });

    test('wording: provider off names Email/Password, policy points to the project, no «Register» ambiguity',
        () async {
      final ru = await AppLocalizations.delegate.load(const Locale('ru'));
      final t = _transport(MockClient((r) async => _authErr('OPERATION_NOT_ALLOWED')));
      final e = await t.signUp(email: _email, password: _password).then<Object?>((_) => null, onError: (Object e) => e);
      expect((e as SyncException).messageIn(ru), contains('Email/Password'));
      expect(e.messageIn(ru), isNot(contains('регистрац')));
      expect(SyncException(SyncErrorKind.passwordPolicy).messageIn(ru), contains('Password policy'));
      expect(SyncException(SyncErrorKind.signUpDisabled).messageIn(ru), contains('Enable create (sign-up)'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(en.syncNoAccountSignUp.toLowerCase(), isNot(contains('register')));
      expect(en.syncPasswordNewHelp.toLowerCase(), isNot(contains('register')));
      final uz = await AppLocalizations.delegate.load(const Locale('uz'));
      expect(uz.syncPasswordMismatch, 'Parollar mos kelmaydi');
    });

    test('every new error kind has a message in each language', () async {
      for (final lang in ['ru', 'uz', 'ky', 'en']) {
        final l = await AppLocalizations.delegate.load(Locale(lang));
        final seen = <String>{};
        for (final k in [
          SyncErrorKind.emailExists,
          SyncErrorKind.weakPassword,
          SyncErrorKind.passwordPolicy,
          SyncErrorKind.invalidEmail,
          SyncErrorKind.signUpDisabled,
          SyncErrorKind.signUpTooManyAttempts,
        ]) {
          final m = SyncException(k, detail: 'ADMIN_ONLY_OPERATION').messageIn(l);
          expect(m, isNotEmpty, reason: '$lang $k');
          expect(m, isNot(contains('ADMIN_ONLY_OPERATION')), reason: 'detail is technical');
          expect(seen.add(m), isTrue, reason: '$lang $k: distinct message');
        }
      }
    });
  });

  group('FakeSyncServer.signUp', () {
    test('same semantics: new account signs in, duplicates / weak / bad e-mail / disabled refused', () async {
      final server = FakeSyncServer()..addUser(testEmail, testPassword);
      final s = await server.client().signUp(email: ' New@Example.test ', password: 'longenough');
      expect(s.email, 'new@example.test');
      expect(server.passwordOf('new@example.test'), 'longenough');
      // The new account can sign in and has no stores.
      final c = server.client();
      await c.signIn(email: 'new@example.test', password: 'longenough');
      expect(await c.listStores(), isEmpty);
      await expectLater(server.client().signUp(email: testEmail.toUpperCase(), password: 'longenough'),
          throwsA(_kind(SyncErrorKind.emailExists)));
      await expectLater(
          server.client().signUp(email: 'x@example.test', password: '12345'), throwsA(_kind(SyncErrorKind.weakPassword)));
      await expectLater(
          server.client().signUp(email: 'not-an-email', password: 'longenough'), throwsA(_kind(SyncErrorKind.invalidEmail)));
      server.signUpDisabled = true;
      await expectLater(server.client().signUp(email: 'y@example.test', password: 'longenough'),
          throwsA(_kind(SyncErrorKind.signUpDisabled)));
      server
        ..signUpDisabled = false
        ..offline = true;
      await expectLater(
          server.client().signUp(email: 'y@example.test', password: 'longenough'), throwsA(_kind(SyncErrorKind.network)));
    });
  });

  group('SyncService.signUp', () {
    test('stores the endpoint, e-mail and refresh token like signIn — never the password', () async {
      final server = FakeSyncServer();
      final db = memoryDb();
      final svc = SyncService(db, transportFactory: (_) => server.client());
      addTearDown(() async {
        svc.dispose();
        await db.close();
      });
      final s = await svc.signUp(endpoint: testEndpoint, email: ' boss@example.test ', password: _password);
      expect(s.email, 'boss@example.test');
      final st = await _syncState(db);
      expect(st[SyncKeys.projectId], testEndpoint.projectId);
      expect(st[SyncKeys.apiKey], testEndpoint.apiKey);
      expect(st[SyncKeys.email], 'boss@example.test');
      expect(st[SyncKeys.refreshToken], s.refreshToken);
      expect(st[SyncKeys.connected], isNull, reason: 'signed in, not connected yet');
      expect(await _everything(db), isNot(contains(_password)));
      // Continues exactly like after sign-in: create the cloud store.
      final info = await svc.createStoreAndUpload(name: 'Новый магазин', environment: StoreEnvironment.test);
      expect(await svc.isConnected(), isTrue);
      expect(server.store(info.id).members[server.userIdOf('boss@example.test')], 'owner');
      expect(await _everything(db), isNot(contains(_password)));
    });

    test('through FirebaseTransport: nothing but the refresh token is kept, request sent once', () async {
      final requests = <http.Request>[];
      final db = memoryDb();
      final svc = SyncService(db, transportFactory: (e) => _transport(MockClient((r) async {
            requests.add(r);
            return _signUpOk();
          }), endpoint: e));
      addTearDown(() async {
        svc.dispose();
        await db.close();
      });
      await svc.signUp(endpoint: _endpoint, email: _email, password: _password);
      expect(requests.single.url.toString(), _signUpUrl);
      final st = await _syncState(db);
      expect(st[SyncKeys.refreshToken], 'refresh-token-of-new-owner');
      expect(st[SyncKeys.email], _email);
      expect(await _everything(db), isNot(contains(_password)));
      expect(await _everything(db), isNot(contains('idToken')));
    });

    test('a refused sign-up stores nothing', () async {
      final server = FakeSyncServer()..addUser(testEmail, testPassword);
      final db = memoryDb();
      final svc = SyncService(db, transportFactory: (_) => server.client());
      addTearDown(() async {
        svc.dispose();
        await db.close();
      });
      await expectLater(svc.signUp(endpoint: testEndpoint, email: testEmail, password: _password),
          throwsA(_kind(SyncErrorKind.emailExists)));
      expect(await _syncState(db), isNot(contains(SyncKeys.refreshToken)));
      expect(await _syncState(db), isNot(contains(SyncKeys.projectId)));
      expect(await _everything(db), isNot(contains(_password)));
    });

    test('guards: no transport -> notConfigured; a connected database -> alreadyConnected', () async {
      final db0 = memoryDb();
      final none = SyncService(db0);
      await expectLater(none.signUp(endpoint: testEndpoint, email: _email, password: _password),
          throwsA(_kind(SyncErrorKind.notConfigured)));
      none.dispose();
      await db0.close();

      final server = FakeSyncServer()..addUser(testEmail, testPassword);
      final db = memoryDb();
      final svc = SyncService(db, transportFactory: (_) => server.client());
      addTearDown(() async {
        svc.dispose();
        await db.close();
      });
      await svc.signIn(endpoint: testEndpoint, email: testEmail, password: testPassword);
      await svc.createStoreAndUpload(name: 'M', environment: StoreEnvironment.test);
      final token = (await _syncState(db))[SyncKeys.refreshToken];
      await expectLater(svc.signUp(endpoint: testEndpoint, email: 'second@example.test', password: _password),
          throwsA(_kind(SyncErrorKind.alreadyConnected)));
      expect(server.signUpCalls, 0, reason: 'refused before contacting the cloud');
      expect((await _syncState(db))[SyncKeys.refreshToken], token, reason: 'the store account stays');
    });

    test('runs exclusively with other engine operations', () async {
      final server = FakeSyncServer();
      final db = memoryDb();
      final svc = SyncService(db, transportFactory: (_) => server.client());
      addTearDown(() async {
        svc.dispose();
        await db.close();
      });
      final a = svc.signUp(endpoint: testEndpoint, email: 'a@example.test', password: _password);
      final b = svc.signUp(endpoint: testEndpoint, email: 'a@example.test', password: _password);
      await a;
      await expectLater(b, throwsA(_kind(SyncErrorKind.emailExists)));
      expect(server.signUpCalls, 2);
    });
  });
}
