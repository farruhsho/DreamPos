import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/db/database.dart';
import '../../core/db/db_location.dart';
import '../../core/money.dart';
import 'settings_logic.dart';

/// File name of the live database (see core `DbLocation`).
const databaseFileName = DbLocation.fileName;

/// Suffix of the staged restore file placed next to the database. It must
/// match `DbLocation.pendingRestoreFile()`, which main.dart applies before the
/// database is opened (`DbLocation.applyPendingRestore`).
const pendingRestoreSuffix = '.restore';

class BackupInfo {
  BackupInfo(this.file, this.size, this.modified);
  final File file;
  final int size;
  final DateTime modified;
  String get name => p.basename(file.path);
  DateTime get date => backupDateFromName(name) ?? modified;
}

/// Backups, restore staging and CSV exports. [documentsDir] (backups and
/// exports live in `<Documents>/DreamPOS/...`) and [dbPath] (the live DB in
/// the app-support dir, see `DbLocation`) are injected so tests can use a
/// temp directory instead of path_provider.
class BackupService {
  BackupService(this.db, this.documentsDir, {Future<String> Function()? dbPath})
    : dbPath = dbPath ?? DbLocation.dbPath;
  final AppDatabase db;
  final Future<Directory> Function() documentsDir;
  final Future<String> Function() dbPath;

  Future<Directory> _sub(List<String> parts) async {
    final d = Directory(p.joinAll([(await documentsDir()).path, ...parts]));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<Directory> backupsDir() => _sub(['DreamPOS', 'backups']);
  Future<Directory> exportsDir() => _sub(['DreamPOS', 'exports']);

  Future<File> databaseFile() async => File(await dbPath());

  /// Same location as `DbLocation.pendingRestoreFile()` (`<db>.restore`).
  Future<File> pendingRestoreFile() async => File('${await dbPath()}$pendingRestoreSuffix');

  /// Consistent snapshot via `VACUUM INTO` (safe while the app is running).
  Future<BackupInfo> create({DateTime? now, String? userId}) async {
    final t = now ?? DateTime.now();
    final dir = await backupsDir();
    var name = backupFileName(t);
    var n = 2;
    while (await File(p.join(dir.path, name)).exists()) {
      name = backupFileName(t).replaceFirst('.sqlite', '-${n++}.sqlite');
    }
    final path = p.join(dir.path, name);
    await db.customStatement('VACUUM INTO ?', [path]);
    final f = File(path);
    if (!await f.exists() || await f.length() == 0) {
      throw Exception('Не удалось создать резервную копию');
    }
    await db.setSetting(SettingKeys.lastBackupAt, t.toUtc().toIso8601String());
    await db.audit('backup.create', userId: userId, entity: 'backup', details: name);
    final st = await f.stat();
    return BackupInfo(f, st.size, st.modified);
  }

  /// Existing backups, newest first.
  Future<List<BackupInfo>> list() async {
    final dir = await backupsDir();
    final out = <BackupInfo>[];
    await for (final e in dir.list()) {
      if (e is File && p.extension(e.path) == '.sqlite') {
        final st = await e.stat();
        out.add(BackupInfo(e, st.size, st.modified));
      }
    }
    out.sort((a, b) => b.date.compareTo(a.date) != 0 ? b.date.compareTo(a.date) : b.name.compareTo(a.name));
    return out;
  }

  Future<void> delete(BackupInfo b, {String? userId}) async {
    if (await b.file.exists()) await b.file.delete();
    await db.audit('backup.delete', userId: userId, entity: 'backup', details: b.name);
  }

  Future<bool> isValidBackup(File f) async {
    if (!await f.exists()) return false;
    final raf = await f.open();
    try {
      final header = await raf.read(16);
      return looksLikeSqlite(header);
    } finally {
      await raf.close();
    }
  }

  /// Copies [backup] to the pending-restore slot next to the DB. The data is
  /// replaced on next app start (by main.dart).
  Future<File> stageRestore(BackupInfo backup, {String? userId}) async {
    if (!await isValidBackup(backup.file)) {
      throw Exception('Файл «${backup.name}» не является резервной копией DreamPOS');
    }
    final target = await pendingRestoreFile();
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.tmp');
    await backup.file.copy(tmp.path);
    if (await target.exists()) await target.delete();
    await tmp.rename(target.path);
    await db.audit('backup.restore_scheduled', userId: userId, entity: 'backup', details: backup.name);
    return target;
  }

  Future<bool> hasPendingRestore() async => (await pendingRestoreFile()).exists();

  Future<void> cancelPendingRestore({String? userId}) async {
    final f = await pendingRestoreFile();
    if (await f.exists()) {
      await f.delete();
      await db.audit('backup.restore_cancelled', userId: userId, entity: 'backup');
    }
  }

  // ---------------------------------------------------------------- exports

  String _stamp(DateTime t) => backupFileName(t).replaceFirst('dreampos-', '').replaceFirst('.sqlite', '');

  Future<File> _writeCsv(String prefix, List<String> rows, DateTime t) async {
    final dir = await exportsDir();
    final f = File(p.join(dir.path, '$prefix-${_stamp(t)}.csv'));
    // UTF-8 BOM so Excel opens Cyrillic correctly.
    await f.writeAsString('﻿${rows.join('\r\n')}\r\n', flush: true);
    return f;
  }

  Future<File> exportProducts({DateTime? now, String? userId}) async {
    final c = Money.currency;
    final cats = {for (final x in await db.select(db.categories).get()) x.id: x.name};
    final rows = await (db.select(db.products)..where((t) => t.deletedAt.isNull())).get();
    rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final lines = [
      csvRow([
        'Наименование',
        'Артикул',
        'Штрихкод',
        'Категория',
        'Ед. изм.',
        'Цена',
        'Себестоимость',
        'Остаток',
        'Мин. остаток',
        'НДС %',
        'Активен',
      ]),
      for (final r in rows)
        csvRow([
          r.name,
          r.sku,
          r.barcode,
          cats[r.categoryId],
          Qty.unitLabel(r.unit),
          csvMoney(r.price, c),
          csvMoney(r.costPrice, c),
          csvQty(r.stockQty),
          csvQty(r.minStock),
          formatPercentValue(r.vatPercent),
          r.isActive ? 'да' : 'нет',
        ]),
    ];
    final f = await _writeCsv('products', lines, now ?? DateTime.now());
    await db.audit('data.export', userId: userId, entity: 'products', details: '${rows.length} строк');
    return f;
  }

  Future<File> exportCustomers({DateTime? now, String? userId}) async {
    final c = Money.currency;
    final rows = await (db.select(db.customers)..where((t) => t.deletedAt.isNull())).get();
    rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final lines = [
      csvRow([
        'Имя',
        'Телефон',
        'Email',
        'Карта',
        'Скидка %',
        'Бонусы',
        'Долг',
        'Лимит долга',
        'Покупок на сумму',
        'Визитов',
      ]),
      for (final r in rows)
        csvRow([
          r.name,
          r.phone,
          r.email,
          r.cardNumber,
          formatPercentValue(r.discountPercent),
          csvMoney(r.bonusBalance, c),
          csvMoney(r.debtBalance, c),
          csvMoney(r.debtLimit, c),
          csvMoney(r.totalSpent, c),
          r.visits,
        ]),
    ];
    final f = await _writeCsv('customers', lines, now ?? DateTime.now());
    await db.audit('data.export', userId: userId, entity: 'customers', details: '${rows.length} строк');
    return f;
  }
}
