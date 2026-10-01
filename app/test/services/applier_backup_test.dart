import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/models/manifest.dart';
import 'package:syncthing_ignore_gui/services/applier.dart';
import 'package:syncthing_ignore_gui/services/rules_source.dart';

void main() {
  test('applyRules never backs up a target that is the source file itself',
      () async {
    final dir = Directory.systemTemp.createTempSync('apply_self');
    try {
      // The same file is both the rules source and a manifest target, and its
      // on-disk content differs from sourceContent (so the hash check does not
      // skip it). Backing it up would leave a `.stignore.bak.*` self-copy.
      final self = File(p.join(dir.path, '.stignore'))
        ..writeAsStringSync('OLD');
      final manifest = Manifest(
        version: '1.0',
        scannedAt: '',
        roots: [],
        files: [
          StignoreRecord(
              path: self.path, size: 0, lastWriteUtc: '', foundAtUtc: ''),
        ],
      );

      final res = await applyRules(
        manifest: manifest,
        sourceContent: 'NEW',
        sourceHash: sha256OfString('NEW'),
        sourcePath: self.path,
        whatIf: false,
        force: false,
        backup: true,
        log: (m, l) {},
      );

      // The file is rewritten, but no self-backup is created.
      expect(res.replaced, 1);
      expect(self.readAsStringSync(), 'NEW');
      final backups = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('.bak.'))
          .toList();
      expect(backups, isEmpty);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('limitBackups keeps at most 3 newest', () {
    final dir = Directory.systemTemp.createTempSync('bak_test');
    try {
      final base = p.join(dir.path, '.stignore');
      for (var i = 0; i < 5; i++) {
        File('$base.bak.2024010${i}000000').writeAsStringSync('x');
      }
      final removed = limitBackups(base);
      expect(removed, 2);
      final remaining = Directory(dir.path)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('.bak.'))
          .length;
      expect(remaining, 3);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
