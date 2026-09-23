/// Log entries and the in-memory log buffer.
library;

import 'package:flutter/foundation.dart';

import '../i18n.dart';

/// A single line in the log view.
class LogEntry {
  const LogEntry(this.text, this.level);

  final String text;

  /// One of `info`, `warn`, `error` or `muted`.
  final String level;
}

/// Owns the log buffer; mixed into `AppState`.
mixin LogState on ChangeNotifier {
  /// Localizations provider, supplied by the preferences mixin.
  AppLocalizations get loc;

  /// Appended-to log, oldest first.
  final List<LogEntry> logs = [];

  void clearLog() {
    logs.clear();
    notifyListeners();
  }

  void log(String message, String level) {
    logs.add(LogEntry(message, level));
    notifyListeners();
  }

  /// Translates the raw `key::arg` strings emitted by the applier into
  /// localized, coloured log lines.
  void logTranslated(String raw, String level) {
    final parts = raw.split('::');
    log(loc.t(parts.first, parts.skip(1).toList()), level);
  }
}
