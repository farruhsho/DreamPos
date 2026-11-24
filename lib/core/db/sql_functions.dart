import 'package:sqlite3/common.dart';

/// Unicode-aware replacements for SQLite's ASCII-only `like`, `lower`,
/// `upper`. Registered on every connection (app and tests), so every LIKE in
/// the app is case-insensitive for Cyrillic/Uzbek text too:
/// `name LIKE '%молоко%'` now matches «Молоко».
///
/// Overriding `like` is the documented SQLite mechanism (the ICU extension
/// does the same). It disables the LIKE index optimisation, which never
/// applied to case-insensitive search anyway.
void registerSqlFunctions(CommonDatabase db) {
  db.createFunction(
    functionName: 'like',
    argumentCount: const AllowedArgumentCount(2),
    deterministic: true,
    function: (args) => _like(args[0], args[1], null),
  );
  db.createFunction(
    functionName: 'like',
    argumentCount: const AllowedArgumentCount(3),
    deterministic: true,
    function: (args) => _like(args[0], args[1], args[2]),
  );
  db.createFunction(
    functionName: 'lower',
    argumentCount: const AllowedArgumentCount(1),
    deterministic: true,
    function: (args) => args[0] is String ? (args[0] as String).toLowerCase() : args[0],
  );
  db.createFunction(
    functionName: 'upper',
    argumentCount: const AllowedArgumentCount(1),
    deterministic: true,
    function: (args) => args[0] is String ? (args[0] as String).toUpperCase() : args[0],
  );
}

final _cache = <String, RegExp>{};

Object? _like(Object? pattern, Object? value, Object? escape) {
  if (pattern == null || value == null) return null;
  final p = pattern.toString();
  final v = value.toString();
  final esc = escape?.toString();
  final key = '${esc ?? ''}\u0000$p';
  var re = _cache[key];
  if (re == null) {
    if (_cache.length > 256) _cache.clear();
    re = _cache[key] = likeToRegExp(p, escape: esc);
  }
  return re.hasMatch(v) ? 1 : 0;
}

/// Converts a SQL LIKE pattern into an anchored, case-insensitive RegExp.
RegExp likeToRegExp(String pattern, {String? escape}) {
  final b = StringBuffer('^');
  for (var i = 0; i < pattern.length; i++) {
    final ch = pattern[i];
    if (escape != null && escape.isNotEmpty && ch == escape[0] && i + 1 < pattern.length) {
      b.write(RegExp.escape(pattern[++i]));
    } else if (ch == '%') {
      b.write('.*');
    } else if (ch == '_') {
      b.write('.');
    } else {
      b.write(RegExp.escape(ch));
    }
  }
  b.write(r'$');
  return RegExp(b.toString(), caseSensitive: false, unicode: true, dotAll: true);
}
