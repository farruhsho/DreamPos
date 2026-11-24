# Spec: Interface localization (D-012 → D-024)

Status: implemented (2026-11-25).

## Languages (owner decision 2026-11-24)
| Code | Language | Script | Notes |
|---|---|---|---|
| `ru` | Русский | Cyrillic | **template**, default; values must stay byte-identical to the current literals (existing tests find widgets by Russian text) |
| `uz` | Oʻzbekcha | Latin (official 1995 alphabet, `oʻ gʻ` written with U+02BB `ʻ`, apostrophe `ʼ` U+02BC) | |
| `ky` | Кыргызча | Cyrillic (ң ө ү) | |
| `en` | English | Latin | |
Tajik is **not** supported (removed by the owner).

## Scale
About 4,200 Russian string literals in `lib/`. The largest modules are products (503), inventory (377), purchasing (376), settings (373), marketing (346) and reports (344).

## Architecture
- **gen-l10n**: `l10n.yaml` with `arb-dir: lib/l10n`, `template-arb-file: app_ru.arb`, `output-dir: lib/l10n/gen`, `synthetic-package: false`, `nullable-getter: false`, class `AppLocalizations`. Generated Dart is committed.
- **ARB fragments to avoid merge conflicts.** Each module owns `lib/l10n/src/<module>/<lang>.arb`, where module is one of: `core`, `app`, `domain`, `auth` and every `lib/features/<m>`. Keys are camelCase, prefixed with the module, e.g. `posPayTitle`, `invReceiptPosted`. Common words (Отмена, Сохранить, Удалить, …) live in `core` as `commonCancel` and similar, and modules reuse them.
  - `dart run tool/l10n_merge.dart` merges all fragments into `lib/l10n/app_<lang>.arb`, then runs `flutter gen-l10n`.
  - It fails on: a duplicate key, a key missing in any language, a placeholder mismatch, or an empty value.
- **Access**:
  - in widgets: `context.l10n.xxx` (extension in `lib/l10n/l10n.dart`);
  - outside widgets (domain `BusinessException` messages, PDF and printing, notification engine, CSV export headers): `L.current`, a top-level `AppLocalizations` updated when the UI locale changes. Defaults to ru, so tests without a locale keep Russian.
  - Printed receipts, gift slips and the Z report use `L.receipt`, from the store setting `receipt_locale` (default `ru`), because the customer may read a different language than the cashier.
- **Plurals and placeholders**: ICU messages in the ARB (`{count, plural, one{…} few{…} many{…} other{…}}`; ru and uk-style rules for ru, `one/other` for en, `other` for uz and ky). Replace `pluralRu` uses; keep `pluralRu` only as a deprecated wrapper if tests need it. Money and quantities are passed already formatted as `String` placeholders.
- **Locale selection**:
  - The UI language is a device preference (SharedPreferences `ui_locale`, provider `uiLocaleProvider`). The picker is in Settings («Язык интерфейса»), on the login screen (compact chip) and in the first step of the setup wizard.
  - The receipt language is the store setting `receipt_locale`, set in Settings → Чек.
- **Material/Cupertino**: delegates are `AppLocalizations.delegate` plus the Global* delegates. Verify that `uz` and `ky` are in `GlobalMaterialLocalizations`; if one is not, add a fallback delegate that loads ru for it.
- **Dates**: `formatDate` / `formatDateTime` / `formatTime` stay numeric (`dd.MM.yyyy`). Month and weekday names come from ARB keys (deviation from the first draft, which used `DateFormat` with intl locale data; see docs/L10N.md).
- **Not translated**:
  - user data (product, category and customer names);
  - text already stored in the DB (movement reasons, audit details, ledger notes);
  - the currency symbol;
  - demo seed content — it may be localized by the locale at seeding time, but this is optional.
- **Checker**: `dart run tool/l10n_check.dart` lists Cyrillic string literals left in `lib/` (excluding `lib/l10n/**`, generated files and an explicit allowlist `tool/l10n_allow.txt` for legitimate cases: Cyrillic regexes, transliteration tables, the `ru` names of languages). It exits 1 on findings. It is a test too (`test/l10n_check_test.dart`), so new hard-coded text fails CI.
- **Screenshots**: the harness reads env `SCREENSHOTS_LOCALE` (default ru); file names get a `_<lang>` suffix when the locale is not ru. Longer languages (uz, ky) must not overflow at 390/1024/1440.

## Translation guidelines
- Use retail and POS vocabulary used in shops of the region, not literal word-for-word translation:
  - uz: Kassa, Chek, Smena, Qaytarish, Ombor, Kirim, Chiqim, Taʼminotchi, Mijoz, Chegirma, Sertifikat, Naqd, Karta, Oʻtkazma, Qarz.
  - ky: Касса, Чек, Смена, Кайтаруу, Кампа, Кириш, Жеткирүүчү, Кардар, Арзандатуу, Сертификат, Накталай, Карта, Которуу, Карыз.
  - en: Register/Till, Receipt, Shift, Return, Stock, Goods receipt, Supplier, Customer, Discount, Gift card, Cash, Card, Transfer, Debt.
- Keep labels short (buttons, chips, table headers); the UI is dense.
- Keep placeholders, punctuation, «» quotes in ru/ky (use “ ” in en and uz), and № in ru/ky (No. in en, № or "-son" style in uz).
