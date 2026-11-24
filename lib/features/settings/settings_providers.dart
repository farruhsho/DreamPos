import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/db/database.dart';
import '../../core/db/db_location.dart';
import '../../core/providers.dart';
import 'backup_service.dart';
import 'settings_logic.dart';

/// Documents directory resolver (overridden in tests with a temp dir).
final settingsDocumentsDirProvider =
    Provider<Future<Directory> Function()>((ref) => getApplicationDocumentsDirectory);

/// Path of the live database file (overridden in tests).
final settingsDbPathProvider = Provider<Future<String> Function()>((ref) => DbLocation.dbPath);

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(
    ref.watch(databaseProvider), ref.watch(settingsDocumentsDirProvider),
    dbPath: ref.watch(settingsDbPathProvider)));

final backupsListProvider = FutureProvider.autoDispose<List<BackupInfo>>(
    (ref) => ref.watch(backupServiceProvider).list());

final pendingRestoreProvider = FutureProvider.autoDispose<bool>(
    (ref) => ref.watch(backupServiceProvider).hasPendingRestore());

final databasePathProvider = FutureProvider.autoDispose<String>(
    (ref) async => (await ref.watch(backupServiceProvider).databaseFile()).path);

/// True once any sale exists -> currency is locked.
final hasSalesProvider =
    StreamProvider<bool>((ref) => watchHasAnySale(ref.watch(databaseProvider)));

final activeProductCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect('SELECT COUNT(*) AS c FROM products WHERE deleted_at IS NULL',
          readsFrom: {db.products})
      .watchSingle()
      .map((r) => r.read<int>('c'));
});

/// Registers that are not deleted, by name.
final registersProvider = StreamProvider<List<Register>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.registers)
        ..where((r) => r.deletedAt.isNull())
        ..orderBy([(r) => OrderingTerm.asc(r.name)]))
      .watch();
});

/// Register bound to this device (shared_preferences, not synced).
class DeviceRegisterNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(deviceRegisterPrefKey);
  }

  Future<void> set(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(deviceRegisterPrefKey);
    } else {
      await prefs.setString(deviceRegisterPrefKey, id);
    }
    state = AsyncData(id);
  }
}

final deviceRegisterProvider =
    AsyncNotifierProvider<DeviceRegisterNotifier, String?>(DeviceRegisterNotifier.new);

class Diagnostics {
  Diagnostics(this.platform, this.dbSize, this.counts);
  final String platform;
  final int dbSize;
  final Map<String, int> counts;
}

String platformLabel() {
  try {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  } catch (_) {
    return 'unknown';
  }
}

final diagnosticsProvider = FutureProvider.autoDispose<Diagnostics>((ref) async {
  final db = ref.watch(databaseProvider);
  return Diagnostics(platformLabel(), await databaseSizeBytes(db), await entityCounts(db));
});

/// Install date (created on first open of the settings).
final installedAtProvider = FutureProvider<DateTime>(
    (ref) => ensureInstalledAt(ref.watch(databaseProvider)));
