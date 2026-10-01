/// Result-list header: title + count, search box, compliance / type filter
/// chips, and the bulk-action toolbar shown when rows are selected.
///
/// Rendered as a [SliverToBoxAdapter] so it sits above [ResultsListSliver] in
/// the page's single [CustomScrollView].
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state/app_state.dart';
import '../state/results_view_state.dart';

class ResultsHeader extends StatelessWidget {
  const ResultsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    final total = context.select<AppState, int>((s) => s.results.length);
    final results = context.select<AppState, List<String>>((s) => s.results);
    final compliance =
        context.select<AppState, Map<String, bool>>((s) => s.compliance);
    final query = context.select<AppState, String>((s) => s.resultQuery);
    final cf = context.select<AppState, String>((s) => s.complianceFilter);
    final tf = context.select<AppState, String>((s) => s.typeFilter);
    final selectedCount =
        context.select<AppState, int>((s) => s.selected.length);
    final shown = filterResults(results, compliance, query, cf, tf).length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('results'),
                key: const Key('results-label'),
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              loc.t('complianceSummary',
                  [context.select<AppState, int>((s) => s.needsApplyCount),
                   context.select<AppState, int>((s) => s.compliantCount)]),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(loc.t('resultCount', [shown, total])),
            const SizedBox(height: 4),
            TextField(
              key: const Key('result-search'),
              onChanged: (v) => context.read<AppState>().setResultQuery(v),
              decoration: InputDecoration(
                hintText: loc.t('searchResults'),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                _chip(context, 'all', cf, loc.t('filterAll'), true),
                _chip(context, 'need', cf, loc.t('filterNeed'), true),
                _chip(context, 'ok', cf, loc.t('filterOk'), true),
                const SizedBox(width: 8),
                _chip(context, 'all', tf, loc.t('typeAll'), false),
                _chip(context, 'file', tf, loc.t('typeFile'), false),
                _chip(context, 'dir', tf, loc.t('typeDir'), false),
              ],
            ),
            if (selectedCount > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(loc.t('selectedCount', [selectedCount]),
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('open-folders'),
                    onPressed: () => _openFolders(context),
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: Text(loc.t('openFolders')),
                  ),
                  TextButton.icon(
                    key: const Key('export-paths'),
                    onPressed: () => _exportPaths(context),
                    icon: const Icon(Icons.upload, size: 16),
                    label: Text(loc.t('exportPaths')),
                  ),
                  TextButton.icon(
                    key: const Key('clear-sel'),
                    onPressed: () => context.read<AppState>().clearSelection(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: Text(loc.t('clearSelection')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  ChoiceChip _chip(BuildContext context, String value, String current,
      String label, bool isCompliance) {
    final state = context.read<AppState>();
    return ChoiceChip(
      label: Text(label),
      selected: current == value,
      onSelected: (_) {
        if (isCompliance) {
          state.setComplianceFilter(value);
        } else {
          state.setTypeFilter(value);
        }
      },
    );
  }

  void _openFolders(BuildContext context) {
    final state = context.read<AppState>();
    for (final path in state.selected) {
      try {
        if (Platform.isWindows) Process.run('explorer', [p.dirname(path)]);
      } on Exception {
        // ignore - opening is a convenience only
      }
    }
  }

  Future<void> _exportPaths(BuildContext context) async {
    final state = context.read<AppState>();
    final uri = await FilePicker.saveFile(
      dialogTitle: state.loc.t('exportPaths'),
      fileName: 'stignore-paths.txt',
      bytes: Uint8List(0),
    );
    if (uri == null) return;
    await state.exportSelected(uri.toFilePath());
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(state.loc.t('exportPaths'))));
  }
}
