/// Backup manager dialog: lists the `.stignore.bak.*` files discovered for the
/// current scan results and offers restore / delete for each.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class BackupDialog extends StatelessWidget {
  const BackupDialog({super.key});

  /// Loads the backups and shows the dialog as a modal route.
  static Future<void> show(BuildContext context) {
    final state = context.read<AppState>();
    unawaited(state.loadBackups(state.results));
    return showDialog<void>(
      context: context,
      builder: (_) => const BackupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.loc;
    final backups = state.backups;

    return AlertDialog(
      key: const Key('backup-dialog'),
      title: Row(
        children: [
          const Icon(Icons.history),
          const SizedBox(width: 8),
          Text(loc.t('backups')),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 360,
        child: backups.isEmpty
            ? Center(child: Text(loc.t('noBackups')))
            : ListView.builder(
                itemCount: backups.length,
                itemBuilder: (_, i) {
                  final e = backups[i];
                  return ListTile(
                    key: Key('backup-row-$i'),
                    title: Text(e.targetName),
                    subtitle: Text('${e.target}\n${e.modified}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('backup-restore-$i'),
                          icon: const Icon(Icons.restore),
                          tooltip: loc.t('restore'),
                          onPressed: () => unawaited(state.restoreBackup(e.bakPath)),
                        ),
                        IconButton(
                          key: Key('backup-delete-$i'),
                          icon: const Icon(Icons.delete),
                          tooltip: loc.t('delete'),
                          onPressed: () => unawaited(state.deleteBackup(e.bakPath)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          key: const Key('backup-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.t('close')),
        ),
      ],
    );
  }
}
