/// Localization string tables for the GUI.
///
/// Mirrors the `$T` ordered dictionaries in the original PowerShell script
/// (en + zh). The per-language maps live in `i18n_en.dart` / `i18n_zh.dart`;
/// this file only assembles them so each table stays under the 200-line limit
/// and the `AppLocalizations.t` formatter in `i18n.dart` stays small.
library;

import 'i18n_en.dart';
import 'i18n_zh.dart';

const Map<String, Map<String, String>> i18nStrings = {
  'en': i18nEn,
  'zh': i18nZh,
};
