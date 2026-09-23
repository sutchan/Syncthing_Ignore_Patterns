import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/services/app_update.dart';
import 'package:syncthing_ignore_gui/services/ruleset_store.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';

void main() {
  late Directory tmp;

  AppState newState(ReleaseFetcher fetcher) => AppState(
        version: '1.24.0',
        settingsStore: SettingsStore(directory: tmp.path),
        rulesetStore: RulesetStore(directory: tmp.path),
        rulesetBundled: () async => '//Version: 9.9.9\nRULES\n',
        releaseFetcher: fetcher,
      );

  setUp(() => tmp = Directory.systemTemp.createTempSync('app_update'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('checkAppUpdate reports a newer release', () async {
    final s = newState((_) async => '1.25.0');
    await s.checkAppUpdate();
    expect(s.availableAppVersion, '1.25.0');
    expect(s.appUpdateStatus, isNotEmpty);
    expect(s.checkingAppUpdate, isFalse);
    expect(s.logs.last.level, 'info');
  });

  test('checkAppUpdate reports being up to date', () async {
    final s = newState((_) async => '1.24.0');
    await s.checkAppUpdate();
    expect(s.availableAppVersion, isNull);
    expect(s.appUpdateStatus, isNotEmpty);
  });

  test('checkAppUpdate surfaces a network failure', () async {
    final s = newState((_) async => throw const HttpException('boom'));
    await s.checkAppUpdate();
    expect(s.availableAppVersion, isNull);
    expect(s.appUpdateStatus, isNotEmpty);
    expect(s.logs.last.level, 'error');
  });
}
