/// Language + theme preferences.
///
/// Every change is written to disk immediately, so the choices survive a
/// restart.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      content: Column(
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
        ],
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
