/// Application state: owns scan/apply orchestration, settings, logs and status.
///
/// Mirrors the PowerShell script's shared UI state. Uses [ChangeNotifier] so
/// widgets rebuild on changes. Long operations run off the UI thread; a
/// [_cancelled] flag provides Stop support.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../i18n.dart';
import '../models/manifest.dart';
import '../services/applier.dart';
import '../services/platform_io.dart';
import '../services/rules_source.dart';
import '../services/scanner.dart';

class LogEntry {
  const LogEntry(this.text, this.level);
  final String text;
  final String level; // 'info' | 'warn' | 'error' | 'muted'
}

class AppState extends ChangeNotifier {
  AppState({this.version = '1.18.10'});

  final String version;
  final AppLocalizations _en = AppLocalizations('en');
  final AppLocalizations _zh = AppLocalizations('zh');

  AppLocalizations get loc => _lang == 'zh' ? _zh : _en;

  String _lang = 'en';
  String get lang => _lang;
  void setLanguage(String v) {
    if (_lang == v) return;
    _lang = v;
    notifyListeners();
  }

  bool _dark = false;
  bool get dark => _dark;
  void setTheme(bool isDark) {
    if (_dark == isDark) return;
    _dark = isDark;
    notifyListeners();
  }

  String rootText = '';
  String manifestPath = 'config${Platform.pathSeparator}stignore-paths.json';

  bool preview = false;
  bool force = false;
  bool backup = true;

  bool isBusy = false;
  bool _cancelled = false;
  double? progress; // null => indeterminate
  String status = '';
  String summary = '';

  final List<String> results = [];
  final List<LogEntry> logs = [];

  void stop() {
    _cancelled = true;
    log(loc.t('stopped'), 'warn');
    notifyListeners();
  }

  void clearLog() {
    logs.clear();
    notifyListeners();
  }

  void log(String message, String level) {
    logs.add(LogEntry(message, level));
    notifyListeners();
  }

  /// Translate the raw keys emitted by [applyRules] into localized, colored logs.
  void _translateApplyLog(String raw, String level) {
    final parts = raw.split('::');
    final key = parts.first;
    final args = parts.skip(1).toList();
    log(loc.t(key, args), level);
  }

  Future<void> pickRoot() async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: loc.t('folderTitle'),
    );
    if (dir != null) {
      rootText = dir;
      notifyListeners();
    }
  }

  Future<void> pickManifest() async {
    // file_picker 13+ 的 saveFile 会写入 bytes 并返回 Uri；此处写入占位空字节，
    // 实际清单内容由 scan()/apply() 覆盖写入。
    final uri = await FilePicker.saveFile(
      dialogTitle: loc.t('fileTitle'),
      fileName: 'stignore-paths.json',
      bytes: Uint8List(0),
    );
    if (uri != null) {
      manifestPath = uri.toFilePath();
      notifyListeners();
    }
  }

  List<String> _resolveRoots() {
    final root = rootText.trim();
    if (root.isEmpty) return listFixedDrives();
    if (Directory(root).existsSync()) return [root];
    throw Exception(loc.t('rootNotFound', [root]));
  }

  Future<void> scan() async {
    _begin();
    status = loc.t('statusPrep');
    notifyListeners();
    List<String> roots;
    try {
      roots = _resolveRoots();
    } on Exception catch (e) {
      _finish();
      log(e.toString(), 'error');
      return;
    }

    log('${loc.t('ready')} (${roots.length} roots)', 'info');
    try {
      final records = await scanRoots(roots, maxThreads: 4);
      if (_cancelled) {
        _finish();
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
      await out.writeAsString(const JsonEncoder.withIndent('  ').convert(manifest.toJson()));

      results
        ..clear()
        ..addAll(records.map((r) => r.path));
      summary = loc.t('summary', [records.length]);
      status = loc.t('statusScanDone', [records.length, _elapsed(_start!)]);
      log(loc.t('scanDone'), 'info');
    } on Exception catch (e) {
      log('${loc.t('failed')}: $e', 'error');
    } finally {
      _finish();
    }
  }

  Future<void> apply() async {
    _begin();
    status = loc.t('statusPrep');
    notifyListeners();

    if (!File(manifestPath).existsSync()) {
      _finish();
      log(loc.t('noManifest'), 'error');
      return;
    }

    String sourceContent;
    try {
      sourceContent = await loadStandardRules();
    } on Exception catch (e) {
      _finish();
      log(e.toString(), 'error');
      return;
    }
    final sourceHash = sha256OfString(sourceContent);
    log('${loc.t('repo')} SHA256: $sourceHash', 'muted');

    late final Manifest manifest;
    try {
      final json = jsonDecode(await File(manifestPath).readAsString()) as Map<String, dynamic>;
      manifest = Manifest.fromJson(json);
    } on Exception {
      _finish();
      log(loc.t('manifestParseFailed', [manifestPath]), 'error');
      return;
    }
    if (manifest.files.isEmpty) {
      _finish();
      log(loc.t('noManifest'), 'error');
      return;
    }

    final result = await applyRules(
      manifest: manifest,
      sourceContent: sourceContent,
      sourceHash: sourceHash,
      sourcePath: manifestPath, // placeholder path; source is bundled asset
      whatIf: preview,
      force: force,
      backup: backup,
      log: _translateApplyLog,
    );

    if (!preview && (result.replaced > 0 || result.errors > 0)) {
      // Re-write the manifest dropping paths that were cleaned.
      final kept = manifest.files
          .where((r) => File(r.path).existsSync())
          .toList();
      final updated = Manifest(
        version: version,
        scannedAt: manifest.scannedAt,
        roots: manifest.roots,
        files: kept,
      );
      await File(manifestPath)
          .writeAsString(const JsonEncoder.withIndent('  ').convert(updated.toJson()));
    }

    summary = loc.t('statusApplyDone', [result.replaced, _elapsed(_start!)]);
    status = loc.t('applyDone');
    log(loc.t('applyDone'), 'info');
    _finish();
  }

  DateTime? _start;
  void _begin() {
    _cancelled = false;
    isBusy = true;
    progress = null;
    _start = DateTime.now();
    results.clear();
    notifyListeners();
  }

  void _finish() {
    isBusy = false;
    progress = 1;
    _start = null;
    notifyListeners();
  }

  String _elapsed(DateTime start) {
    final ts = DateTime.now().difference(start);
    if (ts.inHours >= 1) {
      return '${ts.inHours}:${ts.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
          '${ts.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
    return '${ts.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
        '${ts.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  /// Convenience for building the standard rules source path label.
  String get rulesPathLabel => p.basename(manifestPath);
}
