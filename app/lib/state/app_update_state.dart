/// Manual application update check (no silent installation).
library;

import 'package:flutter/foundation.dart';

import '../models/ruleset_info.dart' show compareRulesetVersions;
import '../services/app_update.dart';
import 'log_state.dart';
import 'preferences_state.dart';

/// Queries the project's GitHub releases and reports whether a newer
/// application build exists. Installing is left to the user (open the releases
/// page), so no download or self-replacement happens here.
mixin AppUpdateState on ChangeNotifier, PreferencesState, LogState {
  /// Application version, supplied by the composing class.
  String get version;

  ReleaseFetcher _releaseFetcher = _fetchFromGitHub;
  bool _checkingUpdate = false;
  String _updateStatus = '';
  String? _latestAppVersion;

  static Future<String> _fetchFromGitHub(Uri uri) =>
      fetchLatestReleaseTag(uri: uri);

  /// Wires the release fetcher; tests inject a fake so nothing hits the network.
  void initAppUpdate({ReleaseFetcher? fetcher}) {
    if (fetcher != null) _releaseFetcher = fetcher;
  }

  /// `true` while a release check is in flight.
  bool get checkingAppUpdate => _checkingUpdate;

  /// Localized outcome of the last check (empty before the first one).
  String get appUpdateStatus => _updateStatus;

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
}
