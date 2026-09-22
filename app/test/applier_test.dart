import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/models/manifest.dart';
import 'package:syncthing_ignore_gui/services/applier.dart';
import 'package:syncthing_ignore_gui/services/rules_source.dart';
import 'package:test/test.dart';

void main() {
  test('applyRules replaces targets, skips identical, backs up', () async {
    final dir = Directory.systemTemp.createTempSync('apply_test');
    try {
      final source = File(p.join(dir.path, 'source.stignore'))
        ..writeAsStringSync('RULES');
      final targetDir = Directory(p.join(dir.path, 'target'))..createSync();
      final target = File(p.join(targetDir.path, '.stignore'))
        ..writeAsStringSync('OLD');
      final target2Dir = Directory(p.join(dir.path, 'target2'))..createSync();
      final target2 = File(p.join(target2Dir.path, '.stignore'))
        ..writeAsStringSync('RULES'); // identical to source

      final manifest = Manifest(
        version: '1.0',
        scannedAt: '',
        roots: [],
        files: [
          StignoreRecord(
              path: target.path, size: 0, lastWriteUtc: '', foundAtUtc: ''),
          StignoreRecord(
              path: target2.path, size: 0, lastWriteUtc: '', foundAtUtc: ''),
        ],
      );

      final res = await applyRules(
        manifest: manifest,
        sourceContent: 'RULES',
        sourceHash: sha256OfString('RULES'),
        sourcePath: source.path,
        whatIf: false,
        force: false,
        backup: true,
        log: (m, l) {},
      );

      expect(res.replaced, 1);
      expect(res.identicalCount, 1);
      expect(target.readAsStringSync(), 'RULES');

      final backups = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('.bak.'))
          .toList();
      expect(backups.length, 1);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('preview mode writes nothing', () async {
    final dir = Directory.systemTemp.createTempSync('apply_preview');
    try {
      final target = File(p.join(dir.path, '.stignore'))
        ..writeAsStringSync('OLD');
      final manifest = Manifest(
        version: '1.0',
        scannedAt: '',
        roots: [],
        files: [
          StignoreRecord(
              path: target.path, size: 0, lastWriteUtc: '', foundAtUtc: ''),
        ],
      );
      final res = await applyRules(
        manifest: manifest,
        sourceContent: 'NEW',
        sourceHash: sha256OfString('NEW'),
        sourcePath: p.join(dir.path, 'x.stignore'),
        whatIf: true,
        force: false,
        backup: true,
        log: (m, l) {},
      );
      expect(res.replaced, 0);
      expect(target.readAsStringSync(), 'OLD');
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
