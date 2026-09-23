import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/models/manifest.dart';
import 'package:syncthing_ignore_gui/services/ruleset_store.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';

void main() {
  const rules = '//Version: 1.0.0\nRULE-A\nRULE-B\n';
  late Directory tmp;

  AppState newState() => AppState(
        settingsStore: SettingsStore(directory: tmp.path),
        rulesetStore: RulesetStore(directory: tmp.path),
        rulesetBundled: () async => rules,
      );

  setUp(() => tmp = Directory.systemTemp.createTempSync('apply_flow'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String writeManifest(List<String> targets) {
    final file = File(p.join(tmp.path, 'paths.json'))
      ..writeAsStringSync(jsonEncode(Manifest(
        version: '1.0.0',
        scannedAt: 'now',
        roots: const [],
        files: [
          for (final t in targets)
            StignoreRecord(path: t, size: 0, lastWriteUtc: '', foundAtUtc: ''),
        ],
      ).toJson()));
    return file.path;
  }

  test('apply writes the effective rules into every manifest path', () async {
    final t1 = File(p.join(tmp.path, 'a.stignore'))..writeAsStringSync('OLD');
    final t2 = File(p.join(tmp.path, 'b.stignore'))..writeAsStringSync('OLD');

    final state = newState();
    state.manifestPath = writeManifest([t1.path, t2.path]);
    state.setBackup(false);

    await state.apply();

    expect(t1.readAsStringSync(), rules);
    expect(t2.readAsStringSync(), rules);
    expect(state.isBusy, isFalse);
    expect(state.summary, contains('2'));
  });

  test('apply honours preview mode (writes nothing)', () async {
    final t1 = File(p.join(tmp.path, 'a.stignore'))..writeAsStringSync('OLD');

    final state = newState();
    state.manifestPath = writeManifest([t1.path]);
    state.setPreview(true);

    await state.apply();

    expect(t1.readAsStringSync(), 'OLD');
  });

  test('apply reports a missing manifest', () async {
    final state = newState();
    state.manifestPath = p.join(tmp.path, 'nope.json');

    await state.apply();

    expect(state.isBusy, isFalse);
    expect(state.logs.any((e) => e.level == 'error'), isTrue);
  });
}
