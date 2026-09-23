/// Scan flow: walks the configured roots and writes the manifest.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/manifest.dart';
import '../services/platform_io.dart';
import '../services/scanner.dart';
import 'log_state.dart';
import 'pickers_state.dart';
import 'preferences_state.dart';
import 'progress_state.dart';
import 'scan_options_state.dart';

mixin ScanFlow on ChangeNotifier,
    ProgressState,
    PreferencesState,
    LogState,
    ScanOptionsState,
    PickersState {
  /// Application version, provided by the composing class.
  String get version;

  /// The running executable's directory, excluded from scanning.
  String get appDirectory;

  /// Resolves the roots to scan: the typed root, or every fixed drive.
  List<String> _resolveRoots() {
    final root = rootText.trim();
    if (root.isEmpty) return listFixedDrives();
    if (Directory(root).existsSync()) return [root];
    throw Exception(loc.t('rootNotFound', [root]));
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
      );
      if (cancelled) {
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

      results
        ..clear()
        ..addAll(records.map((r) => r.path));
      summary = loc.t('summary', [records.length]);
      status = loc.t('statusScanDone', [records.length, elapsed()]);
      log(loc.t('scanDone'), 'info');
    } on Exception catch (e) {
      log('${loc.t('failed')}: $e', 'error');
    } finally {
      finish();
    }
  }

  /// Renders the live status line while roots are being walked.
  void _reportScanProgress(int done, int total, int found, String current) {
    status = total > 1
        ? loc.t('statusScan', [done + 1, total, found, current, elapsed()])
        : loc.t('statusScanOne', [found, current, elapsed()]);
    notifyListeners();
  }

  /// Surfaces an existing manifest at startup: loads its paths into the results
  /// list and logs how many were found, so the tool opens showing prior state
  /// instead of an empty list. Missing or corrupt manifest is not an error.
  Future<void> loadExistingManifest() async {
    final file = File(manifestPath);
    if (!file.existsSync()) return;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final manifest = Manifest.fromJson(json);
      results
        ..clear()
        ..addAll(manifest.files.map((r) => r.path));
      log(loc.t('manifestLoaded', [manifest.files.length]), 'info');
    } on Exception {
      // Ignore: Scan will rebuild the manifest.
    }
    notifyListeners();
  }
}
