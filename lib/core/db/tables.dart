// DreamPOS database schema.
//
// Conventions (see DECISIONS.md):
//  * Every syncable row has a TEXT UUID primary key `id`, `createdAt`,
//    `updatedAt` and soft-delete `deletedAt` so that a future multi-terminal
//    sync (outbox -> server) never needs a schema rewrite.
//  * Money is stored as INTEGER minor units (e.g. tiyin / cents). Never double.
//  * Quantities are REAL rounded to 3 decimals (weighted goods are supported).
//  * Stock is a ledger (`stock_movements`); `products.stockQty` is a cache that
//    is updated in the same transaction as the movement.
import 'package:drift/drift.dart';

mixin SyncColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Key/value store settings (store name, currency, receipt footer, ...).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Staff. Role: owner | admin | manager | cashier | storekeeper.
class Users extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text()();
  TextColumn get pinHash => text()();
  TextColumn get pinSalt => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  /// Max manual discount percent this user may grant without approval.
  RealColumn get maxDiscountPercent => real().withDefault(const Constant(0))();
  /// Monthly sales plan in minor units (0 = none).
  IntColumn get salesPlan => integer().withDefault(const Constant(0))();
  /// Commission percent from own sales (seller motivation).
  RealColumn get commissionPercent => real().withDefault(const Constant(0))();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  IntColumn get failedPinAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();
}

/// Clock-in / clock-out (time tracking).
class WorkSessions extends Table with SyncColumns {
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
}

/// Physical cash registers / terminals.
class Registers extends Table with SyncColumns {
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class Categories extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get parentId => text().nullable()();
  IntColumn get color => integer().withDefault(const Constant(0xFF4F46E5))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// unit: pcs | kg | g | l | m | pack
class Products extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  IntColumn get price => integer()(); // retail price, minor units
  IntColumn get costPrice => integer().withDefault(const Constant(0))(); // last/avg purchase cost
  IntColumn get wholesalePrice => integer().nullable()();
  RealColumn get vatPercent => real().withDefault(const Constant(0))();
  BoolColumn get trackStock => boolean().withDefault(const Constant(true))();
  BoolColumn get allowNegativeStock => boolean().withDefault(const Constant(false))();
  RealColumn get stockQty => real().withDefault(const Constant(0))();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  IntColumn get warrantyMonths => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get description => text().nullable()();
  TextColumn get supplierId => text().nullable()();
}

/// type: sale | return | receipt | writeoff | adjustment | inventory | transfer
class StockMovements extends Table with SyncColumns {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get type => text()();
  RealColumn get qty => real()(); // signed delta
  RealColumn get qtyAfter => real()();
  IntColumn get unitCost => integer().withDefault(const Constant(0))();
  TextColumn get refType => text().nullable()(); // sale | return | purchase | count | manual
  TextColumn get refId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get reason => text().nullable()();
}

/// CRM.
class Customers extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get cardNumber => text().nullable()(); // loyalty card / barcode
  DateTimeColumn get birthday => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  IntColumn get bonusBalance => integer().withDefault(const Constant(0))(); // minor units
  /// Positive = customer owes the store.
  IntColumn get debtBalance => integer().withDefault(const Constant(0))();
  IntColumn get debtLimit => integer().withDefault(const Constant(0))(); // 0 = no credit
  IntColumn get totalSpent => integer().withDefault(const Constant(0))();
  IntColumn get visits => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastVisitAt => dateTime().nullable()();
  TextColumn get tags => text().nullable()(); // comma separated
}

/// Ledger of customer debt and bonus changes.
/// kind: debt_sale | debt_payment | debt_adjust | bonus_earn | bonus_spend | bonus_adjust
@DataClassName('LedgerEntry')
class CustomerLedger extends Table with SyncColumns {
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get kind => text()();
  IntColumn get amount => integer()(); // signed
  IntColumn get balanceAfter => integer()();
  TextColumn get refType => text().nullable()();
  TextColumn get refId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get shiftId => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
}

class Suppliers extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get phone => text().nullable()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get taxId => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get note => text().nullable()();
  /// Positive = store owes the supplier.
  IntColumn get balance => integer().withDefault(const Constant(0))();
}

/// status: draft | ordered | received | cancelled
class PurchaseOrders extends Table with SyncColumns {
  IntColumn get number => integer()();
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  IntColumn get paid => integer().withDefault(const Constant(0))();
  DateTimeColumn get expectedAt => dateTime().nullable()();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get note => text().nullable()();
}

class PurchaseOrderItems extends Table with SyncColumns {
  TextColumn get orderId => text().references(PurchaseOrders, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get qty => real()();
  RealColumn get receivedQty => real().withDefault(const Constant(0))();
  IntColumn get unitCost => integer()();
}

/// Supplier payments (decrease balance).
class SupplierPayments extends Table with SyncColumns {
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get orderId => text().nullable()();
  IntColumn get amount => integer()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  TextColumn get shiftId => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get note => text().nullable()();
}

/// Cash register shift. status: open | closed
class Shifts extends Table with SyncColumns {
  IntColumn get number => integer()();
  TextColumn get registerId => text().nullable()();
  TextColumn get openedBy => text().references(Users, #id)();
  TextColumn get closedBy => text().nullable()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get openingCash => integer().withDefault(const Constant(0))();
  IntColumn get expectedCash => integer().nullable()();
  IntColumn get countedCash => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  TextColumn get note => text().nullable()();
}

/// Cash in/out not tied to a sale. kind: pay_in | pay_out | expense | collection
class CashMovements extends Table with SyncColumns {
  TextColumn get shiftId => text().references(Shifts, #id)();
  TextColumn get kind => text()();
  IntColumn get amount => integer()(); // positive; sign derived from kind
  TextColumn get reason => text().nullable()();
  TextColumn get expenseCategory => text().nullable()();
  TextColumn get userId => text().nullable()();
}

/// status: completed | voided | partially_returned | returned | held (parked)
class Sales extends Table with SyncColumns {
  IntColumn get number => integer()();
  TextColumn get shiftId => text().nullable()();
  TextColumn get registerId => text().nullable()();
  TextColumn get cashierId => text().nullable()();
  TextColumn get sellerId => text().nullable()(); // consultant credited for motivation
  TextColumn get customerId => text().nullable()();
  TextColumn get status => text()();
  IntColumn get subtotal => integer()(); // before discounts
  IntColumn get discountTotal => integer().withDefault(const Constant(0))();
  IntColumn get total => integer()(); // to pay
  IntColumn get costTotal => integer().withDefault(const Constant(0))();
  IntColumn get vatTotal => integer().withDefault(const Constant(0))();
  IntColumn get paidTotal => integer().withDefault(const Constant(0))();
  IntColumn get changeDue => integer().withDefault(const Constant(0))();
  IntColumn get bonusEarned => integer().withDefault(const Constant(0))();
  IntColumn get refundedTotal => integer().withDefault(const Constant(0))();
  TextColumn get promoCode => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get voidReason => text().nullable()();
}

class SaleItems extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get productName => text()(); // snapshot
  RealColumn get qty => real()();
  RealColumn get returnedQty => real().withDefault(const Constant(0))();
  IntColumn get unitPrice => integer()();
  IntColumn get unitCost => integer().withDefault(const Constant(0))();
  IntColumn get discount => integer().withDefault(const Constant(0))(); // line discount total
  IntColumn get total => integer()(); // qty*price - discount
  RealColumn get vatPercent => real().withDefault(const Constant(0))();
  DateTimeColumn get warrantyUntil => dateTime().nullable()();
}

/// method: cash | card | transfer | bonus | debt | gift_card
class SalePayments extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get method => text()();
  IntColumn get amount => integer()();
  TextColumn get reference => text().nullable()(); // gift card code / txn id
}

class Returns extends Table with SyncColumns {
  IntColumn get number => integer()();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get shiftId => text().nullable()();
  TextColumn get userId => text().nullable()();
  IntColumn get total => integer()();
  TextColumn get refundMethod => text()(); // cash | card | debt | bonus ...
  TextColumn get reason => text().nullable()();
  BoolColumn get restock => boolean().withDefault(const Constant(true))();
}

class ReturnItems extends Table with SyncColumns {
  TextColumn get returnId => text().references(Returns, #id)();
  TextColumn get saleItemId => text().references(SaleItems, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get qty => real()();
  IntColumn get amount => integer()();
}

/// status: active | used | expired | blocked
class GiftCards extends Table with SyncColumns {
  TextColumn get code => text()();
  IntColumn get initialAmount => integer()();
  IntColumn get balance => integer()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get soldSaleId => text().nullable()();
  TextColumn get customerId => text().nullable()();
}

/// Marketing promotions.
/// type: percent_order | amount_order | percent_category | percent_product |
///       buy_x_get_y | promo_code
class Promotions extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get value => real()(); // percent or minor-unit amount
  TextColumn get targetId => text().nullable()(); // category/product id
  TextColumn get code => text().nullable()();
  IntColumn get minOrderTotal => integer().withDefault(const Constant(0))();
  IntColumn get buyQty => integer().withDefault(const Constant(0))();
  IntColumn get getQty => integer().withDefault(const Constant(0))();
  DateTimeColumn get startsAt => dateTime().nullable()();
  DateTimeColumn get endsAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

/// Inventory count (stocktake). status: draft | completed | cancelled
class InventoryCounts extends Table with SyncColumns {
  IntColumn get number => integer()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get userId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class InventoryCountItems extends Table with SyncColumns {
  TextColumn get countId => text().references(InventoryCounts, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get expectedQty => real()();
  RealColumn get countedQty => real().nullable()();
  IntColumn get unitCost => integer().withDefault(const Constant(0))();
}

/// Warranty / service claims.
/// status: received | in_repair | replaced | refunded | rejected | returned_to_client
class WarrantyClaims extends Table with SyncColumns {
  IntColumn get number => integer()();
  TextColumn get saleItemId => text().nullable()();
  TextColumn get productId => text().nullable()();
  TextColumn get customerId => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get problem => text()();
  TextColumn get status => text().withDefault(const Constant('received'))();
  TextColumn get resolution => text().nullable()();
  TextColumn get userId => text().nullable()();
}

/// Customer support / tasks / internal notifications.
/// kind: low_stock | debt_due | birthday | shift | system | task
@DataClassName('AppNotification')
class Notifications extends Table with SyncColumns {
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get refType => text().nullable()();
  TextColumn get refId => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

/// Immutable audit trail of sensitive actions.
@DataClassName('AuditEntry')
class AuditLog extends Table {
  IntColumn get seq => integer().autoIncrement()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()();
  TextColumn get action => text()();
  TextColumn get entity => text().nullable()();
  TextColumn get entityId => text().nullable()();
  TextColumn get details => text().nullable()();
}

/// Sync outbox for future multi-terminal / cloud sync.
class SyncOutbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()(); // upsert | delete
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

/// Monotonic document counters (receipt numbers etc.).
class Counters extends Table {
  TextColumn get name => text()();
  IntColumn get value => integer()();
  @override
  Set<Column<Object>> get primaryKey => {name};
}
