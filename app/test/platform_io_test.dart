import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/services/platform_io.dart';

void main() {
  test('listScanDrives returns at least one root', () {
    final drives = listScanDrives();
    expect(drives, isNotEmpty);
    if (Platform.isWindows) {
      for (final d in drives) {
        expect(d, matches(RegExp(r'^[A-Za-z]:\\$')));
      }
    }
  });

  group('normalizeRootPath', () {
    test('trims surrounding whitespace', () {
      final r = normalizeRootPath('  D:\\  ');
      expect(r, equals(r.trim()));
    });

    test('expands bare drive letter and normalizes slashes on Windows', () {
      if (!Platform.isWindows) return;
      expect(normalizeRootPath('Z:'), 'Z:\\');
      expect(normalizeRootPath('z:'), 'z:\\');
      expect(normalizeRootPath('//server/share'), '\\\\server\\share');
      expect(normalizeRootPath('C:\\foo'), 'C:\\foo');
      expect(normalizeRootPath(''), '');
    });
  });
}
