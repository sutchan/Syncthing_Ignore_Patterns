/// Persists user preferences (language + theme) as a small JSON file.
///
/// Uses only `dart:io` so no extra dependency is needed and the logic stays
/// unit-testable. The file lives in the per-user config directory
/// (`%APPDATA%\SyncthingIgnoreGUI\settings.json` on Windows).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/window_bounds.dart';

/// Immutable snapshot of the persisted preferences.
class AppSettings {
  const AppSettings({this.lang = 'en', this.dark = false, this.window});

  /// UI language code, one of `en` / `zh`.
  final String lang;

  /// `true` for the dark theme.
  final bool dark;

  /// Last known window position/size, or `null` when never saved.
  final WindowBounds? window;

  Map<String, Object?> toJson() {
    final bounds = window;
    return <String, Object?>{
      'lang': lang,
      'dark': dark,
      if (bounds != null) 'window': bounds.toJson(),
    };
  }

  /// Rebuilds settings from a decoded JSON object, falling back to defaults
  /// for missing or wrongly-typed fields.
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        lang: json['lang'] is String ? json['lang'] as String : 'en',
        dark: json['dark'] is bool ? json['dark'] as bool : false,
        window: WindowBounds.fromJson(json['window']),
      );
}

/// Reads and writes [AppSettings] to `settings.json`.
class SettingsStore {
  /// [directory] overrides the default config directory (used by tests).
  SettingsStore({String? directory}) : _directory = directory;

  final String? _directory;

  /// The directory that holds `settings.json`.
  String get directory {
    final override = _directory;
    if (override != null) return override;
    final env = Platform.environment;
    if (Platform.isWindows) {
      final appData = env['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return p.join(appData, 'SyncthingIgnoreGUI');
      }
    }
    final home = env['HOME'] ?? env['USERPROFILE'] ?? Directory.systemTemp.path;
    return p.join(home, '.syncthing_ignore_gui');
  }

  /// Absolute path of the settings file.
  String get path => p.join(directory, 'settings.json');

  /// Loads preferences, returning defaults when the file is absent or corrupt.
  Future<AppSettings> load() async {
    try {
      final file = File(path);
      if (!await file.exists()) return const AppSettings();
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) return AppSettings.fromJson(decoded);
    } on Exception {
      // Unreadable or corrupt file: fall back to defaults.
    }
    return const AppSettings();
  }

  /// Writes [settings]; failures are swallowed since preferences are
  /// best-effort and must never break the app.
  Future<void> save(AppSettings settings) async {
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(settings.toJson()),
      );
    } on Exception {
      // Best-effort persistence.
    }
  }
}
