/// Busy flag, progress, status line and results list.
///
/// Shared bookkeeping for the scan and apply flows; mixed into `AppState`.
library;

import 'package:flutter/foundation.dart';

mixin ProgressState on ChangeNotifier {
  /// `true` while a scan/apply is running.
  bool isBusy = false;

  /// Set by [AppState.stop] and checked at the flow's checkpoints.
  bool cancelled = false;

  /// Progress in `0..1`, or `null` for indeterminate.
  double? progress;

  /// One-line status shown under the progress bar.
  String status = '';

  /// Localized summary of the last finished operation.
  String summary = '';

  /// Paths found by the last scan.
  final List<String> results = [];

  DateTime? _start;

  /// Marks an operation as started and clears the previous results.
  void begin() {
    cancelled = false;
    isBusy = true;
    progress = null;
    _start = DateTime.now();
    results.clear();
    notifyListeners();
  }

  /// Marks the running operation as finished.
  void finish() {
    isBusy = false;
    progress = 1;
    _start = null;
    notifyListeners();
  }

  /// Elapsed time since [begin], formatted `mm:ss` (`h:mm:ss` past an hour).
  String elapsed() {
    final start = _start;
    if (start == null) return '00:00';
    final ts = DateTime.now().difference(start);
    final seconds = ts.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = ts.inMinutes.remainder(60).toString().padLeft(2, '0');
    return ts.inHours >= 1 ? '${ts.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }
}
