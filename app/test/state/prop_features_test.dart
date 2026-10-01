import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/ruleset_store.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/services/window_bounds_service.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';

void main() {
  late Directory tmp;

  AppState newState() => AppState(
        settingsStore: SettingsStore(directory: tmp.path),
        rulesetStore: RulesetStore(directory: tmp.path),
        rulesetBundled: () async => '//Version: 9.9.9\nRULES\n',
      );

  setUp(() => tmp = Directory.systemTemp.createTempSync('prop_features'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('PROP-15: window geometry support flag resolves to a boolean', () {
    expect(isWindowGeometrySupported(), isA<bool>());
  });

  test('PROP-16: scan with a missing root surfaces failure in the status line',
      () async {
    final state = newState();
    state.rootText = p.join(tmp.path, 'no-such-dir');
    state.manifestPath = p.join(tmp.path, 'out.json');

    await state.scan();

    expect(state.isBusy, isFalse);
    expect(state.status, state.loc.t('failed'));
    expect(state.logs.any((e) => e.level == 'error'), isTrue);
  });

  test('PROP-16: apply with a missing manifest marks the status as failed',
      () async {
    final state = newState();
    state.manifestPath = p.join(tmp.path, 'missing.json');

    await state.apply();

    expect(state.isBusy, isFalse);
    expect(state.status, state.loc.t('failed'));
    expect(state.logs.any((e) => e.level == 'error'), isTrue);
  });

  test('PROP-17: exportLog writes the in-memory buffer to a temp file',
      () async {
    final state = newState();
    state.log('hello', 'info');
    state.log('world', 'debug');

    final path = await state.exportLog();

    expect(path, isNotNull);
    final file = File(path!);
    expect(file.existsSync(), isTrue);
    final content = file.readAsStringSync();
    expect(content, contains('hello'));
    expect(content, contains('world'));
  });
}
