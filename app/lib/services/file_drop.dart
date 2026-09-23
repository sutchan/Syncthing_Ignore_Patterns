/// Receives OS file drops forwarded by the Windows runner.
///
/// The native runner accepts shell drops (`DragAcceptFiles`) and forwards the
/// dropped paths over [fileDropChannel]; nothing here touches the network.
library;

import 'package:flutter/services.dart';

/// Method channel the Windows runner uses to report dropped files. The name
/// must match `kDropChannelName` in `windows/runner/flutter_window.cpp`.
const MethodChannel fileDropChannel =
    MethodChannel('syncthing_ignore_gui/drop');

/// Which input a dropped path should fill.
enum DropTarget {
  /// A folder: becomes the scan root.
  root,

  /// A `.stignore` / `.json` file: becomes the manifest path.
  manifest,

  /// Anything else: reported and ignored.
  ignore,
}

/// Decides where a dropped [path] belongs: a directory fills the scan root,
/// a `.stignore`/`.json` file fills the manifest path, anything else is ignored.
DropTarget classifyDrop(String path, {required bool isDirectory}) {
  if (isDirectory) return DropTarget.root;
  final lower = path.toLowerCase();
  if (lower.endsWith('.stignore') || lower.endsWith('.json')) {
    return DropTarget.manifest;
  }
  return DropTarget.ignore;
}
