/// Scan flow: walks the configured roots and writes the manifest.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:flutter/foundation.dart';

import '../models/manifest.dart';
import '../services/platform_io.dart';
import '../services/rules_source.dart';
import '../services/scanner.dart';
import 'log_state.dart';
import 'pickers_state.dart';
import 'preferences_state.dart';
import 'progress_state.dart';
import 'ruleset_state.dart';
import 'scan_options_state.dart';

mixin ScanFlow on ChangeNotifier,
    ProgressState,
    PreferencesState,
    LogState,
    ScanOptionsState,
    PickersState,
    RulesetUpdateState {
  /// Application version, provided by the composing class.
  String get version;

  /// The running executable's directory, excluded from scanning.
  String get appDirectory => p.dirname(Platform.resolvedExecutable);

  /// Per-result compliance with the effective ruleset: `true` when a file
  /// already matches the standard rules (Apply would skip it). Empty until
  /// computed after a scan finishes.
  Map<String, bool> _compliance = const {};

  /// Path → `true` when it already matches the effective ruleset.
  Map<String, bool> get compliance => _compliance;

  /// Number of scanned files that would change if Apply were run now.
  int get needsApplyCount => _compliance.values.where((v) => !v).length;

  /// Number of scanned files already compliant with the effective ruleset.
  int get compliantCount => _compliance.values.where((v) => v).length;

  /// Resolves the roots to scan: the typed root (normalized), or every local
  /// and network-mapped drive when blank.
  List<String> _resolveRoots() {
    final paths = rootPaths;
    if (paths.isEmpty) return listScanDrives();
    final resolved = <String>[];
    for (final raw in paths) {
      final root = normalizeRootPath(raw);
      if (root.isEmpty) continue;
      if (FileSystemEntity.isDirectorySync(root)) {
        resolved.add(root);
      } else {
        throw Exception(loc.t('rootNotFound', [root]));
      }
    }
    if (resolved.isEmpty) throw Exception(loc.t('rootNotFound', [rootText]));
    return resolved;
  }

  Future<void> scan() async {
    begin();
    status = loc.t('statusPrep');
    notifyListeners();
    List<String> roots;
    try {
      roots = _resolveRoots();
    } on Exception catch (e) {
      finish();
      log(e.toString(), 'error');
      return;
    }

    log('${loc.t('ready')} (${roots.length} roots)', 'info');
    try {
      final records = await scanRoots(
        roots,
        maxThreads: 4,
        skipDir: appDirectory,
        maxDepth: maxDepth,
        maxFilesPerDir: maxFilesPerDir,
        skipLargeDirs: filterLargeDirs,
        onProgress: _reportScanProgress,
        isCancelled: () => cancelled,
      );
      if (cancelled) {
        status = loc.t('statusStopped');
        finish();
        log(loc.t('stopped'), 'warn');
        return;
      }
      final manifest = Manifest(
        version: version,
        scannedAt: DateTime.now().toUtc().toIso8601String(),
        roots: roots,
        files: records,
      );
      final out = File(manifestPath);
      await out.parent.create(recursive: true);
      await out.writeAsString(
          const JsonEncoder.withIndent('  ').convert(manifest.toJson()));

      replaceResults(records.map((r) => r.path));
      await _computeCompliance();
      summary = loc.t('summary', [records.length]);
      status = loc.t('statusScanDone', [records.length, elapsed()]);
      log(loc.t('scanDone'), 'info');
    } on Exception catch (e) {
      status = loc.t('failed');
      summary = loc.t('failedSummary', [e.toString()]);
      log('${loc.t('failed')}: $e', 'error');
    } finally {
      finish();
    }
  }

  /// Renders the live status line while roots are being walked.
  ///
  /// Multi-root scans know their total, so the bar shows real progress and an
  /// ETA; a single root walks a whole drive of unknown size, so it stays
  /// indeterminate with no ETA.
  void _reportScanProgress(int done, int total, int found, String current) {
    if (total > 1) {
      progress = done / total;
      status = loc.t('statusScan',
          [done + 1, total, found, current, elapsed(), _estimateEta(done, total)]);
    } else {
      progress = null;
      status = loc.t('statusScanOne', [found, current, elapsed()]);
    }
    notifyListeners();
  }

  /// Estimated remaining time for a multi-root scan, derived from elapsed time
  /// and the fraction of roots already processed. Returns `—` when unknown.
  String _estimateEta(int done, int total) {
    final fraction = done / total;
    if (fraction <= 0) return '—';
    final secs = elapsedSeconds;
    if (secs <= 0) return '—';
    final remaining = ((secs / fraction) - secs).round();
    if (remaining <= 0) return '—';
    return formatDuration(remaining);
  }

  /// Compares every scanned file's content against the effective ruleset so the
  /// results list can mark what Apply would change versus leave untouched.
  Future<void> _computeCompliance() async {
    final source = await effectiveRules();
    final sourceHash = sha256OfString(source);
    final map = <String, bool>{};
    for (final path in results) {
      try {
        final file = File(path);
        map[path] = file.existsSync()
            ? sha256OfString(await file.readAsString()) == sourceHash
            : true; // stale path: nothing to write, so nothing to apply
      } on Exception {
        map[path] = false;
      }
    }
    _compliance = map;
    notifyListeners();
  }

  /// Recomputes per-result compliance; safe to call after Apply so the results
  /// list reflects the files just written (PROP-14). Exposed for the apply flow.
  Future<void> refreshCompliance() async {
    await _computeCompliance();
  }

  /// Surfaces an existing manifest at startup: loads its paths into the results
  /// list and logs how many were found, so the tool opens showing prior state
  /// instead of an empty list. Missing or corrupt manifest is not an error.
  Future<void> loadExistingManifest() async {
    final file = File(manifestPath);
    if (!file.existsSync()) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return; // corrupt manifest: ignore
      final manifest = Manifest.fromJson(decoded);
      replaceResults(manifest.files.map((r) => r.path));
      log(loc.t('manifestLoaded', [manifest.files.length]), 'info');
    } on Exception {
      // Ignore: Scan will rebuild the manifest.
    }
    notifyListeners();
  }
}
