// Ruleset provenance + the check-for-update flow (network and assets injected).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/ruleset_store.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';

const String _bundled = '//Version: 1.18.5\n//Updated: 2026-09-22\n**/bundled/\n';
const String _remoteNewer = '//Version: 1.18.6\n//Updated: 2026-09-24\n**/remote/\n';

/// AppState wired to a temp directory, a fake bundled loader and a fake fetcher.
AppState _stateWith(Directory dir, Future<String> Function() fetch) => AppState(
      settingsStore: SettingsStore(directory: dir.path),
      rulesetStore: RulesetStore(directory: dir.path),
      rulesetBundled: () async => _bundled,
      rulesetFetcher: (_) => fetch(),
    );

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sig_ruleset_');
  });
  tearDown(() async {
    // Best-effort cleanup: on Windows a lingering file handle can make the
    // delete fail, which must not be reported as a test failure.
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on FileSystemException {
      // ignored
    }
  });

  File storedRuleset() => File(p.join(dir.path, '.stignore'));

  test('loadRulesetInfo falls back to the bundled ruleset', () async {
    final state = _stateWith(dir, () async => _remoteNewer);

    await state.loadRulesetInfo();

    expect(state.ruleset?.version, '1.18.5');
    expect(state.rulesetDownloaded, isFalse);
    expect(state.rulesetStatus, isEmpty);
  });

  test('checkRulesetUpdate adopts and stores a newer ruleset', () async {
    final state = _stateWith(dir, () async => _remoteNewer);
    await state.loadRulesetInfo();

    await state.checkRulesetUpdate();

    expect(state.ruleset?.version, '1.18.6');
    expect(state.rulesetDownloaded, isTrue);
    expect(state.availableRulesetVersion, '1.18.6');
    expect(state.rulesetStatus, contains('1.18.6'));
    expect(state.checkingRuleset, isFalse);
    expect(storedRuleset().existsSync(), isTrue);
    // the downloaded copy is what Apply will use
    expect(await state.effectiveRules(), _remoteNewer);
  });

  test('checkRulesetUpdate keeps the local copy when the remote is not newer',
      () async {
    final state = _stateWith(dir, () async => '//Version: 1.18.5\n');
    await state.loadRulesetInfo();

    await state.checkRulesetUpdate();

    expect(state.ruleset?.version, '1.18.5');
    expect(state.rulesetDownloaded, isFalse);
    expect(state.availableRulesetVersion, isNull);
    expect(state.rulesetStatus, contains('Already up to date'));
    expect(storedRuleset().existsSync(), isFalse);
  });

  test('checkRulesetUpdate rejects a payload without a version header',
      () async {
    final state = _stateWith(dir, () async => '**/junk/\n');
    await state.loadRulesetInfo();

    await state.checkRulesetUpdate();

    expect(state.ruleset?.version, '1.18.5');
    expect(state.rulesetStatus, contains('version header'));
    expect(storedRuleset().existsSync(), isFalse);
  });

  test('checkRulesetUpdate reports a network failure and stays usable',
      () async {
    final state = _stateWith(dir, () async => throw Exception('offline'));
    await state.loadRulesetInfo();

    await state.checkRulesetUpdate();

    expect(state.rulesetStatus, contains('Ruleset update failed'));
    expect(state.checkingRuleset, isFalse);
    expect(state.ruleset?.version, '1.18.5');
    expect(await state.effectiveRules(), _bundled);
  });

  test('a stored ruleset wins over the bundled copy on startup', () async {
    storedRuleset().writeAsStringSync(_remoteNewer);
    final state = _stateWith(dir, () async => throw Exception('unused'));

    await state.loadRulesetInfo();

    expect(state.ruleset?.version, '1.18.6');
    expect(state.rulesetDownloaded, isTrue);
    expect(await state.effectiveRules(), _remoteNewer);
  });

  test('rulesetPath points at the application directory copy by default', () {
    final store = RulesetStore(directory: dir.path);
    expect(store.appPath, p.join(dir.path, '.stignore'));
    expect(store.candidates, hasLength(1));
  });
}
