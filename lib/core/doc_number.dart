// Document numbers with an optional register code (D-025): `15` when sync is
// off (device_code null), `A-15` when the document was made on register A.

/// Display form of a document number: `N` or `CODE-N`.
String docNo(int number, String? code) {
  final c = code?.trim() ?? '';
  return c.isEmpty ? '$number' : '$c-$number';
}

/// A parsed document number for search. [code] is null when the query had
/// no register code (`15` matches number 15 of every register).
typedef ParsedDocNo = ({String? code, int number});

final _docNoPattern = RegExp(r'^[№#]?\s*(?:([A-Za-z]{1,3})\s*-?\s*)?(\d{1,9})$');

/// Parses `15`, `№15`, `A-15`, `a15`, `AB-7` (code upper-cased). Returns null
/// when [query] is not a document number.
ParsedDocNo? parseDocNo(String query) {
  final m = _docNoPattern.firstMatch(query.trim());
  if (m == null) return null;
  final n = int.tryParse(m.group(2)!);
  if (n == null) return null;
  return (code: m.group(1)?.toUpperCase(), number: n);
}
