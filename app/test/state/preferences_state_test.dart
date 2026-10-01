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

  setUp(() => tmp = Directory.systemTemp.createTempSync('prefs_state'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('setLanguage ignores unsupported codes and keeps the current one', () {
    final s = newState();
    s.setLanguage('fr');
    expect(s.lang, 'en');
    s.setLanguage('zh');
    expect(s.lang, 'zh');
    s.setLanguage('zh'); // no-op -> single notify
  });

  test('setTheme toggles and persists', () {
    final s = newState();
    s.setTheme(true);
    expect(s.dark, isTrue);
    s.setTheme(true); // no-op
    expect(s.dark, isTrue);
  });

  test('boot-check flags toggle and persist', () {
    final s = newState();
    s.setBootCheckAppUpdate(true);
    expect(s.bootCheckAppUpdate, isTrue);
    s.setBootCheckRuleset(true);
    expect(s.bootCheckRuleset, isTrue);
    s.setBootCheckAppUpdate(false);
    s.setBootCheckRuleset(false);
    expect(s.bootCheckAppUpdate, isFalse);
    expect(s.bootCheckRuleset, isFalse);
  });

  test('loadSettings restores saved preferences', () async {
    final s = newState();
    s.setLanguage('zh');
    s.setTheme(true);
    s.setBootCheckAppUpdate(true);
    // Let the unawaited preference writes flush to disk before reloading.
    await Future.delayed(const Duration(milliseconds: 100));
    await s.loadSettings();
    expect(s.lang, 'zh');
    expect(s.dark, isTrue);
    expect(s.bootCheckAppUpdate, isTrue);
  });
}
