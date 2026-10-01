/// Lazy sliver listing the found `.stignore` files (search / filter / selection
/// applied via [ResultsViewState]).
///
/// Tapping a row reveals its containing folder; double-click opens the file;
/// right-click copies the path. A leading checkbox toggles selection for the
/// bulk actions shown in [ResultsHeader].
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state/app_state.dart';
import '../state/results_view_state.dart';

class ResultsListSliver extends StatelessWidget {
  const ResultsListSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    final results = context.select<AppState, List<String>>((s) => s.results);
    final compliance =
        context.select<AppState, Map<String, bool>>((s) => s.compliance);
    final query = context.select<AppState, String>((s) => s.resultQuery);
    final cf = context.select<AppState, String>((s) => s.complianceFilter);
    final tf = context.select<AppState, String>((s) => s.typeFilter);
    final items = filterResults(results, compliance, query, cf, tf);

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text(loc.t('noResults'))),
      );
    }
    return SliverPadding(
      key: const Key('results-list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final path = items[i];
          final ok = compliance[path] ?? false;
          final isSel =
              context.select<AppState, bool>((s) => s.isSelected(path));
          return _ResultsRow(path: path, ok: ok, selected: isSel);
        },
      ),
    );
  }
}

class _ResultsRow extends StatelessWidget {
  const _ResultsRow({
    required this.path,
    required this.ok,
    required this.selected,
  });

  final String path;
  final bool ok;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return InkWell(
      key: Key('result-row-$path'),
      onTap: () => _openFolder(path),
      onDoubleTap: () => _openFile(path),
      onSecondaryTap: () => _copyPath(context, path),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Checkbox(
              key: Key('result-check-$path'),
              value: selected,
              onChanged: (_) => state.toggleSelected(path),
            ),
            Icon(
              ok ? Icons.check_circle : Icons.pending,
              size: 16,
              color: ok ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(path,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  void _openFolder(String path) {
    try {
      if (Platform.isWindows) Process.run('explorer', [p.dirname(path)]);
    } on Exception {
      // ignore - opening is a convenience only
    }
  }

  void _openFile(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', path], runInShell: true);
      }
    } on Exception {
      // ignore - opening is a convenience only
    }
  }

  void _copyPath(BuildContext context, String path) {
    Clipboard.setData(ClipboardData(text: path));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<AppState>().loc.t('pathCopied'))),
    );
  }
}
