// Pure helpers and small DB helpers for the Settings module.
//
// Everything here is UI-free so it can be unit-tested with an in-memory DB.
import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/widgets/widgets.dart' show formatDateTime;
import '../../l10n/l10n.dart';

/// Application version shown in «О программе» (keep in sync with pubspec).
const appVersion = '1.0.0';

/// Length of the trial period in days (placeholder licensing).
const trialPeriodDays = 30;

/// Setting keys used by this module. Values are always strings.
abstract final class SettingKeys {
  static const storeName = 'store_name';
  static const storeAddress = 'store_address';
  static const storePhone = 'store_phone';
  static const storeTaxId = 'store_tax_id';
  static const receiptFooter = 'receipt_footer';
  static const receiptWidthMm = 'receipt_width_mm'; // '58' | '80'
  static const autoPrintReceipt = 'auto_print_receipt'; // '1' | '0'

  static const currencyCode = 'currency_code';
  static const currencySymbol = 'currency_symbol';
  static const currencyDecimals = 'currency_decimals';
  static const currencySymbolBefore = 'currency_symbol_before';
  static const defaultVatPercent = 'default_vat_percent';

  static const requireShift = 'require_shift'; // != '0' means on
  static const allowNegativeStock = 'allow_negative_stock';
  static const returnDays = 'return_days'; // 0 = no limit
  static const debtRequiresLimit = 'debt_requires_limit';
  static const posBanknotes = 'pos_banknotes'; // minor units, comma separated
  static const cashRounding = 'cash_rounding'; // none | step in minor units

  static const loyaltyEnabled = 'loyalty_enabled';
  static const loyaltyEarnPercent = 'loyalty_earn_percent';
  static const loyaltyMaxRedeemPercent = 'loyalty_max_redeem_percent';

  static const themeMode = 'theme_mode'; // system | light | dark

  static const autoBackupDaily = 'auto_backup_daily';
  static const lastBackupAt = 'last_backup_at'; // ISO-8601

  static const demoMode = 'demo_mode';
  static const installedAt = 'installed_at'; // ISO-8601
}

/// Device-local (shared_preferences) key of the register bound to this device.
const deviceRegisterPrefKey = 'register_id';

// ------------------------------------------------------------------ validation

/// Parses a percent value ("2", "2,5", "12.5"). Returns null when invalid.
double? parsePercent(String input) {
  final t = input.trim().replaceAll(',', '.').replaceAll('%', '').trim();
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null || v.isNaN || v.isInfinite) return null;
  return v;
}

/// Validates a percent in [min]..[max]. Returns a localized error or null.
String? validatePercent(String? input, {double min = 0, double max = 100, bool allowEmpty = false}) {
  final t = (input ?? '').trim();
  if (t.isEmpty) return allowEmpty ? null : L.current.settingsErrPercentRange(_num(min), _num(max));
  final v = parsePercent(t);
  if (v == null) return L.current.settingsErrPercentNumber;
  if (v < min || v > max) return L.current.settingsErrPercentAllowed(_num(min), _num(max));
  final frac = t.replaceAll(',', '.').split('.');
  if (frac.length == 2 && frac[1].replaceAll('%', '').trim().length > 2) {
    return L.current.settingsErrTwoDecimals;
  }
  return null;
}

/// Formats a percent for storage/display: 2.0 -> "2", 2.5 -> "2.5".
String formatPercentValue(double v) {
  final r = (v * 100).roundToDouble() / 100;
  return r == r.truncateToDouble() ? r.toStringAsFixed(0) : r.toString();
}

String _num(double v) => formatPercentValue(v);

/// Return period in days: integer 0..3650 (0 = no limit).
String? validateReturnDays(String? input) {
  final t = (input ?? '').trim();
  if (t.isEmpty) return L.current.settingsErrReturnDaysEmpty;
  final v = int.tryParse(t);
  if (v == null) return L.current.settingsErrReturnDaysInt;
  if (v < 0) return L.current.settingsErrNotNegative;
  if (v > 3650) return L.current.settingsErrReturnDaysMax;
  return null;
}

String? validateStoreName(String? input) {
  final t = (input ?? '').trim();
  if (t.isEmpty) return L.current.settingsErrStoreNameRequired;
  if (t.length > 120) return L.current.settingsErrMaxLength('120');
  return null;
}

/// Phone is optional; when given must contain 5–15 digits and only
/// digits, spaces, +, -, ( and ).
String? validatePhone(String? input) {
  final t = (input ?? '').trim();
  if (t.isEmpty) return null;
  if (!RegExp(r'^[0-9+\-() ]+$').hasMatch(t)) {
    return L.current.settingsErrPhoneChars;
  }
  final digits = t.replaceAll(RegExp(r'\D'), '').length;
  if (digits < 5 || digits > 15) return L.current.settingsErrPhoneDigits;
  return null;
}

/// Tax id (ИНН/БИН/ИНН КР): optional, digits only, 9–14 long.
String? validateTaxId(String? input) {
  final t = (input ?? '').trim();
  if (t.isEmpty) return null;
  if (!RegExp(r'^\d+$').hasMatch(t)) return L.current.settingsErrTaxIdDigits;
  if (t.length < 9 || t.length > 14) return L.current.settingsErrTaxIdLength;
  return null;
}

String? validateReceiptFooter(String? input) {
  final t = input ?? '';
  if (t.length > 300) return L.current.settingsErrMaxLength('300');
  if ('\n'.allMatches(t).length >= 6) return L.current.settingsErrFooterLines;
  return null;
}

// ------------------------------------------------------------------ banknotes

class BanknotesResult {
  const BanknotesResult(this.values, [this.error]);
  final List<int> values; // minor units, ascending, unique
  final String? error;
  bool get ok => error == null;

  /// Value to store in `pos_banknotes` ('' = use defaults).
  String get stored => values.join(',');
}

const maxBanknotes = 10;

/// Parses user input like "1000, 2 000, 5000" (major units; decimal part via
/// a dot, e.g. "0.5") into ascending minor units.
BanknotesResult parseBanknotes(String input, CurrencyConfig c) {
  final parts = input
      .split(RegExp(r'[,;\n]'))
      .map((s) => s.replaceAll(RegExp(r'[\s ]'), ''))
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) return const BanknotesResult([]);
  final out = <int>[];
  for (final p in parts) {
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(p)) {
      return BanknotesResult(const [], L.current.settingsErrBanknoteNotNumber(p));
    }
    final dot = p.indexOf('.');
    if (dot >= 0 && p.length - dot - 1 > c.decimals) {
      return BanknotesResult(
        const [],
        c.decimals == 0
            ? L.current.settingsErrBanknoteNoFraction(p, c.code)
            : L.current.settingsErrBanknoteTooManyDecimals(p),
      );
    }
    final v = Money.parse(p, c: c);
    if (v == null || v <= 0) return BanknotesResult(const [], L.current.settingsErrBanknotePositive(p));
    if (v > 1000000000000) return BanknotesResult(const [], L.current.settingsErrBanknoteTooBig(p));
    if (out.contains(v)) return BanknotesResult(const [], L.current.settingsErrBanknoteDuplicate(p));
    out.add(v);
  }
  if (out.length > maxBanknotes) {
    return BanknotesResult(const [], L.current.settingsErrBanknotesMax('$maxBanknotes'));
  }
  out.sort();
  return BanknotesResult(out);
}

/// Stored minor units -> editable text ("1000, 2000").
String banknotesToInput(String? stored, CurrencyConfig c) {
  final list = decodeBanknotes(stored);
  return list.map((v) => Money.toInput(v, c: c)).join(', ');
}

/// Stored `pos_banknotes` -> list of minor units (invalid parts skipped).
List<int> decodeBanknotes(String? stored) =>
    (stored ?? '').split(',').map((s) => int.tryParse(s.trim())).whereType<int>().where((v) => v > 0).toList();

/// Default quick-tender banknotes per currency (minor units).
List<int> defaultBanknotes(CurrencyConfig c) {
  final major = switch (c.code) {
    'UZS' => [1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000],
    'TJS' => [1, 5, 10, 20, 50, 100, 200, 500],
    'KZT' => [200, 500, 1000, 2000, 5000, 10000, 20000],
    'KGS' => [20, 50, 100, 200, 500, 1000, 2000, 5000],
    'RUB' => [50, 100, 200, 500, 1000, 2000, 5000],
    'USD' => [1, 5, 10, 20, 50, 100],
    _ => [1, 5, 10, 50, 100, 500, 1000],
  };
  return [for (final m in major) m * c.factor];
}

// ------------------------------------------------------------------ rounding

/// Allowed `cash_rounding` values: 'none' or the step in minor units.
const cashRoundingOptions = ['none', '50', '100', '500', '1000'];

String cashRoundingLabel(String v, CurrencyConfig c, [AppLocalizations? l]) {
  l ??= L.current;
  if (v == 'none' || int.tryParse(v) == null) return l.settingsRoundingNone;
  return l.settingsRoundingStep(Money.format(int.parse(v), c: c));
}

/// Reference implementation for the POS: rounds a cash total to the nearest
/// [step] minor units (half up). step <= 0 means no rounding.
/// Mirrors the domain rule (D-015): round DOWN in the customer's favour,
/// never below one step.
int roundCash(int amount, int step) {
  if (step <= 0 || amount < step) return amount;
  return amount - amount % step;
}

// ------------------------------------------------------------------ loyalty

/// Live explanation of the loyalty settings for a 100 000 (major) purchase.
String loyaltyExample(double earnPercent, double maxRedeemPercent, CurrencyConfig c, [AppLocalizations? l]) {
  final purchase = 100000 * c.factor;
  final earned = Money.percent(purchase, earnPercent);
  final redeem = Money.percent(purchase, maxRedeemPercent);
  return (l ?? L.current).settingsLoyaltyExample(
    Money.format(purchase, withSymbol: false, c: c),
    Money.format(earned, withSymbol: false, c: c),
    c.symbol,
    formatPercentValue(maxRedeemPercent),
    Money.format(redeem, c: c),
  );
}

// ------------------------------------------------------------------ backups

String _two(int v) => v.toString().padLeft(2, '0');

/// dreampos-YYYYMMDD-HHMM.sqlite
String backupFileName(DateTime t) =>
    'dreampos-${t.year}${_two(t.month)}${_two(t.day)}-${_two(t.hour)}${_two(t.minute)}.sqlite';

final _backupRe = RegExp(r'^dreampos-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(?:-\d+)?\.sqlite$');

bool isBackupFileName(String name) => _backupRe.hasMatch(name);

/// Date encoded in a backup file name (null if the name doesn't match).
DateTime? backupDateFromName(String name) {
  final m = _backupRe.firstMatch(name);
  if (m == null) return null;
  int g(int i) => int.parse(m.group(i)!);
  return DateTime(g(1), g(2), g(3), g(4), g(5));
}

/// True when [header] starts with the SQLite magic string.
bool looksLikeSqlite(List<int> header) {
  const magic = 'SQLite format 3';
  if (header.length < 16) return false;
  for (var i = 0; i < magic.length; i++) {
    if (header[i] != magic.codeUnitAt(i)) return false;
  }
  return header[15] == 0;
}

String formatBytes(int bytes, [AppLocalizations? l]) {
  l ??= L.current;
  if (bytes < 1024) return l.settingsBytes('$bytes');
  final kb = bytes / 1024;
  if (kb < 1024) return l.settingsKilobytes(kb.toStringAsFixed(0));
  final mb = kb / 1024;
  if (mb < 1024) return l.settingsMegabytes(mb.toStringAsFixed(1).replaceAll('.', ','));
  return l.settingsGigabytes((mb / 1024).toStringAsFixed(2).replaceAll('.', ','));
}

// ------------------------------------------------------------------ trial

/// Days left in the trial (0 when expired). Partial days count as a day.
int trialDaysLeft(DateTime installedAt, DateTime now, {int days = trialPeriodDays}) {
  final end = installedAt.add(Duration(days: days));
  if (!now.isBefore(end)) return 0;
  // Clamp: a clock set backwards must not show more than the full period.
  return (end.difference(now).inMinutes / (24 * 60)).ceil().clamp(0, days);
}

// ------------------------------------------------------------------ CSV

final _csvNumber = RegExp(r'^-?\d+([.,]\d+)?$');

/// One CSV row with ';' separator (Excel in Russian locale) and quoting.
/// Text cells that Excel would run as a formula (=, +, -, @, tab, CR) get an
/// apostrophe prefix (CSV/formula injection via product or customer names);
/// plain numbers such as "-5" are kept as is.
String csvRow(List<Object?> cells) => cells
    .map((c) {
      var s = c?.toString() ?? '';
      if (s.isNotEmpty && '=+-@\t\r'.contains(s[0]) && !_csvNumber.hasMatch(s)) s = "'$s";
      if (s.contains(RegExp(r'[;"\n\r]'))) return '"${s.replaceAll('"', '""')}"';
      return s;
    })
    .join(';');

/// Money for spreadsheets: no grouping, decimal comma.
String csvMoney(int minor, CurrencyConfig c) => Money.toInput(minor, c: c).replaceAll('.', ',');

String csvQty(double q) {
  final r = Qty.round(q);
  return (r == r.truncateToDouble() ? r.toStringAsFixed(0) : r.toString()).replaceAll('.', ',');
}

// ------------------------------------------------------------------ receipt preview

/// Fake receipt text built from the store settings, for the live preview and
/// the printer test. Mirrors the layout of `ReceiptData.toText`. Uses the
/// receipt language (store setting `receipt_locale` in [s]); [title] defaults
/// to a sample receipt number.
String sampleReceiptText(
  Map<String, String> s, {
  int width = 42,
  DateTime? now,
  CurrencyConfig? currency,
  String? title,
}) {
  final rl = L.forReceipt(s);
  final c = currency ?? CurrencyConfig.fromSettings(s);
  final b = StringBuffer();
  String center(String t) => t.length >= width ? t : ' ' * ((width - t.length) ~/ 2) + t;
  String lr(String l, String r) {
    final space = width - l.length - r.length;
    return space >= 1 ? '$l${' ' * space}$r' : '$l\n${' ' * (width - r.length).clamp(0, width)}$r';
  }

  String m(int v) => Money.format(v, withSymbol: false, c: c);
  final f = c.factor;
  final line = '-' * width;
  final name = (s[SettingKeys.storeName] ?? '').trim();
  b.writeln(center(name.isEmpty ? 'DreamPOS' : name));
  final addr = (s[SettingKeys.storeAddress] ?? '').trim();
  if (addr.isNotEmpty) b.writeln(center(addr));
  final phone = (s[SettingKeys.storePhone] ?? '').trim();
  if (phone.isNotEmpty) b.writeln(center(rl.corePrintPhone(phone)));
  final tax = (s[SettingKeys.storeTaxId] ?? '').trim();
  if (tax.isNotEmpty) b.writeln(center(rl.corePrintTaxId(tax)));
  b.writeln(line);
  b.writeln(center(title ?? rl.coreReceiptTitle('123')));
  b.writeln(center(formatDateTime(now ?? DateTime.now())));
  b.writeln(rl.corePrintCashier(rl.settingsSampleCashier));
  b.writeln(line);
  final items = [
    (rl.settingsSampleItemMilk, 2, 12000 * f),
    (rl.settingsSampleItemBread, 1, 4000 * f),
    (rl.settingsSampleItemTea, 1, 18500 * f),
  ];
  var total = 0;
  for (final (n, q, p) in items) {
    b.writeln(n);
    b.writeln(lr('  $q x ${m(p)}', m(q * p)));
    total += q * p;
  }
  b.writeln(line);
  b.writeln(lr(rl.corePrintTotal, Money.format(total, c: c)));
  final paid = ((total / (10000 * f)).ceil()) * 10000 * f;
  b.writeln(lr(rl.payCash, Money.format(paid, c: c)));
  if (paid > total) b.writeln(lr(rl.commonChange, Money.format(paid - total, c: c)));
  b.writeln(line);
  final footer = (s[SettingKeys.receiptFooter] ?? '').trim();
  if (footer.isNotEmpty) {
    for (final l in footer.split('\n')) {
      b.writeln(center(l.trim()));
    }
  }
  return L.printable(b.toString());
}

int receiptCharsForWidth(String? widthMm) => widthMm == '58' ? 32 : 42;

// ------------------------------------------------------------------ DB helpers

String _short(String? v) {
  if (v == null) return '—';
  final one = v.replaceAll('\n', '⏎');
  return one.length > 80 ? '${one.substring(0, 77)}...' : one;
}

/// Writes changed settings in one transaction, auditing each change as
/// `settings.change` with "key: old → new". Unchanged values are skipped.
/// Returns the number of keys actually changed.
Future<int> saveSettings(AppDatabase db, Map<String, String> values, {String? userId}) {
  return db.transaction(() async {
    var changed = 0;
    for (final e in values.entries) {
      final old = await db.getSetting(e.key);
      if (old == e.value) continue;
      await db.setSetting(e.key, e.value);
      await db.audit(
        'settings.change',
        userId: userId,
        entity: 'settings',
        entityId: e.key,
        details: '${e.key}: ${_short(old)} → ${_short(e.value)}',
      );
      await db.markDirty('settings', e.key);
      changed++;
    }
    return changed;
  });
}

/// Currency settings for a preset.
Map<String, String> currencySettings(CurrencyConfig c) => {
  SettingKeys.currencyCode: c.code,
  SettingKeys.currencySymbol: c.symbol,
  SettingKeys.currencyDecimals: '${c.decimals}',
  SettingKeys.currencySymbolBefore: c.symbolBefore ? '1' : '0',
};

/// Everything to write when switching currency. `pos_banknotes` and
/// `cash_rounding` are stored in minor units of the OLD currency, so they are
/// reset to the defaults of the new one (otherwise 1000 сум would turn into
/// a 10,00 сом. button).
Map<String, String> currencyChangeSettings(CurrencyConfig c, Map<String, String> current) => {
  ...currencySettings(c),
  if ((current[SettingKeys.posBanknotes] ?? '').trim().isNotEmpty) SettingKeys.posBanknotes: '',
  if ((current[SettingKeys.cashRounding] ?? 'none') != 'none') SettingKeys.cashRounding: 'none',
};

String get currencyLockedMessage => L.current.settingsCurrencyLocked;

/// Switches currency atomically: the "no sales yet" check and the write run
/// in one transaction, so a sale committed meanwhile by another cashier
/// cannot slip in between (DECISIONS D-004).
Future<void> changeCurrency(AppDatabase db, CurrencyConfig c, Map<String, String> current, {String? userId}) =>
    db.transaction(() async {
      if (await hasAnySale(db)) throw Exception(currencyLockedMessage);
      await saveSettings(db, currencyChangeSettings(c, current), userId: userId);
    });

/// Currency is locked as soon as any sale (in any status) exists: amounts
/// are stored in minor units of the original currency (DECISIONS D-004).
Future<bool> hasAnySale(AppDatabase db) async {
  final row = await db.customSelect('SELECT EXISTS(SELECT 1 FROM sales) AS e', readsFrom: {db.sales}).getSingle();
  return row.read<int>('e') == 1;
}

Stream<bool> watchHasAnySale(AppDatabase db) => db
    .customSelect('SELECT EXISTS(SELECT 1 FROM sales) AS e', readsFrom: {db.sales})
    .watchSingle()
    .map((r) => r.read<int>('e') == 1);

/// Counts for the diagnostics card.
Future<Map<String, int>> entityCounts(AppDatabase db) async {
  final row = await db
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM products WHERE deleted_at IS NULL) AS products, '
        '(SELECT COUNT(*) FROM customers WHERE deleted_at IS NULL) AS customers, '
        '(SELECT COUNT(*) FROM sales) AS sales, '
        '(SELECT COUNT(*) FROM users WHERE deleted_at IS NULL) AS users',
        readsFrom: {db.products, db.customers, db.sales, db.users},
      )
      .getSingle();
  return {
    'products': row.read<int>('products'),
    'customers': row.read<int>('customers'),
    'sales': row.read<int>('sales'),
    'users': row.read<int>('users'),
  };
}

/// Logical DB size (page_count * page_size), works for memory DBs too.
Future<int> databaseSizeBytes(AppDatabase db) async {
  final pc = await db.customSelect('PRAGMA page_count').getSingle();
  final ps = await db.customSelect('PRAGMA page_size').getSingle();
  return (pc.data.values.first as int) * (ps.data.values.first as int);
}

/// Text block for support tickets.
String diagnosticsText({
  required String platform,
  required int dbSize,
  required Map<String, int> counts,
  required Map<String, String> settings,
  DateTime? now,
}) {
  final l = L.current;
  final demo = settings[SettingKeys.demoMode] == '1' ? l.settingsYesLower : l.settingsNoLower;
  final b = StringBuffer()
    ..writeln('DreamPOS $appVersion')
    ..writeln(l.settingsDiagPlatform(platform))
    ..writeln(l.settingsDiagStore(settings[SettingKeys.storeName] ?? '—'))
    ..writeln(l.settingsCurrencyValue(settings[SettingKeys.currencyCode] ?? 'UZS'))
    ..writeln(l.settingsDiagDemo(demo))
    ..writeln(l.settingsDiagDbSize(formatBytes(dbSize, l)))
    ..writeln(l.settingsDiagProducts('${counts['products'] ?? 0}'))
    ..writeln(l.settingsDiagSales('${counts['sales'] ?? 0}'))
    ..writeln(l.settingsDiagCustomers('${counts['customers'] ?? 0}'))
    ..writeln(l.settingsDiagUsers('${counts['users'] ?? 0}'))
    ..writeln(l.settingsDiagLastBackup(_isoLabel(settings[SettingKeys.lastBackupAt], l)))
    ..write(l.settingsDiagGenerated(formatDateTime(now ?? DateTime.now())));
  return b.toString();
}

String _isoLabel(String? iso, AppLocalizations l) {
  final d = iso == null ? null : DateTime.tryParse(iso);
  return d == null ? l.settingsNoLower : formatDateTime(d.toLocal());
}

/// Ensures `installed_at` exists; returns the install date.
Future<DateTime> ensureInstalledAt(AppDatabase db, {DateTime? now}) async {
  final v = await db.getSetting(SettingKeys.installedAt);
  final parsed = v == null ? null : DateTime.tryParse(v);
  if (parsed != null) return parsed;
  final t = now ?? DateTime.now();
  await db.setSetting(SettingKeys.installedAt, t.toIso8601String());
  return t;
}

/// Name validation for registers (unique among not deleted, case-insensitive).
String? validateRegisterName(String? name, Iterable<Register> existing, {String? selfId}) {
  final t = (name ?? '').trim();
  if (t.isEmpty) return L.current.settingsErrRegisterNameEmpty;
  if (t.length > 60) return L.current.settingsErrMaxLength('60');
  final dup = existing.any(
    (r) => r.id != selfId && r.deletedAt == null && r.name.trim().toLowerCase() == t.toLowerCase(),
  );
  if (dup) return L.current.settingsErrRegisterDuplicate;
  return null;
}

/// Creates or renames a register (reference data -> direct drift write).
Future<String> upsertRegister(
  AppDatabase db, {
  String? id,
  required String name,
  bool isActive = true,
  String? userId,
}) async {
  final now = DateTime.now();
  final rid = id ?? newId();
  await db.transaction(() async {
    if (id == null) {
      await db
          .into(db.registers)
          .insert(RegistersCompanion.insert(id: rid, name: name.trim(), isActive: Value(isActive)));
    } else {
      if (!isActive && await registerHasOpenShift(db, rid)) throw Exception(registerBusyMessage);
      await (db.update(db.registers)..where((r) => r.id.equals(rid))).write(
        RegistersCompanion(name: Value(name.trim()), isActive: Value(isActive), updatedAt: Value(now)),
      );
    }
    await db.markDirty('registers', rid);
    await db.audit(
      id == null ? 'register.create' : 'register.update',
      userId: userId,
      entity: 'registers',
      entityId: rid,
      details: '${name.trim()}${isActive ? '' : ' (отключена)'}', // audit detail stored in DB // l10n-ignore
    );
  });
  return rid;
}

/// True when a shift is currently open on register [registerId].
Future<bool> registerHasOpenShift(AppDatabase db, String registerId) async {
  final row =
      await (db.select(db.shifts)
            ..where((s) => s.registerId.equals(registerId) & s.status.equals('open'))
            ..limit(1))
          .getSingleOrNull();
  return row != null;
}

String get registerBusyMessage => L.current.settingsRegisterBusy;

/// Soft-deletes a register (sales may reference it). Refused while a shift
/// is open on it, so an open shift never points to a deleted register.
Future<void> deleteRegister(AppDatabase db, Register r, {String? userId}) async {
  final now = DateTime.now();
  await db.transaction(() async {
    if (await registerHasOpenShift(db, r.id)) throw Exception(registerBusyMessage);
    await (db.update(db.registers)..where((t) => t.id.equals(r.id))).write(
      RegistersCompanion(deletedAt: Value(now), isActive: const Value(false), updatedAt: Value(now)),
    );
    await db.markDirty('registers', r.id, op: 'delete');
    await db.audit('register.delete', userId: userId, entity: 'registers', entityId: r.id, details: r.name);
  });
}
