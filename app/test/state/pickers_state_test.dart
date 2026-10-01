import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/services/ruleset_store.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';

void main() {
  late Directory tmp;

  AppState newState() => AppState(
        settingsStore: SettingsStore(directory: tmp.path),
        rulesetStore: RulesetStore(directory: tmp.path),
        rulesetBundled: () async => '//Version: 9.9.9\n',
      );

  setUp(() => tmp = Directory.systemTemp.createTempSync('pickers_state'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('rootPaths splits on commas and newlines, ignoring blanks', () {
    final s = newState();
    s.rootText = 'C:\\a, D:\\b\n  \nE:\\c';
    expect(s.rootPaths, ['C:\\a', 'D:\\b', 'E:\\c']);
  });

  test('addRoot appends and ignores empty input', () {
    final s = newState();
    s.addRoot('');
    expect(s.rootText, '');
    s.addRoot('C:\\a');
    expect(s.rootText, 'C:\\a');
    s.addRoot('D:\\b');
    expect(s.rootText, 'C:\\a\nD:\\b');
  });

  test('clearRoots empties the field and is a no-op when already empty', () {
    final s = newState();
    s.addRoot('C:\\a');
    s.clearRoots();
    expect(s.rootText, '');
    s.clearRoots();
    expect(s.rootText, '');
  });
}
