import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/domain/services/sale_service.dart';
import 'package:dreampos/domain/services/shift_service.dart';
import 'package:dreampos/features/settings/backup_service.dart';
import 'package:dreampos/features/settings/settings_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

const uzs = CurrencyConfig();

/// Money.format groups with a non-breaking space; normalize for readable asserts.
String n(String s) => s.replaceAll(RegExp('[  ]'), ' ');
final tjs = CurrencyConfig.presets.firstWhere((c) => c.code == 'TJS');

void main() {
  group('banknotes', () {
    test('parses, sorts and stores minor units', () {
      final r = parseBanknotes('50000, 1 000; 10000\n5000', uzs);
      expect(r.ok, isTrue);
      expect(r.values, [1000, 5000, 10000, 50000]);
      expect(r.stored, '1000,5000,10000,50000');
    });

    test('empty input means defaults', () {
      final r = parseBanknotes('  ,  ', uzs);
      expect(r.ok, isTrue);
      expect(r.values, isEmpty);
      expect(r.stored, '');
    });

    test('rejects junk, zero, duplicates, too many and fractions for UZS', () {
      expect(parseBanknotes('1000, abc', uzs).error, contains('не число'));
      expect(parseBanknotes('0', uzs).error, contains('больше нуля'));
      expect(parseBanknotes('1000, 1000', uzs).error, contains('дважды'));
      expect(
        parseBanknotes(List.generate(11, (i) => '${i + 1}').join(','), uzs).error,
        contains('Не больше'),
      );
      expect(parseBanknotes('0.5', uzs).error, contains('нет дробных'));
      expect(parseBanknotes('-5', uzs).ok, isFalse);
    });

    test('decimal currencies use minor units', () {
      final r = parseBanknotes('0.5, 1, 20', tjs);
      expect(r.values, [50, 100, 2000]);
      expect(banknotesToInput(r.stored, tjs), '0.5, 1, 20');
      expect(parseBanknotes('0.555', tjs).ok, isFalse);
    });

    test('round trip and defaults', () {
      expect(banknotesToInput('1000,5000', uzs), '1000, 5000');
      expect(decodeBanknotes('1000,x,,-5,200'), [1000, 200]);
      expect(defaultBanknotes(tjs).first, 100);
      expect(defaultBanknotes(uzs), contains(100000));
    });
  });

  group('validators', () {
    test('percent range and format', () {
      expect(validatePercent('2'), isNull);
      expect(validatePercent('2,5'), isNull);
      expect(validatePercent('100'), isNull);
      expect(validatePercent('0'), isNull);
      expect(validatePercent('101'), isNotNull);
      expect(validatePercent('-1'), isNotNull);
      expect(validatePercent('abc'), isNotNull);
      expect(validatePercent(''), isNotNull);
      expect(validatePercent('', allowEmpty: true), isNull);
      expect(validatePercent('1,234'), contains('двух знаков'));
      expect(validatePercent('30', max: 25), isNotNull);
      expect(parsePercent('12,5 %'), 12.5);
      expect(formatPercentValue(2), '2');
      expect(formatPercentValue(2.5), '2.5');
    });

    test('return days', () {
      expect(validateReturnDays('0'), isNull);
      expect(validateReturnDays('14'), isNull);
      expect(validateReturnDays('-1'), isNotNull);
      expect(validateReturnDays('1.5'), isNotNull);
      expect(validateReturnDays('4000'), isNotNull);
      expect(validateReturnDays(''), isNotNull);
    });

    test('store fields', () {
      expect(validateStoreName('  '), isNotNull);
      expect(validateStoreName('Магазин'), isNull);
      expect(validatePhone(''), isNull);
      expect(validatePhone('+998 (90) 123-45-67'), isNull);
      expect(validatePhone('12'), isNotNull);
      expect(validatePhone('tel 123456'), isNotNull);
      expect(validateTaxId('123456789'), isNull);
      expect(validateTaxId('12345'), isNotNull);
      expect(validateTaxId('12345678A'), isNotNull);
      expect(validateReceiptFooter('a\nb\nc\nd\ne\nf\ng'), isNotNull);
      expect(validateReceiptFooter('Спасибо!'), isNull);
    });
  });

  test('cash rounding', () {
    expect(roundCash(12370, 100), 12400);
    expect(roundCash(12349, 100), 12300);
    expect(roundCash(12350, 100), 12400);
    expect(roundCash(12370, 0), 12370);
    expect(roundCash(12370, 1000), 12000);
    expect(cashRoundingLabel('none', uzs), 'Без округления');
    expect(n(cashRoundingLabel('500', uzs)), 'Кратно 500 сум');
  });

  test('loyalty example', () {
    final s = n(loyaltyExample(2, 50, uzs));
    expect(s, contains('С покупки 100 000 начислится 2 000 бонусов'));
    expect(s, contains('50%'));
    expect(s, contains('50 000 сум'));
  });

  group('backup naming', () {
    test('file name format', () {
      expect(backupFileName(DateTime(2026, 3, 7, 9, 5)), 'dreampos-20260307-0905.sqlite');
      expect(isBackupFileName('dreampos-20260307-0905.sqlite'), isTrue);
      expect(isBackupFileName('dreampos-20260307-0905-2.sqlite'), isTrue);
      expect(isBackupFileName('other.sqlite'), isFalse);
      expect(backupDateFromName('dreampos-20261124-2359.sqlite'), DateTime(2026, 11, 24, 23, 59));
      expect(backupDateFromName('x'), isNull);
    });

    test('sqlite header detection and sizes', () {
      expect(looksLikeSqlite([...'SQLite format 3'.codeUnits, 0]), isTrue);
      expect(looksLikeSqlite('Hello world, not sqlite'.codeUnits), isFalse);
      expect(formatBytes(512), '512 Б');
      expect(formatBytes(2048), '2 КБ');
      expect(formatBytes(3 * 1024 * 1024 + 512 * 1024), '3,5 МБ');
    });
  });

  test('trial days left', () {
    final at = DateTime(2026, 11, 1, 10);
    expect(trialDaysLeft(at, DateTime(2026, 11, 1, 10)), 30);
    expect(trialDaysLeft(at, DateTime(2026, 11, 2, 9)), 30); // partial day counts
    expect(trialDaysLeft(at, DateTime(2026, 11, 30, 10)), 1);
    expect(trialDaysLeft(at, DateTime(2026, 12, 1, 10)), 0);
    expect(trialDaysLeft(at, DateTime(2027, 1, 1)), 0);
    // clock set before the install date must not exceed the full period
    expect(trialDaysLeft(at, DateTime(2026, 6, 1)), 30);
  });

  test('csv escaping', () {
    expect(csvRow(['a', 'b;c', 'say "hi"', null, 5]), 'a;"b;c";"say ""hi""";;5');
    expect(csvMoney(123450, tjs), '1234,5');
    expect(csvQty(1.5), '1,5');
    // formula injection is neutralised, numbers are kept
    expect(
      csvRow(['=HYPERLINK("x")', '+7', '@SUM(A1)', '-5', '-1,5', '-abc']),
      '"\'=HYPERLINK(""x"")";\'+7;\'@SUM(A1);-5;-1,5;\'-abc',
    );
  });

  test('sample receipt uses store settings and width', () {
    final txt = sampleReceiptText(
      {
        'store_name': 'Мой магазин',
        'store_phone': '+998 90 000-00-00',
        'receipt_footer': 'Спасибо!\nЖдём снова',
      },
      width: 32,
      now: DateTime(2026, 1, 2, 3, 4),
    );
    expect(txt, contains('Мой магазин'));
    expect(txt, contains('Тел: +998 90 000-00-00'));
    expect(txt, contains('Ждём снова'));
    expect(txt, contains('ИТОГО'));
    for (final l in txt.split('\n')) {
      expect(l.length, lessThanOrEqualTo(32), reason: l);
    }
    expect(receiptCharsForWidth('58'), 32);
    expect(receiptCharsForWidth(null), 42);
  });

  group('db', () {
    late Fixture f;
    setUp(() async => f = await Fixture.create());
    tearDown(() => f.db.close());

    test('saveSettings writes only changes and audits old -> new', () async {
      await f.db.setSetting('store_name', 'Old');
      final n = await saveSettings(f.db, {'store_name': 'New', 'return_days': '7'}, userId: f.owner.id);
      expect(n, 2);
      expect(await f.db.getSetting('store_name'), 'New');
      final again = await saveSettings(f.db, {'store_name': 'New'}, userId: f.owner.id);
      expect(again, 0);
      final audit = await (f.db.select(
        f.db.auditLog,
      )..where((a) => a.action.equals('settings.change'))).get();
      expect(audit, hasLength(2));
      expect(audit.map((a) => a.details), contains('store_name: Old → New'));
      expect(audit.map((a) => a.details), contains('return_days: — → 7'));
      expect(audit.every((a) => a.userId == f.owner.id), isTrue);
    });

    test('currency is locked once a sale exists', () async {
      expect(await hasAnySale(f.db), isFalse);
      final stream = watchHasAnySale(f.db);
      expect(await stream.first, isFalse);
      final p = await f.product('Milk', price: 1500, stock: 5);
      await SaleService(f.db).checkout(
        CheckoutRequest(
          lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 1500)],
          payments: [PaymentInput('cash', 1500)],
          cashierId: f.owner.id,
          shiftId: f.shift.id,
        ),
      );
      expect(await hasAnySale(f.db), isTrue);
      expect(await watchHasAnySale(f.db).first, isTrue);
    });

    test('currency settings for preset', () {
      expect(currencySettings(tjs), {
        'currency_code': 'TJS',
        'currency_symbol': 'сом.',
        'currency_decimals': '2',
        'currency_symbol_before': '0',
      });
    });

    test('currency change resets cash settings stored in old minor units', () {
      expect(currencyChangeSettings(tjs, {}), currencySettings(tjs));
      final ch = currencyChangeSettings(tjs, {'pos_banknotes': '1000,5000', 'cash_rounding': '100'});
      expect(ch['pos_banknotes'], '');
      expect(ch['cash_rounding'], 'none');
      expect(currencyChangeSettings(tjs, {'cash_rounding': 'none'}).containsKey('cash_rounding'), isFalse);
    });

    test('changeCurrency writes atomically and refuses after a sale', () async {
      await f.db.setSetting('pos_banknotes', '1000,5000');
      await changeCurrency(f.db, tjs, {'pos_banknotes': '1000,5000'}, userId: f.owner.id);
      expect(await f.db.getSetting('currency_code'), 'TJS');
      expect(await f.db.getSetting('currency_decimals'), '2');
      expect(await f.db.getSetting('pos_banknotes'), '');

      final p = await f.product('Milk', price: 1500, stock: 5);
      await SaleService(f.db).checkout(
        CheckoutRequest(
          lines: [CheckoutLine(productId: p.id, qty: 1, unitPrice: 1500)],
          payments: [PaymentInput('cash', 1500)],
          cashierId: f.owner.id,
          shiftId: f.shift.id,
        ),
      );
      await expectLater(changeCurrency(f.db, uzs, {}), throwsA(isA<Exception>()));
      expect(await f.db.getSetting('currency_code'), 'TJS');
    });

    test('register with an open shift cannot be deactivated or deleted', () async {
      final id = await upsertRegister(f.db, name: 'Касса 2');
      await ShiftService(f.db).open(userId: f.owner.id, openingCash: 0, registerId: id);
      expect(await registerHasOpenShift(f.db, id), isTrue);
      await expectLater(
        upsertRegister(f.db, id: id, name: 'Касса 2', isActive: false),
        throwsA(isA<Exception>()),
      );
      final r = await (f.db.select(f.db.registers)..where((t) => t.id.equals(id))).getSingle();
      expect(r.isActive, isTrue);
      await expectLater(deleteRegister(f.db, r), throwsA(isA<Exception>()));
      // renaming while active is still allowed
      await upsertRegister(f.db, id: id, name: 'Касса Б');
    });

    test('installed_at is created once', () async {
      final a = await ensureInstalledAt(f.db, now: DateTime(2026, 1, 1));
      final b = await ensureInstalledAt(f.db, now: DateTime(2026, 5, 1));
      expect(a, DateTime(2026, 1, 1));
      expect(b, a);
    });

    test('registers: create, validate unique, soft delete', () async {
      final id = await upsertRegister(f.db, name: 'Касса 1', userId: f.owner.id);
      final all = await f.db.select(f.db.registers).get();
      expect(validateRegisterName('касса 1', all), isNotNull);
      expect(validateRegisterName('касса 1', all, selfId: id), isNull);
      expect(validateRegisterName('', all), isNotNull);
      await upsertRegister(f.db, id: id, name: 'Касса А', isActive: false);
      var r = await (f.db.select(f.db.registers)..where((t) => t.id.equals(id))).getSingle();
      expect(r.name, 'Касса А');
      expect(r.isActive, isFalse);
      await deleteRegister(f.db, r);
      r = await (f.db.select(f.db.registers)..where((t) => t.id.equals(id))).getSingle();
      expect(r.deletedAt, isNotNull);
      final outbox = await (f.db.select(f.db.syncOutbox)..where((o) => o.entityId.equals(id))).get();
      expect(outbox, isNotEmpty);
    });

    test('counts and db size', () async {
      await f.product('A');
      await f.customer('C');
      final c = await entityCounts(f.db);
      expect(c['products'], 1);
      expect(c['customers'], 1);
      expect(c['sales'], 0);
      expect(await databaseSizeBytes(f.db), greaterThan(0));
      final text = diagnosticsText(platform: 'test', dbSize: 4096, counts: c, settings: {'store_name': 'S'});
      expect(text, contains('DreamPOS $appVersion'));
      expect(text, contains('Товаров: 1'));
    });
  });

  group('backup service', () {
    late Fixture f;
    late Directory tmp;
    late BackupService svc;
    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      f = await Fixture.create();
      tmp = await Directory.systemTemp.createTemp('dreampos_settings_test');
      svc = BackupService(
        f.db,
        () async => tmp,
        dbPath: () async =>
            '${tmp.path}${Platform.pathSeparator}appdata${Platform.pathSeparator}dreampos.sqlite',
      );
    });
    tearDown(() async {
      await f.db.close();
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('creates consistent copy, lists, stages restore and deletes', () async {
      await f.product('Хлеб', price: 4000);
      final t = DateTime(2026, 11, 24, 10, 30);
      final b1 = await svc.create(now: t, userId: f.owner.id);
      expect(b1.name, 'dreampos-20261124-1030.sqlite');
      expect(b1.size, greaterThan(0));
      final b2 = await svc.create(now: t);
      expect(b2.name, 'dreampos-20261124-1030-2.sqlite');
      expect(await f.db.getSetting('last_backup_at'), isNotNull);

      // backup is a real database with our data
      final copy = AppDatabase(NativeDatabase(b1.file));
      final products = await copy.select(copy.products).get();
      expect(products.single.name, 'Хлеб');
      await copy.close();

      final list = await svc.list();
      expect(list, hasLength(2));
      expect(await svc.isValidBackup(b1.file), isTrue);

      expect(await svc.hasPendingRestore(), isFalse);
      await svc.stageRestore(b1);
      expect(await svc.hasPendingRestore(), isTrue);
      final pending = await svc.pendingRestoreFile();
      // must be exactly where core DbLocation.applyPendingRestore looks: <db>.restore
      expect(pending.path, endsWith('appdata${Platform.pathSeparator}dreampos.sqlite.restore'));
      expect((await svc.databaseFile()).path, endsWith('dreampos.sqlite'));
      expect(await pending.length(), b1.size);
      await svc.cancelPendingRestore();
      expect(await svc.hasPendingRestore(), isFalse);

      await svc.delete(b2);
      expect(await svc.list(), hasLength(1));
      final actions = (await f.db.select(f.db.auditLog).get()).map((a) => a.action).toList();
      expect(actions, containsAll(['backup.create', 'backup.delete', 'backup.restore_scheduled']));
    });

    test('refuses to stage a non-sqlite file', () async {
      final dir = await svc.backupsDir();
      final bad = File('${dir.path}/dreampos-20260101-0000.sqlite')..writeAsStringSync('garbage file!!!!!');
      final info = (await svc.list()).single;
      expect(info.name, 'dreampos-20260101-0000.sqlite');
      expect(bad.existsSync(), isTrue);
      expect(() => svc.stageRestore(info), throwsA(isA<Exception>()));
    });

    test('exports products and customers to CSV with BOM', () async {
      final catId = newId();
      await f.db.into(f.db.categories).insert(CategoriesCompanion.insert(id: catId, name: 'Хлеб'));
      await f.product('Батон; нарезной', price: 4500, stock: 3, categoryId: catId);
      await f.customer('Иван', bonus: 100);
      final pf = await svc.exportProducts(now: DateTime(2026, 1, 2, 3, 4));
      expect(pf.path, endsWith('products-20260102-0304.csv'));
      final bytes = await pf.readAsBytes();
      expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
      final txt = await pf.readAsString();
      expect(txt, contains('"Батон; нарезной"'));
      expect(txt, contains(';Хлеб;'));
      final cf = await svc.exportCustomers();
      expect(await cf.readAsString(), contains('Иван'));
    });
  });
}
