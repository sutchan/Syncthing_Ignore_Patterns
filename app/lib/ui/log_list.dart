/// Lazy sliver rendering the coloured log view.
///
/// Rendered as a `SliverList.builder` inside the page's [CustomScrollView], so
/// lines are built only when scrolled into view (no nested viewport). The
/// state layer coalesces log notifications to at most one per frame, so a
/// large Apply run rebuilds this section ≤60 times per second instead of once
/// per emitted line.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state/app_state.dart';
import '../state/log_state.dart';

class LogSliver extends StatelessWidget {
  const LogSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    final logs = context.select<AppState, List<LogEntry>>((s) => s.logs);

    return SliverPadding(
      key: const Key('log-list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList.builder(
        itemCount: logs.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(loc.t('log'),
                      key: const Key('log-label'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    key: const Key('copy-log-button'),
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: loc.t('copyAll'),
                    onPressed: logs.isEmpty
                        ? null
                        : () => _copyAll(context, logs, loc),
                  ),
                  IconButton(
                    key: const Key('export-log-button'),
                    icon: const Icon(Icons.download, size: 18),
                    tooltip: loc.t('exportLog'),
                    onPressed: logs.isEmpty
                        ? null
                        : () => _exportLog(context, loc),
                  ),
                ],
              ),
            );
          }
          final LogEntry entry = logs[i - 1];
          final color = switch (entry.level) {
            'error' => Colors.red,
            'warn' => Colors.orange,
            'muted' => Colors.grey,
            _ => Theme.of(context).textTheme.bodyMedium?.color,
          };
          return Text(entry.text,
              key: Key('log-row-${i - 1}'),
              style: TextStyle(fontSize: 12, color: color));
        },
      ),
    );
  }

  /// Copies all log lines to the clipboard for easy issue reporting.
  void _copyAll(
      BuildContext context, List<LogEntry> logs, AppLocalizations loc) {
    final text = logs.map((e) => e.text).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('copied'))),
    );
  }

  Future<void> _exportLog(
      BuildContext context, AppLocalizations loc) async {
    final path = await context.read<AppState>().exportLog();
    if (!context.mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('exportLogFailed'))),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('exportLogDone', [path]))),
    );
  }
}
