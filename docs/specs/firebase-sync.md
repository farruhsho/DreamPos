# Spec: Firebase backend of the multi-register sync (D-026)

Status: **implemented** 2026-11-26. Replaces the server side of D-025 (Supabase). The sync
engine (`docs/specs/multi-register-sync.md`: triggers, LWW, derived caches, device codes) is
unchanged; only the transport, the server, the connect form, the docs and the tests changed.

- Client: `lib/core/sync/firebase_transport.dart` (`FirebaseTransport implements SyncTransport`).
- Server: Cloud Firestore (native mode) + Firebase Authentication (e-mail/password).
- Rules: `firebase/firestore.rules`; indexes: `firebase/firestore.indexes.json`;
  `firebase.json` at the repo root. Deploy:
  `firebase deploy --only firestore --project <project id>`.
- Owner guide (ru): `docs/SYNC_SETUP.md`.
- Owner's TEST project: `dreampos-test-uz26` (Firestore region `nam5`), rules deployed
  2026-11-26. The production project is a separate Firebase project in a European region.

## 1. Why REST and no FlutterFire
The app runs on Windows and Android. FlutterFire's Windows support is incomplete and pulls in
native SDKs; the engine only needs ~6 operations. Three Google REST APIs over `package:http`
give the same code on every platform and are fully testable with `MockClient`:

| What | Endpoint |
|---|---|
| Sign in | `POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=API_KEY` `{email, password, returnSecureToken: true}` → `{idToken, refreshToken, localId, email, expiresIn}` |
| Refresh | `POST https://securetoken.googleapis.com/v1/token?key=API_KEY` form `grant_type=refresh_token&refresh_token=…` → `{id_token, refresh_token, user_id, expires_in}` |
| Data | `https://firestore.googleapis.com/v1/projects/{p}/databases/(default)/documents…` with `Authorization: Bearer <ID token>` |

The Web API key only identifies the project (it is not a secret; access is decided by the
account and the rules). It is typed by the owner, stored locally in `sync_state`
(`fb_project_id`, `fb_api_key`), never synced and never committed to the repo.

## 2. Data model
All integers are Firestore `integerValue` (a **string** on the REST wire); timestamps are set
by the server (`REQUEST_TIME` transform).

| Document | Fields | Written by |
|---|---|---|
| `stores/{storeId}` | `name` (1–200), `environment` (`test`/`production`, immutable), `createdBy` (uid), `createdAt`, `nextSeq` (int, last issued seq), `nextCode` (int, index of the next device code), `hasData` (bool) | `createStore` (create), `registerDevice` (`nextCode`), `push` (`nextSeq`, `hasData`) |
| `stores/{storeId}/members/{uid}` | `role` (`owner`; others informational), `addedAt` | `createStore` (creator); other accounts: owner in the console |
| `users/{uid}/stores/{storeId}` | `name`, `environment` | `createStore`; console for other accounts. Index for `listStores` |
| `stores/{storeId}/devices/{deviceId}` | `code`, `name`, `createdAt`, `lastSeenAt` | `registerDevice` (create), `push` (`lastSeenAt`) |
| `stores/{storeId}/codes/{code}` | `deviceId` | `registerDevice` — makes a code unique per store |
| `stores/{storeId}/changes/{changeId}` | `seq`, `deviceId`, `entity`, `entityId`, `op` (`upsert`/`delete`), `version`, `payload`, `receivedAt` | `push` (create only) |

- `storeId` is a client-generated uuid v4; `deviceId` / `changeId` are the engine's uuids.
  Document ids are checked against `^[A-Za-z0-9_-]{1,128}$`.
- `payload` is the JSON-encoded row as **one string** (`null` for a delete). Firestore never
  types the row's columns (int vs double, 0/1 booleans, big integers stay exact); the server
  never looks inside it. `payload` is exempt from indexing (`firestore.indexes.json`).
- `seq` is per store, gap-free and strictly increasing (§3.4); the engine's pull cursor is the
  last applied `seq` of the store.
- Nothing is ever deleted (rules forbid deletes). Retention/compaction is a later stage.

## 3. Operations (`FirebaseTransport`)
General: endpoint validated before any request (project id `^[a-z][a-z0-9-]{4,28}[a-z0-9]$`,
API key non-empty and `^[A-Za-z0-9_-]{8,200}$`), fixed `https://` Google hosts, 20 s timeout per
request, every failure is a `SyncException`; details carry only HTTP status and stable upper
case codes, never tokens, the password, the key or free text.

### 3.1 Auth
- `signIn`: Identity Toolkit. The session's e-mail comes from the ID token (JWT claim), falls
  back to the response / typed e-mail.
- The API key alone decides which project signs the user in; the project id appears only in
  Firestore paths. Every new ID token's `aud` claim must equal the project id: a key of
  another project (test vs production) → `projectMismatch` before any Firestore call, and the
  session is dropped (otherwise Firestore answers 401 forever, which looks like an expired
  session). A token without `aud` → `protocol`.
- `restoreSession(refreshToken)`: Secure Token. The response's `refresh_token` is kept (it may
  rotate); the engine persists the session's refresh token after every call, also after a
  failed one (`_persistSessionQuietly`).
- The ID token lives 1 h: it is refreshed 60 s before `expiresIn` runs out, and once more on a
  `401 UNAUTHENTICATED` (then the request is retried once; a second 401 → `auth`). Concurrent
  callers share one refresh.
- `signOut` drops the tokens locally (Firebase has no client revoke over REST).
- Error mapping (message code before ` :`):

| Code | `SyncErrorKind` |
|---|---|
| `EMAIL_NOT_FOUND`, `INVALID_PASSWORD`, `INVALID_LOGIN_CREDENTIALS`, `INVALID_EMAIL`, `MISSING_PASSWORD`, `INVALID_REFRESH_TOKEN`, `TOKEN_EXPIRED`, `USER_NOT_FOUND`, `INVALID_GRANT_TYPE`, … | `auth` |
| `USER_DISABLED` | `accountDisabled` |
| `TOO_MANY_ATTEMPTS_TRY_LATER` | `tooManyAttempts` |
| `OPERATION_NOT_ALLOWED`, `PASSWORD_LOGIN_DISABLED`, `CONFIGURATION_NOT_FOUND` | `signInDisabled` («e-mail sign-in not enabled in the Firebase project») |
| `API key not valid…` / reason `API_KEY_*`, `PROJECT_NUMBER_MISMATCH` | `invalidApiKey` |
| ID token `aud` ≠ project id | `projectMismatch` |
| 5xx | `server` (`HTTP <status>`) |
| no connection / timeout | `network` |

### 3.2 Stores
- `createStore(name, env)`: one non-transactional **commit** of three creates with
  `currentDocument.exists = false`: the store (`nextSeq = nextCode = 0`, `hasData = false`,
  `createdAt` = request time), `members/{uid}` (`role: owner`) and `users/{uid}/stores/{id}`.
  The engine chooses the store id and saves it (`pending_store`) **before** the request, so a
  retry after a lost answer sends the same id: on `409 ALREADY_EXISTS` or `403` the transport
  reads `stores/{id}`; a store this account created with the same name and environment is the
  result (no empty twin). Someone else's store → `forbidden` (the engine then drops the id).
  Otherwise a 403 means the rules are missing/outdated → `server` (`PERMISSION_DENIED (create_store)`).
- `listStores`: list `users/{uid}/stores` (paged, 300), then GET each store document (name,
  environment and `hasData` come from the store). A store that answers 403/404 is left out.
- `storeInfo(id)`: GET `stores/{id}`. 404 → `storeNotFound` (the rules allow reading a
  *missing* store document, so «not found» and «not a member» differ); 403 → `forbidden`.

### 3.3 `registerDevice(storeId, deviceId, name)` — transaction
1. `beginTransaction` (read-write) → `batchGet [store, devices/{deviceId}]`.
2. Store missing → `storeNotFound`. Device exists → its `code`, `rollback` (idempotent per
   device id; nothing written).
3. Else `code = deviceCodeForIndex(store.nextCode)` (`A`…`Z`, `AA`…) and `commit`: create
   `devices/{deviceId}` `{code, name, createdAt, lastSeenAt}`, create `codes/{code}`
   `{deviceId}` (`exists = false`: a code is never given twice), update store
   `nextCode + 1`.

### 3.4 `push(storeId, deviceId, changes)` — transaction per chunk
Client-side checks first (same as the old server; nothing is sent if one fails): every
change's `deviceId` equals the pusher's (`device_mismatch`), valid ids, entity 1–100 and
entity id 1–200 characters, `0 ≤ version ≤ maxSyncVersion` (2200-01-01 in ms), payload of
scalars only (no nested objects/arrays), `payload == null` exactly for deletes
(`invalid_changes`, kind `server`). Duplicate change ids in one batch are sent once.

Chunks of at most **398 changes** (400 writes per commit with the store and device updates;
Firestore's limit is 500). For each chunk, up to **5 attempts**:
1. `beginTransaction` → `batchGet [store, devices/{deviceId}, changes/{id}…]`.
2. Store missing → `storeNotFound`; device missing → `server` `device_not_registered`.
3. Change ids already present are skipped (**idempotent**: a re-push after a lost answer
   stores nothing twice). Nothing new → `rollback`, `{accepted: 0, maxSeq: nextSeq}`.
4. `commit`: create each new change with `seq = nextSeq + 1 … nextSeq + k`
   (`exists = false`, `receivedAt` = request time), update the store
   `{nextSeq: nextSeq + k, hasData: true}` (update mask) and the device's `lastSeenAt` (the
  register's clock, informational; a server-time transform alone would need an empty update
  mask, which is avoided).
5. `409 ABORTED` / `ALREADY_EXISTS` (contention with another register) → new transaction after
   a jittered backoff (100·2ⁿ ms ± 50 %); after 5 attempts → `server` (`HTTP 409 ABORTED`).

Because a commit is atomic and serialised on the store document, a reader never sees a seq
before a lower one of the same store is visible (the old Postgres design needed a row lock for
this), and seqs have no gaps.

### 3.5 `pull(storeId, since, max)`
`runQuery` on parent `stores/{storeId}`: `from changes where seq > since order by seq asc
limit max` (`max` clamped to 1…1000). The single-field index on `seq` is automatic; no
composite index is needed. Each document becomes a `SyncChange` (`changeId` = document id,
`payload` decoded from the string); a malformed document → `protocol`.

`batchGet` and `runQuery` stream their results: the JSON array is sent with HTTP 200, and a
failure after the first results arrives as a last `{"error": {code, status}}` element. Such an
element fails the call like the same non-2xx answer (`UNAVAILABLE` → `server HTTP 503`,
`ABORTED` → transaction retry, …), so a cut pull page never looks complete and a cut
`batchGet` never makes a document look missing. Every name of a `batchGet` must come back as
`found` or `missing`, otherwise → `protocol`.

### 3.6 Firestore error mapping
| Answer | `SyncErrorKind` |
|---|---|
| 401 / `UNAUTHENTICATED` (after the one refresh) | `auth` |
| 403 / `PERMISSION_DENIED` | `forbidden` (not a member) |
| 403 with reason `SERVICE_DISABLED` | `server` `HTTP 403 SERVICE_DISABLED (<op>)` (Firestore API off) |
| 404 «database (default) does not exist» | `server` `HTTP 404 NO_DATABASE (<op>)` |
| 404 store document | `storeNotFound` |
| 429 `RESOURCE_EXHAUSTED` (daily quota) | `server` `HTTP 429 RESOURCE_EXHAUSTED (<op>)` |
| 5xx | `server` `HTTP <status>` |
| other 4xx | `server` `HTTP <status> <STATUS> (<op>)` |

## 4. Security rules (`firebase/firestore.rules`)
- **Membership**: every read and write of `stores/{id}/**` requires
  `exists(stores/{id}/members/{request.auth.uid})`. Exception: `get` of a store document that
  does not exist (so the client can report «not found»). Listing `stores` is denied.
- **Store create** only with `createdBy == auth.uid`, exact field set, counters 0,
  `hasData == false`, `createdAt == request.time`, `environment in [test, production]`,
  name 1–200 characters, and **in the same commit** the creator's member document and
  `users/{uid}/stores/{id}` (`existsAfter`).
- **Store update**: only `nextSeq`, `nextCode`, `hasData` change (`environment`, `name`,
  `createdBy` are immutable); `nextSeq` and `nextCode` never decrease; `hasData` never goes
  back to false.
- **Member create**: only `members/{auth.uid}` with `role == 'owner'` while the store does not
  exist yet and `getAfter(store).createdBy == auth.uid` (i.e. only in the creating commit).
  Further accounts are added by the owner in the Firebase console (bypasses rules).
- **Devices**: create by members with a code `^[A-Z]{1,4}$` that `codes/{code}` (after the
  commit) assigns to this device; update only `lastSeenAt` (a timestamp).
- **Codes**: create by members, the device (after the commit) carries this code, and the store's
  `nextCode` grows by exactly 1 in the same commit.
- **Changes**: create only (no update, no delete), exact field set and types, `deviceId` a
  registered device, entity 1–100 / entity id 1–200 characters, `0 ≤ version ≤ 7258118400000`
  (`maxSyncVersion`), `payload` a string for `upsert` and null for `delete`,
  `receivedAt == request.time`, and **`get(store).nextSeq < seq ≤ getAfter(store).nextSeq`**:
  a change can only take a seq from the range its own commit allocated.
- **`users/{uid}/stores/{id}`**: read/create only by `uid` itself, with an existing membership
  (after the commit) and the store's environment.
- **Nothing may be deleted**; everything not matched is denied.

The rules can not look inside the `payload` string; the transport refuses nested payloads
before sending (§3.4) and the engine validates every received row (`rejected` conflict).
A member is trusted with the whole store (same as before: `role` is informational).

Rules cost: the dependent document reads (`members`, `stores`, `devices`, `codes`) are cached per
request, so a push commit of 398 changes stays far below the 20 access calls per request.

The Firestore emulator needs Java 11+ (the build machine has 1.8), so the rules are checked by
`firebase deploy --dry-run` (compilation) and their semantics are mirrored in Dart in the
test emulator (`test/core/sync/firebase_transport_test.dart`), which refuses every write the
rules refuse.

## 5. Quotas and cost (Spark, free)
Free per project and day: **50 000 reads, 20 000 writes, 20 000 deletes**, 1 GiB stored,
10 GiB/month egress. Measured with the engine (`firebase_transport_test.dart` scenario):

- A sale with *k* lines produces about **2 + 3k changes** (sale, sale lines, stock movements,
  the products' stock part, payment; 1 line → 5 changes).
- **Writes per push** = changes + 2 (store counter + device `lastSeenAt`). A 3-line sale ≈ 13
  writes → ~1 500 such sales per day on the free tier.
- **Reads per push** = changes + 2 (transaction `batchGet`) + ~4 rule lookups; **every register
  then pulls every change once** (including its own). With 2 registers a 3-line sale costs
  ≈ 11 + 2 + 4 + 2·11 ≈ **40 reads** on top of the polling below.
- **Reads per pull page** = documents returned + **1 rule lookup**: `changes` read access is
  `isMember()` = `exists(members/{uid})`, and Firestore bills every `get()`/`exists()` of a rule
  as a document read, once per query, also when the query returns nothing.
- **Idle polling**: an empty `runQuery` costs 2 reads (the minimum charge of a query + the
  membership lookup); a register in the foreground syncs every 30 s → up to **5 760 reads per
  register per day** (≈ 2 880 for 12 h). A shop with 4 registers open 24 h spends ≈ 23 000 of
  the 50 000 daily reads on polling alone.
- Example, 2 registers open 12 h: ≈ 5 800 idle reads + 40 reads/sale → (50 000 − 5 800) / 40 ≈
  **1 100, i.e. about 1 000 three-line sales per day** within 50 000 reads.
- **First upload / join**: creating a store uploads *every* row (1 write each) and a joining
  register reads every change (1 read each). A database with more than ~20 000 rows can not be
  uploaded in one day on Spark: the push stops with `RESOURCE_EXHAUSTED` and continues by itself
  after the daily reset (Pacific time midnight). For large databases switch the project to
  **Blaze** (pay as you go, the free quota stays free).
- Storage: a change document ≈ payload + ~200 bytes; 1 GiB holds roughly 1–2 million changes.

## 6. Tests
- `test/core/sync/firebase_transport_test.dart`: validation, auth requests and error mapping,
  Firestore value coding (`integerValue` strings), the request of every operation, idempotent
  re-push, chunking (1 000 changes → 400/400/206 writes), ABORTED retry and a real concurrent
  writer, token refresh (401 and proactive), error mapping, rules semantics, and the engine
  contract (create store, join, sales on two registers, token expiry, lost commit answer,
  rotated refresh token persistence) against an in-memory Firestore REST emulator.
- `test/live/firebase_live_test.dart`: the same two-register scenario against a real TEST
  project; skipped unless `DREAMPOS_FB_PROJECT`, `DREAMPOS_FB_API_KEY`, `DREAMPOS_FB_EMAIL`,
  `DREAMPOS_FB_PASSWORD` are set.
- Engine tests keep using `test/support/fake_sync_server.dart` (same semantics).
