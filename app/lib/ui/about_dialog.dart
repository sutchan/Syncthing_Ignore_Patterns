/// About dialog: version, project info and a manual update check.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_update.dart';
import '../state/app_state.dart';

class AppAboutDialog extends StatelessWidget {
  const AppAboutDialog({super.key});

  /// Opens the dialog on top of the current route.
  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const AppAboutDialog(),
      );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.loc;
    final newer = state.availableAppVersion;
    return AlertDialog(
      key: const Key('about-dialog'),
      title: Text(loc.t('title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('aboutText', [state.version, 'GitHub'])),
          if (state.appUpdateStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(state.appUpdateStatus,
                key: const Key('about-update-status'),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (state.updateInstallStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(state.updateInstallStatus,
                key: const Key('about-install-status'),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
      actions: [
        if (newer != null)
          TextButton(
            key: const Key('about-open-releases'),
            onPressed: _openReleases,
            child: Text(loc.t('openReleases')),
          ),
        if (newer != null)
          FilledButton(
            key: const Key('about-install-update'),
            onPressed: (state.installingUpdate || state.checkingAppUpdate)
                ? null
                : state.installUpdate,
            child: Text(loc.t('installUpdate')),
          ),
        TextButton.icon(
          key: const Key('about-check-update'),
          onPressed: state.checkingAppUpdate ? null : state.checkAppUpdate,
          icon: state.checkingAppUpdate
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(loc.t('checkAppUpdate')),
        ),
        TextButton(
          key: const Key('about-close'),
          onPressed: () => Navigator.pop(context),
          child: Text(loc.t('close')),
        ),
      ],
    );
  }

  /// Best-effort: open the releases page in the default browser.
  void _openReleases() {
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', appReleasesPageUrl],
            runInShell: true);
      }
    } on Exception {
      // opening the page is a convenience only
    }
  }
}
