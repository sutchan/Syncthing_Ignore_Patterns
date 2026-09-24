/// Windows-specific helpers. The tool targets Windows desktop, so drive
/// enumeration uses the Win32 API. On non-Windows (e.g. tests) it falls back
/// to the current directory so the rest of the logic stays exercisable.
library;

import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Returns the list of local (fixed) and network-mapped drive roots,
/// e.g. `['C:\\', 'Z:\\']`. Mapped network drives (DRIVE_REMOTE == 4) are
/// included so a share mounted as a letter can be scanned; removable / CD-ROM
/// drives are excluded. On non-Windows it returns `[Directory.current.path]`.
List<String> listScanDrives() {
  if (!Platform.isWindows) return [Directory.current.path];
  final mask = GetLogicalDrives().value;
  final drives = <String>[];
  for (var i = 0; i < 26; i++) {
    if ((mask & (1 << i)) != 0) {
      final root = '${String.fromCharCode(65 + i)}:\\';
      final ptr = root.toNativeUtf16();
      try {
        // DRIVE_FIXED == 3, DRIVE_REMOTE == 4 (mapped network drive)
        final type = GetDriveType(PCWSTR(ptr));
        if (type == 3 || type == 4) drives.add(root);
      } finally {
        free(ptr);
      }
    }
  }
  return drives;
}

/// Normalizes a user-supplied scan root: trims surrounding whitespace and,
/// on Windows, converts `/` to `\` and expands a bare drive letter (`Z:`) to
/// a rooted path (`Z:\`) so the scanner walks the whole drive rather than the
/// drive's current working directory. A UNC path (`\\server\share`) is left
/// as-is apart from slash normalization. Returns the empty string unchanged.
String normalizeRootPath(String raw) {
  final r = raw.trim();
  if (r.isEmpty) return r;
  if (!Platform.isWindows) return r;
  var out = r.replaceAll('/', '\\');
  if (RegExp(r'^[A-Za-z]:$').hasMatch(out)) out = '$out\\';
  return out;
}
