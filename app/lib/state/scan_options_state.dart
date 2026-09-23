/// Scan/apply option flags and scan-depth settings.
///
/// Split out of the application state so each file stays focused; mixed into
/// `AppState`. Options are session-scoped (not persisted).
library;

import 'package:flutter/foundation.dart';

/// Preview / force / backup flags plus the depth and directory-filter settings.
mixin ScanOptionsState on ChangeNotifier {
  bool _preview = false;
  bool _force = false;
  bool _backup = true;
  int _maxDepth = 3;
  bool _filterLargeDirs = true;
  int _maxFilesPerDir = 100;

  /// Preview only: no files are written.
  bool get preview => _preview;

  /// Force: also clean stale (source-deleted) paths.
  bool get force => _force;

  /// Back up each target before overwriting it.
  bool get backup => _backup;

  /// Maximum scan depth; the root directory counts as level 1.
  int get maxDepth => _maxDepth;

  /// Skip sub-directories that hold more than [maxFilesPerDir] entries.
  bool get filterLargeDirs => _filterLargeDirs;

  /// Entry threshold used by [filterLargeDirs].
  int get maxFilesPerDir => _maxFilesPerDir;

  void setPreview(bool value) {
    if (_preview == value) return;
    _preview = value;
    notifyListeners();
  }

  void setForce(bool value) {
    if (_force == value) return;
    _force = value;
    notifyListeners();
  }

  void setBackup(bool value) {
    if (_backup == value) return;
    _backup = value;
    notifyListeners();
  }

  void setMaxDepth(int value) {
    final clamped = value.clamp(1, 10);
    if (_maxDepth == clamped) return;
    _maxDepth = clamped;
    notifyListeners();
  }

  void setFilterLargeDirs(bool value) {
    if (_filterLargeDirs == value) return;
    _filterLargeDirs = value;
    notifyListeners();
  }

  void setMaxFilesPerDir(int value) {
    final clamped = value < 1 ? 1 : value;
    if (_maxFilesPerDir == clamped) return;
    _maxFilesPerDir = clamped;
    notifyListeners();
  }
}
