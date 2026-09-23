/// Coloured log view.
library;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/log_state.dart';

class LogList extends StatelessWidget {
  const LogList({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('log-list'),
      height: 200,
      child: Card(
        child: ListView.builder(
          itemCount: state.logs.length,
          itemBuilder: (_, i) {
            final LogEntry entry = state.logs[i];
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
