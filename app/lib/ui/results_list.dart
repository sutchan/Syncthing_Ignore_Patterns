/// Scrollable list of the found `.stignore` files.
///
/// Tapping a row opens its containing folder in the OS file manager.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../state/app_state.dart';

class ResultsList extends StatelessWidget {
  const ResultsList({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('results-list'),
      height: 160,
      child: Card(
        child: ListView.builder(
          itemCount: state.results.length,
          itemBuilder: (_, i) => ListTile(
            dense: true,
            leading: const Icon(Icons.description, size: 18),
            title: Text(state.results[i], style: const TextStyle(fontSize: 12)),
            onTap: () => _open(state.results[i]),
          ),
        ),
      ),
    );
  }

  void _open(String path) {
    try {
      // Best-effort: open containing folder in the OS file manager.
      if (Platform.isWindows) {
        Process.run('explorer', [p.dirname(path)]);
      }
    } on Exception {
      // ignore - opening is a convenience only
    }
  }
}
