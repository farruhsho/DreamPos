import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import 'db_location.dart';
import 'sql_functions.dart';
import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

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
  Shifts,
  CashMovements,
  Sales,
  SaleItems,
  SalePayments,
  Returns,
  ReturnItems,
  GiftCards,
  Promotions,
  InventoryCounts,
  InventoryCountItems,
  WarrantyClaims,
  Notifications,
  AuditLog,
  SyncOutbox,
  Counters,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'dreampos',
        native: const DriftNativeOptions(
            databasePath: DbLocation.dbPath, shareAcrossIsolates: true, setup: registerSqlFunctions),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          for (final sql in _indexes) {
            await customStatement(sql);
          }
        },
        onUpgrade: (m, from, to) async {
          // v2: report/lookup indexes. All index DDL is IF NOT EXISTS, so
          // re-running the full list is the simplest correct migration.
          for (final sql in _indexes) {
            await customStatement(sql);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // WAL improves concurrent read/write when several isolates/screens
          // query while a sale is being written.
          if (executor.dialect == SqlDialect.sqlite) {
            await customStatement('PRAGMA journal_mode = WAL').catchError((_) {});
          }
        },
      );

  static const _indexes = [
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_products_barcode ON products(barcode) WHERE barcode IS NOT NULL AND deleted_at IS NULL',
    'CREATE INDEX IF NOT EXISTS ix_products_name ON products(name)',
    'CREATE INDEX IF NOT EXISTS ix_products_sku ON products(sku)',
    'CREATE INDEX IF NOT EXISTS ix_products_category ON products(category_id)',
    'CREATE INDEX IF NOT EXISTS ix_stock_mov_product ON stock_movements(product_id, created_at)',
    'CREATE INDEX IF NOT EXISTS ix_sales_created ON sales(created_at)',
    'CREATE INDEX IF NOT EXISTS ix_sales_shift ON sales(shift_id)',
    'CREATE INDEX IF NOT EXISTS ix_sales_customer ON sales(customer_id)',
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_sales_number ON sales(number)',
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
  ];

  // ---------------------------------------------------------------- helpers

  /// Atomically increments and returns the next number for [name]
  /// (receipt numbers, shift numbers, PO numbers ...). Must be called inside
  /// a transaction when used for a document that is inserted in the same tx.
  Future<int> nextNumber(String name) async {
    final row = await (select(counters)..where((c) => c.name.equals(name)))
        .getSingleOrNull();
    final next = (row?.value ?? 0) + 1;
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

  Future<void> markDirty(String entity, String entityId,
      {String op = 'upsert'}) {
    return into(syncOutbox).insert(SyncOutboxCompanion.insert(
        entity: entity, entityId: entityId, op: op));
  }
}
