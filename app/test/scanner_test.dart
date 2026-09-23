import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('findStignoreFiles finds nested files, skips .git and skipDir', () async {
    final root = Directory.systemTemp.createTempSync('scan_test');
    try {
      File(p.join(root.path, '.stignore')).writeAsStringSync('a');
      final sub = Directory(p.join(root.path, 'sub'))..createSync();
      File(p.join(sub.path, '.stignore')).writeAsStringSync('b');
      final git = Directory(p.join(root.path, '.git'))..createSync();
      File(p.join(git.path, '.stignore')).writeAsStringSync('c');
      final skip = Directory(p.join(root.path, 'skipme'))..createSync();
      File(p.join(skip.path, '.stignore')).writeAsStringSync('d');
      // A nested `.stignore` under the skipped dir must also be excluded
      // (subtree skip, not just the exact directory).
      final skipDeep =
          Directory(p.join(skip.path, 'nested', 'x'))..createSync(recursive: true);
      File(p.join(skipDeep.path, '.stignore')).writeAsStringSync('e');

      final recs = await findStignoreFiles(root.path, skipDir: skip.path);
      final paths = recs.map((r) => r.path).toList();

      expect(paths, contains(p.join(root.path, '.stignore')));
      expect(paths, contains(p.join(sub.path, '.stignore')));
      expect(paths, isNot(contains(p.join(git.path, '.stignore'))));
      expect(paths, isNot(contains(p.join(skip.path, '.stignore'))));
      expect(paths, isNot(contains(p.join(skipDeep.path, '.stignore'))));
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

  test('maxDepth limits how deep .stignore files are found', () async {
    final root = Directory.systemTemp.createTempSync('depth_test');
    try {
      File(p.join(root.path, '.stignore')).writeAsStringSync('l1');
      final a = Directory(p.join(root.path, 'a'))..createSync();
      File(p.join(a.path, '.stignore')).writeAsStringSync('l2');
      final b = Directory(p.join(a.path, 'b'))..createSync();
      File(p.join(b.path, '.stignore')).writeAsStringSync('l3');
      final c = Directory(p.join(b.path, 'c'))..createSync();
      File(p.join(c.path, '.stignore')).writeAsStringSync('l4');
      final d = Directory(p.join(c.path, 'd'))..createSync();
      File(p.join(d.path, '.stignore')).writeAsStringSync('l5');

      final shallow = await findStignoreFiles(root.path, maxDepth: 1);
      expect(shallow.length, 1); // only the root-level file

      final deep = await findStignoreFiles(root.path, maxDepth: 10);
      expect(deep.length, 5);
    } finally {
      root.deleteSync(recursive: true);
    }
  });

  test('skipLargeDirs skips directories with too many entries', () async {
    final root = Directory.systemTemp.createTempSync('large_test');
    try {
      File(p.join(root.path, '.stignore')).writeAsStringSync('root');
      final big = Directory(p.join(root.path, 'big'))..createSync();
      for (var i = 0; i < 120; i++) {
        File(p.join(big.path, 'f$i')).writeAsStringSync('x');
      }
      File(p.join(big.path, '.stignore')).writeAsStringSync('inside');

      final filtered = await findStignoreFiles(
        root.path,
        skipLargeDirs: true,
        maxFilesPerDir: 100,
      );
      final filteredPaths = filtered.map((r) => r.path).toList();
      expect(filteredPaths, contains(p.join(root.path, '.stignore')));
      expect(filteredPaths,
          isNot(contains(p.join(big.path, '.stignore'))));
      expect(filtered.length, 1);

      final unfiltered = await findStignoreFiles(
        root.path,
        skipLargeDirs: false,
        maxFilesPerDir: 100,
      );
      expect(unfiltered.length, 2);
    } finally {
      root.deleteSync(recursive: true);
    }
  });
}
