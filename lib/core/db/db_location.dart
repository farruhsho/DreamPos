import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the database lives and how backups are restored.
///
/// The DB is stored in the application-support directory (not the user's
/// Documents) so users don't move/delete it by accident:
///   Windows: %APPDATA%\<company>\dreampos\dreampos.sqlite
///
/// Restore protocol (used by Settings → Резервное копирование):
///   1. The UI copies the chosen backup to `<db>.restore` (see [pendingRestoreFile]).
///   2. On next start, [applyPendingRestore] runs BEFORE the DB is opened:
///      the current DB (+ -wal/-shm) is renamed to `<db>.before-restore-<ts>`
///      (never deleted), then `<db>.restore` becomes the DB.
class DbLocation {
  DbLocation._();

  static const fileName = 'dreampos.sqlite';

  static Future<Directory> dataDir() async {
    final d = await getApplicationSupportDirectory();
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<String> dbPath() async => p.join((await dataDir()).path, fileName);

  static Future<File> pendingRestoreFile() async => File('${await dbPath()}.restore');

  static Future<Directory> backupsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(docs.path, 'DreamPOS', 'backups'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Returns true if a restore was applied.
  static Future<bool> applyPendingRestore({DateTime? now}) async {
    final restore = await pendingRestoreFile();
    if (!await restore.exists()) return false;
    final db = await dbPath();
    final ts = (now ?? DateTime.now()).toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    for (final suffix in ['', '-wal', '-shm']) {
      final f = File('$db$suffix');
      if (await f.exists()) await f.rename('$db.before-restore-$ts$suffix');
    }
    await restore.rename(db);
    return true;
  }
}
