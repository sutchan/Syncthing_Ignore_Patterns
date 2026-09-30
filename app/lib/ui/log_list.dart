/// Coloured log view.
///
/// Subscribes only to the `logs` slice. The state layer coalesces log
/// notifications to at most one per frame, so a large Apply run rebuilds this
/// list ≤60 times per second instead of once per emitted line.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/log_state.dart';

class LogList extends StatelessWidget {
  const LogList({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.select<AppState, List<LogEntry>>((s) => s.logs);
    return SizedBox(
      key: const Key('log-list'),
      height: 200,
      child: Card(
        child: ListView.builder(
          itemCount: logs.length,
          itemBuilder: (_, i) {
            final LogEntry entry = logs[i];
            final color = switch (entry.level) {
              'error' => Colors.red,
              'warn' => Colors.orange,
              'muted' => Colors.grey,
              _ => Theme.of(context).textTheme.bodyMedium?.color,
            };
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Text(entry.text,
                  style: TextStyle(fontSize: 12, color: color)),
            );
          },
        ),
      ),
    );
  }
}
