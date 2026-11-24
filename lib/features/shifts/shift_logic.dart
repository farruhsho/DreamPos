// Pure / data logic of the shifts module: denominations, cash counting,
// extended X/Z report figures, opening-cash suggestion, history rows.
import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../domain/services/shift_service.dart';

export '../../core/widgets/widgets.dart' show pluralRu;

// ------------------------------------------------------------ denominations

/// Banknotes and coins in MAJOR units per currency code (largest first).
const _denominationsMajor = <String, List<num>>{
  'UZS': [200000, 100000, 50000, 20000, 10000, 5000, 2000, 1000, 500, 200, 100],
  'TJS': [500, 200, 100, 50, 20, 10, 5, 3, 1, 0.5, 0.2, 0.1],
  'KZT': [20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1],
  'KGS': [5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 3, 1],
  'RUB': [5000, 2000, 1000, 500, 200, 100, 50, 10, 5, 2, 1],
  'USD': [100, 50, 20, 10, 5, 2, 1, 0.25, 0.1, 0.05, 0.01],
};

const _fallbackMajor = <num>[1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];

/// Denominations for [c] in MINOR units, largest first. Values that cannot be
/// represented with the configured number of decimals are dropped.
List<int> denominationsFor(CurrencyConfig c) {
  final major = _denominationsMajor[c.code.toUpperCase()] ?? _fallbackMajor;
  final out = <int>{};
  for (final m in major) {
    final minor = (m * c.factor).round();
    if (minor > 0 && (minor / c.factor - m).abs() < 1e-9) out.add(minor);
  }
  return out.toList()..sort((a, b) => b.compareTo(a));
}

/// Cash count by denomination (denomination minor units -> pieces).
class CashCount {
  CashCount([Map<int, int>? counts]) : counts = {...?counts};
  final Map<int, int> counts;

  int get total {
    var t = 0;
    counts.forEach((d, n) {
      if (n > 0) t += d * n;
    });
    return t;
  }

  int get pieces => counts.values.where((n) => n > 0).fold(0, (s, n) => s + n);

  CashCount withCount(int denomination, int n) => CashCount({...counts, denomination: n < 0 ? 0 : n});

  /// Short text like "200 000 × 3; 1 000 × 5" for the shift note / audit.
  String describe(CurrencyConfig c) {
    final keys = counts.keys.where((k) => (counts[k] ?? 0) > 0).toList()..sort((a, b) => b.compareTo(a));
    return keys.map((k) => '${Money.format(k, withSymbol: false, c: c)} × ${counts[k]}').join('; ');
  }
}

/// Classification of a counted-vs-expected difference.
enum CashDiff { exact, shortage, surplus }

CashDiff classifyDiff(int counted, int expected) => counted == expected
    ? CashDiff.exact
    : counted < expected
    ? CashDiff.shortage
    : CashDiff.surplus;

/// Validates the close-shift form. Returns a Russian error or null.
String? validateClose({required int? counted, required int expected, required String note, int collection = 0}) {
  if (counted == null) return 'Введите сумму наличных в кассе';
  if (counted < 0) return 'Сумма не может быть отрицательной';
  if (collection < 0) return 'Сумма инкассации не может быть отрицательной';
  if (collection > counted) return 'Инкассация не может превышать пересчитанную сумму';
  if (counted != expected && note.trim().isEmpty) {
    return 'Укажите причину расхождения';
  }
  return null;
}

/// Closes [shiftId] with [counted] cash in the drawer. When [collection] > 0
/// the collection movement is recorded first and the rest ([counted] −
/// [collection]) stays as the counted float. Both steps run in ONE
/// transaction: if closing fails, the collection is rolled back too.
Future<ShiftReport> closeShiftWithCollection(
  AppDatabase db, {
  required String shiftId,
  required String userId,
  required int counted,
  int collection = 0,
  String? note,
}) {
  final svc = ShiftService(db);
  return db.transaction(() async {
    if (collection > 0) {
      await svc.cashMovement(
        shiftId: shiftId,
        kind: 'collection',
        amount: collection,
        userId: userId,
        reason: 'Инкассация при закрытии смены',
      );
    }
    return svc.close(shiftId: shiftId, userId: userId, countedCash: counted - collection, note: note);
  });
}

// ------------------------------------------------------------ cash ops

const cashKinds = ['pay_in', 'pay_out', 'expense', 'collection'];

String cashKindLabel(String k) => switch (k) {
  'pay_in' => 'Внесение',
  'pay_out' => 'Выплата',
  'expense' => 'Расход',
  'collection' => 'Инкассация',
  _ => k,
};

bool cashKindIsIn(String k) => k == 'pay_in';

const expenseCategories = ['Аренда', 'Зарплата', 'Хозтовары', 'Транспорт', 'Коммунальные', 'Прочее'];

// ------------------------------------------------------------ extended report

/// [ShiftReport] plus figures the domain report does not expose.
class ShiftFigures {
  ShiftFigures({
    required this.report,
    required this.returnedCost,
    required this.movementsByKind,
    required this.expensesByCategory,
  });

  final ShiftReport report;

  /// Cost of goods that came back with this shift's returns.
  final int returnedCost;
  final Map<String, int> movementsByKind;
  final Map<String, int> expensesByCategory;

  Shift get shift => report.shift;
  int get netRevenue => report.salesTotal - report.returnsTotal;
  int get netCost => report.costTotal - returnedCost;

  /// Gross profit net of returns.
  int get grossProfit => netRevenue - netCost;
  int get averageCheck => report.salesCount == 0 ? 0 : report.salesTotal ~/ report.salesCount;
  int get expectedCash => report.expectedCash;

  /// Uses the frozen expectedCash of a closed shift (never re-computed).
  int get expectedForDiff => shift.expectedCash ?? report.expectedCash;
  int? get difference => shift.countedCash == null ? null : shift.countedCash! - expectedForDiff;

  static Future<ShiftFigures> load(AppDatabase db, String shiftId) async {
    final rep = await ShiftService(db).report(shiftId);
    final rc = await db
        .customSelect(
          'SELECT COALESCE(SUM(ri.qty * si.unit_cost), 0) AS c '
          'FROM return_items ri '
          'JOIN returns r ON r.id = ri.return_id '
          'JOIN sale_items si ON si.id = ri.sale_item_id '
          'WHERE r.shift_id = ?',
          variables: [Variable.withString(shiftId)],
          readsFrom: {db.returnItems, db.returns, db.saleItems},
        )
        .getSingle();
    final returnedCost = ((rc.data['c'] as num?) ?? 0).round();
    final moves = await (db.select(db.cashMovements)..where((m) => m.shiftId.equals(shiftId))).get();
    final byKind = <String, int>{};
    final byCat = <String, int>{};
    for (final m in moves) {
      byKind[m.kind] = (byKind[m.kind] ?? 0) + m.amount;
      if (m.kind == 'expense') {
        final c = m.expenseCategory ?? 'Прочее';
        byCat[c] = (byCat[c] ?? 0) + m.amount;
      }
    }
    return ShiftFigures(report: rep, returnedCost: returnedCost, movementsByKind: byKind, expensesByCategory: byCat);
  }
}

/// Suggested opening cash: what stayed in the drawer after the previous
/// shift (counted cash; a collection at close is already subtracted there).
Future<int> suggestOpeningCash(AppDatabase db) async {
  final prev =
      await (db.select(db.shifts)
            ..where((s) => s.status.equals('closed'))
            ..orderBy([(s) => OrderingTerm.desc(s.closedAt)])
            ..limit(1))
          .getSingleOrNull();
  if (prev == null) return 0;
  final v = prev.countedCash ?? prev.expectedCash ?? 0;
  return v < 0 ? 0 : v;
}

// ------------------------------------------------------------ history

class ShiftHistoryRow {
  ShiftHistoryRow({required this.shift, required this.salesTotal, required this.salesCount});
  final Shift shift;
  final int salesTotal;
  final int salesCount;

  int? get difference =>
      shift.countedCash == null || shift.expectedCash == null ? null : shift.countedCash! - shift.expectedCash!;
}

Stream<List<ShiftHistoryRow>> watchShiftHistory(AppDatabase db, {String? onlyUserId, DateTime? from, int limit = 300}) {
  final where = <String>[];
  final vars = <Variable>[];
  if (onlyUserId != null) {
    where.add('(s.opened_by = ? OR s.closed_by = ?)');
    vars
      ..add(Variable.withString(onlyUserId))
      ..add(Variable.withString(onlyUserId));
  }
  if (from != null) {
    where.add('s.opened_at >= ?');
    vars.add(Variable.withDateTime(from));
  }
  final sql =
      'SELECT s.*, '
      "COALESCE((SELECT SUM(x.total) FROM sales x WHERE x.shift_id = s.id AND x.status NOT IN ('voided','held')), 0) AS h_sales_total, "
      "(SELECT COUNT(*) FROM sales x WHERE x.shift_id = s.id AND x.status NOT IN ('voided','held')) AS h_sales_count "
      'FROM shifts s '
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
      'ORDER BY s.number DESC LIMIT $limit';
  return db
      .customSelect(sql, variables: vars, readsFrom: {db.shifts, db.sales})
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            ShiftHistoryRow(
              shift: db.shifts.map(r.data),
              salesTotal: r.read<int>('h_sales_total'),
              salesCount: r.read<int>('h_sales_count'),
            ),
        ],
      );
}

