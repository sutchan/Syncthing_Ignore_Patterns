/// Scan-root and manifest path inputs plus their pickers.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'preferences_state.dart';

mixin PickersState on ChangeNotifier, PreferencesState {
  /// Scan root typed or picked by the user (blank = all fixed drives).
  String rootText = '';

  /// Where the manifest JSON is written.
  String manifestPath = 'config${Platform.pathSeparator}stignore-paths.json';

  Future<void> pickRoot() async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: loc.t('folderTitle'),
    );
    if (dir == null) return;
    rootText = dir;
    notifyListeners();
  }

  Future<void> pickManifest() async {
    // file_picker 13+ 的 saveFile 会写入 bytes 并返回 Uri；此处写入占位空字节，
    // 实际清单内容由 scan()/apply() 覆盖写入。
    final uri = await FilePicker.saveFile(
      dialogTitle: loc.t('fileTitle'),
      fileName: 'stignore-paths.json',
      bytes: Uint8List(0),
    );
    if (uri == null) return;
    manifestPath = uri.toFilePath();
    notifyListeners();
  }
}
