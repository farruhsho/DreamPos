import 'dart:io';

import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ux/harness.dart';

const _sections = ['store', 'currency', 'sales', 'loyalty', 'devices', 'appearance', 'backup', 'data', 'about'];

void main() {
  testWidgets('settings ux screens', skip: !screenshotsEnabled, (tester) async {
    // Plugins are not registered in tests: fake prefs (device register) and
    // path_provider (backups dir) so sections render their real content.
    SharedPreferences.setMockInitialValues({});
    final tmp = Directory.systemTemp.createTempSync('dreampos_ux_settings');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => tmp.path,
    );
    final h = await UxHarness.start(tester);
    // Finders use the run's language (SCREENSHOTS_LOCALE), ru by default.
    final l = L.of(h.locale);
    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f.first);
      await h.settle(2);
      await tester.tap(f.first);
      await h.settle();
    }

    void hideSnack() => ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).removeCurrentSnackBar();

    Future<void> scroll(double dy) async {
      final sz = uxSizes[h.sizeName]!;
      await tester.dragFrom(Offset(sz.width * 0.7, sz.height * 0.55), Offset(0, dy));
      await h.settle();
    }

    for (final size in ['desktop', 'tablet']) {
      h.setSize(size);
      await h.go('/settings');
      for (final s in _sections) {
        await tap(find.byKey(ValueKey('nav-$s')));
        if (s == 'backup' || s == 'about') await h.settle(10); // file IO
        await h.shot('settings_$s');
        if (s == 'backup' && size == 'desktop') {
          await tap(find.text(l.settingsBackupCreateNow));
          await h.settle(10);
          await h.shot('settings_backup_created');
          hideSnack();
          await h.settle();
        }
        if (s == 'store' || s == 'devices') {
          // scroll to the bottom for the receipt preview / printer card
          await scroll(-2000);
          await h.settle();
          await h.shot('settings_${s}_bottom');
        }
        if (s == 'devices' && size == 'desktop') {
          final add = find.text(l.commonAdd);
          if (add.evaluate().isNotEmpty) {
            await scroll(3000);
            await h.settle();
            await tap(add);
            await h.shot('settings_devices_add_dialog');
            final cancel = find.text(l.commonCancel);
            if (cancel.evaluate().isNotEmpty) await tap(cancel);
          }
        }
      }
      // dirty store form -> save bar. The section list is longer since the
      // «Синхронизация» section (D-025): «Магазин» may be scrolled out of the
      // lazily built nav list after «О программе», so open the screen afresh.
      await h.go('/');
      await h.go('/settings');
      await tap(find.byKey(const ValueKey('nav-store')));
      await tester.enterText(find.byType(TextFormField).first, 'Магазин «Ташкент Маркет» 2');
      await h.settle();
      await h.shot('settings_store_dirty');
      await tap(find.text(l.settingsCancelVerb));
    }

    h.setSize('phone');
    await h.go('/settings');
    await h.shot('settings_list');
    for (final s in _sections) {
      await tap(find.byKey(ValueKey('nav-$s')));
      if (s == 'backup' || s == 'about') await h.settle(10);
      await h.shot('settings_$s');
      if (s == 'devices') {
        await tap(find.text(l.commonAdd));
        await h.shot('settings_devices_add_dialog');
        await tap(find.text(l.commonCancel));
      }
      if (s == 'backup') {
        await tap(find.text(l.settingsBackupCreateNow));
        await h.settle(10);
        hideSnack();
        await h.settle();
        await h.shot('settings_backup_created');
      }
      if (s == 'store' || s == 'devices' || s == 'sales' || s == 'currency' || s == 'backup' || s == 'about') {
        await scroll(-2500);
        await h.settle();
        await h.shot('settings_${s}_bottom');
      }
      if (s == 'store') {
        await scroll(4000);
        await h.settle();
        await tester.enterText(find.byType(TextFormField).first, 'Магазин 2');
        await h.settle();
        await h.shot('settings_store_dirty');
        await tap(find.text(l.settingsCancelVerb));
      }
      await Navigator.of(tester.element(find.byType(Scaffold).last)).maybePop();
      await h.settle();
    }
    await h.finish();
  });
}
