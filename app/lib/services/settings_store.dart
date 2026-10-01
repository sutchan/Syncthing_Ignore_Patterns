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
import 'app_paths.dart';

/// Immutable snapshot of the persisted preferences.
class AppSettings {
  const AppSettings({
    this.lang = 'en',
    this.dark = false,
    this.window,
    this.maxDepth = 3,
    this.filterLargeDirs = true,
    this.maxFilesPerDir = 100,
    this.backup = true,
    this.bootCheckAppUpdate = false,
    this.bootCheckRuleset = false,
  });

  /// UI language code, one of `en` / `zh`.
  final String lang;

  /// `true` for the dark theme.
  final bool dark;

  /// Last known window position/size, or `null` when never saved.
  final WindowBounds? window;

  /// Default scan depth (root directory counts as level 1).
  final int maxDepth;

  /// Default: skip sub-directories that hold more than [maxFilesPerDir] entries.
  final bool filterLargeDirs;

  /// Entry threshold used by [filterLargeDirs].
  final int maxFilesPerDir;

  /// Default: back up each target before overwriting it.
  final bool backup;

  /// `true` to check for an app update in the background on startup.
  final bool bootCheckAppUpdate;

  /// `true` to check the ruleset repo in the background on startup.
  final bool bootCheckRuleset;

  Map<String, Object?> toJson() {
    final bounds = window;
    return <String, Object?>{
      'lang': lang,
      'dark': dark,
      if (bounds != null) 'window': bounds.toJson(),
      'maxDepth': maxDepth,
      'filterLargeDirs': filterLargeDirs,
      'maxFilesPerDir': maxFilesPerDir,
      'backup': backup,
      'bootCheckAppUpdate': bootCheckAppUpdate,
      'bootCheckRuleset': bootCheckRuleset,
    };
  }

  /// Rebuilds settings from a decoded JSON object, falling back to defaults
  /// for missing or wrongly-typed fields.
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        lang: json['lang'] is String ? json['lang'] as String : 'en',
        dark: json['dark'] is bool ? json['dark'] as bool : false,
        window: WindowBounds.fromJson(json['window']),
        maxDepth: json['maxDepth'] is int ? json['maxDepth'] as int : 3,
        filterLargeDirs: json['filterLargeDirs'] is bool
            ? json['filterLargeDirs'] as bool
            : true,
        maxFilesPerDir: json['maxFilesPerDir'] is int
            ? json['maxFilesPerDir'] as int
            : 100,
        backup: json['backup'] is bool ? json['backup'] as bool : true,
        bootCheckAppUpdate: json['bootCheckAppUpdate'] is bool
            ? json['bootCheckAppUpdate'] as bool
            : false,
        bootCheckRuleset: json['bootCheckRuleset'] is bool
            ? json['bootCheckRuleset'] as bool
            : false,
      );
}

/// Reads and writes [AppSettings] to `settings.json`.
class SettingsStore {
  /// [directory] overrides the default config directory (used by tests).
  SettingsStore({String? directory}) : _directory = directory;

  final String? _directory;

  /// The directory that holds `settings.json`.
  String get directory => _directory ?? defaultDataDirectory();

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

  /// Tail of the write queue, so overlapping saves are applied in order.
  Future<void> _queue = Future<void>.value();

  /// Writes [settings] once any pending write has finished.
  ///
  /// Failures are swallowed since preferences are best-effort and must never
  /// break the app. Serialising matters: a language/theme change and the window
  /// geometry sampler can save within the same tick, and interleaved
  /// `writeAsString` calls can leave an *older* snapshot (or a half-written
  /// file) on disk, which silently loses the user's choice.
  Future<void> save(AppSettings settings) {
    final next = _queue.then((_) => _write(settings));
    _queue = next;
    return next;
  }

  /// Completes once every queued write has finished. Lets callers (mainly
  /// tests) wait for the serialised saves to land without polling the file.
  Future<void> get idle => _queue;

  Future<void> _write(AppSettings settings) async {
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(settings.toJson()),
        flush: true,
      );
    } on Exception {
      // Best-effort persistence.
    }
  }
}
