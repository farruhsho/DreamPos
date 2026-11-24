// Login + setup wizard screenshots. Run: SCREENSHOTS=1 flutter test test/ux/auth_screens_test.dart
import 'package:dreampos/core/providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('login and setup screens', (tester) async {
    final h = await UxHarness.start(tester);
    for (final size in uxSizes.keys) {
      h.setSize(size);
      h.container.read(sessionProvider.notifier).logout();
      await h.settle(8);
      await h.shot('login');
    }
    // setup wizard: pretend setup not done
    await tester.runAsync(() => h.db.setSetting('setup_done', '0'));
    h.container.invalidate(setupDoneProvider);
    await h.settle(8);
    for (final size in uxSizes.keys) {
      h.setSize(size);
      await h.settle();
      await h.shot('setup_step1');
    }
    await h.finish();
  }, skip: !screenshotsEnabled, timeout: const Timeout(Duration(minutes: 5)));
}
