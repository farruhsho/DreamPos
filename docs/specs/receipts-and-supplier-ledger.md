# Spec: Goods receipt documents + supplier ledger (roadmap item 2)

Status: in implementation (2026-11-24). Decision record: D-021, D-022 in DECISIONS.md.

## Goals
1. Every goods receipt (manual «Приход» and receiving against a purchase order) is a
   **numbered document** (`Приход №N`) with lines, supplier, supplier invoice number, note,
   author, and status `posted` | `reversed`.
2. A posted receipt can be **reversed (сторно)** with a mandatory reason, all-or-nothing.
3. Every change of `suppliers.balance` is written to an immutable **supplier ledger** with a
   running balance (like `customer_ledger`). The ledger is the audit trail; `suppliers.balance`
   stays as the cached value and must always equal the last `balanceAfter`.
4. Supplier payments can be **cancelled** (reversal entry, not hard delete).
5. UI: receipt document list/detail with reversal and PDF; supplier «Взаиморасчёты» with
   reconciliation act (акт сверки) PDF/CSV; PO detail shows its receipts.

## Schema (schemaVersion 2 → 3)
New tables (all `with SyncColumns`, registered in `@DriftDatabase`):

```dart
/// status: posted | reversed
class GoodsReceipts extends Table with SyncColumns {
  IntColumn get number => integer()();                 // db.nextNumber('receipt')
  TextColumn get supplierId => text().nullable()();
  TextColumn get orderId => text().nullable()();       // purchase order, if any
  TextColumn get supplierInvoice => text().nullable()();// № накладной поставщика
  TextColumn get status => text().withDefault(const Constant('posted'))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  TextColumn get userId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get reversedAt => dateTime().nullable()();
  TextColumn get reversedBy => text().nullable()();
  TextColumn get reverseReason => text().nullable()();
}

class GoodsReceiptItems extends Table with SyncColumns {
  TextColumn get receiptId => text().references(GoodsReceipts, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get orderItemId => text().nullable()();   // purchase_order_items.id
  RealColumn get qty => real()();
  IntColumn get unitCost => integer()();
  IntColumn get oldPrice => integer().nullable()();    // retail price before, if changed
  IntColumn get newPrice => integer().nullable()();    // retail price set by this receipt
}

/// kind: opening | receipt | receipt_reversal | payment | payment_cancel | adjustment
/// amount signed: positive = store owes supplier MORE.
@DataClassName('SupplierLedgerEntry')
class SupplierLedger extends Table with SyncColumns {
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  IntColumn get balanceAfter => integer()();
  TextColumn get refType => text().nullable()();  // goods_receipt | supplier_payment
  TextColumn get refId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get note => text().nullable()();
}
```
`SupplierPayments` gets `DateTimeColumn get cancelledAt => dateTime().nullable()();`
and `TextColumn get cancelReason => text().nullable()();`.

Migration `from < 3`: `m.createTable` for the 3 tables, `m.addColumn` for the 2 payment
columns, then **opening entries**: for every supplier with `balance != 0` insert a ledger row
`kind='opening', amount=balance, balanceAfter=balance, note='Начальный остаток'`.
Historical receipts are NOT back-filled into documents (decision D-022; no production data
exists yet). Indexes (IF NOT EXISTS, appended to `_indexes`): `goods_receipts(created_at)`,
`goods_receipts(supplier_id)`, `goods_receipts(order_id)`, `goods_receipt_items(receipt_id)`,
`supplier_ledger(supplier_id, created_at)`.

Stock movement types: new type **`receipt_reversal`** (negative qty). Receipt movements now use
`refType: 'receipt'`, `refId: <goods_receipts.id>` for BOTH manual and PO receipts
(the old `refType 'purchase'/refId orderId` is no longer written; readers that compute a
PO's received value must use goods_receipt_items of posted receipts with that orderId).

## Domain services (lib/domain/services) — the only writers
### SupplierLedgerService (`supplier_service.dart`)
- `Future<int> post({supplierId, kind, amount, refType, refId, userId, note})` — must run inside
  a caller transaction (wraps its own `db.transaction`, drift nests). Reads supplier, writes
  `balance + amount`, inserts ledger row with `balanceAfter`, markDirty both. Returns new balance.
- `pay(...)` — moved from `PurchasingRepo.paySupplier` (same validation & messages: amount>0,
  known method, cash needs open shift, overpay needs `allowOverpay`, order belongs to supplier and
  not cancelled). Writes payment + ledger `payment` (amount = −payment), updates `purchase_orders.paid`.
  Audit `supplier.payment`. `PurchasingRepo.paySupplier` delegates to it (keep signature).
- `cancelPayment(paymentId, {reason, userId})` — reason required. Not already cancelled.
  Cash payment can be cancelled only while its shift is still `open`
  (`'Смена оплаты закрыта — отмена невозможна'`). Sets `cancelledAt/cancelReason`, ledger
  `payment_cancel` (+amount), decreases `purchase_orders.paid` (not below 0). Audit `supplier.payment_cancel`.
- `adjust(supplierId, amount, {reason, userId})` — manual correction (amount ≠ 0, reason required),
  ledger `adjustment`, audit `supplier.adjust`. UI gates it with `Perm.manageSettings`
  (owner/admin only).
- `ShiftService.report` must ignore cancelled supplier payments (`cancelledAt IS NULL`); same for
  any other reader of supplier_payments (shift providers, purchasing lists show them struck/marked).

### ReceiptService (`receipt_service.dart`)
```dart
class ReceiptLineInput { productId; qty; unitCost; int? newPrice; String? orderItemId; }
Future<PostedReceipt> post({required List<ReceiptLineInput> lines, String? supplierId,
  String? orderId, String? supplierInvoice, String? note, String? userId, bool canEditPrices = true})
Future<void> reverse(String receiptId, {required String reason, String? userId})
```
`post` (one transaction): validate (non-empty, qty > 0 and integral for non-fractional units,
qty ≤ 1e7, unitCost ≥ 0, newPrice > 0 when given, product exists & not deleted, no duplicate
productId+orderItemId); supplier must exist & not deleted if given; if `orderId` given it must
belong to the supplier and be `ordered`/`draft`. Number = `nextNumber('receipt')`. Insert header
+ items; per line `StockService.receive(refType:'receipt', refId:id, reason:'Приход №N…')`;
price change records `oldPrice/newPrice` and audits `product.price`. If supplier and total ≠ 0 →
ledger `receipt` (+total, refType goods_receipt). Audit `receipt.post`. `PostedReceipt{id, number, total}`.

`reverse` (one transaction): receipt exists, status `posted`, reason non-empty. For every line:
`StockService.move(delta: −qty, type:'receipt_reversal', refType:'receipt', refId:id,
enforce: true, unitCost: line.unitCost)` → fails with the standard «Недостаточно товара …» when stock
was already sold (unless negative stock allowed). Weighted-average cost rollback: with S = stock
before reversal, C = current cost: if S − qty > 0 and (C·S − unitCost·qty) > 0 then new cost =
round((C·S − unitCost·qty)/(S − qty)), otherwise keep C. Price: if `newPrice != null` and the
product's current price still equals `newPrice`, restore `oldPrice`; otherwise leave it. PO lines:
`receivedQty −= qty` (≥ 0); a `received` PO with remaining qty goes back to `ordered`,
`receivedAt = null`. Supplier: ledger `receipt_reversal` (−total). Header → `reversed`,
`reversedAt/By/reason`. Audit `receipt.reverse`. Reversing twice → «Приход №N уже сторнирован».

`InventoryRepo.postReceipt` and `PurchasingRepo.receiveOrder` keep their public signatures/return
types but delegate to `ReceiptService.post` (PO: `orderId`, `orderItemId` per line, PO
receivedQty/status updates stay in the same transaction). Add `receiptServiceProvider` and
`supplierLedgerServiceProvider` to `lib/core/providers.dart`.

## UI
Inventory (`lib/features/inventory`):
- Receipt form: add «№ накладной поставщика» field; success message «Приход №N проведён».
- New «Документы» view (tab or segmented control within the Приход tab): list with period
  filter, supplier filter, status filter, search by number/invoice; columns №, дата, поставщик,
  накладная, позиций, сумма, статус chip («Проведён» / «Сторнирован»), source (Заказ №N).
- Detail dialog/page: header, lines (товар, кол-во, цена закупки, сумма, новая розничная цена),
  totals, author, reversal info; actions: «Печать» (PDF, offline fonts like inventory_pdf.dart),
  «Сторнировать» (needs `Perm.stockOps`, confirm + mandatory reason, destructive styling).
- Movements: label `receipt_reversal` → «Сторно прихода»; reference shows «Приход №N».

Purchasing (`lib/features/purchasing`):
- Supplier detail: «Взаиморасчёты» section — ledger with date, operation, document, приход (+),
  расход (−), баланс; period filter; opening balance for the period; actions «Оплата» (existing),
  «Отменить оплату» on payment rows, «Корректировка» (manageSettings only); «Акт сверки» PDF and CSV
  export for the period (opening balance, rows, turnover, closing balance, signature lines).
- PO detail: list of its receipt documents (№, дата, сумма, статус) opening the receipt detail;
  received value = Σ posted receipts.
- Price control tab: ignore lines of reversed receipts.

Everywhere: loading/error/empty states, Russian validation texts, 390/1024/1440 without
overflow, double-tap protection, permission gating, ux_screens_test coverage.

## Tests (must add)
Domain (`test/domain/receipt_service_test.dart`, `supplier_ledger_test.dart`): numbering; stock +
avg cost on post; ledger rows and balance == last balanceAfter; reverse restores stock, cost,
price (and does not restore a price changed since), supplier balance, PO receivedQty/status;
reverse blocked when stock sold; double reverse; payment cancel incl. closed-shift block;
shift report ignores cancelled payments; migration v2→v3 creates opening entries.
