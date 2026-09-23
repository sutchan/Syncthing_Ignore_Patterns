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
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const App(),
    ),
  );
}
