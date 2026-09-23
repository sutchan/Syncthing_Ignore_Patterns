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

  setUp(() => tmp = Directory.systemTemp.createTempSync('state_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('progress begin/finish reset flags and results', () {
    final s = newState();
    s.results.add('a');
    s.begin();
    expect(s.isBusy, isTrue);
    expect(s.progress, isNull);
    expect(s.cancelled, isFalse);
    expect(s.results, isEmpty);
    s.finish();
    expect(s.isBusy, isFalse);
    expect(s.progress, 1);
    expect(s.elapsed(), matches(RegExp(r'^\d{2}:\d{2}$')));
  });

  test('scan option setters clamp and notify', () {
    final s = newState();
    var notified = 0;
    s.addListener(() => notified++);
    s.setPreview(true);
    expect(s.preview, isTrue);
    s.setForce(true);
    expect(s.force, isTrue);
    s.setBackup(false);
    expect(s.backup, isFalse);
    s.setMaxDepth(99);
    expect(s.maxDepth, 10);
    s.setMaxDepth(0);
    expect(s.maxDepth, 1);
    s.setFilterLargeDirs(false);
    expect(s.filterLargeDirs, isFalse);
    s.setMaxFilesPerDir(0);
    expect(s.maxFilesPerDir, 1);
    s.setMaxFilesPerDir(500);
    expect(s.maxFilesPerDir, 500);
    expect(notified, 8);
  });

  test('log buffer supports append, translate and clear', () {
    final s = newState();
    s.log('plain', 'info');
    expect(s.logs.single.text, 'plain');
    s.logTranslated('summary::3', 'info');
    expect(s.logs.last.text, contains('3'));
    s.clearLog();
    expect(s.logs, isEmpty);
  });

  test('applyDrop fills the matching input', () {
    final s = newState();
    final dir = Directory(p.join(tmp.path, 'dropped'))..createSync();
    s.applyDrop(dir.path);
    expect(s.rootText, dir.path);

    final file = File(p.join(tmp.path, 'r.stignore'))..writeAsStringSync('x');
    s.applyDrop(file.path);
    expect(s.manifestPath, file.path);

    s.applyDrop(p.join(tmp.path, 'notes.txt'));
    expect(s.logs.last.level, 'muted');
  });

  test('stop() flags cancellation and rulesPathLabel shows the file name', () {
    final s = newState();
    s.manifestPath = 'config/stignore-paths.json';
    expect(s.rulesPathLabel, 'stignore-paths.json');
    s.stop();
    expect(s.cancelled, isTrue);
    expect(s.logs.last.level, 'warn');
  });
}
