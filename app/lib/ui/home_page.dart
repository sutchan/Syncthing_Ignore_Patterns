/// Main screen: assembles the scan/apply UI from focused sub-widgets.
///
/// This shell only subscribes to the current locale (which changes rarely);
/// each sub-widget selects the narrow slice of `AppState` it actually renders,
/// so high-frequency notifications (scan progress, apply logs) rebuild only
/// the affected leaf instead of the whole column.
///
/// The page is one [CustomScrollView] of slivers: the short form is one eager
/// box, while the result/log sections are lazy `SliverList.builder`s. This
/// replaces a `SingleChildScrollView` wrapping two nested fixed-height
/// `ListView`s — the nested viewports built their item rows inside an
/// already-eager column; the sliver lists build rows only when they scroll
/// into view and share a single scroll position.
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
      body: const CustomScrollView(
        key: Key('home-scroll'),
        slivers: [
          // The form is short and cheap, so it is built eagerly as one box.
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RootField(),
                  SizedBox(height: 12),
                  OptionsRow(),
                  SizedBox(height: 12),
                  ScanOptions(),
                  SizedBox(height: 12),
                  RulesetCard(),
                  SizedBox(height: 12),
                  ActionRow(),
                  SizedBox(height: 12),
                  _ProgressSection(),
                ],
              ),
            ),
          ),
          // The lists are the only potentially long parts; their rows are
          // built lazily and share the page's single scroll position.
          ResultsSliver(),
          LogSliver(),
        ],
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
      ],
    );
  }
}
