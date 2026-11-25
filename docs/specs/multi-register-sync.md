# Spec: Multi-register sync (roadmap item 1, D-003 → D-025)

Status: **implemented** (2026-11-25, schema v6; third review 2026-11-26, schema v7). Owner approved the stage; a real Supabase
project is **not** connected by us. The owner supplies the project URL, anon key and account.
Everything is tested against an in-memory fake server and a mocked HTTP layer; the SQL was
reviewed by hand but not executed (no Postgres on the build machine). Where the
implementation deliberately differs from the design below, see «Implementation notes» at the
end.

## Goals
1. Several registers (Windows PCs / Android) of one store work offline and converge to the same
   data when they sync through a Supabase (Postgres) project.
2. A new register joins an existing store and downloads everything.
3. Accounting stays correct: ledgers never lose rows, cached balances equal their ledgers,
   document numbers never clash across registers.
4. Test and production data are strictly separated (owner constraint).
5. Nothing irreversible: disconnecting never deletes local data; the server never deletes rows
   (soft delete only, as locally).

## Current state (verified 2026-11-25)
- All synced tables use `SyncColumns` (UUID `id`, createdAt, updatedAt, deletedAt).
- `sync_outbox(seq, entity, entityId, op, at, syncedAt)` exists, but `db.markDirty` is called
  only ~80 times. Sale items, payments, stock movements, shifts, cash movements and others are
  **not** marked. So the outbox cannot be trusted as the change source.
- `Counters` are local; `ux_sales_number` is UNIQUE on `sales(number)`.
- Cached aggregates: `products.stockQty` (+ `costPrice` avg), `customers.debtBalance`,
  `customers.bonusBalance`, `suppliers.balance`, `gift_cards.balance/status`,
  `purchase_orders.paid`, `purchase_order_items.receivedQty`, `sales.paidTotal`/status after
  returns, etc.
- Tables without UUIDs: `settings` (key/value), `audit_log` (int autoincrement), `sync_outbox`,
  `counters`.

## Design
### 1. Change capture: SQLite triggers (replaces reliance on markDirty)
- Schema v5 creates, for **every synced table**, `AFTER INSERT`, `AFTER UPDATE` and
  `AFTER DELETE` triggers that insert `(entity, entity_id, op, at)` into `sync_outbox`, unless
  `sync_flags.applying = 1`. `at` is wall-clock milliseconds
  (`CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER)`).
- `sync_flags` is a one-row normal table, because SQLite triggers cannot reference TEMP
  objects. The apply engine sets `applying=1` and back to 0 inside the same transaction.
- Triggers are created in `onCreate` and in the v5 upgrade, from one generated list (a single
  source of truth: `syncedTables` in `lib/core/sync/sync_tables.dart`), with `DROP TRIGGER IF
  EXISTS` first so it is idempotent. A test asserts that every `SyncColumns` table in
  `allTables` is either in `syncedTables` or in an explicit `localOnlyTables` list.
- `db.markDirty` stays as API, but becomes a no-op (the triggers already did it). Keep the
  signature so modules do not change.
- `settings` sync: a trigger on settings too, with `entity_id = key`, **except** device-local
  keys. The set of local keys is in `sync_tables.dart` (`localSettingKeys`): `register_id`,
  `device_code`, every `sync_*` key, `ui_*`, printer/hardware keys, and backup paths. Agents
  enumerate the real keys from `lib/features/settings` and the setup wizard. The trigger uses
  `WHEN NEW.key NOT IN (...) AND NEW.key NOT LIKE 'sync\_%' ESCAPE '\'`.
- Local-only tables (no triggers): `sync_outbox`, `sync_flags`, `sync_state`, `counters`,
  `notifications` (generated per device), `audit_log`. Audit sync is a known limitation for
  this stage.

### 2. Wire format
A change = `{changeId (uuid), entity, entityId, op: upsert|delete, version (int HLC),
deviceId, payload}`. `payload` is the **raw SQL row** (`SELECT * FROM <table> WHERE id = ?`
as a column→value map, the drift storage format: DateTime as int seconds, bool as 0/1). It is
read at push time, so the latest state is sent and repeated edits collapse. A row that no longer
exists is sent as `op: delete`.

### 3. Versions and conflict resolution (row-level LWW with a hybrid logical clock)
- `sync_state` (key/value, local) holds `device_id` (uuid, generated once), `hlc` (last issued
  version), `pull_cursor` (last server seq), `store_id`, `last_push_at`, `last_pull_at`,
  `last_error`.
- `sync_row_versions(entity, entity_id, version, device_id)` (local) stores the version that
  produced the current local row.
- Push: for each distinct (entity, entityId) in the unsynced outbox (ordered by seq), version =
  `max(outbox.at, hlc + 1)`, then `hlc = version`. Write `sync_row_versions`.
- Apply remote change: if `remote.version < local.version`, or equal with
  `remote.deviceId <= local.deviceId`, skip it (local wins; it will be pushed or already was).
  Otherwise apply it. In both cases set `hlc = max(hlc, remote.version)`.
- A local row with an **unpushed** outbox entry whose `at` is greater than the remote version
  also wins.
- Append-only tables (ledgers, movements, sale items, payments, return items, gift sale
  payments, cash movements, receipt items, audit-like rows) never conflict. The first insert
  wins and later identical upserts are no-ops.

### 4. Cached aggregates are derived, never synced
- Ledgers and documents are the truth. In a remote apply, **cached columns are never taken from
  the payload** for an existing local row. For a new row they are inserted as given, then
  recomputed.
- After every applied batch, `SyncAggregates.recompute(db, touched)` recomputes the caches of
  the touched entities from their ledgers, in the same transaction, with triggers suppressed.
  The cached columns of the local device then match the derived values on all devices.
- The cache → ledger map is in `lib/core/sync/aggregates.dart`. The core agent must check every
  formula against the domain services, because the exact sign and kind conventions are in
  `StockService`, the customer ledger and bonus code, `SupplierLedgerService`, `GiftCardService`,
  `SaleService`/returns and purchasing. At minimum:
  - `products.stockQty = Σ stock_movements.qty` (not deleted);
  - `customers.debtBalance` and `bonusBalance` from `customer_ledger`, by kind;
  - `suppliers.balance = Σ supplier_ledger.amount`;
  - `gift_cards.balance` from initialAmount and redemptions/refunds/voids, as GiftCardService
    defines it;
  - `purchase_orders.paid` from non-cancelled supplier payments with that orderId;
  - `purchase_order_items.receivedQty` from posted receipt items (minus reversals).
  Where a cache cannot be derived exactly, document it and keep LWW for it (for example
  `products.costPrice`: LWW from the row; concurrent receipts on two registers give a slightly
  different average — known limitation).
- **v5 migration normalises ledgers so that cache == derived value holds on every existing
  database.** Where they differ, it inserts an `opening`/adjustment ledger row with the
  difference (same idea as D-022), reason «Начальный остаток (синхронизация)». The ledger `balanceAfter`
  running-balance invariant (D-021) is relaxed to **cache == Σ amounts**. `balanceAfter` stays as
  the originating device's view. Update tests that assert the old invariant, and D-021.
- `tool`/debug: `SyncAggregates.verifyAll(db)` returns the mismatches. It is used in tests and
  on the «Синхронизация» screen («Проверка целостности»).

### 5. Unique constraints and document numbers
- Each register has a **device code** (`A`, `B`, … `Z`, then `AA`…), assigned by the server
  at register join and stored in local setting `device_code`.
- Every numbered document table gets a nullable `device_code TEXT` column (v5): sales, returns,
  shifts, goods_receipts, gift_card_sales, purchase_orders, inventory_counts, warranty_claims,
  and every other table with `number` (check). New documents copy the current `device_code`
  (null when sync is off, which keeps single-register behaviour and every existing ru test
  unchanged).
- `ux_sales_number` becomes `UNIQUE(ifnull(device_code,''), number)` (and the same for the other
  number indexes, if any).
- Display: one helper `docNo(int number, String? code)` in `lib/core/doc_number.dart` returns
  `N` or `CODE-N`, used everywhere a document number is shown or printed («Чек №A-15»). Search
  by number accepts `15` and `A-15`.
- Other unique keys with offline collisions (`products.barcode`, `customers.card_number`,
  `gift_cards.code`): on apply, if the incoming row breaks a unique index, the row with the
  **lower** version loses the value (barcode/card set to null; gift code: impossible in practice,
  but then mark the loser `blocked`). Create a local notification «Конфликт синхронизации: …».
  Record the event in `sync_conflicts` (local log table shown on the sync screen).

### 6. Business conflicts we accept (documented, surfaced, not prevented)
Offline registers can oversell stock, spend one gift card twice, or pass a debt limit. After
apply, if a recomputed cache is negative (stock where negative stock is not allowed, gift card
balance, bonus), create a notification and a `sync_conflicts` row. Never block or roll back
another register's sale.

### 7. Server (Supabase): `supabase/migrations/0001_dreampos_sync.sql`
- `stores(id uuid pk, name, environment text check in ('test','production'), created_by uuid,
  created_at)`.
- `store_members(store_id, user_id → auth.users, role text, pk(store_id,user_id))`.
- `devices(id uuid pk, store_id, code text, name, register_id text, created_at, last_seen_at,
  unique(store_id, code))`.
- `changes(seq bigserial pk, store_id, change_id uuid unique, device_id, entity text,
  entity_id text, op text, version bigint, payload jsonb, received_at timestamptz default now())`,
  index `(store_id, seq)`.
- RLS on all tables: a user sees and writes only rows of stores where they are a member.
- RPCs (security definer, check membership):
  - `create_store(name, environment)` → store id; the caller becomes owner.
  - `register_device(store_id, device_id, name)` → code (next free letter code). Idempotent per
    device_id.
  - `push_changes(store_id, device_id, changes jsonb)` → `{accepted, max_seq}`. Idempotent:
    `on conflict (change_id) do nothing`.
  - `pull_changes(store_id, since bigint, max int)` → rows ordered by seq.
  - `store_info(store_id)` → name, environment, `has_data` (exists changes).
- Nothing in the SQL deletes rows. Retention/compaction is a later stage.
- `docs/SYNC_SETUP.md` (ru): how the owner creates a Supabase project, applies the SQL (SQL
  editor), enables email auth, creates a **separate test project** (or test store with
  `environment='test'`) and connects a register.

### 8. Client transport
- `abstract class SyncTransport { signIn; createStore; registerDevice; storeInfo; push; pull; }`
  in `lib/core/sync/transport.dart`.
- `SupabaseTransport` uses the `http` package (add `http` to pubspec) against GoTrue
  (`/auth/v1/token?grant_type=password|refresh_token`) and PostgREST RPC (`/rest/v1/rpc/<fn>`)
  with `apikey` + `Authorization: Bearer`. Refresh the access token on 401 once. Timeouts 20 s.
  The password is **never stored**, only the refresh token (local `sync_state`). Do not log
  tokens. HTTPS only (reject `http://` URLs except `localhost`/`127.0.0.1` for local dev).
- `FakeSyncServer implements SyncTransport` (in `test/support/` **and** usable from
  `lib/core/sync/fake_server.dart` only if needed by the UX harness; prefer test-only) — in-memory,
  same semantics as the SQL (seq, idempotent change_id, codes A/B/C).
- Errors are `SyncException` with localized messages (l10n `sync*` keys).

### 9. Engine: `SyncService` (`lib/core/sync/sync_service.dart`)
- `syncNow()`: push (batches of 200 entities; one HTTP call per batch; mark outbox rows
  `syncedAt` only after the server confirms), then pull (batches of 500 until empty; apply each
  batch in **one transaction**; advance `pull_cursor` in the same transaction). Changes with
  `deviceId == own` are skipped but still advance the cursor.
- Apply order inside a batch: the batch order is the server order, so a parent row always
  arrives before the child created after it. Run the batch with
  `PRAGMA foreign_keys` behaviour checked: if FKs are enforced, apply with
  `defer_foreign_keys = ON` inside the transaction.
- Re-entrancy: one sync at a time (a mutex). Periodic every 30 s while connected and the app is
  in the foreground, plus right after a sale/return is completed (debounced 3 s). Backoff on
  errors: 30 s → 5 min.
- Outbox cleanup: delete rows with `syncedAt` older than 7 days (local bookkeeping only — not
  user data).
- Provider `syncStatusProvider`: state (off / idle / syncing / error / offline), pending count,
  last sync time, last error.

### 10. Join, first upload, separation of test and production
- **Connect** (Settings → «Синхронизация», Perm.manageSettings, owner/admin only): URL, anon
  key, email, password → sign in → either:
  - «Создать магазин в облаке» (name, environment test/production): only if this database is
    the **first** device. It uploads everything: enqueue every row of every synced table and every
    synced setting into the outbox, then push.
  - «Подключить к существующему» (choose a store): allowed only if the local database has **no
    business data** (no sales, products, customers…). Otherwise show the reason and stop: two
    databases are never merged. A fresh install can choose «Подключиться к магазину» in the setup
    wizard (first step) instead of creating a store locally. It then signs in, registers the
    device, pulls everything and lands on the login screen (users come from the cloud).
- **Test / production**: a database with `demo_mode=1` may connect only to a store with
  `environment='test'`; a `production` store refuses it (message). A `test` store shows a
  persistent «Тестовый магазин» badge next to the demo badge. The environment cannot be changed
  from the client.
- **Disconnect**: stops sync and clears tokens and the cursor; keeps all local data and
  `device_code` (numbers stay unique). Confirm dialog.
- Users / PINs sync like other rows (hashes only). Login works offline on every register.

### 11. UI
- Settings → new section «Синхронизация» (`lib/features/settings/sections/sync_section.dart`):
  status card (state, pending, last sync, store name, environment badge, device code), «Синхронизировать
  сейчас», connect wizard, disconnect, «Проверка целостности» (runs verifyAll, shows mismatches),
  conflicts list (`sync_conflicts`). Loading/error/empty states.
- Shell top bar: a small cloud icon with state/pending tooltip, only when sync is configured.
- Setup wizard: first step gets «Подключиться к существующему магазину».
- All strings via l10n in ru/uz/ky/en (`lib/l10n/src/sync/*.arb` with prefix `sync`, plus settings
  keys). `tool/l10n_check.dart` must stay clean. 390/1024/1440 without overflow in all 4 languages.

## Tests (must add)
- Trigger coverage: every synced table write lands in the outbox; apply does not echo.
- Two and three `AppDatabase` instances + `FakeSyncServer`: create on A, sync, appears on B;
  edits on both offline → LWW converges (same rows on all devices: compare full table dumps
  excluding local tables); sales on A and B → both sales present, stock = initial − both,
  numbers `A-1` and `B-1`; supplier payments on two devices → balance == Σ ledger on both;
  gift card spent twice offline → negative balance + conflict row + notification; barcode
  collision → loser loses barcode + conflict row; delete propagation (soft and hard);
  idempotent re-push (network failure after server accepted); pull cursor persistence; resume
  after a crash mid-batch (transaction rollback).
- Randomized convergence test (seeded): N random operations through the real domain services on
  3 devices with random sync points; at the end all devices are identical and
  `verifyAll` is empty on each.
- v4 → v5 migration on a file database: triggers exist, normalisation rows created, caches
  equal derived values, existing numbers unchanged.
- `SupabaseTransport` with `http/testing.dart` MockClient: sign-in, refresh on 401, RPC payloads,
  error mapping, https-only.
- Demo DB refused by a production store; join refused for a non-empty DB.
- UX screenshots of the sync section (connected, error, conflicts) and the join step.

## Implementation notes (deliberate differences, after review)
- **Schema v6** adds `sale_payments.gift_card_id`, `purchase_orders.lines_rev`,
  `purchase_order_items.lines_rev` and re-creates the triggers (below).
- **User part / stat part (§3, §4).** A row of a table in `statColumns`
  (`lib/core/sync/sync_tables.dart`: stock, cost price, debt/bonus balances, customer
  statistics, supplier balance, gift balance, PO paid/received, returned quantities) has two
  parts with their own LWW versions (`sync_row_versions` entity `<table>` and `<table>#s`). The
  UPDATE trigger writes op `upsert` when a person-edited column changed and op `stat` when a
  bookkeeping column changed (or only `updated_at`); status changes inside `statStatuses`
  (e.g. `completed ↔ partially_returned`, `active ↔ used`) count as bookkeeping. The push
  marks the payload with `@parts` (`u`, `s`, absent = both). So a sale on a register that has
  not pulled the owner's price / debt-limit / block edit no longer re-sends the stale row.
  `updated_at` is merged as the maximum. Append-only tables also go through LWW (same effect as
  «first insert wins», their only later writes are caches).
- **Void is sticky:** `sales.status = 'voided'` and `gift_card_sales.status = 'voided'` (with
  their void columns) win over any version.
- **Own changes** are not skipped blindly: they go through the same LWW (normally the local row
  already has that version). An own change newer than the local row means the file was
  restored from a backup or copied: it is applied, and the database gets a **new device id and
  code** (`sync_conflicts` kind `identity`).
- **Document numbers (§5):** `db.nextNumber` returns at least `MAX(number)+1` of the documents
  with this register's code (no effect while sync is off), so a store created again after a
  disconnect, a later joiner or a restored backup never reuses a number. Two documents with the
  same `(device_code, number)` on apply (only possible after a restore/copy) do not fail the
  page: the newer one gets the code `<code>~XXXX` (kind `unique_number`).
- **Unique keys with a pending local edit:** the local row counts as newer only when the edit
  would also win LWW (`at > remote version`), so all devices pick the same loser.
- **Gift card codes:** redemptions keep the card id (`sale_payments.gift_card_id`); the
  balance is derived by id (by code only for pre-v6 rows), so renaming a losing duplicate code
  does not move money between cards.
- **§6, more accepted conflicts surfaced:** `void_return` (a sale voided on one register and
  returned on another) and `over_return` (returned more than sold on several registers), plus
  `unique_number` and `identity`.
- **§9 order:** the push puts a pending parent row before a child that references it (the
  current row is sent, so it may point at a parent created later). On apply, a change whose
  parent has not arrived is **parked** (`sync_state.parked`) and retried with later pages
  instead of failing the page forever.
- Text with U+0000 is stripped before push (Postgres `jsonb` refuses it) and locally.
- **Draft purchase orders** are saved as a whole line set under a new `lines_rev`; after a
  pull only the lines of the header revision that won LWW are kept.
- **§7 server:** `devices` has PK `(store_id, id)`; extra RPC `list_stores`; `push_changes`
  requires a registered device. `store_members.role` is informational: every cloud account of a
  store has full access to its data (documented in `docs/SYNC_SETUP.md`).
- **§10:** «Подключить к существующему» is also allowed with data for the store this database
  was disconnected from (only that store is offered). A database that was on a `test` store may
  not create a `production` store (`SyncErrorKind.testData`). An interrupted «Создать магазин»
  reuses the empty store it created. An interrupted join resumes in the setup wizard
  («Повторить загрузку»); a connected database never gets the local store wizard. An open
  shift is stamped with the new code when a store is created.
- **Shifts:** with sync on, the current shift (POS, returns, closing, dashboard) is the open
  shift with this register's code; without sync, unchanged.
- **Second review (no schema change):**
  - **§9 order is pull, then push.** A restored / copied file learns that its device id was
    taken over before it pushes anything under that id, so only the copy moves to a new id and
    code; the working register keeps its letter (when the copy has not seen any newer change of
    the original, whichever pushes first keeps the identity). The new id/code is owed in
    `sync_state.reidentify_pending`, written in the same transaction as the change that revealed
    it, and done at the start of the next sync if `register_device` failed.
  - **Shifts after a code change:** a database that got a new code (restore/copy) keeps its open
    shifts with the old code as its current shift (device-local setting `sync_own_shifts`); the
    rows keep their code (for a copy the original register still uses that shift). «Создать
    магазин» re-codes this register's own open shift to the new code and renames other
    registers' open shifts that carry that code to `<code>~XXXX`, so they never become current.
  - **Gift card refund on a sale void** follows the derived rule: a card whose gift sale is
    voided stays `blocked` with balance 0; a blocked/expired card keeps its status.
  - **Draft purchase orders:** a remote change never moves an order back to `draft` once it left
    it on any register (`initialStatus`), and a remote delete of an order line that a receipt
    references keeps the line soft-deleted (`goods_receipt_items.order_item_id` counts as a
    reference), so a received draft cannot be received a second time.
  - **More conflicts surfaced (§6):** `double_void` (one gift card sale voided on two registers:
    both refunded, one void kept) and `void_redeem` (a card spent while its sale was voided
    elsewhere).
  - **`updated_at`:** when a remote change supersedes an unpushed local edit that left a later
    `updated_at`, the row is sent once more, so every register keeps the same maximum.
  - **Outbox / performance:** the outbox of a database that was never connected is pruned on
    open (create/join enqueue every row anyway); indexes `ix_sync_outbox_entity`,
    `ix_sale_payments_gift_card` / `ix_sale_payments_gift_ref`; the gift card cache check uses two
    indexed lookups. The v5 upgrade step adds the v6 columns first (it already reads them).
- **Conflict text is language-neutral:** `sync_conflicts.details` stores JSON
  `{"m": <kind>, "a": {...}}` with raw data (amounts in minor units, quantity + unit code,
  document number + register code, names/codes); `lib/core/sync/conflict_text.dart`
  (`ConflictText.title/body`) formats it with the current UI language, so the conflicts list
  follows a language switch. Older rows with finished text and the technical `normalize` rows are
  shown as stored. The local notification created with a conflict keeps the text of the UI
  language of that moment, like every notification.
- **Third review (schema v7):**
  - **Users (§10):** `users.last_login_at`, `failed_pin_attempts`, `locked_until` are a stat
    part (`statColumns`; v7 re-creates the triggers). A PIN login on one register no longer
    re-sends its stale PIN / role / `is_active` over the owner's deactivation or PIN change
    made on another one.
  - **PIN collisions:** salted hashes cannot be compared, so the sync cannot find two users
    with one PIN. (1) A first join (not a reconnect) remembers the database's active users
    (`sync_state.join_local_users`); after the first complete pull, before anything is pushed,
    they are deactivated (open work sessions ended) when the store has an active owner/admin
    of its own; conflict kind `join_users`. (2) `AuthService.loginWithPin` refuses a PIN that
    matches more than one active user (`errPinAmbiguous`, audit `auth.pin_conflict`) instead
    of logging in whichever comes first in that database. Known limitation: if the only
    owner's PIN collides, only another owner/admin can fix it.
  - **One-time effects finalised on two registers offline** (a goods receipt reversed, an
    inventory count completed, a supplier payment cancelled) are written with deterministic
    ids (`effectId`, UUID v5 of the source line / document): both registers write the same
    stock movement / ledger row ids, so after syncing the effect exists once (append-only
    LWW). The document header converges by LWW as before.
  - **Cash supplier payments** can only be cancelled on the register whose open shift holds
    them (device code / `sync_own_shifts`, as for the current shift; no change without sync).
  - **Opening cash suggestion** only looks at this register's closed shifts when sync is on.
  - **Order lines received before v3** (no receipt documents): the v5 normalisation adds one
    posted receipt per order («Начальный остаток (синхронизация)», total 0, no stock or supplier
    rows; `ReceiptService.reverse` refuses it) instead of only logging a `normalize` conflict,
    so every register derives the same `received_qty` and the goods cannot be received twice.
  - **Performance:** indexes `ix_return_items_sale_item` and
    `ix_goods_receipt_items_order_item` (created with the v6 columns before the v5
    normalisation, and on open for existing files): `verifyAll` / the v5 upgrade are no longer
    quadratic in sale lines × return lines.
  - **Refresh token:** the rotated refresh token is stored after every engine call, also a
    failed one (`SyncService._exclusive`, `listStores`), so a sync that refreshed the access
    token and then failed does not leave a revoked token for the next app start.
- **Known limitations:** a parked change whose parent never arrives (hard-deleted elsewhere)
  stays parked; customer statistics (`total_spent`, `visits`) and the average cost are LWW
  (concurrent increments can lose one); audit log and notifications stay per device.
