// Applies to every test file: the UI and receipt languages start as ru, so
// tests that find widgets by Russian text never depend on test order.
import 'dart:async';

import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(L.reset);
  await testMain();
}
