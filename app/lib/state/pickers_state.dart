/// Scan-root and manifest path inputs plus their pickers.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../services/file_drop.dart';
import 'log_state.dart';
import 'preferences_state.dart';

mixin PickersState on ChangeNotifier, PreferencesState, LogState {
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

  /// Applies a path dropped onto the window.
  ///
  /// Folders become the scan root; `.stignore` / `.json` files become the
  /// manifest path; anything else is reported in the log and ignored.
  void applyDrop(String path) {
    final target =
        classifyDrop(path, isDirectory: Directory(path).existsSync());
    if (target == DropTarget.ignore) {
      log(loc.t('dropIgnored', [path]), 'muted');
      notifyListeners();
      return;
    }
    if (target == DropTarget.root) {
      rootText = path;
      log(loc.t('dropRoot', [path]), 'info');
    } else {
      manifestPath = path;
      log(loc.t('dropManifest', [path]), 'info');
    }
    notifyListeners();
  }

  /// Listens for files dropped onto the window (forwarded by the Windows
  /// runner over [fileDropChannel]); a no-op on other platforms.
  void listenForFileDrops() {
    fileDropChannel.setMethodCallHandler((call) async {
      if (call.method != 'onFilesDropped') return;
      final args = call.arguments;
      if (args is List) {
        for (final path in args.whereType<String>()) {
          applyDrop(path);
        }
      }
    });
  }
}
