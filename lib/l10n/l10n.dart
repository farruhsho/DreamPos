// Localization entry point. See docs/L10N.md.
//
// - In widgets: `context.l10n.commonSave`.
// - Outside widgets (domain errors, PDF, CSV, notifications): `L.current.xxx`
//   (the UI language; ru until the app sets another one).
// - Printed receipts / slips / Z report: `L.receipt` or `L.forReceipt(settings)`
//   (store setting `receipt_locale`, default ru).
import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// UI languages in picker order. Tajik is not supported.
const supportedLanguageCodes = <String>['ru', 'uz', 'ky', 'en'];

/// Native language names for pickers (never translated).
const languageNativeNames = <String, String>{
  'ru': 'Русский',
  'uz': 'Oʻzbekcha',
  'ky': 'Кыргызча',
  'en': 'English',
};

/// Short labels for the compact login-screen chip.
const languageShortNames = <String, String>{'ru': 'RU', 'uz': 'UZ', 'ky': 'KY', 'en': 'EN'};

abstract final class L {
  static final Map<String, AppLocalizations> _cache = {};

  /// Normalizes a stored/requested code to a supported one (default `ru`).
  static String normalize(String? code) {
    final c = (code ?? '').trim().toLowerCase().split(RegExp('[-_]')).first;
    return supportedLanguageCodes.contains(c) ? c : 'ru';
  }

  /// Localizations for a language code (unsupported -> ru).
  static AppLocalizations of(String? code) {
    final c = normalize(code);
    return _cache[c] ??= lookupAppLocalizations(Locale(c));
  }

  /// UI language for code outside the widget tree. Kept in sync with
  /// `uiLocaleProvider` by the app; ru by default (tests stay Russian).
  static AppLocalizations current = of('ru');

  /// Language of printed customer documents (store setting `receipt_locale`).
  static AppLocalizations receipt = of('ru');

  static void setCurrent(String? code) => current = of(code);
  static void setReceipt(String? code) => receipt = of(code);

  /// Receipt language from a settings map (`receipt_locale`), for printing
  /// code that already loaded the settings.
  static AppLocalizations forReceipt(Map<String, String> settings) => of(settings['receipt_locale']);

  /// Resets both to ru (for tests).
  static void reset() {
    current = of('ru');
    receipt = of('ru');
  }

  /// Text for PDF/thermal output: ʻ/ʼ (Uzbek oʻ gʻ and ʼ) become ‘ and ’, which
  /// every printer code page and font has. The bundled Roboto fonts cover U+02BB
  /// (patched in, see tool/patch_fonts_02bb.py) for on-screen text.
  static String printable(String s) => s.replaceAll('ʻ', '‘').replaceAll('ʼ', '’');
}

extension L10nContext on BuildContext {
  /// Localized strings. Falls back to [L.current] when no
  /// AppLocalizations delegate is above (bare MaterialApp in tests).
  AppLocalizations get l10n => Localizations.of<AppLocalizations>(this, AppLocalizations) ?? L.current;
}
