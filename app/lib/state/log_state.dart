/// Log entries and the in-memory log buffer.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

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
    _logs = [..._logs, LogEntry(message, level)];
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
}
