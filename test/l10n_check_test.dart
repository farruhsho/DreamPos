// Localization guard rails (docs/L10N.md):
//  - ARB fragments merge cleanly and lib/l10n/app_*.arb is up to date;
//  - no hard-coded Cyrillic text in lib/ outside folders listed in
//    tool/l10n_pending.txt (module agents delete their line when done);
//  - runtime plumbing: L.current / L.receipt, uiLocaleProvider, Material support.
import 'dart:io';

import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/permissions.dart';
import 'package:dreampos/core/providers.dart';
import 'package:dreampos/core/security/pin.dart';
import 'package:dreampos/core/widgets/widgets.dart';
import 'package:dreampos/domain/services/sale_service.dart' show paymentMethodLabel;
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/l10n_check_lib.dart';
import '../tool/l10n_merge_lib.dart';

void main() {
  final root = Directory.current.path;

  tearDown(L.reset);

  group('ARB fragments', () {
    test('merge without errors and committed app_*.arb are up to date', () {
      final r = mergeFragments(root);
      expect(r.errors, isEmpty, reason: r.errors.join('\n'));
      for (final lang in l10nLanguages) {
        final committed = File('$root/lib/l10n/app_$lang.arb').readAsStringSync().replaceAll('\r\n', '\n');
        expect(committed, r.arbText(lang),
            reason: 'lib/l10n/app_$lang.arb is stale: run `dart run tool/l10n_merge.dart`');
      }
    });

    test('validations catch broken fragments', () {
      final tmp = Directory.systemTemp.createTempSync('l10n_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      void frag(String m, String lang, String json) =>
          (File('${tmp.path}/lib/l10n/src/$m/$lang.arb')..createSync(recursive: true)).writeAsStringSync(json);
      frag('core', 'ru', '{"commonA": "А {x}", "commonB": "Б", "commonC": "В", "bad_key": "x"}');
      frag('core', 'uz', '{"commonA": "A", "commonB": "", "commonC": "Ц"}');
      frag('core', 'ky', '{"commonA": "А {x}", "commonB": "Б", "commonC": "В", "bad_key": "x"}');
      frag('core', 'en', '{"commonA": "A {x}", "commonB": "B", "commonC": "C", "bad_key": "x", "commonZ": "z"}');
      frag('pos', 'ru', '{"commonA": "dup", "posX": "Х"}');
      frag('pos', 'uz', '{"commonA": "dup", "posX": "X"}');
      frag('pos', 'ky', '{"commonA": "dup"}');
      frag('pos', 'en', '{"commonA": "dup", "posX": "X"}');
      frag('pos', 'tg', '{}');
      final e = mergeFragments(tmp.path).errors.join('\n');
      expect(e, contains('placeholders')); // uz commonA lost {x}
      expect(e, contains('"commonB" is empty'));
      expect(e, contains('missing key "bad_key"')); // uz
      expect(e, contains('contains Cyrillic')); // uz commonC
      expect(e, contains('not camelCase'));
      expect(e, contains('key "commonZ" is not in ru'));
      expect(e, contains('duplicate key "commonA"'));
      expect(e, contains('must start with pos'));
      expect(e, contains('missing key "posX"')); // ky
      expect(e, contains('unsupported language'));
    });

    test('ICU argument parser', () {
      expect(icuArguments('{count, plural, one{{count} item} other{{count} items}}'), {'count': 'plural'});
      expect(icuArguments('Чек №{number} · {time}'), {'number': 'simple', 'time': 'simple'});
      expect(() => icuArguments('broken {'), throwsFormatException);
    });
  });

  group('hard-coded text', () {
    test('no Cyrillic string literals in lib/ (except tool/l10n_pending.txt folders)', () {
      final found = findCyrillicLiterals(root: root);
      expect(found, isEmpty,
          reason: 'Move these strings to lib/l10n/src/<module>/*.arb (docs/L10N.md):\n${found.join('\n')}');
    });

    test('core, app, domain and auth are never pending', () {
      final pending = readPending(root);
      for (final m in ['core', 'app', 'domain', 'auth']) {
        expect(pending, isNot(contains(modulePath(m))));
      }
    });

    test('pending and allowlist entries point to existing paths', () {
      for (final p in readPending(root)) {
        expect(Directory('$root/$p').existsSync(), isTrue, reason: 'stale tool/l10n_pending.txt entry: $p');
      }
      for (final e in Allowlist.load(root).entries) {
        final path = e.split(' | ').first.trim();
        final ok = path.endsWith('/')
            ? Directory('$root/$path').existsSync()
            : File('$root/$path').existsSync();
        expect(ok, isTrue, reason: 'stale tool/l10n_allow.txt entry: $e');
      }
    });

    test('lexer skips comments and finds nested literals', () {
      final lits = scanStringLiterals("""
// 'коммент'
/* 'блок' */
final a = 'да';
final b = '\${x ? 'нет' : ''}';
final c = r'\\d+';
""").map((l) => l.ownText).toList();
      expect(lits, containsAll(['да', 'нет']));
      expect(lits.any((l) => l.contains('коммент') || l.contains('блок')), isFalse);
    });
  });

  group('runtime', () {
    test('every language loads; Material/Cupertino support ru/uz/ky/en', () {
      for (final code in supportedLanguageCodes) {
        expect(L.of(code).localeName, code);
        final loc = Locale(code);
        expect(AppLocalizations.delegate.isSupported(loc), isTrue);
        expect(GlobalMaterialLocalizations.delegate.isSupported(loc), isTrue, reason: code);
        expect(GlobalCupertinoLocalizations.delegate.isSupported(loc), isTrue, reason: code);
        expect(GlobalWidgetsLocalizations.delegate.isSupported(loc), isTrue, reason: code);
      }
      expect(L.of('tg').localeName, 'ru'); // Tajik is not supported -> ru
      expect(L.normalize('uz_UZ'), 'uz');
    });

    test('defaults to ru; L.current drives domain/core text', () {
      expect(L.current.localeName, 'ru');
      expect(PinHasher.validate('1'), 'PIN — от 4 до 8 цифр');
      expect(Role.cashier.label, 'Кассир');
      expect(Qty.format(2, 'pcs'), '2 шт');
      L.setCurrent('en');
      expect(PinHasher.validate('1'), 'PIN must be 4–8 digits');
      expect(Role.cashier.label, 'Cashier');
      expect(Qty.format(2, 'pcs'), '2 pcs');
      expect(paymentMethodLabel('cash'), 'Cash');
      expect(paymentMethodLabel('cash', L.of('ky')), 'Накталай');
    });

    test('ICU plurals replace pluralRu (same Russian output)', () {
      for (final n in [0, 1, 2, 4, 5, 11, 12, 14, 21, 22, 25, 101, 111]) {
        expect(L.of('ru').commonReceiptsCount(n), '$n ${pluralRu(n, 'чек', 'чека', 'чеков')}');
        expect(L.of('ru').commonPositionsCount(n), '$n ${pluralRu(n, 'позиция', 'позиции', 'позиций')}');
      }
      expect(L.of('en').commonReceiptsCount(1), '1 receipt');
      expect(L.of('en').commonReceiptsCount(5), '5 receipts');
      expect(L.of('uz').commonReceiptsCount(5), '5 ta chek');
      expect(L.of('ky').commonReceiptsCount(5), '5 чек');
    });

    test('receipt language comes from receipt_locale', () {
      expect(L.forReceipt({}).localeName, 'ru');
      expect(L.forReceipt({'receipt_locale': 'uz'}).corePrintTotal, 'JAMI');
      expect(L.printable('Oʻtkazma'), 'O‘tkazma');
    });

    test('uiLocaleProvider: default ru, set() persists and updates L.current', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(uiLocaleProvider), 'ru');
      await c.read(uiLocaleProvider.notifier).set('ky');
      expect(c.read(uiLocaleProvider), 'ky');
      expect(L.current.localeName, 'ky');
      expect((await SharedPreferences.getInstance()).getString('ui_locale'), 'ky');
    });

    test('uiLocaleProvider loads the saved preference', () async {
      SharedPreferences.setMockInitialValues({'ui_locale': 'uz'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(uiLocaleProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(uiLocaleProvider), 'uz');
    });

    testWidgets('context.l10n follows the app locale and falls back to L.current', (tester) async {
      String? seen;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        seen = c.l10n.commonSave;
        return const SizedBox();
      })));
      expect(seen, 'Сохранить'); // no delegate -> L.current (ru)
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('uz'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(builder: (c) {
          seen = c.l10n.commonSave;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();
      expect(seen, 'Saqlash');
    });
  });
}
