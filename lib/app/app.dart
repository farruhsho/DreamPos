import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import 'router.dart';

class DreamPosApp extends ConsumerWidget {
  const DreamPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // keep settings (and Money.currency) live for the whole app
    ref.watch(settingsProvider);
    final lang = ref.watch(uiLocaleProvider); // also keeps L.current in sync
    ref.watch(receiptLocaleProvider); // keeps L.receipt in sync
    final router = ref.watch(routerProvider);
    final setup = ref.watch(setupDoneProvider);
    final themeMode = switch (ref.watch(settingProvider('theme_mode'))) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    return MaterialApp.router(
      title: 'DreamPOS',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      locale: Locale(lang),
      // ru/uz/ky/en are all covered by GlobalMaterial/Cupertino/Widgets
      // localizations (flutter_localizations), so no fallback delegate is needed.
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => setup.isLoading
          ? const Material(child: Center(child: CircularProgressIndicator()))
          : child!,
    );
  }
}
