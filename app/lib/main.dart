/// Entry point for the Syncthing .stignore Manager (Flutter Windows desktop).
library;

import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface framework errors (build/layout/paint) instead of crashing silently.
  FlutterError.onError = (details) {
    developer.log(
      details.exceptionAsString(),
      name: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  // Catch asynchronous errors that escape Flutter's framework handling.
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'Uncaught async error: $error',
      name: 'Uncaught',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  // Friendly screen for release builds instead of the red error page.
  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Something went wrong.\nPlease restart the app.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
  }

  final state = AppState();
  // Language must be restored first: the manifest-load step logs a localized
  // message, so it needs the saved locale.
  await state.loadSettings();
  // Ruleset metadata and the previous manifest are independent disk reads, so
  // run them concurrently instead of serially (async-parallel).
  await Future.wait([
    state.loadRulesetInfo(),
    state.loadExistingManifest(),
  ]);
  // Accept folders / .stignore files dragged onto the window.
  state.listenForFileDrops();
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
