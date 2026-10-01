import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/services/version_util.dart';

void main() {
  test('isValidVersion accepts plain semver-like versions', () {
    expect(isValidVersion('1.28.5'), isTrue);
    expect(isValidVersion('1.0'), isTrue);
    expect(isValidVersion('0.0.1'), isTrue);
  });

  test('isValidVersion rejects path-traversal-capable tags', () {
    // A release tag that embeds a separator or `..` segment must be rejected
    // before it is interpolated into a download URL or an archive path.
    expect(isValidVersion('1.24.0/evil'), isFalse);
    expect(isValidVersion('1.24.0..'), isFalse);
    expect(isValidVersion('../1.24.0'), isFalse);
    // The `v` prefix is stripped before validation, so a raw `v` is invalid here.
    expect(isValidVersion('v1.24.0'), isFalse);
    expect(isValidVersion(''), isFalse);
    expect(isValidVersion('   '), isFalse);
  });
}
