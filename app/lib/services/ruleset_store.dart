/// Reads and writes the on-disk ruleset (`.stignore`) copies.
///
/// Two locations are used, in priority order:
///
///  1. next to the executable — the application directory always ships the
///     ruleset, and updates are written back there while it stays writable;
///  2. the per-user data directory (`%APPDATA%\SyncthingIgnoreGUI`) — used when
///     the application directory is read-only (e.g. installed under
///     `Program Files`).
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_paths.dart';

class RulesetStore {
  /// [directory] redirects *both* locations into one folder, which keeps tests
  /// hermetic and off the real installation.
  RulesetStore({String? directory}) : _override = directory;

  final String? _override;

  /// Directory holding the executable.
  String get appDirectory =>
      _override ?? p.dirname(Platform.resolvedExecutable);

  /// Per-user data directory used as the fallback location.
  String get dataDirectory => _override ?? defaultDataDirectory();

  /// `true` when an override collapses both locations into one folder.
  bool get isOverridden => _override != null;

  /// Ruleset shipped next to the executable.
  String get appPath => p.join(appDirectory, '.stignore');

  /// Downloaded ruleset cache.
  String get cachePath => p.join(dataDirectory, '.stignore');

  /// Locations consulted when loading, most trusted first.
  List<String> get candidates {
    final paths = <String>[appPath];
    if (cachePath != appPath) paths.add(cachePath);
    return paths;
  }

  /// Path shown in the UI as "where the ruleset lives".
  String get primaryPath => candidates.first;

  /// Returns the first readable, non-empty ruleset, or `null` when none exist.
  Future<String?> read() async {
    for (final path in candidates) {
      final content = await _readIfPresent(path);
      if (content != null && content.trim().isNotEmpty) return content;
    }
    return null;
  }

  /// Persists [content], preferring the application directory; returns the path
  /// actually written. Throws when no location accepts the write.
  Future<String> write(String content) async {
    final failures = <String>[];
    for (final path in candidates) {
      try {
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsString(content, flush: true);
        return path;
      } on Exception catch (e) {
        failures.add('$path -> $e');
      }
    }
    throw FileSystemException(
      'failed to write the ruleset',
      failures.join(' | '),
    );
  }

  Future<String?> _readIfPresent(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } on Exception {
      return null; // unreadable file: fall through to the next candidate
    }
  }
}
