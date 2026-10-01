import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/models/manifest.dart';
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

  setUp(() => tmp = Directory.systemTemp.createTempSync('scan_flow'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('scan writes a manifest and fills the results list', () async {
    final root = Directory(p.join(tmp.path, 'root'))..createSync();
    final nested = Directory(p.join(root.path, 'sub'))..createSync();
    File(p.join(nested.path, '.stignore')).writeAsStringSync('x');

    final state = newState();
    state.rootText = root.path;
    final manifest = p.join(tmp.path, 'paths.json');
    state.manifestPath = manifest;

    await state.scan();

    expect(state.isBusy, isFalse);
    expect(state.results.length, 1);
    expect(File(manifest).existsSync(), isTrue);
    final decoded = Manifest.fromJson(
        jsonDecode(File(manifest).readAsStringSync()) as Map<String, dynamic>);
    expect(decoded.files.single.path, p.join(nested.path, '.stignore'));
    expect(state.summary, contains('1'));
  });

  test('scan reports a missing root without writing a manifest', () async {
    final state = newState();
    state.rootText = p.join(tmp.path, 'does-not-exist');
    final manifest = p.join(tmp.path, 'none.json');
    state.manifestPath = manifest;

    await state.scan();

    expect(state.isBusy, isFalse);
    expect(File(manifest).existsSync(), isFalse);
    expect(state.logs.any((e) => e.level == 'error'), isTrue);
  });

  test('scan rejects a file used as the root', () async {
    final state = newState();
    final file = File(p.join(tmp.path, 'not-a-dir.txt'))..writeAsStringSync('x');
    state.rootText = file.path;
    final manifest = p.join(tmp.path, 'file.json');
    state.manifestPath = manifest;

    await state.scan();

    expect(state.isBusy, isFalse);
    expect(File(manifest).existsSync(), isFalse);
    expect(state.logs.any((e) => e.level == 'error'), isTrue);
  });

  test('loadExistingManifest surfaces an existing manifest', () async {
    final manifest = File(p.join(tmp.path, 'existing.json'))
      ..writeAsStringSync(jsonEncode(Manifest(
        version: '1.0.0',
        scannedAt: 'now',
        roots: const [],
        files: const [
          StignoreRecord(
              path: 'a/.stignore', size: 1, lastWriteUtc: '', foundAtUtc: ''),
        ],
      ).toJson()));

    final state = newState();
    state.manifestPath = manifest.path;
    await state.loadExistingManifest();

    expect(state.results, ['a/.stignore']);
    expect(state.logs.last.text, contains('1'));
  });
}
