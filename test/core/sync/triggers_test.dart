// Change capture by SQLite triggers (D-025, spec §1).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/sync/sync_tables.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<List<SyncOutboxData>> outbox() =>
      (db.select(db.syncOutbox)..orderBy([(o) => OrderingTerm.asc(o.seq)])).get();

  const syncCols = {'id', 'created_at', 'updated_at', 'deleted_at'};

  test('every table is classified; every SyncColumns table is synced or local', () {
    final names = {for (final t in db.allTables) t.actualTableName};
    for (final t in db.allTables) {
      final cols = {for (final c in t.$columns) c.name};
      final name = t.actualTableName;
      expect(
          syncedTables.contains(name) || localOnlyTables.contains(name) || name == settingsTable, isTrue,
          reason: '$name is not classified in sync_tables.dart');
      if (cols.containsAll(syncCols)) {
        expect(syncedTables.contains(name) != localOnlyTables.contains(name), isTrue,
            reason: '$name must be in exactly one of syncedTables / localOnlyTables');
      }
    }
    for (final n in [...syncedTables, ...localOnlyTables]) {
      expect(names, contains(n), reason: '$n listed but not in the schema');
    }
    for (final n in syncedTables) {
      final t = db.allTables.firstWhere((t) => t.actualTableName == n);
      expect({for (final c in t.$columns) c.name}.containsAll(syncCols), isTrue, reason: '$n lacks SyncColumns');
    }
    expect(syncedTables.toSet(), hasLength(syncedTables.length));
    for (final e in cachedColumns.entries) {
      final t = db.allTables.firstWhere((t) => t.actualTableName == e.key);
      expect({for (final c in t.$columns) c.name}.containsAll(e.value), isTrue, reason: e.key);
    }
  });

  test('all sync triggers exist after onCreate; sync_flags has its row', () async {
    final rows = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'").get();
    expect(rows.map((r) => r.read<String>('name')).toSet(), syncTriggerNames().toSet());
    final flag = await db.select(db.syncFlags).getSingle();
    expect(flag.id, 1);
    expect(flag.applying, 0);
  });

  /// Inserts a minimal row into [table] (FKs off): every NOT NULL column
  /// without a default gets a value of its type.
  Future<String> insertRow(String table) async {
    final cols = await db.customSelect('PRAGMA table_info($table)').get();
    final id = newId();
    final names = <String>['id'];
    final values = <Variable>[Variable.withString(id)];
    for (final c in cols) {
      final name = c.read<String>('name');
      if (name == 'id' || c.read<int>('notnull') == 0 || c.data['dflt_value'] != null) continue;
      names.add(name);
      final type = c.read<String>('type').toUpperCase();
      values.add(type.contains('INT')
          ? const Variable<int>(1)
          : type.contains('REAL')
              ? const Variable<double>(1)
              : Variable.withString('x$id'));
    }
    await db.customInsert(
        'INSERT INTO $table (${names.join(', ')}) VALUES (${List.filled(names.length, '?').join(', ')})',
        variables: values);
    return id;
  }

  test('insert / update / delete of every synced table land in the outbox; applying=1 suppresses', () async {
    await db.customStatement('PRAGMA foreign_keys = OFF');
    final before = DateTime.now().millisecondsSinceEpoch;
    for (final t in syncedTables) {
      final start = (await outbox()).length;
      final id = await insertRow(t);
      await db.customStatement('UPDATE $t SET updated_at = updated_at + 1 WHERE id = ?', [id]);
      await db.customStatement('DELETE FROM $t WHERE id = ?', [id]);
      final rows = (await outbox()).skip(start).toList();
      // A write that changes nothing but updated_at is bookkeeping (`stat`)
      // on the tables split into a user and a stat part.
      final touchOp = statColumns.containsKey(t) ? 'stat' : 'upsert';
      expect(rows.map((r) => (r.entity, r.entityId, r.op)).toList(),
          [(t, id, 'upsert'), (t, id, touchOp), (t, id, 'delete')],
          reason: t);
      for (final r in rows) {
        expect(r.at, greaterThanOrEqualTo(before - 1000), reason: 'at is epoch ms');
        expect(r.at, lessThanOrEqualTo(DateTime.now().millisecondsSinceEpoch + 1000));
        expect(r.syncedAt, isNull);
      }
    }
    final n = (await outbox()).length;
    await db.withSyncSuppressed(() async {
      for (final t in syncedTables) {
        final id = await insertRow(t);
        await db.customStatement('UPDATE $t SET updated_at = updated_at + 1 WHERE id = ?', [id]);
        await db.customStatement('DELETE FROM $t WHERE id = ?', [id]);
      }
      await db.setSetting('store_name', 'Без эха');
    });
    expect(await outbox(), hasLength(n), reason: 'applying=1 writes nothing');
    expect((await db.select(db.syncFlags).getSingle()).applying, 0, reason: 'flag restored');
    // restored also after an error (the transaction rolls back)
    await expectLater(db.withSyncSuppressed(() async => throw StateError('x')), throwsStateError);
    expect((await db.select(db.syncFlags).getSingle()).applying, 0);
  });

  test('settings: synced keys captured by key, local keys excluded', () async {
    await db.setSetting('store_name', 'Магазин');
    await db.setSetting('store_name', 'Магазин 2');
    await db.setSetting('syncx', '1'); // `_` in sync_% is not a wildcard
    for (final k in [...localSettingKeys, 'sync_store_id', 'sync_url', 'ui_locale', 'printer_name', 'backup_dir']) {
      expect(isLocalSettingKey(k), isTrue, reason: k);
      await db.setSetting(k, 'v');
      await db.setSetting(k, 'v2');
    }
    await db.customStatement("DELETE FROM settings WHERE key IN ('store_name', 'sync_url')");
    final rows = await outbox();
    expect(rows.map((r) => (r.entity, r.entityId, r.op)).toList(), [
      ('settings', 'store_name', 'upsert'),
      ('settings', 'store_name', 'upsert'),
      ('settings', 'syncx', 'upsert'),
      ('settings', 'store_name', 'delete'),
    ]);
    expect(isLocalSettingKey('store_name'), isFalse);
    expect(isLocalSettingKey('receipt_locale'), isFalse);
  });

  test('markDirty is a no-op kept for compatibility', () async {
    await db.markDirty('products', 'p1');
    await db.markDirty('customers', 'c1', op: 'delete');
    expect(await outbox(), isEmpty);
  });

  test('device code: null by default, copied into new documents; numbers unique per code', () async {
    final f = await Fixture.create();
    addTearDown(f.db.close);
    expect(await f.db.deviceCode(), isNull);
    expect(f.shift.deviceCode, isNull);
    await f.db.setSetting(deviceCodeSettingKey, ' B ');
    expect(await f.db.deviceCode(), 'B');
    await f.db.setSetting(deviceCodeSettingKey, '');
    expect(await f.db.deviceCode(), isNull);

    Future<void> sale(int number, String? code) => f.db.into(f.db.sales).insert(SalesCompanion.insert(
        id: newId(), number: number, deviceCode: Value(code), status: 'completed', subtotal: 0, total: 0));
    await sale(1, null);
    await sale(1, 'A');
    await sale(1, 'B');
    await expectLater(sale(1, null), throwsA(anything));
    await expectLater(sale(1, 'A'), throwsA(anything));
    final idx = await f.db
        .customSelect("SELECT sql FROM sqlite_master WHERE name IN ('ux_sales_number', 'ux_gift_sales_number')")
        .get();
    expect(idx, hasLength(2));
    for (final r in idx) {
      expect(r.read<String>('sql'), contains("ifnull(device_code, '')"));
    }
  });
}
