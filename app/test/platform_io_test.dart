import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/services/platform_io.dart';

void main() {
  test('listFixedDrives returns at least one root', () {
    final drives = listFixedDrives();
    expect(drives, isNotEmpty);
    if (Platform.isWindows) {
      for (final d in drives) {
        expect(d, matches(RegExp(r'^[A-Za-z]:\\$')));
      }
    }
  });
}
