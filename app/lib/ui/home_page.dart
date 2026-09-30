/// Main screen: assembles the scan/apply UI from focused sub-widgets.
///
/// This shell only subscribes to the current locale (which changes rarely);
/// each sub-widget selects the narrow slice of `AppState` it actually renders,
/// so high-frequency notifications (scan progress, apply logs) rebuild only
/// the affected leaf instead of the whole column.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state/app_state.dart';
import 'about_dialog.dart';
import 'action_row.dart';
import 'log_list.dart';
import 'options_row.dart';
import 'results_list.dart';
import 'root_field.dart';
import 'ruleset_card.dart';
import 'scan_options.dart';
import 'settings_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);

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
            onPressed: () => AppAboutDialog.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        key: const Key('home-scroll'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RootField(),
            const SizedBox(height: 12),
            const OptionsRow(),
            const SizedBox(height: 12),
            const ScanOptions(),
            const SizedBox(height: 12),
            const RulesetCard(),
            const SizedBox(height: 12),
            const ActionRow(),
            const SizedBox(height: 12),
            const _ProgressSection(),
            Text(loc.t('results'),
                key: const Key('results-label'),
                style: Theme.of(context).textTheme.titleMedium),
            const ResultsList(),
            const SizedBox(height: 12),
            Text(loc.t('log'),
                key: const Key('log-label'),
                style: Theme.of(context).textTheme.titleMedium),
            const LogList(),
          ],
        ),
      ),
    );
  }
}

/// Progress bar plus the live status/summary lines.
///
/// Kept separate from [HomePage] because its slices update frequently while a
/// scan/apply is running; isolating the subscription keeps the rest of the
/// form out of the rebuild path.
class _ProgressSection extends StatelessWidget {
  const _ProgressSection();

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AppState, bool>((s) => s.isBusy);
    final progress = context.select<AppState, double?>((s) => s.progress);
    final status = context.select<AppState, String>((s) => s.status);
    final summary = context.select<AppState, String>((s) => s.summary);

    return Column(
      key: const Key('progress-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isBusy)
          LinearProgressIndicator(
            key: const Key('progress-bar'),
            value: progress,
            minHeight: 6,
          ),
        const SizedBox(height: 6),
        Text(status,
            key: const Key('status-text'),
            style: Theme.of(context).textTheme.bodySmall),
        Text(summary,
            key: const Key('summary-text'),
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
      ],
    );
  }
}
