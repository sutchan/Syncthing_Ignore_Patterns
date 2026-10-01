/// Log entries and the in-memory log buffer.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;

import '../i18n.dart';

/// A single line in the log view.
class LogEntry {
  const LogEntry(this.text, this.level);

  final String text;

  /// One of `info`, `warn`, `error` or `muted`.
  final String level;
}

/// Maximum number of log lines kept in memory. A long Apply run can emit one
/// line per touched file; without a cap the buffer (and the log view) would
/// grow without bound. Only the newest lines are retained.
const int maxLogEntries = 1000;

/// Owns the log buffer; mixed into `AppState`.
mixin LogState on ChangeNotifier {
  /// Localizations provider, supplied by the preferences mixin.
  AppLocalizations get loc;

  /// Appended-to log, oldest first.
  ///
  /// A fresh list instance is assigned on every append/clear (instead of
  /// mutating in place) so `context.select((s) => s.logs)` subscribers detect
  /// the change by identity without a deep comparison.
  List<LogEntry> get logs => _logs;
  List<LogEntry> _logs = const [];

  /// Whether a frame-coalesced notification is already pending.
  bool _notifyScheduled = false;

  void clearLog() {
    _logs = const [];
    notifyListeners();
  }

  void log(String message, String level) {
    final next = List<LogEntry>.of(_logs)
      ..add(LogEntry(message, level));
    // Ring-buffer cap: drop the oldest lines once the limit is exceeded.
    if (next.length > maxLogEntries) {
      next.removeRange(0, next.length - maxLogEntries);
    }
    _logs = next;
    _scheduleNotify();
  }

  /// Translates the raw `key::arg` strings emitted by the applier into
  /// localized, coloured log lines.
  void logTranslated(String raw, String level) {
    final parts = raw.split('::');
    log(loc.t(parts.first, parts.skip(1).toList()), level);
  }

  /// Fires at most one `notifyListeners()` per frame.
  ///
  /// During Apply the applier can emit hundreds of lines (one per touched
  /// file); notifying synchronously per line rebuilds the whole subscribed
  /// widget subtree hundreds of times. Coalescing to one notification per
  /// frame keeps the log live while cutting rebuilds to ≤60/s.
  ///
  /// main() calls `WidgetsFlutterBinding.ensureInitialized()`, so the binding
  /// exists in the real app and in `testWidgets`; a plain `test()` that does
  /// not initialize it falls back to a synchronous notification.
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    final SchedulerBinding binding;
    try {
      binding = SchedulerBinding.instance;
    } on Object {
      notifyListeners();
      return;
    }
    _notifyScheduled = true;
    binding.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  /// Persists the current log buffer to a timestamped `.txt` file in the
  /// system temp directory and returns its path, or `null` on failure.
  ///
  /// Lets users export logs for offline troubleshooting (PROP-17).
  Future<String?> exportLog() async {
    try {
      final dir = await Directory.systemTemp.createTemp('stignore_log_');
      final file = File(p.join(dir.path, 'stignore_log_${_logStamp()}.txt'));
      await file.writeAsString(logs.map((e) => e.text).join('\n'));
      return file.path;
    } on Object catch (e) {
      log('${loc.t('exportLogFailed')}: $e', 'error');
      return null;
    }
  }

  String _logStamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
