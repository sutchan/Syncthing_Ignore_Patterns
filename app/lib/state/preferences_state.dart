/// Language, theme and window-geometry preferences, persisted to disk.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../i18n.dart';
import '../models/window_bounds.dart';
import '../services/settings_store.dart';
import '../services/window_bounds.dart';

/// Preferences shared by the UI; mixed into `AppState`.
///
/// Call [initPreferences] once from the owning class' constructor to supply the
/// backing store (tests inject a temporary directory).
mixin PreferencesState on ChangeNotifier {
  final AppLocalizations _en = AppLocalizations('en');
  final AppLocalizations _zh = AppLocalizations('zh');

  late SettingsStore _settings;
  Timer? _windowTimer;
  WindowBounds? _windowBounds;
  String _lang = 'en';
  bool _dark = false;

  /// Wires the persistence layer; must run before [loadSettings].
  void initPreferences(SettingsStore store) => _settings = store;

  /// Localizations for the current language.
  AppLocalizations get loc => _lang == 'zh' ? _zh : _en;

  /// Current UI language code.
  String get lang => _lang;

  /// `true` when the dark theme is active.
  bool get dark => _dark;

  /// Last known window geometry, or `null` when none was saved yet.
  WindowBounds? get windowBounds => _windowBounds;

  void setLanguage(String value) {
    if (!AppLocalizations.supported.contains(value) || _lang == value) return;
    _lang = value;
    _persistSettings();
    notifyListeners();
  }

  void setTheme(bool isDark) {
    if (_dark == isDark) return;
    _dark = isDark;
    _persistSettings();
    notifyListeners();
  }

  /// Restores the persisted preferences. Call once before `runApp` so the
  /// first frame already uses the saved language, theme and window geometry.
  Future<void> loadSettings() async {
    final saved = await _settings.load();
    _lang = AppLocalizations.supported.contains(saved.lang) ? saved.lang : 'en';
    _dark = saved.dark;
    _windowBounds = saved.window;
    notifyListeners();
  }

  /// Moves the window to the saved geometry.
  ///
  /// Call after the runner window exists (e.g. from a post-frame callback); a
  /// no-op when nothing was saved or the saved geometry is unusable.
  void restoreWindowBounds() {
    final saved = _windowBounds;
    if (saved != null) applyWindowBounds(saved);
  }

  /// Persists the window geometry when it changed since the last write.
  void captureWindowBounds() {
    final current = readWindowBounds();
    if (current == null || current == _windowBounds) return;
    _windowBounds = current;
    _persistSettings();
  }

  /// Starts sampling the window geometry.
  ///
  /// Move/resize notifications would need a native hook, so the geometry is
  /// polled instead; only actual changes reach the disk.
  void startWindowTracking({Duration interval = const Duration(seconds: 2)}) {
    _windowTimer?.cancel();
    _windowTimer = Timer.periodic(interval, (_) => captureWindowBounds());
  }

  void _persistSettings() {
    unawaited(_settings.save(
      AppSettings(lang: _lang, dark: _dark, window: _windowBounds),
    ));
  }

  @override
  void dispose() {
    _windowTimer?.cancel();
    super.dispose();
  }
}
