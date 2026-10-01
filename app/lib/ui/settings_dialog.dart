/// Language + theme preferences.
///
/// Every change is written to disk immediately, so the choices survive a
/// restart.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/window_bounds_service.dart';
import '../state/app_state.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  /// Shows the dialog as a modal route.
  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const SettingsDialog(),
      );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.loc;

    return AlertDialog(
      key: const Key('settings-dialog'),
      title: Row(
        children: [
          const Icon(Icons.settings),
          const SizedBox(width: 8),
          Text(loc.t('settings')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(loc.t('lang')),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            key: const Key('language-selector'),
            segments: [
              ButtonSegment(value: 'en', label: Text(loc.t('enItem'))),
              ButtonSegment(value: 'zh', label: Text(loc.t('zhItem'))),
            ],
            selected: {state.lang},
            onSelectionChanged: (v) => state.setLanguage(v.first),
          ),
          const SizedBox(height: 20),
          Text(loc.t('theme')),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            key: const Key('theme-selector'),
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.light_mode),
                label: Text(loc.t('themeLight')),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.dark_mode),
                label: Text(loc.t('themeDark')),
              ),
            ],
            selected: {state.dark},
            onSelectionChanged: (v) => state.setTheme(v.first),
          ),
          if (!isWindowGeometrySupported())
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                loc.t('windowGeometryWindowsOnly'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Text(loc.t('scanDefaults')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  key: const Key('scan-depth-slider'),
                  value: state.maxDepth.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (v) {
                    state.setMaxDepth(v.round());
                    state.persistPreferences();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('${state.maxDepth} ${loc.t('level')}'),
            ],
          ),
          SwitchListTile(
            key: const Key('skip-large-dirs-switch'),
            title: Text(loc.t('skipLargeDirs')),
            value: state.filterLargeDirs,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            onChanged: (v) {
              state.setFilterLargeDirs(v);
              state.persistPreferences();
            },
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  key: const Key('max-files-slider'),
                  value: state.maxFilesPerDir.toDouble(),
                  min: 10,
                  max: 500,
                  divisions: 49,
                  onChanged: (v) {
                    state.setMaxFilesPerDir(v.round());
                    state.persistPreferences();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('${state.maxFilesPerDir}'),
            ],
          ),
          SwitchListTile(
            key: const Key('backup-default-switch'),
            title: Text(loc.t('backup')),
            value: state.backup,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            onChanged: (v) {
              state.setBackup(v);
              state.persistPreferences();
            },
          ),
          const SizedBox(height: 8),
          Text(loc.t('startupChecks')),
          const SizedBox(height: 4),
          SwitchListTile(
            key: const Key('boot-app-update-switch'),
            title: Text(loc.t('bootCheckAppUpdate')),
            value: state.bootCheckAppUpdate,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            onChanged: (v) => state.setBootCheckAppUpdate(v),
          ),
          SwitchListTile(
            key: const Key('boot-ruleset-switch'),
            title: Text(loc.t('bootCheckRuleset')),
            value: state.bootCheckRuleset,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            onChanged: (v) => state.setBootCheckRuleset(v),
          ),
        ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('settings-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.t('close')),
        ),
      ],
    );
  }
}
