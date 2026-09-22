/// Windows-specific helpers. The tool targets Windows desktop, so drive
/// enumeration uses the Win32 API. On non-Windows (e.g. tests) it falls back
/// to the current directory so the rest of the logic stays exercisable.
library;

import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Returns the list of fixed (local) drive roots, e.g. `['C:\\', 'D:\\']`.
List<String> listFixedDrives() {
  if (!Platform.isWindows) return [Directory.current.path];
  final mask = GetLogicalDrives();
  final drives = <String>[];
  for (var i = 0; i < 26; i++) {
    if ((mask & (1 << i)) != 0) {
      final root = '${String.fromCharCode(65 + i)}:\\';
      final ptr = root.toNativeUtf16();
      try {
        // DRIVE_FIXED == 3
        if (GetDriveType(ptr) == 3) drives.add(root);
      } finally {
        free(ptr);
      }
    }
  }
  return drives;
}
