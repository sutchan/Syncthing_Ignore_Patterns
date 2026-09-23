/// Main screen: assembles the scan/apply UI from focused sub-widgets.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'action_row.dart';
import 'log_list.dart';
import 'options_row.dart';
import 'results_list.dart';
import 'root_field.dart';
import 'scan_options.dart';
import 'settings_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.loc;

    return Scaffold(
      key: const Key('home-scaffold'),
      appBar: AppBar(
        title: Text(loc.t('title')),
        actions: [
          IconButton(
            key: const Key('settings-button'),
            icon: const Icon(Icons.settings),
            tooltip: loc.t('settings'),
            onPressed: () => SettingsDialog.show(context),
          ),
          IconButton(
            key: const Key('about-button'),
            icon: const Icon(Icons.info_outline),
            tooltip: loc.t('about'),
            onPressed: () => _showAbout(context, state),
          ),
        ],
      ),
      body: SingleChildScrollView(
        key: const Key('home-scroll'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RootField(state: state),
            const SizedBox(height: 12),
            OptionsRow(state: state),
            const SizedBox(height: 12),
            ScanOptions(state: state),
            const SizedBox(height: 12),
            ActionRow(state: state),
            const SizedBox(height: 12),
            if (state.isBusy)
              LinearProgressIndicator(
                key: const Key('progress-bar'),
                value: state.progress,
                minHeight: 6,
              ),
            const SizedBox(height: 6),
            Text(state.status,
                key: const Key('status-text'),
                style: Theme.of(context).textTheme.bodySmall),
            Text(state.summary,
                key: const Key('summary-text'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Text(loc.t('results'),
                key: const Key('results-label'),
                style: Theme.of(context).textTheme.titleMedium),
            ResultsList(state: state),
            const SizedBox(height: 12),
            Text(loc.t('log'),
                key: const Key('log-label'),
                style: Theme.of(context).textTheme.titleMedium),
            LogList(state: state),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context, AppState state) {
    final loc = state.loc;
    showAboutDialog(
      context: context,
      applicationName: loc.t('title'),
      applicationVersion: state.version,
      children: [Text(loc.t('aboutText', [state.version, 'GitHub']))],
    );
  }
}
