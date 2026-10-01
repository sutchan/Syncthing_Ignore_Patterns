import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/app_paths.dart';

void main() {
  test('defaultDataDirectory resolves to the per-user app folder', () {
    final dir = defaultDataDirectory();
    expect(dir, isNotEmpty);
    expect(
      ['SyncthingIgnoreGUI', '.syncthing_ignore_gui'],
      contains(p.basename(dir)),
    );
  });
}
