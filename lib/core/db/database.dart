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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'dreampos',
        native: const DriftNativeOptions(
            databasePath: DbLocation.dbPath, shareAcrossIsolates: true, setup: registerSqlFunctions),
      );

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          for (final sql in _indexes) {
            await customStatement(sql);
          }
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
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_gift_sales_number ON gift_card_sales(number)',
    'CREATE INDEX IF NOT EXISTS ix_gift_sale_payments_sale ON gift_card_sale_payments(sale_id)',
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
