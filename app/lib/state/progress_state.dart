/// Busy flag, progress, status line and results list.
///
/// Shared bookkeeping for the scan and apply flows; mixed into `AppState`.
library;

import 'package:flutter/foundation.dart';

/// Maximum number of scan-result paths kept in memory for the results view.
///
/// This is a display-only buffer: Apply reads targets from the manifest file
/// on disk, which always keeps the full record set. Capping the in-memory list
/// prevents a scan of a very large tree from growing the UI state without
/// bound. Only the most recently scanned paths are retained.
const int maxResultEntries = 5000;

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
  ///
  /// A fresh list instance is assigned on every change (rather than mutating
  /// in place) so `context.select((s) => s.results)` subscribers can detect
  /// the update by identity without a deep list comparison.
  List<String> get results => _results;
  List<String> _results = [];

  /// Replaces the result paths. Called by the scan flow after a scan or when
  /// an existing manifest is loaded at startup. The list is capped to
  /// [maxResultEntries] newest entries for the UI; the manifest on disk keeps
  /// every record.
  void replaceResults(Iterable<String> paths) {
    final list = paths.toList();
    if (list.length > maxResultEntries) {
      list.removeRange(0, list.length - maxResultEntries);
    }
    _results = list;
  }

  DateTime? _start;

  /// Marks an operation as started and clears the previous results.
  void begin() {
    cancelled = false;
    isBusy = true;
    progress = null;
    _start = DateTime.now();
    _results = [];
    notifyListeners();
  }

  /// Marks the running operation as finished.
  void finish() {
    isBusy = false;
    progress = 1;
    _start = null;
    notifyListeners();
  }

  /// Elapsed seconds since [begin].
  int get elapsedSeconds {
    final start = _start;
    return start == null ? 0 : DateTime.now().difference(start).inSeconds;
  }

  /// Elapsed time since [begin], formatted `mm:ss` (`h:mm:ss` past an hour).
  String elapsed() => formatDuration(elapsedSeconds);

  /// Formats a duration in seconds as `mm:ss` (`h:mm:ss` past an hour).
  String formatDuration(int totalSeconds) {
    final seconds = totalSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = (totalSeconds ~/ 60).remainder(60).toString().padLeft(2, '0');
    return totalSeconds >= 3600
        ? '${totalSeconds ~/ 3600}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
