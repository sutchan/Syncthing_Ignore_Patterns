import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/services/file_drop.dart';

void main() {
  test('classifyDrop routes directories to the scan root', () {
    expect(classifyDrop(r'C:\data', isDirectory: true), DropTarget.root);
  });

  test('classifyDrop routes rules and manifest files to the manifest path', () {
    expect(
      classifyDrop(r'C:\x\.stignore', isDirectory: false),
      DropTarget.manifest,
    );
    expect(
      classifyDrop(r'C:\x\paths.JSON', isDirectory: false),
      DropTarget.manifest,
    );
  });

  test('classifyDrop ignores unrelated files', () {
    expect(
      classifyDrop(r'C:\x\photo.png', isDirectory: false),
      DropTarget.ignore,
    );
  });
}
