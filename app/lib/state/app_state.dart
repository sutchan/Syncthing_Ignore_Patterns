/// Application state: composes the scan/apply flows with the preferences,
/// options, logging, picker and progress mixins.
///
/// Each concern lives in its own file — `preferences_state.dart`,
/// `scan_options_state.dart`, `log_state.dart`, `progress_state.dart`,
/// `pickers_state.dart`, `scan_flow.dart`, `apply_flow.dart` — so no single
/// file grows unbounded. [ChangeNotifier] lets widgets rebuild on changes.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../services/settings_store.dart';
import 'apply_flow.dart';
import 'log_state.dart';
import 'pickers_state.dart';
import 'preferences_state.dart';
import 'progress_state.dart';
import 'scan_flow.dart';
import 'scan_options_state.dart';

class AppState extends ChangeNotifier
    with
        PreferencesState,
        ScanOptionsState,
        LogState,
        ProgressState,
        PickersState,
        ScanFlow,
        ApplyFlow {
  AppState({this.version = '1.21.0', SettingsStore? settingsStore}) {
    initPreferences(settingsStore ?? SettingsStore());
  }

  /// Application version shown in the About dialog and written into manifests.
  @override
  final String version;

  /// Directory of the running executable. Its `.stignore` files (the bundled
  /// standard rules) are excluded from scan/apply so the tool never rewrites
  /// its own files.
  @override
  String get appDirectory => p.dirname(Platform.resolvedExecutable);

  /// Aborts the running scan/apply at the next checkpoint.
  void stop() {
    cancelled = true;
    log(loc.t('stopped'), 'warn');
    notifyListeners();
  }

  /// Convenience label for the standard rules source path.
  String get rulesPathLabel => p.basename(manifestPath);
}
