# Spec: Gift card sale as a receipt document (roadmap item)

Status: in implementation (2026-11-24). Decision record: D-023 in DECISIONS.md.

## Problem
`MarketingRepo.issueGiftCard` creates a card; a cash payment becomes a shift `pay_in`
movement and card/transfer payments are recorded nowhere. So the Z-report has no card or
transfer gift card money, there is no receipt for the buyer, and a sold card cannot be
cancelled correctly.

## Accounting principle (D-023)
Selling a gift card is an **advance received (liability), not revenue**. Revenue comes when the
card is redeemed in a normal sale (payment method `gift_card`, as today). So gift card sales:
- are **not** rows in `sales`. Every revenue, profit, ABC, staff-motivation and dashboard figure
  stays as it is, and nothing is counted twice;
- appear in the shift / Z-report as their own section «Сертификаты» and in expected cash;
- appear in the payments report as a separate line «Продажа сертификатов (аванс)».

## Schema (schemaVersion 3 → 4)
```dart
/// status: completed | voided
class GiftCardSales extends Table with SyncColumns {
  IntColumn get number => integer()();                 // db.nextNumber('gift_sale')
  TextColumn get giftCardId => text().references(GiftCards, #id)();
  IntColumn get amount => integer()();                 // nominal = sum of payments
  TextColumn get shiftId => text().nullable()();
  TextColumn get registerId => text().nullable()();
  TextColumn get cashierId => text().nullable()();
  TextColumn get customerId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  IntColumn get changeDue => integer().withDefault(const Constant(0))();
  DateTimeColumn get voidedAt => dateTime().nullable()();
  TextColumn get voidedBy => text().nullable()();
  TextColumn get voidShiftId => text().nullable()();
  TextColumn get voidReason => text().nullable()();
  TextColumn get note => text().nullable()();
}
/// method: cash | card | transfer   (amount > 0; cash amount is net of change)
class GiftCardSalePayments extends Table with SyncColumns {
  TextColumn get saleId => text().references(GiftCardSales, #id)();
  TextColumn get method => text()();
  IntColumn get amount => integer()();
  TextColumn get reference => text().nullable()();     // card slip / transfer id
}
```
`GiftCards.soldSaleId` (already exists) gets the `gift_card_sales.id`.
Migration `from < 4`: inside a transaction, create both tables (guard against an already
existing table like the v3 migration does), add index `gift_card_sales(shift_id)` and
`gift_card_sales(created_at)` to `_indexes`. No backfill: older cards keep `soldSaleId = null`.

## Domain: `GiftCardService` (lib/domain/services/gift_card_service.dart)
```dart
class GiftSalePaymentInput { String method; int amount; String? reference; }
class GiftCardSaleRequest { String code; int amount; List<GiftSalePaymentInput> payments;
  String cashierId; String? shiftId; String? registerId; String? customerId;
  DateTime? expiresAt; String? note; int cashTendered (optional, for change) }
Future<GiftSaleResult> sell(GiftCardSaleRequest r)   // {saleId, number, giftCard, changeDue}
Future<void> voidSale(String giftSaleId, {required String reason, required String userId, required String shiftId})
```
`sell` (one transaction):
- Code validation stays as today: normalised, 6–32 characters, A-Z0-9, unique. Nominal > 0, expiry not in
  the past.
- An open shift is required **always**, because this is a till operation. Message: «Откройте смену, чтобы продать сертификат».
- Payment methods: only cash, card and transfer. Bonus, debt and gift_card are refused. The payments must add up exactly to the nominal.
  Cash tendered may exceed the cash part; the difference is change (`changeDue`).
- Writes the card (`soldSaleId`, customerId, expiresAt), the sale header (`gift_sale` counter), and
  the payments. markDirty on all of them. Audit `gift_card.sell`.
- No shift `cash_movements` row. Cash is accounted for through the shift report (below).

`voidSale` (one transaction): the sale must be `completed`; reason required; the card is untouched
(`balance == initialAmount`, not used in any sale payment); `shiftId` must be an open shift. Marks the sale
`voided` (voidedAt/By/ShiftId/Reason). The card becomes `status 'blocked'` with balance 0 and is soft-kept
(not deleted). Refunds go back by the original methods, in the void shift. Audit `gift_card.void_sale`.
Message when the card was used: «Сертификат уже использован — аннулирование невозможно».

`MarketingRepo.issueGiftCard` keeps its signature and delegates to `GiftCardService.sell` with a
single payment (method, amount). It now requires `shiftId` for every method (update its tests:
card/transfer without a shift must now fail). Add `giftCardServiceProvider` to providers.dart.

## Shift report (ShiftService.report + ShiftReport)
New fields: `giftSalesCount`, `giftSalesByMethod` (completed sales whose shiftId == shift),
`giftRefundsByMethod` (voided sales whose voidShiftId == shift). `expectedCash` adds
`giftSalesByMethod['cash'] − giftRefundsByMethod['cash']`. `salesTotal`, `netRevenue`, `grossProfit`
are unchanged. Update D-010 wording in DECISIONS.md.

## Printing
`lib/core/printing/gift_receipt.dart`: text slip + PDF like `receipt.dart`, using the store
header from settings and `printReceipt`-style printing. Contents: «Продажа сертификата №N», date,
cashier, code (large, monospaced, grouped by 4), nominal, expiry «до …» or «без срока», payments,
change, and the footer «Сертификат не является фискальным чеком на товар» (only when receipt footer
settings allow; keep it simple). A voided sale prints an «АННУЛИРОВАН» marker.

## UI
POS (`lib/features/pos`):
- Action «Продать сертификат» in the POS actions/menu (Perm.sell, needs an open shift). Dialog:
  nominal (quick nominals from setting or 50k/100k/200k/500k in major units), code (generate /
  scan / type), optional customer, optional expiry, then split payment cash/card/transfer with
  cash tendered and change. On success: a dialog with the number, code, «Печать», «Готово».

Marketing (`lib/features/marketing/gift_cards_tab.dart`):
- «Выпустить» uses the same dialog/flow (it can be a shared widget in marketing that POS imports,
  or the reverse — pick one owner and keep it in one place).
- Card detail shows the sale document (№, date, cashier, payments, status) with «Печать» and
  «Аннулировать продажу». Aннулирование needs Perm.voidSale, a mandatory reason, an open shift and
  confirmation. Unused cards only; otherwise the button is disabled and its tooltip says why.
- A list «Продажи сертификатов» (segment or sub-tab) with period and status filters.

Shifts (`lib/features/shifts`): the X/Z screen and Z PDF get a section «Сертификаты»: sold N, by
method, voided, and the cash effect; expected cash includes it.

Reports (`lib/features/reports`): payments report gets a separate block «Продажа сертификатов
(аванс, не выручка)» by method for the period, minus voided ones. Revenue totals are unchanged.

Everywhere: loading, error and empty states, Russian texts, 390/1024/1440 without overflow,
double-tap protection, permission gating, ux_screens_test coverage.

## Tests (must add)
`test/domain/gift_card_service_test.dart`:
- sell with split payments and change;
- sell is refused without a shift, with a wrong sum, with a bad method, or with a duplicate code;
- the card and the document are linked;
- the shift report shows gift sales and expectedCash includes cash;
- salesTotal and revenue are unchanged;
- redeeming the card in a normal sale still counts as revenue only once;
- void restores and refunds in the void shift; void is refused for a used card, twice, or without a reason or shift;
- migration v3 → v4 on a file database.
