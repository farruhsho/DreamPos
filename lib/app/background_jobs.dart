import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../core/db/database.dart';
import '../core/providers.dart';
import '../features/settings/backup_service.dart';
import '../features/settings/settings_logic.dart';

/// Daily automatic backup (setting `auto_backup_daily` = '1').
/// Checked 10 s after the shell starts and then hourly, because a till often
/// runs for days without restart. Old backups are never deleted automatically.
Future<bool> runAutoBackupIfDue(AppDatabase db, {DateTime? now, BackupService? service}) async {
  if (await db.getSetting(SettingKeys.autoBackupDaily) != '1') return false;
  final t = now ?? DateTime.now();
  final last = DateTime.tryParse(await db.getSetting(SettingKeys.lastBackupAt) ?? '');
  if (last != null && t.toUtc().difference(last.toUtc()) < const Duration(hours: 24)) {
    return false;
  }
  final svc = service ?? BackupService(db, getApplicationDocumentsDirectory);
  await svc.create(now: t);
  await db.audit('backup.auto');
  return true;
}

final backgroundJobsProvider = Provider<void>((ref) {
  final db = ref.watch(databaseProvider);
  var busy = false;
  Future<void> tick() async {
    if (busy) return;
    busy = true;
    try {
      await runAutoBackupIfDue(db);
    } catch (e, st) {
      debugPrint('Auto backup failed: $e\n$st');
    } finally {
      busy = false;
    }
  }

  final first = Timer(const Duration(seconds: 10), tick);
  final hourly = Timer.periodic(const Duration(hours: 1), (_) => tick());
  ref.onDispose(() {
    first.cancel();
    hourly.cancel();
  });
});
