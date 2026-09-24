import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/models/window_bounds.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';

void main() {
  test('load returns defaults when the file is missing', () async {
    final dir = await Directory.systemTemp.createTemp('sig_settings_');
    addTearDown(() => dir.delete(recursive: true));

    final settings = await SettingsStore(directory: dir.path).load();
    expect(settings.lang, 'en');
    expect(settings.dark, isFalse);
  });

  test('save then load round-trips the preferences', () async {
    final dir = await Directory.systemTemp.createTemp('sig_settings_');
    addTearDown(() => dir.delete(recursive: true));
    final store = SettingsStore(directory: dir.path);

    await store.save(const AppSettings(lang: 'zh', dark: true));
    expect(File(p.join(dir.path, 'settings.json')).existsSync(), isTrue);

    final settings = await store.load();
    expect(settings.lang, 'zh');
    expect(settings.dark, isTrue);
  });

  test('load falls back to defaults on corrupt JSON', () async {
    final dir = await Directory.systemTemp.createTemp('sig_settings_');
    addTearDown(() => dir.delete(recursive: true));
    File(p.join(dir.path, 'settings.json')).writeAsStringSync('{not json');

    final settings = await SettingsStore(directory: dir.path).load();
    expect(settings.lang, 'en');
    expect(settings.dark, isFalse);
  });

  test('AppState restores saved preferences on startup', () async {
    final dir = await Directory.systemTemp.createTemp('sig_state_');
    addTearDown(() => dir.delete(recursive: true));
    final store = SettingsStore(directory: dir.path);
    await store.save(const AppSettings(lang: 'zh', dark: true));

    final state = AppState(settingsStore: store);
    await state.loadSettings();

    expect(state.lang, 'zh');
    expect(state.dark, isTrue);
    expect(state.loc.t('scan'), '扫描 .stignore 文件');
  });

  test('AppState writes language/theme changes back to disk', () async {
    final dir = await Directory.systemTemp.createTemp('sig_state_');
    addTearDown(() => dir.delete(recursive: true));
    final store = SettingsStore(directory: dir.path);

    final state = AppState(settingsStore: store)..setTheme(true);
    state.setLanguage('zh');
    state.setLanguage('klingon'); // unsupported codes must be ignored
    state.setTheme(false);

    await store.idle; // wait for the serialised writes to land on disk
    final saved = await store.load();
    expect(saved.lang, 'zh');
    expect(saved.dark, isFalse);
  });

  test('save then load round-trips the window geometry', () async {
    final dir = await Directory.systemTemp.createTemp('sig_settings_');
    addTearDown(() => dir.delete(recursive: true));
    final store = SettingsStore(directory: dir.path);

    await store.save(const AppSettings(
      lang: 'zh',
      dark: true,
      window: WindowBounds(x: 120, y: 80, width: 1024, height: 700),
    ));

    final settings = await store.load();
    expect(
      settings.window,
      const WindowBounds(x: 120, y: 80, width: 1024, height: 700),
    );
  });

  test('missing or malformed window geometry is ignored', () async {
    final dir = await Directory.systemTemp.createTemp('sig_settings_');
    addTearDown(() => dir.delete(recursive: true));
    final store = SettingsStore(directory: dir.path);

    await store.save(const AppSettings());
    expect((await store.load()).window, isNull);

    File(p.join(dir.path, 'settings.json')).writeAsStringSync(
        '{"lang":"en","dark":false,"window":{"x":"a","y":2}}');
    expect((await store.load()).window, isNull);
  });

  test('WindowBounds rejects implausible sizes', () {
    expect(
      const WindowBounds(x: 0, y: 0, width: 100, height: 100).isUsable,
      isFalse,
    );
    expect(
      const WindowBounds(x: 0, y: 0, width: 1024, height: 700).isUsable,
      isTrue,
    );
  });

  test('overlapping saves keep the newest snapshot', () async {
    final dir = await Directory.systemTemp.createTemp('sig_settings_');
    addTearDown(() => dir.delete(recursive: true));
    final store = SettingsStore(directory: dir.path);

    // Fire several saves without awaiting, mimicking rapid UI toggles.
    await Future.wait(<Future<void>>[
      store.save(const AppSettings(lang: 'en', dark: true)),
      store.save(const AppSettings(lang: 'zh', dark: true)),
      store.save(const AppSettings(lang: 'zh', dark: false)),
    ]);

    final saved = await store.load();
    expect(saved.lang, 'zh');
    expect(saved.dark, isFalse);
  });
}
