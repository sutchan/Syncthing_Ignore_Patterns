/// Apply flow: writes the standard rules into every path in the manifest.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/manifest.dart';
import '../services/applier.dart';
import '../services/rules_source.dart';
import 'log_state.dart';
import 'pickers_state.dart';
import 'scan_flow.dart';
import 'preferences_state.dart';
import 'progress_state.dart';
import 'ruleset_state.dart';
import 'scan_options_state.dart';

mixin ApplyFlow on ChangeNotifier,
    ProgressState,
    PreferencesState,
    LogState,
    ScanOptionsState,
    PickersState,
    RulesetUpdateState,
    ScanFlow {
  /// Application version, recorded in the re-written manifest.
  @override
  String get version;

  /// The running executable's directory, excluded from applying.
  @override
  String get appDirectory;

  /// Number of paths in the manifest that [apply] would touch, or `0` when the
  /// manifest is missing/corrupt. Read synchronously so the pre-apply prompt can
  /// be shown within the button handler without an async gap.
  int pendingApplyCount() {
    try {
      final decoded = jsonDecode(File(manifestPath).readAsStringSync());
      if (decoded is! Map<String, dynamic>) return 0;
      return Manifest.fromJson(decoded).files.length;
    } on Object {
      return 0;
    }
  }

  Future<void> apply() async {
    begin();
    status = loc.t('statusPrep');
    notifyListeners();

    if (!File(manifestPath).existsSync()) {
      status = loc.t('failed');
      summary = loc.t('failedSummary', [loc.t('noManifest')]);
      finish();
      log(loc.t('noManifest'), 'error');
      return;
    }

    String sourceContent;
    try {
      sourceContent = await effectiveRules();
    } on Exception catch (e) {
      status = loc.t('failed');
      summary = loc.t('failedSummary', [e.toString()]);
      finish();
      log(e.toString(), 'error');
      return;
    }
    final sourceHash = sha256OfString(sourceContent);
    log('${loc.t('repo')} SHA256: $sourceHash', 'muted');
    log(
      loc.t('rulesetInUse', [ruleset?.version ?? '—', ruleset?.updated ?? '—']),
      'muted',
    );

    late final Manifest manifest;
    try {
      final decoded = jsonDecode(await File(manifestPath).readAsString());
      if (decoded is! Map<String, dynamic>) {
        status = loc.t('failed');
        summary = loc.t('failedSummary',
            [loc.t('manifestParseFailed', [manifestPath])]);
        finish();
        log(loc.t('manifestParseFailed', [manifestPath]), 'error');
        return;
      }
      manifest = Manifest.fromJson(decoded);
    } on Object {
      status = loc.t('failed');
      summary = loc.t('failedSummary',
          [loc.t('manifestParseFailed', [manifestPath])]);
      finish();
      log(loc.t('manifestParseFailed', [manifestPath]), 'error');
      return;
    }
    if (manifest.files.isEmpty) {
      status = loc.t('failed');
      summary = loc.t('failedSummary', [loc.t('noManifest')]);
      finish();
      log(loc.t('noManifest'), 'error');
      return;
    }

    ApplyResult result;
    try {
      result = await applyRules(
        manifest: manifest,
        sourceContent: sourceContent,
        sourceHash: sourceHash,
        sourcePath: rulesetPath,
        skipRoots: [appDirectory],
        whatIf: preview,
        force: force,
        backup: backup,
        isCancelled: () => cancelled,
        log: logTranslated,
      );
    } on Object catch (e) {
      status = loc.t('failed');
      summary = loc.t('failedSummary', [e.toString()]);
      log('${loc.t('failed')}: $e', 'error');
      finish();
      return;
    }

    if (!preview && (result.replaced > 0 || result.errors > 0)) {
      // Re-write the manifest dropping paths that no longer exist. `exists()`
      // is awaited so a large manifest does not block the UI thread.
      final kept = <StignoreRecord>[];
      for (final r in manifest.files) {
        if (await File(r.path).exists()) kept.add(r);
      }
      final updated = Manifest(
        version: version,
        scannedAt: manifest.scannedAt,
        roots: manifest.roots,
        files: kept,
      );
      await File(manifestPath).writeAsString(
          const JsonEncoder.withIndent('  ').convert(updated.toJson()));
    }

    if (result.cancelled) {
      summary = loc.t('statusApplyDone', [result.replaced, elapsed()]);
      status = loc.t('statusStopped');
      log(loc.t('stopped'), 'warn');
      finish();
      return;
    }

    summary = loc.t('statusApplyDone', [result.replaced, elapsed()]);
    status = loc.t('applyDone');
    log(loc.t('applyDone'), 'info');
    if (!preview) {
      // PROP-14: recompute compliance so the results list reflects the files
      // just written (a successful apply should show "all compliant").
      await refreshCompliance();
    }
    finish();
  }
}
