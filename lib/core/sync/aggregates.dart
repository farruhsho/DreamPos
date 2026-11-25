// Cached aggregates are derived, never synced (D-025, spec §4).
//
// Every formula below was checked against the domain services that maintain
// the cache today, so on a single register `verifyAll` is empty after any
// sequence of service calls:
//
// | cache                              | derived from (rows with deleted_at IS NULL)                         | maintained by |
// |------------------------------------|---------------------------------------------------------------------|---------------|
// | products.stock_qty                 | Qty.round(Σ stock_movements.qty of the product)                     | StockService.move (every stock change; nothing when trackStock is off, so both sides stay unchanged) |
// | customers.debt_balance             | Σ customer_ledger.amount, kind ∈ debt_sale, debt_payment, debt_adjust | SaleService.checkout/returnItems/voidSale, CustomerService.payDebt |
// | customers.bonus_balance            | Σ customer_ledger.amount, kind ∈ bonus_earn, bonus_spend, bonus_adjust | SaleService (earn/spend, return claw-back, void), CustomerService.adjustBonus |
// | suppliers.balance                  | Σ supplier_ledger.amount                                            | SupplierLedgerService.post (D-021) |
// | gift_cards.balance                 | 0 if the card's gift_card_sales document is voided; else initial_amount − Σ sale_payments.amount (method gift_card, gift_card_id = card; pre-v6 rows: reference = code) of sales that are not voided | GiftCardService.sell/voidSale, SaleService.checkout (redeem) / voidSale (refund). Returns never refund to a card. |
// | gift_cards.status                  | voided sale → blocked; active/used → (balance ≤ 0 ? used : active); expired/blocked kept | same |
// | purchase_orders.paid               | Σ supplier_payments.amount with that order_id and cancelled_at IS NULL | SupplierLedgerService.pay/cancelPayment |
// | purchase_order_items.received_qty  | Qty.round(Σ goods_receipt_items.qty with that order_item_id of posted goods_receipts) | PurchasingRepo.receiveOrderDoc (+), ReceiptService.reverse (−) |
// | sale_items.returned_qty            | sale voided → qty; else Qty.round(Σ return_items.qty of the item)    | SaleService.returnItems/voidSale |
// | sales.refunded_total               | sale voided → total; else Σ returns.total of the sale               | SaleService.returnItems/voidSale |
// | sales.status                       | voided/held kept; no returned qty → completed; every item fully returned → returned; else partially_returned | SaleService.returnItems/voidSale |
//
// Not exactly derivable — kept last-writer-wins from the row (known
// limitations, documented in the spec):
// * products.cost_price — moving weighted average; concurrent receipts on two
//   registers give a slightly different average. products.price likewise.
// * customers.total_spent / visits / last_visit_at — clamped at 0 on returns
//   and voids (`max(0, …)`), so not a pure sum; concurrent sales to one
//   customer on two registers can lose one increment.
// * purchase_orders.status/total/received_at, goods_receipts.total,
//   shifts.expected_cash — document fields written once by their own register.
// * Legacy rows from before the documents existed may not match. Order lines
//   received before v3 (no goods_receipts) get a posted «opening» receipt
//   document for the received quantity from the v5 normalisation (total 0,
//   no stock or supplier movements: those happened back then; it cannot be
//   reversed), so every register derives the same received quantity and the
//   goods are never received twice. Other legacy mismatches (pre-v4 gift
//   cards) are logged to `sync_conflicts` (kind `normalize`).
//
// Ledger-backed caches (stock, debt, bonus, supplier balance) are normalised
// by the v5 migration with a difference row («Начальный остаток
// (синхронизация)»), so `cache == Σ ledger` holds on every database (the D-021
// "balance == last balanceAfter" invariant is relaxed to this).
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../db/database.dart';
import '../money.dart';

/// Note of the v5 normalisation rows. Stored DB text stays Russian (D-024),
/// like the v3 «Начальный остаток» opening rows (D-022).
const syncOpeningNote = 'Начальный остаток (синхронизация)'; // l10n-ignore: stored ledger note

/// One cache whose stored value differs from the value derived from its
/// ledger / documents.
class AggregateMismatch {
  const AggregateMismatch(this.table, this.id, this.column, this.cached, this.derived);

  /// SQL table and column of the cache.
  final String table;
  final String id;
  final String column;
  final Object? cached;
  final Object? derived;

  /// True for caches that have a ledger the v5 normalisation can append to.
  bool get ledgerBacked => switch ((table, column)) {
        ('products', 'stock_qty') ||
        ('customers', 'debt_balance') ||
        ('customers', 'bonus_balance') ||
        ('suppliers', 'balance') =>
          true,
        _ => false,
      };

  @override
  String toString() => '$table.$column[$id]: cached=$cached derived=$derived';

  @override
  bool operator ==(Object other) =>
      other is AggregateMismatch &&
      other.table == table &&
      other.id == id &&
      other.column == column &&
      other.cached == cached &&
      other.derived == derived;

  @override
  int get hashCode => Object.hash(table, id, column, cached, derived);
}

/// Ids of the cache owners to recompute.
class AggregateTargets {
  final products = <String>{};
  final customers = <String>{};
  final suppliers = <String>{};
  final giftCards = <String>{};
  final purchaseOrders = <String>{};
  final purchaseOrderItems = <String>{};
  final sales = <String>{};

  bool get isEmpty =>
      products.isEmpty &&
      customers.isEmpty &&
      suppliers.isEmpty &&
      giftCards.isEmpty &&
      purchaseOrders.isEmpty &&
      purchaseOrderItems.isEmpty &&
      sales.isEmpty;
}

/// A redemption belongs to a card by id (v6); rows from before v6 have no
/// id and match by code. The code alone is not enough: after two registers
/// issued one code offline, the losing card is renamed (sync_service).
const _paymentOfCard = '(p.gift_card_id = g.id OR (p.gift_card_id IS NULL AND p.reference = g.code))';

const _debtKinds = "('debt_sale', 'debt_payment', 'debt_adjust')";
const _bonusKinds = "('bonus_earn', 'bonus_spend', 'bonus_adjust')";
const _chunk = 500;

abstract final class SyncAggregates {
  /// Every cache mismatch in the database (no writes). Empty on a healthy
  /// database. Used by tests and «Проверка целостности».
  static Future<List<AggregateMismatch>> verifyAll(AppDatabase db) => _checkAll(db, null);

  /// Recomputes the caches affected by [touched] (SQL table name → ids of the
  /// rows that were inserted/updated, e.g. what a remote batch applied) and
  /// writes the derived values. Child rows are resolved to their owners
  /// (`stock_movements` → product, `customer_ledger` → customer,
  /// `return_items` → sale, `sale_payments` → gift card…). A hard-deleted
  /// child cannot be resolved: pass its parent id as well.
  ///
  /// Runs in one transaction with the sync triggers suppressed (caches are
  /// derived on every device, they are not pushed) and does not touch
  /// `updated_at`. Returns what was changed.
  static Future<List<AggregateMismatch>> recompute(
      AppDatabase db, Map<String, Iterable<String>> touched) {
    return db.withSyncSuppressed(() async {
      final t = await resolveTargets(db, touched);
      if (t.isEmpty) return const <AggregateMismatch>[];
      final changed = await _checkAll(db, t);
      for (final m in changed) {
        await db.customStatement(
            'UPDATE ${m.table} SET ${m.column} = ? WHERE id = ?', [m.derived, m.id]);
      }
      return changed;
    });
  }

  /// Maps changed rows to the cache owners they affect.
  static Future<AggregateTargets> resolveTargets(
      AppDatabase db, Map<String, Iterable<String>> touched) async {
    final t = AggregateTargets();
    Set<String> ids(String table) => {...?touched[table]};
    Future<void> lookup(Set<String> into, String table, String sqlBeforeIn) async {
      final src = ids(table).toList();
      for (var i = 0; i < src.length; i += _chunk) {
        final part = src.sublist(i, i + _chunk > src.length ? src.length : i + _chunk);
        final rows = await db
            .customSelect('$sqlBeforeIn (${List.filled(part.length, '?').join(', ')})',
                variables: [for (final id in part) Variable.withString(id)])
            .get();
        for (final r in rows) {
          final v = r.data.values.first;
          if (v is String) into.add(v);
        }
      }
    }

    t.products.addAll(ids('products'));
    await lookup(t.products, 'stock_movements', 'SELECT product_id FROM stock_movements WHERE id IN');
    t.customers.addAll(ids('customers'));
    await lookup(t.customers, 'customer_ledger', 'SELECT customer_id FROM customer_ledger WHERE id IN');
    t.suppliers.addAll(ids('suppliers'));
    await lookup(t.suppliers, 'supplier_ledger', 'SELECT supplier_id FROM supplier_ledger WHERE id IN');

    t.giftCards.addAll(ids('gift_cards'));
    await lookup(t.giftCards, 'gift_card_sales', 'SELECT gift_card_id FROM gift_card_sales WHERE id IN');
    const byPayment = 'SELECT g.id FROM gift_cards g JOIN sale_payments p ON $_paymentOfCard '
        "WHERE p.method = 'gift_card' AND";
    await lookup(t.giftCards, 'sale_payments', '$byPayment p.id IN');
    await lookup(t.giftCards, 'sales', '$byPayment p.sale_id IN');

    t.purchaseOrders.addAll(ids('purchase_orders'));
    await lookup(t.purchaseOrders, 'supplier_payments',
        'SELECT order_id FROM supplier_payments WHERE order_id IS NOT NULL AND id IN');
    t.purchaseOrderItems.addAll(ids('purchase_order_items'));
    await lookup(t.purchaseOrderItems, 'goods_receipt_items',
        'SELECT order_item_id FROM goods_receipt_items WHERE order_item_id IS NOT NULL AND id IN');
    await lookup(t.purchaseOrderItems, 'goods_receipts',
        'SELECT order_item_id FROM goods_receipt_items WHERE order_item_id IS NOT NULL AND receipt_id IN');

    t.sales.addAll(ids('sales'));
    await lookup(t.sales, 'returns', 'SELECT sale_id FROM returns WHERE id IN');
    await lookup(t.sales, 'sale_items', 'SELECT sale_id FROM sale_items WHERE id IN');
    await lookup(t.sales, 'return_items',
        'SELECT si.sale_id FROM return_items ri JOIN sale_items si ON si.id = ri.sale_item_id WHERE ri.id IN');
    return t;
  }

  /// v5 migration: makes `cache == derived` hold. For ledger-backed caches a
  /// difference row is appended («Начальный остаток (синхронизация)»;
  /// `balanceAfter`/`qtyAfter` = the cached value, so the last running
  /// balance also still equals the cache). Order lines received before v3
  /// (more received than the posted receipt documents say) get one opening
  /// receipt document per order ([_openingReceipts]). Other mismatches
  /// (legacy documents) are logged to `sync_conflicts` (kind `normalize`) and
  /// left unchanged. Idempotent. Returns the mismatches found.
  static Future<List<AggregateMismatch>> normalize(AppDatabase db) {
    return db.transaction(() async {
      final found = await verifyAll(db);
      final now = DateTime.now();
      final legacyReceived = <AggregateMismatch>[];
      for (final m in found) {
        final id = newId();
        switch ((m.table, m.column)) {
          case ('purchase_order_items', 'received_qty')
              when (m.cached as num).toDouble() > (m.derived as num).toDouble():
            legacyReceived.add(m);
          case ('products', 'stock_qty'):
            final cached = (m.cached as num).toDouble();
            final p = await (db.select(db.products)..where((t) => t.id.equals(m.id))).getSingle();
            await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
                  id: id,
                  productId: m.id,
                  type: 'adjustment',
                  qty: Qty.round(cached - (m.derived as num).toDouble()),
                  qtyAfter: cached,
                  unitCost: Value(p.costPrice),
                  refType: const Value('sync'),
                  reason: const Value(syncOpeningNote),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ));
          case ('customers', 'debt_balance' || 'bonus_balance'):
            final cached = m.cached as int;
            await db.into(db.customerLedger).insert(CustomerLedgerCompanion.insert(
                  id: id,
                  customerId: m.id,
                  kind: m.column == 'debt_balance' ? 'debt_adjust' : 'bonus_adjust',
                  amount: cached - (m.derived as int),
                  balanceAfter: cached,
                  refType: const Value('sync'),
                  note: const Value(syncOpeningNote),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ));
          case ('suppliers', 'balance'):
            final cached = m.cached as int;
            final hasRows = await (db.select(db.supplierLedger)
                  ..where((l) => l.supplierId.equals(m.id))
                  ..limit(1))
                .getSingleOrNull();
            await db.into(db.supplierLedger).insert(SupplierLedgerCompanion.insert(
                  id: id,
                  supplierId: m.id,
                  kind: hasRows == null ? 'opening' : 'adjustment',
                  amount: cached - (m.derived as int),
                  balanceAfter: cached,
                  note: const Value(syncOpeningNote),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ));
          default:
            final details = '${m.column}: cached=${m.cached}; derived=${m.derived}';
            final dup = await (db.select(db.syncConflicts)
                  ..where((c) =>
                      c.kind.equals('normalize') &
                      c.entity.equals(m.table) &
                      c.entityId.equals(m.id) &
                      c.details.equals(details)))
                .get();
            if (dup.isEmpty) {
              await db.into(db.syncConflicts).insert(SyncConflictsCompanion.insert(
                    kind: 'normalize',
                    entity: Value(m.table),
                    entityId: Value(m.id),
                    details: Value(details),
                  ));
            }
        }
      }
      await _openingReceipts(db, legacyReceived, now);
      return found;
    });
  }

  /// Order lines received before v3 have `received_qty` but no receipt
  /// documents, so a joining register would derive 0 and allow receiving the
  /// goods again. One posted receipt per order («Начальный остаток
  /// (синхронизация)», total 0) gets a line with the missing quantity: the
  /// derived value then equals the cache everywhere. No stock movement or
  /// supplier ledger row: those effects already happened (and the v3/v5
  /// opening rows cover the balances). `ReceiptService.reverse` refuses it.
  static Future<void> _openingReceipts(AppDatabase db, List<AggregateMismatch> lines, DateTime now) async {
    if (lines.isEmpty) return;
    final byOrder = <String, List<(PurchaseOrderItem, double)>>{};
    for (final m in lines) {
      final it = await (db.select(db.purchaseOrderItems)..where((t) => t.id.equals(m.id))).getSingle();
      byOrder.putIfAbsent(it.orderId, () => []).add(
          (it, Qty.round((m.cached as num).toDouble() - (m.derived as num).toDouble())));
    }
    final code = await db.deviceCode();
    for (final e in byOrder.entries) {
      final order = await (db.select(db.purchaseOrders)..where((t) => t.id.equals(e.key))).getSingleOrNull();
      final at = order?.receivedAt ?? now;
      final rid = newId();
      await db.into(db.goodsReceipts).insert(GoodsReceiptsCompanion.insert(
            id: rid,
            number: await db.nextNumber('receipt'),
            deviceCode: Value(code),
            supplierId: Value(order?.supplierId),
            orderId: Value(e.key),
            total: const Value(0),
            note: const Value(syncOpeningNote),
            createdAt: Value(at),
            updatedAt: Value(now),
          ));
      for (final (it, qty) in e.value) {
        await db.into(db.goodsReceiptItems).insert(GoodsReceiptItemsCompanion.insert(
              id: newId(),
              receiptId: rid,
              productId: it.productId,
              orderItemId: Value(it.id),
              qty: qty,
              unitCost: it.unitCost,
              createdAt: Value(at),
              updatedAt: Value(now),
            ));
      }
    }
  }

  // ------------------------------------------------------------------ checks

  static Future<List<AggregateMismatch>> _checkAll(AppDatabase db, AggregateTargets? t) async => [
        ...await _stock(db, t?.products),
        ...await _customers(db, t?.customers),
        ...await _suppliers(db, t?.suppliers),
        ...await _giftCards(db, t?.giftCards),
        ...await _orderPaid(db, t?.purchaseOrders),
        ...await _orderItemsReceived(db, t?.purchaseOrderItems),
        ...await _saleItemsReturned(db, t?.sales),
        ...await _sales(db, t?.sales),
      ];

  /// Runs `[select] FROM <table> t [WHERE t.<idCol> IN (…)]`, chunked; when
  /// [ids] is null, over the whole table.
  static Future<List<QueryRow>> _rows(AppDatabase db, String select, Set<String>? ids,
      {String idCol = 'id'}) async {
    if (ids == null) return db.customSelect(select).get();
    final list = ids.toList();
    final out = <QueryRow>[];
    for (var i = 0; i < list.length; i += _chunk) {
      final part = list.sublist(i, i + _chunk > list.length ? list.length : i + _chunk);
      out.addAll(await db
          .customSelect('$select WHERE t.$idCol IN (${List.filled(part.length, '?').join(', ')})',
              variables: [for (final id in part) Variable.withString(id)])
          .get());
    }
    return out;
  }

  static bool _qtyDiffers(double a, double b) => (a - b).abs() > 1e-6;

  static Future<List<AggregateMismatch>> _stock(AppDatabase db, Set<String>? ids) async {
    final rows = await _rows(
        db,
        'SELECT t.id, t.stock_qty AS cached, '
        '(SELECT COALESCE(SUM(m.qty), 0.0) FROM stock_movements m '
        'WHERE m.product_id = t.id AND m.deleted_at IS NULL) AS derived FROM products t',
        ids);
    return [
      for (final r in rows)
        if (_qtyDiffers(r.read<double>('cached'), Qty.round(r.read<double>('derived'))))
          AggregateMismatch('products', r.read<String>('id'), 'stock_qty', r.read<double>('cached'),
              Qty.round(r.read<double>('derived'))),
    ];
  }

  static Future<List<AggregateMismatch>> _customers(AppDatabase db, Set<String>? ids) async {
    final rows = await _rows(
        db,
        'SELECT t.id, t.debt_balance AS debt, t.bonus_balance AS bonus, '
        '(SELECT COALESCE(SUM(l.amount), 0) FROM customer_ledger l WHERE l.customer_id = t.id '
        'AND l.deleted_at IS NULL AND l.kind IN $_debtKinds) AS d_debt, '
        '(SELECT COALESCE(SUM(l.amount), 0) FROM customer_ledger l WHERE l.customer_id = t.id '
        'AND l.deleted_at IS NULL AND l.kind IN $_bonusKinds) AS d_bonus FROM customers t',
        ids);
    return [
      for (final r in rows) ...[
        if (r.read<int>('debt') != r.read<int>('d_debt'))
          AggregateMismatch('customers', r.read<String>('id'), 'debt_balance', r.read<int>('debt'),
              r.read<int>('d_debt')),
        if (r.read<int>('bonus') != r.read<int>('d_bonus'))
          AggregateMismatch('customers', r.read<String>('id'), 'bonus_balance', r.read<int>('bonus'),
              r.read<int>('d_bonus')),
      ],
    ];
  }

  static Future<List<AggregateMismatch>> _suppliers(AppDatabase db, Set<String>? ids) async {
    final rows = await _rows(
        db,
        'SELECT t.id, t.balance AS cached, (SELECT COALESCE(SUM(l.amount), 0) FROM supplier_ledger l '
        'WHERE l.supplier_id = t.id AND l.deleted_at IS NULL) AS derived FROM suppliers t',
        ids);
    return [
      for (final r in rows)
        if (r.read<int>('cached') != r.read<int>('derived'))
          AggregateMismatch('suppliers', r.read<String>('id'), 'balance', r.read<int>('cached'),
              r.read<int>('derived')),
    ];
  }

  /// Derivation of the gift card caches (see [_giftCards]); public for the
  /// query-plan regression test (no full scan of `sale_payments` per card).
  @visibleForTesting
  static const giftCardsSql = 'SELECT t.id, t.balance, t.status, t.initial_amount, '
        "EXISTS (SELECT 1 FROM gift_card_sales s WHERE s.gift_card_id = t.id AND s.status = 'voided' "
        'AND s.deleted_at IS NULL) AS voided, '
        // Two indexed lookups (by card id; pre-v6 rows by code) instead of
        // one OR condition that scans every payment for every card.
        '(SELECT COALESCE(SUM(p.amount), 0) FROM sale_payments p JOIN sales s ON s.id = p.sale_id '
        "WHERE p.method = 'gift_card' AND p.gift_card_id = t.id AND s.status <> 'voided' "
        'AND p.deleted_at IS NULL AND s.deleted_at IS NULL) + '
        '(SELECT COALESCE(SUM(p.amount), 0) FROM sale_payments p JOIN sales s ON s.id = p.sale_id '
        "WHERE p.method = 'gift_card' AND p.reference = t.code AND p.gift_card_id IS NULL "
      "AND s.status <> 'voided' AND p.deleted_at IS NULL AND s.deleted_at IS NULL) AS redeemed FROM gift_cards t";

  static Future<List<AggregateMismatch>> _giftCards(AppDatabase db, Set<String>? ids) async {
    final rows = await _rows(db, giftCardsSql, ids);
    final out = <AggregateMismatch>[];
    for (final r in rows) {
      final id = r.read<String>('id');
      final voided = r.read<int>('voided') == 1;
      final balance = voided ? 0 : r.read<int>('initial_amount') - r.read<int>('redeemed');
      final status = r.read<String>('status');
      final dStatus = voided
          ? 'blocked'
          : (status == 'active' || status == 'used')
              ? (balance <= 0 ? 'used' : 'active')
              : status;
      if (r.read<int>('balance') != balance) {
        out.add(AggregateMismatch('gift_cards', id, 'balance', r.read<int>('balance'), balance));
      }
      if (status != dStatus) out.add(AggregateMismatch('gift_cards', id, 'status', status, dStatus));
    }
    return out;
  }

  static Future<List<AggregateMismatch>> _orderPaid(AppDatabase db, Set<String>? ids) async {
    final rows = await _rows(
        db,
        'SELECT t.id, t.paid AS cached, (SELECT COALESCE(SUM(p.amount), 0) FROM supplier_payments p '
        'WHERE p.order_id = t.id AND p.cancelled_at IS NULL AND p.deleted_at IS NULL) AS derived '
        'FROM purchase_orders t',
        ids);
    return [
      for (final r in rows)
        if (r.read<int>('cached') != r.read<int>('derived'))
          AggregateMismatch('purchase_orders', r.read<String>('id'), 'paid', r.read<int>('cached'),
              r.read<int>('derived')),
    ];
  }

  /// Derivation of `purchase_order_items.received_qty`; public for the
  /// query-plan regression test (receipt lines looked up by index).
  @visibleForTesting
  static const orderItemsReceivedSql =
      'SELECT t.id, t.received_qty AS cached, (SELECT COALESCE(SUM(i.qty), 0.0) FROM goods_receipt_items i '
      "JOIN goods_receipts r ON r.id = i.receipt_id WHERE i.order_item_id = t.id AND r.status = 'posted' "
      'AND i.deleted_at IS NULL AND r.deleted_at IS NULL) AS derived FROM purchase_order_items t';

  static Future<List<AggregateMismatch>> _orderItemsReceived(AppDatabase db, Set<String>? ids) async {
    final rows = await _rows(db, orderItemsReceivedSql, ids);
    return [
      for (final r in rows)
        if (_qtyDiffers(r.read<double>('cached'), Qty.round(r.read<double>('derived'))))
          AggregateMismatch('purchase_order_items', r.read<String>('id'), 'received_qty',
              r.read<double>('cached'), Qty.round(r.read<double>('derived'))),
    ];
  }

  /// Derivation of `sale_items.returned_qty`; public for the query-plan
  /// regression test (return lines looked up by `ix_return_items_sale_item`,
  /// not scanned once per sale line: the v5 upgrade runs it over the whole
  /// store).
  @visibleForTesting
  static const saleItemsReturnedSql = 'SELECT t.id, t.qty, t.returned_qty AS cached, s.status, '
      '(SELECT COALESCE(SUM(ri.qty), 0.0) FROM return_items ri WHERE ri.sale_item_id = t.id '
      'AND ri.deleted_at IS NULL) AS returned FROM sale_items t JOIN sales s ON s.id = t.sale_id';

  /// [saleIds]: items of these sales (null = all items).
  static Future<List<AggregateMismatch>> _saleItemsReturned(AppDatabase db, Set<String>? saleIds) async {
    final rows = await _rows(db, saleItemsReturnedSql, saleIds, idCol: 'sale_id');
    final out = <AggregateMismatch>[];
    for (final r in rows) {
      final derived =
          r.read<String>('status') == 'voided' ? r.read<double>('qty') : Qty.round(r.read<double>('returned'));
      if (_qtyDiffers(r.read<double>('cached'), derived)) {
        out.add(AggregateMismatch('sale_items', r.read<String>('id'), 'returned_qty', r.read<double>('cached'), derived));
      }
    }
    return out;
  }

  /// Derivation of `sales.refunded_total` / status; public for the
  /// query-plan regression test.
  @visibleForTesting
  static const salesSql = 'SELECT t.id, t.status, t.total, t.refunded_total, '
      '(SELECT COALESCE(SUM(r.total), 0) FROM returns r WHERE r.sale_id = t.id AND r.deleted_at IS NULL) '
      'AS refunded, '
      '(SELECT COUNT(*) FROM sale_items si JOIN return_items ri ON ri.sale_item_id = si.id '
      'WHERE si.sale_id = t.id AND ri.deleted_at IS NULL) AS return_lines, '
      '(SELECT COUNT(*) FROM sale_items si WHERE si.sale_id = t.id AND si.qty - '
      '(SELECT COALESCE(SUM(ri.qty), 0) FROM return_items ri WHERE ri.sale_item_id = si.id '
      'AND ri.deleted_at IS NULL) > 0.000000001) AS open_lines FROM sales t';

  static Future<List<AggregateMismatch>> _sales(AppDatabase db, Set<String>? ids) async {
    final rows = await _rows(db, salesSql, ids);
    final out = <AggregateMismatch>[];
    for (final r in rows) {
      final id = r.read<String>('id');
      final status = r.read<String>('status');
      final voided = status == 'voided';
      final refunded = voided ? r.read<int>('total') : r.read<int>('refunded');
      if (r.read<int>('refunded_total') != refunded) {
        out.add(AggregateMismatch('sales', id, 'refunded_total', r.read<int>('refunded_total'), refunded));
      }
      final dStatus = (voided || status == 'held')
          ? status
          : r.read<int>('return_lines') == 0
              ? 'completed'
              : r.read<int>('open_lines') == 0
                  ? 'returned'
                  : 'partially_returned';
      if (status != dStatus) out.add(AggregateMismatch('sales', id, 'status', status, dStatus));
    }
    return out;
  }
}
