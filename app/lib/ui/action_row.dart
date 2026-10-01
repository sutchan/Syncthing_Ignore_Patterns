/// Scan / apply / clear-log / stop buttons.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state/app_state.dart';

class ActionRow extends StatelessWidget {
  const ActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    final isBusy = context.select<AppState, bool>((s) => s.isBusy);
    final state = context.read<AppState>();

    return Wrap(
      key: const Key('action-row'),
      spacing: 8,
      children: [
        ElevatedButton.icon(
          key: const Key('scan-button'),
          onPressed: isBusy ? null : state.scan,
          icon: const Icon(Icons.search),
          label: Text(loc.t('scan')),
        ),
        ElevatedButton.icon(
          key: const Key('apply-button'),
          onPressed: isBusy ? null : () => runApplyWithConfirm(context, state),
          icon: const Icon(Icons.upload),
          label: Text(loc.t('apply')),
        ),
        OutlinedButton.icon(
          key: const Key('clear-log-button'),
          onPressed: isBusy ? null : state.clearLog,
          icon: const Icon(Icons.clear_all),
          label: Text(loc.t('clear')),
        ),
        if (isBusy)
          FilledButton.icon(
            key: const Key('stop-button'),
            onPressed: state.stop,
            icon: const Icon(Icons.stop),
            label: Text(loc.t('stop')),
          ),
      ],
    );
  }

}

/// Runs Apply with the same confirmation prompt used by the Apply button.
///
/// Mirrors the safety prompt in the PowerShell tool: when the run would
/// actually write files (not preview-only and not force) it asks first.
Future<void> runApplyWithConfirm(BuildContext context, AppState state) async {
  if (!state.preview && !state.force) {
    final count = state.pendingApplyCount();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('apply-confirm-dialog'),
        title: Text(state.loc.t('applyTitle')),
        content: Text(state.loc.t('applyConfirm', [count])),
        actions: [
          TextButton(
            key: const Key('apply-confirm-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(state.loc.t('cancel')),
          ),
          FilledButton(
            key: const Key('apply-confirm-ok'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(state.loc.t('apply')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }
  await state.apply();
}
