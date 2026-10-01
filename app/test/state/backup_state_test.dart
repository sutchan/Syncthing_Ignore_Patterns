import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/ruleset_store.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';

void main() {
  late Directory tmp;

  AppState newState() => AppState(
        settingsStore: SettingsStore(directory: tmp.path),
        rulesetStore: RulesetStore(directory: tmp.path),
        rulesetBundled: () async => '//Version: 9.9.9\nRULES\n',
      );

  setUp(() => tmp = Directory.systemTemp.createTempSync('bk_state'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('loadBackups surfaces discovered backups and toggles the loading flag',
      () async {
    final s = newState();
    final target = File(p.join(tmp.path, 'a.stignore'))..writeAsStringSync('x');
    File(p.join(tmp.path, 'a.stignore.bak.20240101000000'))
        .writeAsStringSync('old');
    var loadingSeen = false;
    s.addListener(() {
      if (s.loadingBackups) loadingSeen = true;
    });
    await s.loadBackups([target.path]);
    expect(loadingSeen, isTrue);
    expect(s.backups, hasLength(1));
    expect(s.loadingBackups, isFalse);
  });

  test('restoreBackup restores then refreshes; unknown path is a no-op',
      () async {
    final s = newState();
    final target = File(p.join(tmp.path, 'a.stignore'))..writeAsStringSync('live');
    final bakFile = File(p.join(tmp.path, 'a.stignore.bak.20240101000000'))
      ..writeAsStringSync('restored');
    await s.loadBackups([target.path]);
    await s.restoreBackup(bakFile.path);
    expect(target.readAsStringSync(), 'restored');
    expect(s.logs.last.level, 'info');
    await s.restoreBackup('C:\\does\\not\\exist.bak.1');
  });

  test('deleteBackup deletes then refreshes; unknown path is a no-op', () async {
    final s = newState();
    final target = File(p.join(tmp.path, 'a.stignore'))..writeAsStringSync('x');
    final bakFile = File(p.join(tmp.path, 'a.stignore.bak.20240101000000'))
      ..writeAsStringSync('old');
    await s.loadBackups([target.path]);
    await s.deleteBackup(bakFile.path);
    expect(bakFile.existsSync(), isFalse);
    expect(s.backups, isEmpty);
    await s.deleteBackup('C:\\does\\not\\exist.bak.1');
  });
}
