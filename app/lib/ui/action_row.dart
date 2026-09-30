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
    final preview = context.select<AppState, bool>((s) => s.preview);
    final force = context.select<AppState, bool>((s) => s.force);
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
          onPressed: isBusy
              ? null
              : () => _onApply(context, state, loc, preview, force),
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

  /// Runs Apply, but first asks for confirmation when the run would actually
  /// write files (i.e. not preview-only and not force) — mirroring the safety
  /// prompt in the PowerShell tool.
  Future<void> _onApply(
    BuildContext context,
    AppState state,
    AppLocalizations loc,
    bool preview,
    bool force,
  ) async {
    if (!preview && !force) {
      final count = state.pendingApplyCount();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('apply-confirm-dialog'),
          title: Text(loc.t('applyTitle')),
          content: Text(loc.t('applyConfirm', [count])),
          actions: [
            TextButton(
              key: const Key('apply-confirm-cancel'),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.t('cancel')),
            ),
            FilledButton(
              key: const Key('apply-confirm-ok'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.t('apply')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await state.apply();
  }
}
