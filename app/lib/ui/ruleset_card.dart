/// Ruleset version display plus the "check for update" action.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../models/ruleset_info.dart';
import '../state/app_state.dart';

class RulesetCard extends StatelessWidget {
  const RulesetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    final info = context.select<AppState, RulesetInfo?>((s) => s.ruleset);
    final downloaded =
        context.select<AppState, bool>((s) => s.rulesetDownloaded);
    final rulesetPath =
        context.select<AppState, String>((s) => s.rulesetPath);
    final checking =
        context.select<AppState, bool>((s) => s.checkingRuleset);
    final status = context.select<AppState, String>((s) => s.rulesetStatus);
    final state = context.read<AppState>();

    final theme = Theme.of(context);
    final version = info == null ? '—' : 'v${info.version}';
    final origin =
        downloaded ? loc.t('rulesetDownloaded') : loc.t('rulesetBuiltin');
    final updated = info?.updated;

    return Card(
      key: const Key('ruleset-card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('ruleset'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Tooltip(
              message: loc.t('rulesetPath', [rulesetPath]),
              child: Text(
                '${loc.t('rulesetCurrent', [version])} · $origin'
                '${updated == null ? '' : ' · ${loc.t('rulesetUpdatedAt', [updated])}'}',
                key: const Key('ruleset-version'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('ruleset-check-button'),
              onPressed: checking ? null : state.checkRulesetUpdate,
              icon: checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(checking
                  ? loc.t('rulesetChecking')
                  : loc.t('checkRulesetUpdate')),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                status,
                key: const Key('ruleset-status'),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (state.rulesetAdded > 0 || state.rulesetRemoved > 0) ...[
              const SizedBox(height: 6),
              Text(
                loc.t('rulesetChanges', [state.rulesetAdded, state.rulesetRemoved]),
                key: const Key('ruleset-diff'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
