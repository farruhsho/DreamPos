// SQL side of document-number search (D-025): `15` matches №15 of every
// register, `A-15` only register A's №15. Display goes through docNo().
import 'package:drift/drift.dart';

import '../core/doc_number.dart';
import '../core/sync/sync_tables.dart' show deviceCodeSettingKey;

export '../core/doc_number.dart';

/// This register's code from the settings map (null when sync is off). A
/// document created just now carries this code.
String? deviceCodeOf(Map<String, String>? settings) {
  final c = settings?[deviceCodeSettingKey]?.trim() ?? '';
  return c.isEmpty ? null : c;
}

/// SQL condition (with its variables) matching [query] as a document number
/// against table alias [alias] (`<alias>.number`, `<alias>.device_code`).
/// Null when [query] is not a document number.
({String sql, List<Variable> vars})? docNoWhere(String alias, String query) {
  final p = parseDocNo(query);
  if (p == null) return null;
  return docNoMatch(alias, p);
}

/// Condition for an already parsed number.
({String sql, List<Variable> vars}) docNoMatch(String alias, ParsedDocNo p) {
  if (p.code == null) return (sql: '$alias.number = ?', vars: [Variable.withInt(p.number)]);
  return (
    sql: '($alias.number = ? AND upper($alias.device_code) = ?)',
    vars: [Variable.withInt(p.number), Variable.withString(p.code!)],
  );
}

/// True when [number]/[code] is the document [query] names (in-memory
/// filters). A bare number matches every register; otherwise the code must
/// match. False when [query] is not a document number.
bool docNoMatches(int number, String? code, String query) {
  final p = parseDocNo(query);
  if (p == null) return false;
  return p.number == number && (p.code == null || p.code == (code?.trim().toUpperCase() ?? ''));
}
