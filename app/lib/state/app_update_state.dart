/// Application update: manual check plus one-click download & install.
library;

import 'package:flutter/foundation.dart';

import '../models/ruleset_info.dart' show compareRulesetVersions;
import '../services/app_update.dart';
import '../services/update_installer.dart';
import 'log_state.dart';
import 'preferences_state.dart';

/// Queries the project's GitHub releases, reports whether a newer build exists
/// and can download + apply it by relaunching through a helper script.
mixin AppUpdateState on ChangeNotifier, PreferencesState, LogState {
  /// Application version, supplied by the composing class.
  String get version;

  ReleaseFetcher _releaseFetcher = _fetchFromGitHub;
  UpdateInstaller _installer = UpdateInstaller();
  bool _checkingUpdate = false;
  bool _installing = false;
  String _updateStatus = '';
  String? _latestAppVersion;
  String _installStatus = '';

  static Future<String> _fetchFromGitHub(Uri uri) =>
      fetchLatestReleaseTag(uri: uri);

  /// Wires the release fetcher and installer; tests inject fakes so nothing
  /// touches the network or the filesystem outside a temporary directory.
  void initAppUpdate({ReleaseFetcher? fetcher, UpdateInstaller? installer}) {
    if (fetcher != null) _releaseFetcher = fetcher;
    if (installer != null) _installer = installer;
  }

  /// `true` while a release check is in flight.
  bool get checkingAppUpdate => _checkingUpdate;

  /// `true` while an update is being downloaded/applied.
  bool get installingUpdate => _installing;

  /// Localized outcome of the last check (empty before the first one).
  String get appUpdateStatus => _updateStatus;

  /// Progress/outcome text of the last download & install attempt.
  String get updateInstallStatus => _installStatus;

  /// Newer version found by the last check, or `null` when up to date/unknown.
  String? get availableAppVersion => _latestAppVersion;

  /// Queries GitHub releases and compares the latest tag against [version].
  Future<void> checkAppUpdate() async {
    if (_checkingUpdate) return;
    _checkingUpdate = true;
    _updateStatus = '';
    notifyListeners();
    try {
      final latest = await _releaseFetcher(Uri.parse(appReleasesApiUrl));
      if (compareRulesetVersions(latest, version) > 0) {
        _latestAppVersion = latest;
        _updateStatus = loc.t('appUpdateAvailable', [latest, version]);
        log(_updateStatus, 'info');
      } else {
        _latestAppVersion = null;
        _updateStatus = loc.t('appUpToDate', [version]);
        log(_updateStatus, 'info');
      }
    } on Exception catch (e) {
      _updateStatus = loc.t('appUpdateFailed', ['$e']);
      log(_updateStatus, 'error');
    } finally {
      _checkingUpdate = false;
      notifyListeners();
    }
  }

  /// Downloads the release found by [checkAppUpdate] and applies it.
  ///
  /// On success the process exits so the helper script can replace the
  /// executable; when the app directory is read-only or the download fails the
  /// status explains why and nothing is changed.
  Future<void> installUpdate() async {
    final target = _latestAppVersion;
    if (target == null || _installing) return;
    _installing = true;
    _installStatus = loc.t('updateDownloading', [target]);
    notifyListeners();
    try {
      await _installer.install(target);
      // Reached only when the process did not exit (e.g. in tests).
      _installStatus = loc.t('updateApplying');
      log(_installStatus, 'info');
    } on Exception catch (e) {
      _installStatus = loc.t('updateInstallFailed', ['$e']);
      log(_installStatus, 'error');
    } finally {
      _installing = false;
      notifyListeners();
    }
  }
}
