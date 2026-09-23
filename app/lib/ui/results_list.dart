/// Scrollable list of the found `.stignore` files.
///
/// Tapping a row reveals its containing folder in the OS file manager; double
/// clicking opens the file itself with the default editor.
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
          itemBuilder: (_, i) {
            final path = state.results[i];
            return InkWell(
              // Single click reveals the file; double click opens it.
              onTap: () => _openFolder(path),
              onDoubleTap: () => _openFile(path),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.description, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(path,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Best-effort: reveal the file in its folder in the OS file manager.
  void _openFolder(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer', [p.dirname(path)]);
      }
    } on Exception {
      // ignore - opening is a convenience only
    }
  }

  /// Best-effort: open the file with its default editor. `start` is a cmd
  /// builtin, so it runs through `cmd /c`; the empty title argument keeps
  /// quoted paths from being swallowed by `start`.
  void _openFile(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', path], runInShell: true);
      }
    } on Exception {
      // ignore - opening is a convenience only
    }
  }
}
