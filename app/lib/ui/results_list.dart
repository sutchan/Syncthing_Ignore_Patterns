/// Lazy sliver listing the found `.stignore` files.
///
/// Tapping a row reveals its containing folder in the OS file manager; double
/// clicking opens the file itself with the default editor.
///
/// Rendered as a `SliverList.builder` inside the page's [CustomScrollView], so
/// rows are built only when scrolled into view (no nested viewport). Only the
/// `results` slice is subscribed to, so high-frequency notifications from
/// other concerns (logging, progress) never rebuild this section.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state/app_state.dart';

class ResultsSliver extends StatelessWidget {
  const ResultsSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    final results = context.select<AppState, List<String>>((s) => s.results);

    return SliverPadding(
      key: const Key('results-list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      sliver: SliverList.builder(
        itemCount: results.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(loc.t('results'),
                  key: const Key('results-label'),
                  style: Theme.of(context).textTheme.titleMedium),
            );
          }
          final path = results[i - 1];
          return InkWell(
            // Single click reveals the file; double click opens it.
            onTap: () => _openFolder(path),
            onDoubleTap: () => _openFile(path),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
