// Single source of truth for what is synchronised between registers (D-025,
// docs/specs/multi-register-sync.md §1, §4).
//
// Pure constants + SQL generators: no database import, so `database.dart` can
// use it from `onCreate` / the v5 upgrade.
import '../db/tables.dart' show sqlNowMs;

/// Every `SyncColumns` table whose rows are synchronised, parents before
/// children (FK-safe order for a first upload). Each gets AFTER INSERT /
/// UPDATE / DELETE triggers writing to `sync_outbox` (entity = table name,
/// entity_id = `id`).
const syncedTables = <String>[
  'users',
  'work_sessions',
  'registers',
  'categories',
  'products',
  'stock_movements',
  'customers',
  'customer_ledger',
  'suppliers',
  'purchase_orders',
  'purchase_order_items',
  'supplier_payments',
  'goods_receipts',
  'goods_receipt_items',
  'supplier_ledger',
  'shifts',
  'cash_movements',
  'sales',
  'sale_items',
  'sale_payments',
  'returns',
  'return_items',
  'gift_cards',
  'gift_card_sales',
  'gift_card_sale_payments',
  'promotions',
  'inventory_counts',
  'inventory_count_items',
  'warranty_claims',
];

/// The key/value settings table: synced too (entity `settings`, entity_id =
/// `key`), except [localSettingKeys] / [localSettingPrefixes].
const settingsTable = 'settings';

/// Tables that never leave the device (no triggers). `notifications` are
/// generated per device; `audit_log` sync is a known limitation of this stage.
const localOnlyTables = <String>[
  'sync_outbox',
  'sync_flags',
  'sync_state',
  'sync_row_versions',
  'sync_conflicts',
  'counters',
  'notifications',
  'audit_log',
];

/// Rows that are written once and never edited (ledgers, movements, document
/// lines, payments). They never conflict: the first insert wins and a later
/// identical upsert is a no-op. (`sale_items.returned_qty` is a cache, see
/// [cachedColumns], so sale items are append-only for sync purposes.)
const appendOnlyTables = <String>{
  'stock_movements',
  'customer_ledger',
  'supplier_ledger',
  'sale_items',
  'sale_payments',
  'return_items',
  'gift_card_sale_payments',
  'cash_movements',
  'goods_receipt_items',
};

/// Cached (derived) columns per table, SQL names. A remote upsert of an
/// existing local row never takes these from the payload; after the batch
/// `SyncAggregates.recompute` derives them from the ledgers/documents
/// (`lib/core/sync/aggregates.dart`).
const cachedColumns = <String, Set<String>>{
  'products': {'stock_qty'},
  'customers': {'debt_balance', 'bonus_balance'},
  'suppliers': {'balance'},
  'gift_cards': {'balance'},
  'purchase_orders': {'paid'},
  'purchase_order_items': {'received_qty'},
  'sales': {'refunded_total'},
  'sale_items': {'returned_qty'},
};

/// Columns written by bookkeeping (stock, balances, statistics) rather than
/// by a person editing the row, SQL names. A write that changes only these
/// (plus `updated_at`) is captured as outbox op `stat`, pushed as the row's
/// «stat part» and merged on its own last-writer-wins version, so a sale on
/// one register never re-sends that register's stale copy of the price,
/// debt limit or block flag the owner just changed on another one (spec §3).
/// Includes every [cachedColumns] column (those are recomputed, never
/// applied) plus statistics that cannot be derived (kept LWW).
///
/// `users`: a PIN login writes the last login time and resets the failed
/// attempts / lock (schema v7). As a user-part write it would make the stale
/// copy of the row on the login register beat the owner's deactivation, PIN
/// or role change made on another register.
const statColumns = <String, Set<String>>{
  'users': {'last_login_at', 'failed_pin_attempts', 'locked_until'},
  'products': {'stock_qty', 'cost_price'},
  'customers': {'debt_balance', 'bonus_balance', 'total_spent', 'visits', 'last_visit_at'},
  'suppliers': {'balance'},
  'gift_cards': {'balance'},
  'purchase_orders': {'paid', 'received_at'},
  'purchase_order_items': {'received_qty'},
  'sales': {'refunded_total'},
  'sale_items': {'returned_qty'},
};

/// Status columns whose changes between the listed values are bookkeeping
/// (a stat change: returns, redemptions, receiving); a change to or from any
/// other value (void, block, cancel…) is a user change.
const statStatuses = <String, Set<String>>{
  'gift_cards': {'active', 'used'},
  'sales': {'completed', 'partially_returned', 'returned'},
  'purchase_orders': {'ordered', 'received'},
};

/// Values that, once a document has them on any register, win over every
/// other value of that row regardless of versions (a void, a reversal or a
/// count's stock correction is irreversible: its effect rows exist on every
/// register): table → (status value, columns that travel with it).
const stickyStatus = <String, ({String value, List<String> columns})>{
  'sales': (value: 'voided', columns: ['status', 'void_reason']),
  'gift_card_sales': (
    value: 'voided',
    columns: ['status', 'voided_at', 'voided_by', 'void_shift_id', 'void_reason'],
  ),
  'goods_receipts': (value: 'reversed', columns: ['status', 'reversed_at', 'reversed_by', 'reverse_reason']),
  'inventory_counts': (value: 'completed', columns: ['status', 'completed_at']),
};

/// Status a document starts in and never returns to: table → status. A
/// remote edit made in that status never overrides a row that has left it,
/// and a remote change that has left it always overrides a local row still
/// in it (a draft purchase order edited on one register while another sent,
/// received or cancelled it, or an inventory count edited on one register
/// while another completed or cancelled it: the draft edit loses, D-025).
const initialStatus = <String, String>{'purchase_orders': 'draft', 'inventory_counts': 'draft'};

/// Setting holding this register's device code (`A`, `B`… assigned by the
/// server at join). Null/absent when sync is off.
const deviceCodeSettingKey = 'device_code';

/// Device-local settings (never synced). Real keys used in `lib/`:
/// * `register_id` — register bound to this device (today in
///   shared_preferences; reserved here so it never syncs if moved to the DB);
/// * `device_code` — this register's document code;
/// * `setup_done`, `installed_at` — per-install bootstrap/trial date;
/// * `theme_mode` — UI preference of this device (`ui_locale` lives in
///   shared_preferences; all `ui_*` keys are local by prefix);
/// * `receipt_width_mm`, `auto_print_receipt` — the printer attached here;
/// * `auto_backup_daily`, `last_backup_at` — backups of this device's file.
const localSettingKeys = <String>[
  'register_id',
  deviceCodeSettingKey,
  'setup_done',
  'installed_at',
  'theme_mode',
  'receipt_width_mm',
  'auto_print_receipt',
  'auto_backup_daily',
  'last_backup_at',
];

/// Prefixes of device-local setting keys: sync bookkeeping, UI, printer /
/// hardware and backup paths.
const localSettingPrefixes = <String>['sync_', 'ui_', 'printer_', 'hw_', 'backup_'];

/// True when the setting [key] stays on this device.
bool isLocalSettingKey(String key) =>
    localSettingKeys.contains(key) || localSettingPrefixes.any(key.startsWith);

String _q(String s) => "'${s.replaceAll("'", "''")}'";

/// SQL condition over `<row>.key` that is true for synced (non-local) keys.
/// Prefixes are compared with `substr`, not LIKE: LIKE is replaced by an
/// application function (D-017) that SQLite refuses inside triggers.
String _syncedKeyCondition(String row) {
  final keys = localSettingKeys.map(_q).join(', ');
  final prefixes =
      localSettingPrefixes.map((p) => ' AND substr($row.key, 1, ${p.length}) <> ${_q(p)}').join();
  return '$row.key NOT IN ($keys)$prefixes';
}

/// Trigger guard: outbox writes are suppressed while `sync_flags.applying = 1`.
const _notApplying = 'COALESCE((SELECT applying FROM sync_flags WHERE id = 1), 0) = 0';

/// Names of every sync trigger (for tests / diagnostics).
List<String> syncTriggerNames() => [
      for (final t in [...syncedTables, settingsTable])
        for (final op in [
          'ins',
          'upd',
          if (statColumns.containsKey(t)) 'upds',
          'del',
        ])
          'trg_sync_${t}_$op',
    ];

/// `OLD.c IS NOT NEW.c` over the user (non-stat) columns of [table]: true
/// when a person-edited column changed. `updated_at` is ignored.
String _userChanged(String table, List<String> columns) {
  final stat = statColumns[table] ?? const <String>{};
  final status = statStatuses[table];
  final parts = <String>[
    for (final c in columns)
      if (c != 'updated_at' && !stat.contains(c) && !(status != null && c == 'status')) 'OLD."$c" IS NOT NEW."$c"',
    if (status != null)
      '(OLD.status IS NOT NEW.status AND NOT (OLD.status IN (${status.map(_q).join(', ')}) '
          'AND NEW.status IN (${status.map(_q).join(', ')})))',
  ];
  return parts.isEmpty ? '0' : '(${parts.join(' OR ')})';
}

/// True when a stat column (or a stat-range status) changed.
String _statChanged(String table) {
  final stat = statColumns[table] ?? const <String>{};
  final status = statStatuses[table];
  final parts = <String>[
    for (final c in stat) 'OLD."$c" IS NOT NEW."$c"',
    if (status != null) 'OLD.status IS NOT NEW.status',
  ];
  return parts.isEmpty ? '0' : '(${parts.join(' OR ')})';
}

/// DDL that (re)creates every sync trigger. Idempotent: each trigger is
/// dropped first. Run in `onCreate` and in the v5/v6 upgrades (after
/// `sync_flags` and `sync_outbox` exist).
///
/// [columns] maps a synced table to its SQL columns (needed for the
/// user/stat split of the [statColumns] tables): an UPDATE that changes a
/// user column writes op `upsert`; one that changes a stat column, or nothing
/// but `updated_at`, writes op `stat` (both when both changed).
List<String> syncTriggerStatements(Map<String, List<String>> columns) {
  final out = <String>[];
  void add(String table, String op, String event, String idExpr, String outOp, [String? extraWhen]) {
    final name = 'trg_sync_${table}_$op';
    final when = extraWhen == null ? _notApplying : '$_notApplying AND $extraWhen';
    out
      ..add('DROP TRIGGER IF EXISTS $name')
      ..add('CREATE TRIGGER $name AFTER $event ON $table WHEN $when BEGIN '
          'INSERT INTO sync_outbox (entity, entity_id, op, at) '
          "VALUES (${_q(table)}, $idExpr, '$outOp', $sqlNowMs); END");
  }

  for (final t in syncedTables) {
    add(t, 'ins', 'INSERT', 'NEW.id', 'upsert');
    if (statColumns.containsKey(t)) {
      final cols = columns[t];
      if (cols == null || cols.isEmpty) throw ArgumentError('columns of $t are required');
      final user = _userChanged(t, cols);
      add(t, 'upd', 'UPDATE', 'NEW.id', 'upsert', user);
      add(t, 'upds', 'UPDATE', 'NEW.id', 'stat', '(${_statChanged(t)} OR NOT $user)');
    } else {
      add(t, 'upd', 'UPDATE', 'NEW.id', 'upsert');
    }
    add(t, 'del', 'DELETE', 'OLD.id', 'delete');
  }
  add(settingsTable, 'ins', 'INSERT', 'NEW.key', 'upsert', _syncedKeyCondition('NEW'));
  add(settingsTable, 'upd', 'UPDATE', 'NEW.key', 'upsert', _syncedKeyCondition('NEW'));
  add(settingsTable, 'del', 'DELETE', 'OLD.key', 'delete', _syncedKeyCondition('OLD'));
  return out;
}
