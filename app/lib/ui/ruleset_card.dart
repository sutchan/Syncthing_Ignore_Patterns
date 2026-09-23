/// Ruleset version display plus the "check for update" action.
library;

import 'package:flutter/material.dart';

import '../state/app_state.dart';

class RulesetCard extends StatelessWidget {
  const RulesetCard({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final loc = state.loc;
    final theme = Theme.of(context);
    final info = state.ruleset;
    final version = info == null ? '—' : 'v${info.version}';
    final origin = state.rulesetDownloaded
        ? loc.t('rulesetDownloaded')
        : loc.t('rulesetBuiltin');
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
              message: loc.t('rulesetPath', [state.rulesetPath]),
              child: Text(
                '${loc.t('rulesetCurrent', [version])} · $origin'
                '${updated == null ? '' : ' · ${loc.t('rulesetUpdatedAt', [updated])}'}',
                key: const Key('ruleset-version'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('ruleset-check-button'),
              onPressed:
                  state.checkingRuleset ? null : state.checkRulesetUpdate,
              icon: state.checkingRuleset
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(state.checkingRuleset
                  ? loc.t('rulesetChecking')
                  : loc.t('checkRulesetUpdate')),
            ),
            if (state.rulesetStatus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                state.rulesetStatus,
                key: const Key('ruleset-status'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
