import 'package:flutter/material.dart';

/// DreamPOS design tokens. Keep colors/spacing here; features must not
/// hard-code colors except semantic ones from [AppColors].
class AppColors {
  static const brand = Color(0xFF4338CA); // indigo 700
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const danger = Color(0xFFB91C1C);
  static const info = Color(0xFF0369A1);
}

/// Bundled font families (see pubspec `fonts:`).
class AppFonts {
  static const sans = 'Roboto';
  /// Use for receipts, codes, aligned numbers. Never 'monospace' (not a real
  /// family on Windows).
  static const mono = 'RobotoMono';
}

class Gap {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class Breakpoints {
  static const compact = 600.0;
  static const medium = 1000.0;
  static const expanded = 1400.0;
}

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.brand, brightness: b);
  // Bundled Roboto (Apache 2.0): identical Cyrillic typography on all platforms.
  final base = ThemeData(
      colorScheme: scheme, useMaterial3: true, brightness: b, fontFamily: 'Roboto');
  final radius = BorderRadius.circular(12);
  return base.copyWith(
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor:
        b == Brightness.light ? const Color(0xFFF6F7FB) : scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: b == Brightness.light ? Colors.white : scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: b == Brightness.light ? Colors.white : scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: b == Brightness.light ? Colors.white : scheme.surfaceContainerHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      isDense: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: radius)),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, width: 420),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6), space: 1),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: b == Brightness.light ? Colors.white : scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
