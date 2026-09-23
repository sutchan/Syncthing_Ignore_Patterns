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
    RulesetUpdateState {
  /// Application version, recorded in the re-written manifest.
  String get version;

  /// The running executable's directory, excluded from applying.
  String get appDirectory;

  /// Number of paths in the manifest that [apply] would touch, or `0` when the
  /// manifest is missing/corrupt. Read synchronously so the pre-apply prompt can
  /// be shown within the button handler without an async gap.
  int pendingApplyCount() {
    try {
      final json = jsonDecode(File(manifestPath).readAsStringSync())
          as Map<String, dynamic>;
      return Manifest.fromJson(json).files.length;
    } on Exception {
      return 0;
    }
  }

  Future<void> apply() async {
    begin();
    status = loc.t('statusPrep');
    notifyListeners();

    if (!File(manifestPath).existsSync()) {
      finish();
      log(loc.t('noManifest'), 'error');
      return;
    }

    String sourceContent;
    try {
      sourceContent = await effectiveRules();
    } on Exception catch (e) {
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
      final json = jsonDecode(await File(manifestPath).readAsString())
          as Map<String, dynamic>;
      manifest = Manifest.fromJson(json);
    } on Exception {
      finish();
      log(loc.t('manifestParseFailed', [manifestPath]), 'error');
      return;
    }
    if (manifest.files.isEmpty) {
      finish();
      log(loc.t('noManifest'), 'error');
      return;
    }

    final result = await applyRules(
      manifest: manifest,
      sourceContent: sourceContent,
      sourceHash: sourceHash,
      sourcePath: manifestPath, // placeholder path; source is bundled asset
      skipRoots: [appDirectory],
      whatIf: preview,
      force: force,
      backup: backup,
      isCancelled: () => cancelled,
      log: logTranslated,
    );

    if (!preview && (result.replaced > 0 || result.errors > 0)) {
      // Re-write the manifest dropping paths that were cleaned.
      final kept =
          manifest.files.where((r) => File(r.path).existsSync()).toList();
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
    finish();
  }
}
