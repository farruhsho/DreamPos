// Schema v4 → v5 on a file database (D-025).
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/sql_functions.dart';
import 'package:dreampos/core/sync/aggregates.dart';
import 'package:dreampos/core/sync/sync_tables.dart';
import 'package:flutter_test/flutter_test.dart';

const _numbered = [
  'sales',
  'returns',
  'shifts',
  'goods_receipts',
  'gift_card_sales',
  'purchase_orders',
  'inventory_counts',
  'warranty_claims',
];

/// Builds the current schema in [file], fills it, then strips it to v4.
Future<void> _buildV4(File file, Future<void> Function(AppDatabase db) fill) async {
  final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
  await fill(db);
  for (final sql in [
    for (final t in syncTriggerNames()) 'DROP TRIGGER IF EXISTS $t',
    'DROP TABLE sync_flags',
    'DROP TABLE sync_state',
    'DROP TABLE sync_row_versions',
    'DROP TABLE sync_conflicts',
    'DROP INDEX ux_sales_number',
    'DROP INDEX ux_gift_sales_number',
    // (code, number) indexes of the other numbered documents (sync review 4)
    for (final t in _numbered) 'DROP INDEX IF EXISTS ix_${t}_code_number',
    for (final t in _numbered) 'ALTER TABLE $t DROP COLUMN device_code',
    // v6 columns and indexes: a real v4 file has none of them
    'DROP INDEX IF EXISTS ix_sale_payments_gift_card',
    'DROP INDEX IF EXISTS ix_sale_payments_gift_ref',
    'DROP INDEX IF EXISTS ix_sync_outbox_entity',
    'DROP INDEX IF EXISTS ix_return_items_sale_item',
    'DROP INDEX IF EXISTS ix_goods_receipt_items_order_item',
    'ALTER TABLE sale_payments DROP COLUMN gift_card_id',
    'ALTER TABLE purchase_orders DROP COLUMN lines_rev',
    'ALTER TABLE purchase_order_items DROP COLUMN lines_rev',
    'CREATE UNIQUE INDEX ux_sales_number ON sales(number)',
    'CREATE UNIQUE INDEX ux_gift_sales_number ON gift_card_sales(number)',
    'DELETE FROM sync_outbox',
    // a v4 outbox row: drift DateTime = epoch seconds
    "INSERT INTO sync_outbox (entity, entity_id, op, at) VALUES ('products', 'old', 'upsert', 1764000000)",
    'PRAGMA user_version = 4',
  ]) {
    await db.customStatement(sql);
  }
  await db.close();
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('dreampos_mig_v5_'));
  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('v4 → v5: tables, columns, triggers, indexes, outbox ms, normalisation, numbers unchanged', () async {
    final file = File('${dir.path}${Platform.pathSeparator}v4.sqlite');
    final pid = newId(), cid = newId(), sid = newId(), gid = newId(), uid = newId();
    final saleIds = [newId(), newId()];
    await _buildV4(file, (db) async {
      await db.into(db.users).insert(UsersCompanion.insert(id: uid, name: 'U', role: 'owner', pinHash: 'x', pinSalt: 'y'));
      await db.into(db.products).insert(
          ProductsCompanion.insert(id: pid, name: 'Товар', price: 1000, costPrice: const Value(700), stockQty: const Value(8)));
      await db.into(db.customers).insert(CustomersCompanion.insert(
          id: cid, name: 'Клиент', debtBalance: const Value(2500), bonusBalance: const Value(40)));
      await db.into(db.suppliers).insert(SuppliersCompanion.insert(id: sid, name: 'Поставщик', balance: const Value(900)));
      await db.into(db.giftCards).insert(GiftCardsCompanion.insert(id: gid, code: 'OLD0000001', initialAmount: 500, balance: 500));
      for (var i = 0; i < 2; i++) {
        await db.into(db.sales).insert(SalesCompanion.insert(
            id: saleIds[i], number: i + 1, status: 'completed', subtotal: 100, total: 100, paidTotal: const Value(100)));
      }
      await db.into(db.counters).insert(CountersCompanion.insert(name: 'sale', value: 2));
    });

    final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.first, 7);
    // new local tables
    expect((await db.select(db.syncFlags).getSingle()).applying, 0);
    expect(await db.select(db.syncState).get(), isEmpty);
    expect(await db.select(db.syncRowVersions).get(), isEmpty);
    // device_code everywhere, null on old rows; numbers unchanged
    for (final t in _numbered) {
      final cols = await db.customSelect('PRAGMA table_info($t)').get();
      expect(cols.map((c) => c.read<String>('name')), contains('device_code'), reason: t);
    }
    final sales = await (db.select(db.sales)..orderBy([(s) => OrderingTerm.asc(s.number)])).get();
    expect(sales.map((s) => (s.id, s.number, s.deviceCode)), [(saleIds[0], 1, null), (saleIds[1], 2, null)]);
    // unique indexes replaced
    for (final name in ['ux_sales_number', 'ux_gift_sales_number']) {
      final sql = await db.customSelect('SELECT sql FROM sqlite_master WHERE name = ?',
          variables: [Variable.withString(name)]).getSingle();
      expect(sql.read<String>('sql'), contains("ifnull(device_code, '')"), reason: name);
    }
    await expectLater(
        db.into(db.sales).insert(SalesCompanion.insert(id: newId(), number: 1, status: 'completed', subtotal: 0, total: 0)),
        throwsA(anything));
    await db.into(db.sales).insert(SalesCompanion.insert(
        id: newId(), number: 1, deviceCode: const Value('A'), status: 'completed', subtotal: 0, total: 0));
    // triggers
    final trg = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'").get();
    expect(trg.map((r) => r.read<String>('name')).toSet(), syncTriggerNames().toSet());
    // v6 columns exist
    for (final (t, c) in [('sale_payments', 'gift_card_id'), ('purchase_orders', 'lines_rev'), ('purchase_order_items', 'lines_rev')]) {
      final cols = await db.customSelect('PRAGMA table_info($t)').get();
      expect(cols.map((r) => r.read<String>('name')), contains(c), reason: '$t.$c');
    }
    // normalisation rows (and the derived caches now match)
    expect(await SyncAggregates.verifyAll(db), isEmpty);
    final mv = await (db.select(db.stockMovements)..where((m) => m.productId.equals(pid))).getSingle();
    expect((mv.qty, mv.qtyAfter, mv.type, mv.unitCost, mv.reason), (8.0, 8.0, 'adjustment', 700, syncOpeningNote));
    final cl = await (db.select(db.customerLedger)..where((l) => l.customerId.equals(cid))).get();
    expect({for (final l in cl) l.kind: (l.amount, l.balanceAfter, l.note)},
        {'debt_adjust': (2500, 2500, syncOpeningNote), 'bonus_adjust': (40, 40, syncOpeningNote)});
    final sl = await (db.select(db.supplierLedger)..where((l) => l.supplierId.equals(sid))).getSingle();
    expect((sl.kind, sl.amount, sl.balanceAfter), ('opening', 900, 900));
    // caches themselves are unchanged
    expect((await (db.select(db.products)..where((p) => p.id.equals(pid))).getSingle()).stockQty, 8);
    expect((await (db.select(db.suppliers)..where((s) => s.id.equals(sid))).getSingle()).balance, 900);
    // never connected: the outbox is not kept (a store upload enqueues
    // every row, the normalisation rows included)
    final out = (await db.select(db.syncOutbox).get()).map((o) => o.entityId);
    for (final id in ['old', mv.id, sl.id, ...cl.map((l) => l.id)]) {
      expect(out, isNot(contains(id)));
    }
    expect(await db.select(db.syncConflicts).get(), isEmpty);
  });

  test('a real v4 file with gift cards and redemptions upgrades (v6 columns are added before v5 reads them)',
      () async {
    final file = File('${dir.path}${Platform.pathSeparator}v4gift.sqlite');
    final gid = newId(), sid = newId();
    await _buildV4(file, (db) async {
      await db.into(db.giftCards).insert(GiftCardsCompanion.insert(id: gid, code: 'G1', initialAmount: 1000, balance: 700));
      await db.into(db.sales).insert(SalesCompanion.insert(
          id: sid, number: 1, status: 'completed', subtotal: 300, total: 300, paidTotal: const Value(300)));
      await db.into(db.salePayments).insert(
          SalePaymentsCompanion.insert(id: newId(), saleId: sid, method: 'gift_card', amount: 300, reference: const Value('G1')));
    });
    final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    addTearDown(db.close);
    expect((await db.customSelect('PRAGMA user_version').getSingle()).data.values.first, 7);
    // the pre-v6 redemption still counts by code
    expect(await SyncAggregates.verifyAll(db), isEmpty);
    final idx = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'index'").get();
    expect(idx.map((r) => r.read<String>('name')), containsAll([
      'ix_sale_payments_gift_card',
      'ix_sale_payments_gift_ref',
      'ix_sync_outbox_entity',
      // created before the v5 normalisation reads them (quadratic otherwise)
      'ix_return_items_sale_item',
      'ix_goods_receipt_items_order_item',
    ]));
  });

  test('v6 → v7 on a file: the users triggers split login bookkeeping (stat) from person edits', () async {
    final file = File('${dir.path}${Platform.pathSeparator}v6.sqlite');
    final db0 = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    await db0.into(db0.syncState).insert(SyncStateCompanion.insert(key: 'store_id', value: 'store-1'));
    final uid = newId();
    await db0.into(db0.users).insert(UsersCompanion.insert(id: uid, name: 'U', role: 'cashier', pinHash: 'h', pinSalt: 's'));
    for (final sql in [
      'DROP TRIGGER trg_sync_users_upd',
      'DROP TRIGGER trg_sync_users_upds',
      // the v6 trigger: every UPDATE of a user is a person edit
      'CREATE TRIGGER trg_sync_users_upd AFTER UPDATE ON users '
          'WHEN COALESCE((SELECT applying FROM sync_flags WHERE id = 1), 0) = 0 BEGIN '
          "INSERT INTO sync_outbox (entity, entity_id, op, at) VALUES ('users', NEW.id, 'upsert', 1); END",
      'DROP INDEX ix_return_items_sale_item',
      'DELETE FROM sync_outbox',
      'PRAGMA user_version = 6',
    ]) {
      await db0.customStatement(sql);
    }
    await db0.close();
    final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    addTearDown(db.close);
    expect((await db.customSelect('PRAGMA user_version').getSingle()).data.values.first, 7);
    final trg = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'").get();
    expect(trg.map((r) => r.read<String>('name')).toSet(), syncTriggerNames().toSet());
    expect(syncTriggerNames(), contains('trg_sync_users_upds'));
    final idx = await db.customSelect("SELECT 1 FROM sqlite_master WHERE name = 'ix_return_items_sale_item'").get();
    expect(idx, hasLength(1), reason: 'a v6 file gets the new index on open');
    await (db.update(db.users)..where((u) => u.id.equals(uid))).write(UsersCompanion(lastLoginAt: Value(DateTime.now())));
    await (db.update(db.users)..where((u) => u.id.equals(uid))).write(const UsersCompanion(isActive: Value(false)));
    final ops = await db.customSelect("SELECT op FROM sync_outbox WHERE entity = 'users' ORDER BY seq").get();
    expect(ops.map((r) => r.read<String>('op')), ['stat', 'upsert']);
  });

  test('v5 → v6 on a file: columns, triggers, a connected outbox is kept', () async {
    final file = File('${dir.path}${Platform.pathSeparator}v5.sqlite');
    final db0 = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    await db0.into(db0.syncState).insert(SyncStateCompanion.insert(key: 'store_id', value: 'store-1'));
    for (final sql in [
      for (final t in syncTriggerNames()) 'DROP TRIGGER IF EXISTS $t',
      'DROP INDEX IF EXISTS ix_sale_payments_gift_card',
      'DROP INDEX IF EXISTS ix_sale_payments_gift_ref',
      'ALTER TABLE sale_payments DROP COLUMN gift_card_id',
      'ALTER TABLE purchase_orders DROP COLUMN lines_rev',
      'ALTER TABLE purchase_order_items DROP COLUMN lines_rev',
      "INSERT INTO sync_outbox (entity, entity_id, op, at) VALUES ('products', 'p1', 'upsert', 1764000000000)",
      'PRAGMA user_version = 5',
    ]) {
      await db0.customStatement(sql);
    }
    await db0.close();
    final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    addTearDown(db.close);
    expect((await db.customSelect('PRAGMA user_version').getSingle()).data.values.first, 7);
    final cols = await db.customSelect('PRAGMA table_info(sale_payments)').get();
    expect(cols.map((r) => r.read<String>('name')), contains('gift_card_id'));
    final trg = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'").get();
    expect(trg.map((r) => r.read<String>('name')).toSet(), syncTriggerNames().toSet());
    expect((await db.select(db.syncOutbox).get()).map((o) => o.entityId), ['p1'],
        reason: 'a database that was connected keeps its unsynced outbox');
  });

  test('the outbox of a never-connected database is pruned on open', () async {
    final file = File('${dir.path}${Platform.pathSeparator}off.sqlite');
    final db0 = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    for (var i = 0; i < 5; i++) {
      await db0.into(db0.customers).insert(CustomersCompanion.insert(id: newId(), name: 'c$i'));
    }
    expect(await db0.select(db0.syncOutbox).get(), hasLength(5), reason: 'the triggers capture');
    await db0.close();
    final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    addTearDown(db.close);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('a half-migrated v4 file (some v5 parts present) still upgrades', () async {
    final file = File('${dir.path}${Platform.pathSeparator}half.sqlite');
    final db0 = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    await db0.into(db0.suppliers).insert(SuppliersCompanion.insert(id: newId(), name: 'S', balance: const Value(10)));
    // interrupted earlier v5: tables, columns and triggers exist, version 4
    await db0.customStatement('PRAGMA user_version = 4');
    await db0.close();
    final db = AppDatabase(NativeDatabase(file, setup: registerSqlFunctions));
    addTearDown(db.close);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.first, 7);
    expect(await SyncAggregates.verifyAll(db), isEmpty);
    expect(await db.select(db.supplierLedger).get(), hasLength(1));
    final trg = await db.customSelect("SELECT COUNT(*) AS n FROM sqlite_master WHERE type = 'trigger'").getSingle();
    expect(trg.read<int>('n'), syncTriggerNames().length);
  });
}
