/// Localization for the GUI. Mirrors the `$T` ordered dictionaries in the
/// original PowerShell script (en + zh). Keys are identical so messages stay
/// in sync across both implementations. The string tables live in
/// `i18n_strings.dart`.
library;

import 'i18n_strings.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  /// Supported locales: 'en' and 'zh'.
  final String locale;

  static const List<String> supported = ['en', 'zh'];

  /// Returns the localized string for [key], with `{0}`, `{1}`... placeholders
  /// filled by [args] (mirrors PowerShell `-f` formatting).
  String t(String key, [List<Object> args = const []]) {
    var s = i18nStrings[locale]?[key] ?? i18nStrings['en']?[key] ?? key;
    for (var i = 0; i < args.length; i++) {
      s = s.replaceAll('{$i}', args[i].toString());
    }
    return s;
  }
}
