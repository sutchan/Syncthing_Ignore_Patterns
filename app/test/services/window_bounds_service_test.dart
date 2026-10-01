import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/models/window_bounds.dart';
import 'package:syncthing_ignore_gui/services/window_bounds.dart';

void main() {
  test('implausibly small geometry is refused before any Win32 call', () {
    const tiny = WindowBounds(x: 0, y: 0, width: 10, height: 10);
    expect(tiny.isUsable, isFalse);
    expect(applyWindowBounds(tiny), isFalse);
  });

  test('readWindowBounds returns null or a positive geometry', () {
    // Whether a runner window exists depends on the host; the contract is that
    // the result is either `null` or a sane geometry (never negative sizes).
    final bounds = readWindowBounds();
    if (bounds != null) {
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    }
  });
}
