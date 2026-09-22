import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/scanner.dart';
import 'package:test/test.dart';

void main() {
  test('findStignoreFiles finds nested files, skips .git and skipDir', () {
    final root = Directory.systemTemp.createTempSync('scan_test');
    try {
      File(p.join(root.path, '.stignore')).writeAsStringSync('a');
      final sub = Directory(p.join(root.path, 'sub'))..createSync();
      File(p.join(sub.path, '.stignore')).writeAsStringSync('b');
      final git = Directory(p.join(root.path, '.git'))..createSync();
      File(p.join(git.path, '.stignore')).writeAsStringSync('c');
      final skip = Directory(p.join(root.path, 'skipme'))..createSync();
      File(p.join(skip.path, '.stignore')).writeAsStringSync('d');

      final recs = findStignoreFiles(root.path, skipDir: skip.path);
      final paths = recs.map((r) => r.path).toList();

      expect(paths, contains(p.join(root.path, '.stignore')));
      expect(paths, contains(p.join(sub.path, '.stignore')));
      expect(paths, isNot(contains(p.join(git.path, '.stignore'))));
      expect(paths, isNot(contains(p.join(skip.path, '.stignore'))));
      expect(recs.length, 2);
    } finally {
      root.deleteSync(recursive: true);
    }
  });

  test('scanRoots returns combined records across roots', () async {
    final a = Directory.systemTemp.createTempSync('root_a');
    final b = Directory.systemTemp.createTempSync('root_b');
    try {
      File(p.join(a.path, '.stignore')).writeAsStringSync('a');
      File(p.join(b.path, '.stignore')).writeAsStringSync('b');
      final recs = await scanRoots([a.path, b.path]);
      expect(recs.length, 2);
    } finally {
      a.deleteSync(recursive: true);
      b.deleteSync(recursive: true);
    }
  });
}
