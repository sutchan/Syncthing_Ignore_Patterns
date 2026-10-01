import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/rules_source.dart';

void main() {
  test('sha256OfString is a stable hex digest', () {
    final h = sha256OfString('abc');
    expect(h.length, 64);
    expect(h, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(sha256OfString('abc'), h);
  });

  test('loadStandardRules reads a custom path verbatim', () async {
    final dir = Directory.systemTemp.createTempSync('rules_src');
    try {
      final file = File(p.join(dir.path, 'rules.stignore'))
        ..writeAsStringSync('LINE1\nLINE2\n');
      final content = await loadStandardRules(path: file.path);
      expect(content, 'LINE1\nLINE2\n');
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
