// Shared logic of tool/l10n_merge.dart, also used by test/l10n_check_test.dart.
import 'dart:convert';
import 'dart:io';

/// Supported UI languages; `ru` is the template. Tajik is not supported.
const l10nLanguages = ['ru', 'uz', 'ky', 'en'];

/// Allowed key prefixes per fragment module. A module not listed here must
/// prefix its keys with its own folder name (camelCased).
const modulePrefixes = <String, List<String>>{
  'core': ['common', 'core', 'unit', 'pay', 'role', 'lang'],
  'app': ['app', 'nav'],
  'domain': ['err', 'dom'],
  'auth': ['auth', 'setup'],
  'pos': ['pos'],
  'products': ['prod'],
  'inventory': ['inv'],
  'purchasing': ['pur'],
  'settings': ['settings'],
  'marketing': ['mkt'],
  'reports': ['rep'],
  'customers': ['cust'],
  'dashboard': ['dash'],
  'notifications': ['notif'],
  'sales': ['sales'],
  'shifts': ['shift'],
  'staff': ['staff'],
  'warranty': ['warranty'],
};

List<String> prefixesFor(String module) =>
    modulePrefixes[module] ??
    [module.replaceAllMapped(RegExp(r'_(\w)'), (m) => m.group(1)!.toUpperCase())];

final _keyRe = RegExp(r'^[a-z][a-zA-Z0-9]*$');
final _cyr = RegExp('[\u0400-\u04FF]');

class MergeResult {
  final errors = <String>[];
  final warnings = <String>[];
  final modules = <String>[];
  final arbs = <String, Map<String, Object?>>{};
  int keyCount = 0;

  /// Exact text written to `lib/l10n/app_<lang>.arb`.
  String arbText(String lang) => '${const JsonEncoder.withIndent('  ').convert(arbs[lang])}\n';
}

/// ICU argument used in a message: name -> kind ('plural', 'select', 'simple', ...).
Map<String, String> icuArguments(String msg) {
  final args = <String, String>{};
  var i = 0;
  final n = msg.length;

  void skipWs() {
    while (i < n && msg[i].trim().isEmpty) {
      i++;
    }
  }

  String ident() {
    final s = i;
    while (i < n && RegExp(r'[A-Za-z0-9_]').hasMatch(msg[i])) {
      i++;
    }
    return msg.substring(s, i);
  }

  late void Function(bool nested) message;

  void argument() {
    // at '{'
    i++;
    skipWs();
    final name = ident();
    skipWs();
    if (name.isEmpty) {
      throw FormatException('bad placeholder near "${msg.substring(i - 1)}"');
    }
    if (i < n && msg[i] == '}') {
      i++;
      args.putIfAbsent(name, () => 'simple');
      return;
    }
    if (i >= n || msg[i] != ',') throw FormatException('expected "," or "}" after "$name"');
    i++;
    skipWs();
    final type = ident();
    skipWs();
    if (type == 'plural' || type == 'select' || type == 'selectordinal') {
      args[name] = type;
      if (i >= n || msg[i] != ',') throw FormatException('expected "," after "$type"');
      i++;
      while (true) {
        skipWs();
        if (i >= n) throw const FormatException('unterminated plural/select');
        if (msg[i] == '}') {
          i++;
          return;
        }
        while (i < n && msg[i] != '{' && msg[i].trim().isNotEmpty) {
          i++;
        }
        skipWs();
        if (i >= n || msg[i] != '{') throw const FormatException('expected "{" after a case');
        i++;
        message(true);
      }
    }
    args.putIfAbsent(name, () => type);
    var depth = 1;
    while (i < n && depth > 0) {
      if (msg[i] == '{') depth++;
      if (msg[i] == '}') depth--;
      i++;
    }
  }

  message = (bool nested) {
    while (i < n) {
      final c = msg[i];
      if (c == '{') {
        argument();
      } else if (c == '}') {
        if (nested) {
          i++;
          return;
        }
        throw const FormatException('unbalanced "}"');
      } else {
        i++;
      }
    }
    if (nested) throw const FormatException('unterminated "{"');
  };

  message(false);
  return args;
}

Map<String, Object?>? _readJson(File f, List<String> errors, String label) {
  try {
    final v = jsonDecode(f.readAsStringSync());
    if (v is! Map<String, Object?>) {
      errors.add('$label: not a JSON object');
      return null;
    }
    // jsonDecode silently keeps the last duplicate; catch duplicates textually.
    final text = f.readAsStringSync();
    final seen = <String>{};
    for (final m in RegExp(r'(?:^|[{,])\s*"([^"\\]+)"\s*:', multiLine: true).allMatches(text)) {
      final k = m.group(1)!;
      if (!seen.add(k) && v.containsKey(k)) errors.add('$label: duplicate key "$k" in the file');
    }
    return v;
  } on FormatException catch (e) {
    errors.add('$label: invalid JSON (${e.message})');
    return null;
  }
}

/// Reads and validates every fragment under `<root>/lib/l10n/src`.
MergeResult mergeFragments(String root) {
  final r = MergeResult();
  final src = Directory('$root/lib/l10n/src');
  if (!src.existsSync()) {
    r.errors.add('lib/l10n/src not found');
    return r;
  }
  final modules = src.listSync().whereType<Directory>().map((d) => d.uri.pathSegments
      .where((s) => s.isNotEmpty)
      .last).toList()
    ..sort((a, b) {
      // core first so common keys lead the merged file
      const first = ['core', 'app', 'domain', 'auth'];
      final ia = first.indexOf(a), ib = first.indexOf(b);
      if (ia >= 0 || ib >= 0) return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      return a.compareTo(b);
    });
  r.modules.addAll(modules);
  for (final lang in l10nLanguages) {
    r.arbs[lang] = {'@@locale': lang};
  }
  final owner = <String, String>{}; // key -> module

  for (final m in modules) {
    final frags = <String, Map<String, Object?>>{};
    for (final lang in l10nLanguages) {
      final f = File('${src.path}/$m/$lang.arb');
      final label = 'lib/l10n/src/$m/$lang.arb';
      if (!f.existsSync()) {
        r.errors.add('$label: missing fragment');
        continue;
      }
      final j = _readJson(f, r.errors, label);
      if (j != null) frags[lang] = j;
    }
    final extra = Directory('${src.path}/$m')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.arb') && !l10nLanguages.contains(n.substring(0, n.length - 4)));
    for (final e in extra) {
      r.errors.add('lib/l10n/src/$m/$e: unsupported language (only ${l10nLanguages.join('/')})');
    }
    final ru = frags['ru'];
    if (ru == null) continue;
    final keys = ru.keys.where((k) => !k.startsWith('@')).toList();
    final prefixes = prefixesFor(m);
    for (final k in keys) {
      if (!_keyRe.hasMatch(k)) r.errors.add('$m: key "$k" is not camelCase');
      final okPrefix = prefixes.any((p) =>
          k.startsWith(p) && k.length > p.length && RegExp(r'[A-Z0-9]').hasMatch(k[p.length]));
      if (!okPrefix) r.errors.add('$m: key "$k" must start with ${prefixes.join(' / ')} + Capital');
      final prev = owner[k];
      if (prev != null) {
        r.errors.add('duplicate key "$k" in modules $prev and $m');
      } else {
        owner[k] = m;
      }
    }
    for (final k in ru.keys.where((k) => k.startsWith('@') && !k.startsWith('@@'))) {
      if (!ru.containsKey(k.substring(1))) r.errors.add('$m/ru: metadata "$k" without a message');
    }

    for (final k in keys) {
      final ruVal = ru[k];
      if (ruVal is! String || ruVal.isEmpty) {
        r.errors.add('$m/ru: "$k" is empty or not a string');
        continue;
      }
      Map<String, String> ruArgs;
      try {
        ruArgs = icuArguments(ruVal);
      } on FormatException catch (e) {
        r.errors.add('$m/ru: "$k": ${e.message}');
        continue;
      }
      // metadata for the template: declared one, completed with inferred placeholders
      final declared = ru['@$k'];
      final meta = <String, Object?>{if (declared is Map<String, Object?>) ...declared};
      if (ruArgs.isNotEmpty) {
        final ph = <String, Object?>{
          if (meta['placeholders'] is Map<String, Object?>) ...meta['placeholders']! as Map<String, Object?>,
        };
        for (final a in ruArgs.entries) {
          ph.putIfAbsent(a.key, () => {'type': a.value == 'plural' || a.value == 'selectordinal' ? 'int' : 'String'});
        }
        meta['placeholders'] = ph;
      }
      r.arbs['ru']![k] = ruVal;
      if (meta.isNotEmpty) r.arbs['ru']!['@$k'] = meta;

      for (final lang in l10nLanguages.skip(1)) {
        final fr = frags[lang];
        if (fr == null) continue;
        final v = fr[k];
        if (v == null) {
          r.errors.add('$m/$lang: missing key "$k"');
          continue;
        }
        if (v is! String || v.trim().isEmpty) {
          r.errors.add('$m/$lang: "$k" is empty or not a string');
          continue;
        }
        try {
          final a = icuArguments(v);
          final want = ruArgs.keys.toSet(), got = a.keys.toSet();
          if (want.length != got.length || !want.containsAll(got)) {
            r.errors.add('$m/$lang: "$k" placeholders {${got.join(', ')}} != ru {${want.join(', ')}}');
          }
        } on FormatException catch (e) {
          r.errors.add('$m/$lang: "$k": ${e.message}');
        }
        if ((lang == 'uz' || lang == 'en') && _cyr.hasMatch(v)) {
          r.errors.add('$m/$lang: "$k" contains Cyrillic: $v');
        }
        r.arbs[lang]![k] = v;
      }
    }
    for (final lang in l10nLanguages.skip(1)) {
      final fr = frags[lang];
      if (fr == null) continue;
      for (final k in fr.keys.where((k) => !k.startsWith('@'))) {
        if (!ru.containsKey(k)) r.errors.add('$m/$lang: key "$k" is not in ru');
      }
    }
  }
  r.keyCount = owner.length;
  return r;
}
