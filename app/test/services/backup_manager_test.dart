import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/backup_manager.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('bk_manager'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('listForTargets finds .bak.* siblings, newest first, ignores others', () {
    final target = File(p.join(tmp.path, 'a.stignore'))..writeAsStringSync('x');
    final oldBak = File(p.join(tmp.path, 'a.stignore.bak.20240101000000'))
      ..writeAsStringSync('old');
    final newBak = File(p.join(tmp.path, 'a.stignore.bak.20240102000000'))
      ..writeAsStringSync('new');
    File(p.join(tmp.path, 'a.stignore.tmp')).writeAsStringSync('y');
    // Sort is by real modification time, so pin explicit timestamps.
    final base = DateTime(2024, 1, 1);
    oldBak.setLastModifiedSync(base);
    newBak.setLastModifiedSync(base.add(const Duration(hours: 1)));
    final entries = listForTargets([target.path]);
    expect(entries, hasLength(2));
    expect(entries.first.bakPath, newBak.path);
    expect(entries.first.targetName, 'a.stignore');
  });

  test('listForTargets returns empty for a missing directory', () {
    expect(listForTargets([p.join(tmp.path, 'nope.stignore')]), isEmpty);
  });

  test('restore copies the backup over the target and re-backs-up the live file',
      () async {
    final target = File(p.join(tmp.path, 'a.stignore'))..writeAsStringSync('live');
    final bakFile = File(p.join(tmp.path, 'a.stignore.bak.20240101000000'))
      ..writeAsStringSync('restored');
    final entry = BackupEntry(
      target: target.path,
      bakPath: bakFile.path,
      modified: DateTime.now(),
    );
    await restore(entry);
    expect(target.readAsStringSync(), 'restored');
    final baks = Directory(tmp.path)
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('a.stignore.bak.'))
        .length;
    expect(baks, 2);
  });

  test('deleteEntry removes the backup file', () async {
    final target = File(p.join(tmp.path, 'a.stignore'))..writeAsStringSync('x');
    final bakFile = File(p.join(tmp.path, 'a.stignore.bak.20240101000000'))
      ..writeAsStringSync('old');
    final entry = BackupEntry(
      target: target.path,
      bakPath: bakFile.path,
      modified: DateTime.now(),
    );
    await deleteEntry(entry);
    expect(bakFile.existsSync(), isFalse);
  });
}
