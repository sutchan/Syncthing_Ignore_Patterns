/// Ruleset provenance and the online update flow.
library;

import 'package:flutter/foundation.dart';

import '../models/ruleset_info.dart';
import '../services/rules_source.dart';
import '../services/ruleset_store.dart';
import '../services/ruleset_update.dart';
import 'log_state.dart';
import 'preferences_state.dart';

/// Loads the ruleset shipped inside the app; injectable so tests avoid assets.
typedef RulesetLoader = Future<String> Function();

mixin RulesetUpdateState on ChangeNotifier, PreferencesState, LogState {
  late RulesetStore _store;
  RulesetFetcher _fetcher = _fetchFromRepository;
  RulesetLoader _bundled = loadStandardRules;

  RulesetInfo? _ruleset;
  bool _downloaded = false;
  bool _checking = false;
  String? _availableVersion;
  String _status = '';

  static Future<String> _fetchFromRepository(Uri uri) =>
      fetchRulesetFromRepo(uri: uri);

  /// Wires the ruleset dependencies; tests inject a temporary store and fakes.
  void initRuleset({
    RulesetStore? store,
    RulesetFetcher? fetcher,
    RulesetLoader? bundled,
  }) {
    _store = store ?? RulesetStore();
    if (fetcher != null) _fetcher = fetcher;
    if (bundled != null) _bundled = bundled;
  }

  /// Metadata of the ruleset currently in effect, or `null` before loading.
  RulesetInfo? get ruleset => _ruleset;

  /// `true` when the effective ruleset came from disk instead of the bundle.
  bool get rulesetDownloaded => _downloaded;

  /// Path the app reads the ruleset from (and writes updates to).
  String get rulesetPath => _store.primaryPath;

  /// `true` while a repository check is in flight.
  bool get checkingRuleset => _checking;

  /// Newer version found in the repository, or `null` when none is known.
  String? get availableRulesetVersion => _availableVersion;

  /// Localized outcome of the last check (empty before the first one).
  String get rulesetStatus => _status;

  /// Loads the ruleset metadata in effect. Never touches the network.
  Future<void> loadRulesetInfo() async {
    final stored = await _store.read();
    if (stored != null) {
      final info = RulesetInfo.parse(stored);
      if (info != null) {
        _ruleset = info;
        _downloaded = true;
        notifyListeners();
        return;
      }
    }
    _ruleset = RulesetInfo.parse(await _bundled());
    _downloaded = false;
    notifyListeners();
  }

  /// The rules content in effect: an on-disk copy when present, else the
  /// bundled asset.
  Future<String> effectiveRules() async => await _store.read() ?? _bundled();

  /// Downloads the repository ruleset and adopts it when it is newer.
  Future<void> checkRulesetUpdate() async {
    if (_checking) return;
    _checking = true;
    _status = '';
    notifyListeners();
    try {
      final content = await _fetcher(Uri.parse(rulesetRepoUrl));
      final remote = RulesetInfo.parse(content);
      if (remote == null) {
        _status = loc.t('rulesetInvalid');
        log(_status, 'warn');
        return;
      }
      final current = _ruleset;
      if (current != null &&
          compareRulesetVersions(remote.version, current.version) <= 0) {
        _status = loc.t('rulesetUpToDate', [current.version]);
        log(_status, 'info');
        return;
      }
      await _store.write(content);
      _ruleset = remote;
      _downloaded = true;
      _availableVersion = remote.version;
      _status = loc.t('rulesetUpdated', [remote.version, current?.version ?? '—']);
      log(_status, 'info');
    } on Exception catch (e) {
      _status = loc.t('rulesetUpdateFailed', ['$e']);
      log(_status, 'error');
    } finally {
      _checking = false;
      notifyListeners();
    }
  }
}
