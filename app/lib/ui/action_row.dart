/// Scan / apply / clear-log / stop buttons.
library;

import 'package:flutter/material.dart';

import '../state/app_state.dart';

class ActionRow extends StatelessWidget {
  const ActionRow({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final loc = state.loc;
    return Wrap(
      key: const Key('action-row'),
      spacing: 8,
      children: [
        ElevatedButton.icon(
          key: const Key('scan-button'),
          onPressed: state.isBusy ? null : state.scan,
          icon: const Icon(Icons.search),
          label: Text(loc.t('scan')),
        ),
        ElevatedButton.icon(
          key: const Key('apply-button'),
          onPressed: state.isBusy ? null : state.apply,
          icon: const Icon(Icons.upload),
          label: Text(loc.t('apply')),
        ),
        OutlinedButton.icon(
          key: const Key('clear-log-button'),
          onPressed: state.isBusy ? null : state.clearLog,
          icon: const Icon(Icons.clear_all),
          label: Text(loc.t('clear')),
        ),
        if (state.isBusy)
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
