// Merges lib/l10n/src/<module>/<lang>.arb fragments into lib/l10n/app_<lang>.arb
// and regenerates lib/l10n/gen/*.dart with `flutter gen-l10n`.
//
//   dart run tool/l10n_merge.dart            # validate + merge + gen-l10n
//   dart run tool/l10n_merge.dart --check    # validate only (no files written)
//
// Validations (any failure -> exit 1, nothing written): duplicate key, key
// missing/extra in a language, placeholder mismatch, empty value, key not
// camelCase or without the module prefix, Cyrillic in uz/en values, bad JSON.
//
// Safe to run while other agents edit other fragments: runs are serialized by
// a lock file (build/l10n_merge.lock), gen-l10n runs in a private temp
// directory (outside the project, so analyzers never see half-written files),
// and the ARBs and generated files are then moved into lib/l10n one by one
// (temp file + rename), only when their content changed.
import 'dart:io';

import 'l10n_merge_lib.dart';

Future<void> main(List<String> args) async {
  final checkOnly = args.contains('--check');
  final root = Directory.current.path.replaceAll('\\', '/');
  final lock = await _acquireLock('$root/build/l10n_merge.lock');
  Directory? work;
  try {
    final result = mergeFragments(root);
    for (final w in result.warnings) {
      stdout.writeln('warning: $w');
    }
    if (result.errors.isNotEmpty) {
      for (final e in result.errors) {
        stderr.writeln('error: $e');
      }
      stderr.writeln('l10n_merge: ${result.errors.length} error(s), nothing written');
      exitCode = 1;
      return;
    }
    stdout.writeln('l10n_merge: ${result.keyCount} keys x ${l10nLanguages.length} languages, '
        '${result.modules.length} modules OK');
    if (checkOnly) return;

    work =Directory.systemTemp.createTempSync('dreampos_l10n_');
    Directory('${work.path}/lib/l10n').createSync(recursive: true);
    File('$root/l10n.yaml').copySync('${work.path}/l10n.yaml');
    File('${work.path}/pubspec.yaml').writeAsStringSync(_workPubspec);
    final arbTexts = <String, String>{};
    for (final lang in l10nLanguages) {
      final text = result.arbText(lang);
      arbTexts[lang] = text;
      File('${work.path}/lib/l10n/app_$lang.arb').writeAsStringSync(text);
    }

    final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
    final gen = await Process.run(flutter, ['gen-l10n', '--project-dir', work.path],
        workingDirectory: work.path, runInShell: Platform.isWindows);
    if (gen.exitCode != 0) {
      stderr
        ..writeln(gen.stdout)
        ..writeln(gen.stderr)
        ..writeln('l10n_merge: flutter gen-l10n failed (exit ${gen.exitCode})');
      exitCode = 1;
      return;
    }
    // gen-l10n succeeded: publish ARBs and generated Dart.
    var changedArb = 0;
    for (final e in arbTexts.entries) {
      if (_writeAtomic('$root/lib/l10n/app_${e.key}.arb', e.value)) changedArb++;
    }
    final genOut = Directory('${work.path}/lib/l10n/gen');
    final dest = Directory('$root/lib/l10n/gen')..createSync(recursive: true);
    var changedGen = 0;
    final produced = <String>{};
    for (final f in genOut.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      produced.add(name);
      if (_writeAtomic('${dest.path}/$name', f.readAsStringSync())) changedGen++;
    }
    for (final f in dest.listSync().whereType<File>()) {
      if (!produced.contains(f.uri.pathSegments.last)) f.deleteSync();
    }
    stdout.writeln('l10n_merge: wrote $changedArb ARB and $changedGen generated file(s)');
  } finally {
    try {
      work?.deleteSync(recursive: true);
    } catch (_) {}
    try {
      lock.deleteSync();
    } catch (_) {}
  }
}

const _workPubspec = '''
name: dreampos_l10n_work
publish_to: none
environment:
  sdk: ^3.10.0
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
flutter:
  generate: true
''';

/// Writes [text] to a sibling temp file and renames it over [path].
/// Returns false (and writes nothing) when the content is unchanged.
bool _writeAtomic(String path, String text) {
  final f = File(path);
  if (f.existsSync() && f.readAsStringSync() == text) return false;
  final tmp = File('$path.$pid.tmp');
  tmp.writeAsStringSync(text, flush: true);
  for (var attempt = 0;; attempt++) {
    try {
      tmp.renameSync(path);
      return true;
    } on FileSystemException {
      // Windows: the target may be briefly open by an analyzer/IDE.
      if (attempt >= 20) rethrow;
      sleep(const Duration(milliseconds: 250));
    }
  }
}

Future<File> _acquireLock(String path) async {
  final f = File(path);
  f.parent.createSync(recursive: true);
  final deadline = DateTime.now().add(const Duration(minutes: 10));
  var told = false;
  while (true) {
    try {
      f.createSync(exclusive: true);
      f.writeAsStringSync('$pid ${DateTime.now().toIso8601String()}');
      return f;
    } on FileSystemException {
      // Stale lock (crashed run) older than 5 minutes -> take it over.
      try {
        if (DateTime.now().difference(f.lastModifiedSync()) > const Duration(minutes: 5)) {
          f.deleteSync();
          continue;
        }
      } catch (_) {}
      if (DateTime.now().isAfter(deadline)) {
        stderr.writeln('l10n_merge: could not acquire $path');
        exit(1);
      }
      if (!told) {
        stdout.writeln('l10n_merge: waiting for another merge to finish...');
        told = true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
}
