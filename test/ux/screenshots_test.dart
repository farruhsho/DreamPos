// Captures every main screen at desktop, tablet and phone sizes.
// Run: SCREENSHOTS=1 flutter test test/ux/screenshots_test.dart
// Optional: SCREENSHOTS_DIR=<dir>, SCREENSHOTS_ROUTES=/pos,/sales
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const allRoutes = [
  '/dashboard', '/pos', '/sales', '/shifts', '/products', '/inventory', '/purchasing',
  '/customers', '/marketing', '/warranty', '/reports', '/staff', '/settings', '/notifications',
];

void main() {
  testWidgets('capture main screens', (tester) async {
    final filter = Platform.environment['SCREENSHOTS_ROUTES'];
    final routes = filter == null ? allRoutes : filter.split(',');
    final h = await UxHarness.start(tester);
    final problems = <String>[];
    for (final size in uxSizes.keys) {
      h.setSize(size);
      await h.settle();
      for (final r in routes) {
        await h.go(r);
        final errs = await h.shot(r.substring(1));
        if (errs.isNotEmpty) problems.add('$size $r: ${errs.first.split('\n').first}');
      }
    }
    await h.finish();
    // ignore: avoid_print
    print(problems.isEmpty ? 'RENDER OK' : 'RENDER PROBLEMS:\n${problems.join('\n')}');
  }, skip: !screenshotsEnabled, timeout: const Timeout(Duration(minutes: 10)));
}
