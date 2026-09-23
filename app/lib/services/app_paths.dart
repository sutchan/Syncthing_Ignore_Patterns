/// Per-user locations shared by the app's small on-disk stores.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Per-user data directory (`%APPDATA%\SyncthingIgnoreGUI` on Windows).
///
/// Used for `settings.json` and the downloaded ruleset cache.
String defaultDataDirectory() {
  final env = Platform.environment;
  if (Platform.isWindows) {
    final appData = env['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return p.join(appData, 'SyncthingIgnoreGUI');
    }
  }
  final home = env['HOME'] ?? env['USERPROFILE'] ?? Directory.systemTemp.path;
  return p.join(home, '.syncthing_ignore_gui');
}
