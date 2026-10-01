/// Reads and restores the top-level window geometry via the Win32 API.
///
/// Flutter's Windows runner registers its window class as
/// `FLUTTER_RUNNER_WIN32_WINDOW` (see `windows/runner/win32_window.cpp`), so the
/// handle can be located by class name without touching the C++ runner. All
/// helpers are no-ops on non-Windows platforms.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../models/window_bounds.dart';

/// Window class registered by Flutter's Windows runner template.
const String _runnerWindowClass = 'FLUTTER_RUNNER_WIN32_WINDOW';

/// Finds the runner's top-level window, or `null` when it cannot be located.
HWND? _findRunnerWindow() {
  if (!Platform.isWindows) return null;
  final className = _runnerWindowClass.toNativeUtf16();
  try {
    final hwnd = FindWindow(PCWSTR(className), null).value;
    return hwnd.address == 0 ? null : hwnd;
  } finally {
    free(className);
  }
}

/// Returns the window's current geometry, or `null` when unavailable.
WindowBounds? readWindowBounds() {
  final hwnd = _findRunnerWindow();
  if (hwnd == null) return null;
  final rect = calloc.allocate<RECT>(sizeOf<RECT>());
  try {
    if (!GetWindowRect(hwnd, rect).value) return null;
    final r = rect.ref;
    return WindowBounds(
      x: r.left,
      y: r.top,
      width: r.right - r.left,
      height: r.bottom - r.top,
    );
  } finally {
    calloc.free(rect);
  }
}

/// Moves/resizes the window to [bounds]. Returns `true` on success.
///
/// Unusable (too small) bounds and bounds that fall outside the current virtual
/// screen are ignored, so a window saved on a disconnected monitor never
/// reappears off-screen.
bool applyWindowBounds(WindowBounds bounds) {
  if (!bounds.isUsable || !_isOnVirtualScreen(bounds)) return false;
  final hwnd = _findRunnerWindow();
  if (hwnd == null) return false;
  return SetWindowPos(
    hwnd,
    null,
    bounds.x,
    bounds.y,
    bounds.width,
    bounds.height,
    SWP_NOZORDER | SWP_NOACTIVATE,
  ).value;
}

/// Whether [bounds] intersects the virtual screen (all monitors combined).
bool _isOnVirtualScreen(WindowBounds bounds) {
  final left = GetSystemMetrics(SM_XVIRTUALSCREEN);
  final top = GetSystemMetrics(SM_YVIRTUALSCREEN);
  final width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  final height = GetSystemMetrics(SM_CYVIRTUALSCREEN);
  if (width <= 0 || height <= 0) return true; // metrics unavailable: don't block
  return bounds.x + bounds.width > left &&
      bounds.y + bounds.height > top &&
      bounds.x < left + width &&
      bounds.y < top + height;
}
