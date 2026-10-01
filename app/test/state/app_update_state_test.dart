import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/app_update.dart';
import 'package:syncthing_ignore_gui/services/ruleset_store.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/services/update_installer.dart';
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

  UpdateInstaller fakeInstaller({
    required Directory staging,
    required String executable,
    ReleaseDownloader? downloader,
    void Function(int)? exitApp,
  }) =>
      UpdateInstaller(
        stagingDirectory: staging,
        downloader:
            downloader ?? (uri, dest) => dest.writeAsBytes(zipMagic, flush: true),
        launcher: (_) async {},
        exitApp: exitApp ?? (_) {},
        executablePath: executable,
      );

  test('installUpdate downloads, launches and exits', () async {
    final staging = Directory.systemTemp.createTempSync('upd_state');
    final appDir = Directory.systemTemp.createTempSync('upd_state_app');
    try {
      final exe = File(p.join(appDir.path, 'SyncthingIgnoreGUI.exe'))
        ..writeAsStringSync('fake');
      var exitCode = -1;
      final s = newState((_) async => '1.25.0');
      s.initAppUpdate(
        installer: fakeInstaller(
          staging: staging,
          executable: exe.path,
          exitApp: (code) => exitCode = code,
        ),
      );

      await s.checkAppUpdate();
      expect(s.availableAppVersion, '1.25.0');
      await s.installUpdate();

      expect(exitCode, 0);
      expect(s.installingUpdate, isFalse);
      expect(s.updateInstallStatus, isNotEmpty);
    } finally {
      staging.deleteSync(recursive: true);
      appDir.deleteSync(recursive: true);
    }
  });

  test('installUpdate reports a download failure and does not exit', () async {
    final staging = Directory.systemTemp.createTempSync('upd_state_fail');
    final appDir = Directory.systemTemp.createTempSync('upd_state_fail_app');
    try {
      final exe = File(p.join(appDir.path, 'SyncthingIgnoreGUI.exe'))
        ..writeAsStringSync('fake');
      var exited = false;
      final s = newState((_) async => '1.25.0');
      s.initAppUpdate(
        installer: fakeInstaller(
          staging: staging,
          executable: exe.path,
          downloader: (_, __) async => throw const HttpException('boom'),
          exitApp: (_) => exited = true,
        ),
      );

      await s.checkAppUpdate();
      await s.installUpdate();

      expect(exited, isFalse);
      expect(s.updateInstallStatus, isNotEmpty);
      expect(s.logs.last.level, 'error');
    } finally {
      staging.deleteSync(recursive: true);
      appDir.deleteSync(recursive: true);
    }
  });

  test('installUpdate is a no-op without a newer version', () async {
    final s = newState((_) async => '1.25.0');
    await s.installUpdate();
    expect(s.updateInstallStatus, isEmpty);
  });
}
