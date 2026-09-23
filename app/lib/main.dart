/// Entry point for the Syncthing .stignore Manager (Flutter Windows desktop).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore language/theme before the first frame so the window opens with the
  // user's saved preferences instead of a default flash.
  final state = AppState();
  await state.loadSettings();
  // Ruleset metadata is read from disk (no network), so the version is visible
  // on the first frame.
  await state.loadRulesetInfo();
  // Show any manifest left over from a previous session ("loaded N file(s)").
  await state.loadExistingManifest();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const App(),
    ),
  );
  // The runner window exists once the first frame is scheduled: restore the
  // saved geometry there, then keep sampling it for the next run.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    state.restoreWindowBounds();
    state.startWindowTracking();
  });
}
