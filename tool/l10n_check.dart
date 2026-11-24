// Lists Cyrillic string literals left in lib/ (hard-coded UI text).
//
//   dart run tool/l10n_check.dart                 # all of lib/ except folders in tool/l10n_pending.txt
//   dart run tool/l10n_check.dart --all           # all of lib/, pending folders included
//   dart run tool/l10n_check.dart --module pos    # only lib/features/pos (core/app/domain -> lib/<m>, auth -> lib/features/auth)
//   dart run tool/l10n_check.dart --path lib/features/pos/widgets
//
// Exits 1 when something is found. Skipped: lib/l10n/**, generated files
// (*.g.dart, *.freezed.dart), comments, lines ending with `// l10n-ignore`
// and entries of tool/l10n_allow.txt (see that file for the format).
import 'dart:io';

import 'l10n_check_lib.dart';

void main(List<String> args) {
  String? onlyPath;
  var all = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--module':
        onlyPath = modulePath(args[++i]);
      case '--path':
        onlyPath = args[++i];
      case '--all':
        all = true;
      case '-h' || '--help':
        stdout.writeln('usage: dart run tool/l10n_check.dart [--all] [--module <name>] [--path <dir>]');
        exit(0);
      default:
        stderr.writeln('unknown argument: ${args[i]}');
        exit(2);
    }
  }
  final findings = findCyrillicLiterals(
    root: Directory.current.path,
    onlyPath: onlyPath,
    skipPending: onlyPath == null && !all,
  );
  for (final f in findings) {
    stdout.writeln(f);
  }
  final files = findings.map((f) => f.file).toSet().length;
  if (findings.isEmpty) {
    stdout.writeln('l10n_check: OK (no Cyrillic literals)');
    exit(0);
  }
  stdout.writeln('l10n_check: ${findings.length} Cyrillic literal(s) in $files file(s)');
  exit(1);
}
