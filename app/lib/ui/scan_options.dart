/// Scan-depth and large-directory filter controls.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state/app_state.dart';

class ScanOptions extends StatelessWidget {
  const ScanOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    final maxDepth = context.select<AppState, int>((s) => s.maxDepth);
    final filterLargeDirs =
        context.select<AppState, bool>((s) => s.filterLargeDirs);
    final maxFilesPerDir =
        context.select<AppState, int>((s) => s.maxFilesPerDir);
    final state = context.read<AppState>();

    return Card(
      key: const Key('scan-options-card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('scanDepth'),
                style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    key: const Key('scan-depth-slider'),
                    value: maxDepth.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$maxDepth',
                    onChanged: (v) => state.setMaxDepth(v.toInt()),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text('$maxDepth ${loc.t('level')}'),
                ),
              ],
            ),
            const Divider(),
            CheckboxListTile(
              key: const Key('skip-large-dirs-checkbox'),
              title: Text(loc.t('skipLargeDirs')),
              value: filterLargeDirs,
              onChanged: (v) => state.setFilterLargeDirs(v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            if (filterLargeDirs)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        key: const Key('max-files-slider'),
                        value: maxFilesPerDir.toDouble(),
                        min: 10,
                        max: 1000,
                        divisions: 99,
                        label: '$maxFilesPerDir',
                        onChanged: (v) => state.setMaxFilesPerDir(v.toInt()),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                          '${loc.t('maxFilesPerDir')}: $maxFilesPerDir'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
