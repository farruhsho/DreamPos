import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../sync/aggregates.dart';
import '../sync/sync_tables.dart';
import 'db_location.dart';
import 'sql_functions.dart';
import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// Namespace of [effectId] (a fixed random UUID).
const _effectNamespace = '6b1f9a52-3c4e-4d8b-9e57-2f0c8d1a7b33';

/// Deterministic id (UUID v5) of a one-time effect row, e.g. the reversal
/// stock movement of one receipt line. Two registers that finalise the same
/// document offline (D-025) write rows with the SAME id, so after syncing the
/// effect exists once instead of twice (append-only rows: one wins LWW).
String effectId(String kind, String sourceId) => _uuid.v5(_effectNamespace, '$kind:$sourceId');

/// Migration v2 → v3 back-fill: every supplier with a non-zero cached
/// balance gets an `opening` ledger row so that `suppliers.balance` equals the
/// last `balanceAfter`. Suppliers that already have ledger rows are skipped,
/// which makes the function safe to run twice. Returns the number of rows
/// inserted.
Future<int> insertOpeningSupplierEntries(AppDatabase db) async {
  final sups = await (db.select(db.suppliers)..where((s) => s.balance.equals(0).not())).get();
  var n = 0;
  for (final s in sups) {
    final has = await (db.select(db.supplierLedger)
          ..where((l) => l.supplierId.equals(s.id))
          ..limit(1))
        .getSingleOrNull();
    if (has != null) continue;
    final id = newId();
    await db.into(db.supplierLedger).insert(SupplierLedgerCompanion.insert(
          id: id,
          supplierId: s.id,
          kind: 'opening',
          amount: s.balance,
          balanceAfter: s.balance,
          note: const Value('Начальный остаток'),
        ));
    await db.markDirty('supplier_ledger', id);
    n++;
  }
  return n;
}

@DriftDatabase(tables: [
  Settings,
  Users,
  WorkSessions,
  Registers,
  Categories,
  Products,
  StockMovements,
  Customers,
  CustomerLedger,
  Suppliers,
  PurchaseOrders,
  PurchaseOrderItems,
  SupplierPayments,
  GoodsReceipts,
  GoodsReceiptItems,
  SupplierLedger,
  Shifts,
  CashMovements,
  Sales,
  SaleItems,
  SalePayments,
  Returns,
  ReturnItems,
  GiftCards,
  GiftCardSales,
  GiftCardSalePayments,
  Promotions,
  InventoryCounts,
  InventoryCountItems,
  WarrantyClaims,
  Notifications,
  AuditLog,
  SyncOutbox,
  Counters,
  SyncFlags,
  SyncState,
  SyncRowVersions,
  SyncConflicts,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'dreampos',
        native: const DriftNativeOptions(
            databasePath: DbLocation.dbPath, shareAcrossIsolates: true, setup: registerSqlFunctions),
      );

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          for (final sql in _indexes) {
            await customStatement(sql);
          }
          await _installSync();
        },
        onUpgrade: (m, from, to) async {
          // v3: goods receipt documents + supplier ledger (D-021, D-022).
          // drift does not wrap onUpgrade in a transaction and sets
          // user_version only afterwards, so the step is both atomic (SQLite
          // DDL is transactional) and idempotent (a file left half-migrated by
          // an older build still upgrades: ADD COLUMN has no IF NOT EXISTS).
          if (from < 3) {
            await transaction(() async {
              await m.createTable(goodsReceipts);
              await m.createTable(goodsReceiptItems);
              await m.createTable(supplierLedger);
              final cols = await _columnNames('supplier_payments');
              if (!cols.contains(supplierPayments.cancelledAt.name)) {
                await m.addColumn(supplierPayments, supplierPayments.cancelledAt);
              }
              if (!cols.contains(supplierPayments.cancelReason.name)) {
                await m.addColumn(supplierPayments, supplierPayments.cancelReason);
              }
              await insertOpeningSupplierEntries(this);
            });
          }
          // v4: gift card sale documents (D-023). createTable is
          // CREATE TABLE IF NOT EXISTS, so a half-migrated file still
          // upgrades. No back-fill: older cards keep soldSaleId = null.
          if (from < 4) {
            await transaction(() async {
              await m.createTable(giftCardSales);
              await m.createTable(giftCardSalePayments);
            });
          }
          // v5: multi-register sync (D-025, docs/specs/multi-register-sync.md).
          // Idempotent like v3/v4: CREATE TABLE IF NOT EXISTS, columns added
          // only when missing, triggers dropped and re-created, the outbox
          // seconds → milliseconds conversion only touches values that are
          // still seconds, and normalisation only inserts the differences.
          if (from < 5) {
            await transaction(() async {
              await m.createTable(syncFlags);
              await m.createTable(syncState);
              await m.createTable(syncRowVersions);
              await m.createTable(syncConflicts);
              for (final (table, column) in <(TableInfo, GeneratedColumn)>[
                (sales, sales.deviceCode),
                (returns, returns.deviceCode),
                (shifts, shifts.deviceCode),
                (goodsReceipts, goodsReceipts.deviceCode),
                (giftCardSales, giftCardSales.deviceCode),
                (purchaseOrders, purchaseOrders.deviceCode),
                (inventoryCounts, inventoryCounts.deviceCode),
                (warrantyClaims, warrantyClaims.deviceCode),
              ]) {
                if (!(await _columnNames(table.actualTableName)).contains(column.name)) {
                  await m.addColumn(table, column);
                }
              }
              // sync_outbox.at: epoch seconds (drift DateTime) → milliseconds.
              await customStatement('UPDATE sync_outbox SET at = at * 1000 WHERE at < 100000000000');
              // Document numbers are unique per register code.
              for (final sql in _numberIndexes) {
                await customStatement('DROP INDEX IF EXISTS ${sql.name}');
                await customStatement(sql.ddl);
              }
              // The triggers and the normalisation below read the v6
              // columns (sale_payments.gift_card_id…): add them first, or a
              // real v2–v4 file fails here and never opens.
              await _addV6Columns(m);
              await _installSync();
              await SyncAggregates.normalize(this);
            });
          }
          // v6: sync review fixes (D-025). Gift card redemptions keep the card
          // id; draft purchase orders carry a line-set revision; the UPDATE
          // triggers split person edits (`upsert`) from bookkeeping (`stat`).
          // Idempotent: columns added only when missing, triggers re-created.
          if (from < 6) {
            await transaction(() async {
              await _addV6Columns(m);
              await _installSync();
            });
          }
          // v7: login bookkeeping of `users` (last_login_at, failed PIN
          // attempts, lock) is a stat part (`statColumns`), so a login on one
          // register never re-sends that register's stale PIN / role /
          // is_active over the owner's change on another (D-025). The
          // triggers are re-created; idempotent.
          if (from < 7) {
            await transaction(_installSync);
          }
          // v2: report/lookup indexes. All index DDL is IF NOT EXISTS, so
          // re-running the full list is the simplest correct migration.
          for (final sql in _indexes) {
            await customStatement(sql);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Files created as v6 before these indexes existed get them here
          // (IF NOT EXISTS: a no-op afterwards).
          for (final sql in _syncIndexes) {
            await customStatement(sql);
          }
          await pruneUnconnectedOutbox();
          // WAL improves concurrent read/write when several isolates/screens
          // query while a sale is being written.
          if (executor.dialect == SqlDialect.sqlite) {
            await customStatement('PRAGMA journal_mode = WAL').catchError((_) {});
          }
        },
      );

  /// sync_flags row + change-capture triggers (idempotent).
  Future<void> _installSync() async {
    await customStatement('INSERT OR IGNORE INTO sync_flags (id, applying) VALUES (1, 0)');
    for (final sql in syncTriggerStatements(syncTableColumns)) {
      await customStatement(sql);
    }
  }

  /// SQL columns of every synced table (for the change-capture triggers).
  Map<String, List<String>> get syncTableColumns => {
        for (final t in allTables)
          if (syncedTables.contains(t.actualTableName)) t.actualTableName: [for (final c in t.$columns) c.name],
      };

  /// UNIQUE(ifnull(device_code,''), number) indexes of numbered documents
  /// (v5; before: UNIQUE(number)). Names kept from v1/v4.
  static const _numberIndexes = [
    (
      name: 'ux_sales_number',
      ddl: "CREATE UNIQUE INDEX IF NOT EXISTS ux_sales_number ON sales(ifnull(device_code, ''), number)",
    ),
    (
      name: 'ux_gift_sales_number',
      ddl: "CREATE UNIQUE INDEX IF NOT EXISTS ux_gift_sales_number ON gift_card_sales(ifnull(device_code, ''), number)",
    ),
  ];

  /// v6 columns (idempotent: added only when missing) and their indexes.
  /// Also run by the v5 step, which already reads them.
  Future<void> _addV6Columns(Migrator m) async {
    for (final (table, column) in <(TableInfo, GeneratedColumn)>[
      (salePayments, salePayments.giftCardId),
      (purchaseOrders, purchaseOrders.linesRev),
      (purchaseOrderItems, purchaseOrderItems.linesRev),
    ]) {
      if (!(await _columnNames(table.actualTableName)).contains(column.name)) {
        await m.addColumn(table, column);
      }
    }
    for (final sql in _syncIndexes) {
      await customStatement(sql);
    }
  }

  /// Indexes the sync engine relies on: outbox lookups per entity (push
  /// collapse, LWW pending checks), gift card redemptions by card id /
  /// legacy code (cache check of every card), return lines by sale line and
  /// receipt lines by order line (the returned / received quantity of every
  /// line in `SyncAggregates.verifyAll`, which the v5 upgrade runs over the
  /// whole store: without them it is quadratic).
  static const _syncIndexes = [
    'CREATE INDEX IF NOT EXISTS ix_sync_outbox_entity ON sync_outbox(entity, entity_id, synced_at)',
    "CREATE INDEX IF NOT EXISTS ix_sale_payments_gift_card ON sale_payments(gift_card_id) WHERE method = 'gift_card'",
    "CREATE INDEX IF NOT EXISTS ix_sale_payments_gift_ref ON sale_payments(reference) WHERE method = 'gift_card'",
    'CREATE INDEX IF NOT EXISTS ix_return_items_sale_item ON return_items(sale_item_id)',
    'CREATE INDEX IF NOT EXISTS ix_goods_receipt_items_order_item ON goods_receipt_items(order_item_id)',
  ];

  /// The triggers capture every write, also on a database that was never
  /// connected to a store; nothing would ever push or clean that outbox.
  /// It is not needed there: creating a store and joining one both enqueue
  /// every row. A database that was connected once keeps its outbox
  /// (changes made while disconnected are pushed after reconnecting).
  /// Returns the number of rows removed.
  Future<int> pruneUnconnectedOutbox() async {
    final hasState = await customSelect(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name IN ('sync_outbox', 'sync_state')")
        .get();
    if (hasState.length < 2) return 0;
    return customUpdate(
        "DELETE FROM sync_outbox WHERE synced_at IS NULL AND NOT EXISTS "
        "(SELECT 1 FROM sync_state WHERE key = 'store_id')",
        updates: {syncOutbox},
        updateKind: UpdateKind.delete);
  }

  Future<Set<String>> _columnNames(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return {for (final r in rows) r.read<String>('name')};
  }

  static const _indexes = [
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_products_barcode ON products(barcode) WHERE barcode IS NOT NULL AND deleted_at IS NULL',
    'CREATE INDEX IF NOT EXISTS ix_products_name ON products(name)',
    'CREATE INDEX IF NOT EXISTS ix_products_sku ON products(sku)',
    'CREATE INDEX IF NOT EXISTS ix_products_category ON products(category_id)',
    'CREATE INDEX IF NOT EXISTS ix_stock_mov_product ON stock_movements(product_id, created_at)',
    'CREATE INDEX IF NOT EXISTS ix_sales_created ON sales(created_at)',
    'CREATE INDEX IF NOT EXISTS ix_sales_shift ON sales(shift_id)',
    'CREATE INDEX IF NOT EXISTS ix_sales_customer ON sales(customer_id)',
    "CREATE UNIQUE INDEX IF NOT EXISTS ux_sales_number ON sales(ifnull(device_code, ''), number)",
    'CREATE INDEX IF NOT EXISTS ix_sale_items_sale ON sale_items(sale_id)',
    'CREATE INDEX IF NOT EXISTS ix_sale_items_product ON sale_items(product_id)',
    'CREATE INDEX IF NOT EXISTS ix_sale_payments_sale ON sale_payments(sale_id)',
    'CREATE INDEX IF NOT EXISTS ix_customers_phone ON customers(phone)',
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_customers_card ON customers(card_number) WHERE card_number IS NOT NULL AND deleted_at IS NULL',
    'CREATE INDEX IF NOT EXISTS ix_ledger_customer ON customer_ledger(customer_id, created_at)',
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_gift_code ON gift_cards(code)',
    'CREATE INDEX IF NOT EXISTS ix_cash_mov_shift ON cash_movements(shift_id)',
    'CREATE INDEX IF NOT EXISTS ix_returns_sale ON returns(sale_id)',
    // v2
    'CREATE INDEX IF NOT EXISTS ix_stock_mov_type ON stock_movements(type, created_at)',
    'CREATE INDEX IF NOT EXISTS ix_ledger_kind ON customer_ledger(kind, customer_id, created_at)',
    'CREATE INDEX IF NOT EXISTS ix_returns_shift ON returns(shift_id)',
    'CREATE INDEX IF NOT EXISTS ix_return_items_return ON return_items(return_id)',
    'CREATE INDEX IF NOT EXISTS ix_sales_status_created ON sales(status, created_at)',
    'CREATE INDEX IF NOT EXISTS ix_audit_at ON audit_log(at)',
    // v3
    'CREATE INDEX IF NOT EXISTS ix_goods_receipts_created ON goods_receipts(created_at)',
    'CREATE INDEX IF NOT EXISTS ix_goods_receipts_supplier ON goods_receipts(supplier_id)',
    'CREATE INDEX IF NOT EXISTS ix_goods_receipts_order ON goods_receipts(order_id)',
    'CREATE INDEX IF NOT EXISTS ix_goods_receipt_items_receipt ON goods_receipt_items(receipt_id)',
    'CREATE INDEX IF NOT EXISTS ix_supplier_ledger_supplier ON supplier_ledger(supplier_id, created_at)',
    // v4
    'CREATE INDEX IF NOT EXISTS ix_gift_sales_shift ON gift_card_sales(shift_id)',
    'CREATE INDEX IF NOT EXISTS ix_gift_sales_void_shift ON gift_card_sales(void_shift_id)',
    'CREATE INDEX IF NOT EXISTS ix_gift_sales_created ON gift_card_sales(created_at)',
    'CREATE INDEX IF NOT EXISTS ix_gift_sales_card ON gift_card_sales(gift_card_id)',
    "CREATE UNIQUE INDEX IF NOT EXISTS ux_gift_sales_number ON gift_card_sales(ifnull(device_code, ''), number)",
    'CREATE INDEX IF NOT EXISTS ix_gift_sale_payments_sale ON gift_card_sale_payments(sale_id)',
  ];

  // ---------------------------------------------------------------- helpers

  /// Counter name → numbered document table (with `number` + `device_code`).
  static const numberedDocumentTables = <String, String>{
    'sale': 'sales',
    'return': 'returns',
    'shift': 'shifts',
    'receipt': 'goods_receipts',
    'gift_sale': 'gift_card_sales',
    'po': 'purchase_orders',
    'inventory': 'inventory_counts',
    'warranty': 'warranty_claims',
  };

  /// Atomically increments and returns the next number for [name]
  /// (receipt numbers, shift numbers, PO numbers ...). Must be called inside
  /// a transaction when used for a document that is inserted in the same tx.
  ///
  /// With a device code (sync on, D-025) the number is also above every
  /// existing document of that code: the counters are local to the file,
  /// while documents with this code can come from elsewhere (a store created
  /// again after a disconnect, pulled history, a restored backup). Without a
  /// code nothing changes.
  Future<int> nextNumber(String name) async {
    final row = await (select(counters)..where((c) => c.name.equals(name)))
        .getSingleOrNull();
    var next = (row?.value ?? 0) + 1;
    final table = numberedDocumentTables[name];
    if (table != null) {
      final code = await deviceCode();
      if (code != null) {
        final m = await customSelect(
            "SELECT MAX(number) AS m FROM $table WHERE ifnull(device_code, '') = ?",
            variables: [Variable.withString(code)]).getSingle();
        final max = m.readNullable<int>('m') ?? 0;
        if (max >= next) next = max + 1;
      }
    }
    await into(counters).insertOnConflictUpdate(
        CountersCompanion.insert(name: name, value: next));
    return next;
  }

  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) => into(settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Stream<Map<String, String>> watchSettings() => select(settings)
      .watch()
      .map((rows) => {for (final r in rows) r.key: r.value});

  Future<void> audit(String action,
      {String? userId, String? entity, String? entityId, String? details}) {
    return into(auditLog).insert(AuditLogCompanion.insert(
      action: action,
      userId: Value(userId),
      entity: Value(entity),
      entityId: Value(entityId),
      details: Value(details),
    ));
  }

  /// No-op since schema v5 (D-025): SQLite triggers on every synced table
  /// write `sync_outbox` themselves, including rows that callers never marked
  /// (sale items, payments, movements…). Calling it as well would only add
  /// duplicate outbox rows, and a hand-written `op: 'delete'` for a soft
  /// delete would be wrong (the row still exists and is sent as an upsert).
  /// Kept with the same signature so modules do not change.
  Future<void> markDirty(String entity, String entityId,
          {String op = 'upsert'}) =>
      Future.value();

  /// This register's document code (`A`, `B`…) or null when sync is off.
  /// New numbered documents copy it into `device_code`.
  Future<String?> deviceCode() async {
    final v = (await getSetting(deviceCodeSettingKey))?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  /// Device-local setting (never synced: `sync_` prefix): ids of open shifts
  /// this database keeps as its own although they carry an earlier code of
  /// it. Written when the database got a new code after a backup restore /
  /// copy (D-025): the shift with the drawer's cash stays this register's
  /// current shift instead of being orphaned.
  static const ownShiftsSettingKey = 'sync_own_shifts';

  /// Parses [ownShiftsSettingKey].
  static Set<String> parseOwnShifts(String? raw) =>
      {for (final s in (raw ?? '').split(',')) if (s.trim().isNotEmpty) s.trim()};

  /// The current open shift of this register: the latest open shift; with a
  /// device code, the latest open shift with this code or one of
  /// [ownShifts] (D-025). [registerId] narrows it further.
  SimpleSelectStatement<$ShiftsTable, Shift> currentShiftQuery(String? code, Set<String> ownShifts,
      {String? registerId}) {
    final q = select(shifts)..where((s) => s.status.equals('open'));
    if (code != null) {
      q.where((s) => ownShifts.isEmpty ? s.deviceCode.equals(code) : (s.deviceCode.equals(code) | s.id.isIn(ownShifts)));
    }
    if (registerId != null) q.where((s) => s.registerId.equals(registerId));
    q
      ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
      ..limit(1);
    return q;
  }

  /// Runs [body] in a transaction with the sync triggers suppressed
  /// (`sync_flags.applying = 1`), restoring the previous flag afterwards —
  /// also on error, when the whole transaction rolls back anyway. Used by the
  /// sync engine to apply remote changes and recompute caches without
  /// echoing them into the outbox.
  Future<T> withSyncSuppressed<T>(Future<T> Function() body) => transaction(() async {
        final prev = await customSelect('SELECT applying FROM sync_flags WHERE id = 1')
                .getSingleOrNull()
                .then((r) => r?.read<int>('applying')) ??
            0;
        await customStatement('INSERT OR REPLACE INTO sync_flags (id, applying) VALUES (1, 1)');
        try {
          return await body();
        } finally {
          await customStatement('UPDATE sync_flags SET applying = ? WHERE id = 1', [prev]);
        }
      });
}
