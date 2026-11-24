// Shared logic of tool/l10n_check.dart, also used by test/l10n_check_test.dart.
import 'dart:io';

class Finding {
  Finding(this.file, this.line, this.literal);
  final String file; // forward slashes, relative to the project root
  final int line;
  final String literal;
  @override
  String toString() => '$file:$line: $literal';
}

/// `pos` -> `lib/features/pos`; `core`/`app`/`domain` -> `lib/<m>`; `auth` -> `lib/features/auth`.
String modulePath(String module) =>
    const {'core', 'app', 'domain', 'l10n'}.contains(module) ? 'lib/$module' : 'lib/features/$module';

final _cyr = RegExp('[Ѐ-ӿ]');

/// Folders listed in tool/l10n_pending.txt (not yet migrated).
List<String> readPending(String root) => _readList('$root/tool/l10n_pending.txt');

List<String> _readList(String path) {
  final f = File(path);
  if (!f.existsSync()) return const [];
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .map((l) => l.replaceAll('\\', '/'))
      .toList();
}

/// Allowlist entries: `path` (a file, or a folder ending with `/`) allows
/// everything in it; `path | text` allows literals in that file containing `text`.
class Allowlist {
  Allowlist(this.entries);
  factory Allowlist.load(String root) => Allowlist(_readList('$root/tool/l10n_allow.txt'));
  final List<String> entries;

  bool allows(String file, String literal) {
    for (final e in entries) {
      final bar = e.indexOf(' | ');
      if (bar < 0) {
        if (e.endsWith('/') ? file.startsWith(e) : file == e) return true;
      } else {
        final p = e.substring(0, bar).trim();
        final text = e.substring(bar + 3);
        if (p == file && literal.contains(text)) return true;
      }
    }
    return false;
  }
}

bool _excluded(String rel) =>
    rel.startsWith('lib/l10n/') || rel.endsWith('.g.dart') || rel.endsWith('.freezed.dart');

bool _under(String rel, String dir) {
  final d = dir.endsWith('/') ? dir : '$dir/';
  return rel == dir || rel.startsWith(d);
}

/// Scans `lib/` (or [onlyPath]) for string literals containing Cyrillic.
List<Finding> findCyrillicLiterals({required String root, String? onlyPath, bool skipPending = true}) {
  final allow = Allowlist.load(root);
  final pending = skipPending ? readPending(root) : const <String>[];
  final base = Directory('$root/lib');
  final out = <Finding>[];
  final files = base
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final only = onlyPath?.replaceAll('\\', '/').replaceAll(RegExp(r'/$'), '');
  for (final f in files) {
    final rel = f.path.substring(root.length + 1).replaceAll('\\', '/');
    if (_excluded(rel)) continue;
    if (only != null && !_under(rel, only)) continue;
    if (pending.any((p) => _under(rel, p.replaceAll(RegExp(r'/$'), '')))) continue;
    final src = f.readAsStringSync();
    final lines = src.split('\n');
    for (final lit in scanStringLiterals(src)) {
      if (!_cyr.hasMatch(lit.ownText)) continue;
      final lineText = lines[lit.line - 1];
      if (lineText.contains('l10n-ignore')) continue;
      final shown = lit.source.length > 100 ? '${lit.source.substring(0, 100)}…' : lit.source;
      if (allow.allows(rel, lit.source)) continue;
      out.add(Finding(rel, lit.line, shown.replaceAll('\n', r'\n')));
    }
  }
  return out;
}

class Literal {
  Literal(this.line, this.source, this.ownText);
  final int line;
  final String source; // full source of the literal, quotes included
  final String ownText; // literal text without nested interpolated code
}

/// Minimal Dart lexer: returns every string literal (nested ones inside
/// `${...}` too), skipping comments.
List<Literal> scanStringLiterals(String src) {
  final out = <Literal>[];
  var i = 0;
  final n = src.length;

  int lineAt(int pos) {
    var l = 1;
    for (var k = 0; k < pos && k < n; k++) {
      if (src.codeUnitAt(k) == 10) l++;
    }
    return l;
  }

  bool isIdent(int c) =>
      (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || c == 36;

  late int Function(int pos, bool untilBrace) code;

  // Parses a string starting at the quote at [pos]; returns the index after it.
  int string(int start, int pos, bool raw) {
    final q = src[pos];
    final triple = pos + 2 < n && src[pos + 1] == q && src[pos + 2] == q;
    var p = pos + (triple ? 3 : 1);
    final own = StringBuffer();
    while (p < n) {
      final c = src[p];
      if (triple ? (src.startsWith(q * 3, p)) : c == q) {
        p += triple ? 3 : 1;
        break;
      }
      if (!triple && c == '\n') break; // unterminated, be lenient
      if (!raw && c == '\\') {
        own.write(src.substring(p, (p + 2).clamp(0, n)));
        p += 2;
        continue;
      }
      if (!raw && c == r'$' && p + 1 < n && src[p + 1] == '{') {
        p = code(p + 2, true);
        continue;
      }
      own.write(c);
      p++;
    }
    out.add(Literal(lineAt(start), src.substring(start, p.clamp(0, n)), own.toString()));
    return p;
  }

  code = (int pos, bool untilBrace) {
    var p = pos;
    var depth = 0;
    while (p < n) {
      final c = src[p];
      if (c == '/' && p + 1 < n && src[p + 1] == '/') {
        final e = src.indexOf('\n', p);
        p = e < 0 ? n : e;
        continue;
      }
      if (c == '/' && p + 1 < n && src[p + 1] == '*') {
        var d = 1;
        p += 2;
        while (p < n && d > 0) {
          if (src.startsWith('/*', p)) {
            d++;
            p += 2;
          } else if (src.startsWith('*/', p)) {
            d--;
            p += 2;
          } else {
            p++;
          }
        }
        continue;
      }
      if (c == '\'' || c == '"') {
        final raw = p > 0 && src[p - 1] == 'r' && (p < 2 || !isIdent(src.codeUnitAt(p - 2)));
        p = string(raw ? p - 1 : p, p, raw);
        continue;
      }
      if (c == '{') depth++;
      if (c == '}') {
        if (untilBrace && depth == 0) return p + 1;
        depth--;
      }
      p++;
    }
    return p;
  };

  i = code(0, false);
  assert(i >= 0);
  return out;
}
