/// Main screen: controls for scan/apply plus live status, results and log.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: loc.t('settings'),
            onPressed: () => _showSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: loc.t('about'),
            onPressed: () => _showAbout(context, state),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RootField(state: state),
            const SizedBox(height: 12),
            _OptionsRow(state: state),
            const SizedBox(height: 12),
            _ScanOptions(state: state),
            const SizedBox(height: 12),
            _ActionRow(state: state),
            const SizedBox(height: 12),
            if (state.isBusy)
              LinearProgressIndicator(
                value: state.progress,
                minHeight: 6,
              ),
            const SizedBox(height: 6),
            Text(state.status, style: Theme.of(context).textTheme.bodySmall),
            Text(state.summary,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Text(loc.t('results'),
                style: Theme.of(context).textTheme.titleMedium),
            _ResultsList(state: state),
            const SizedBox(height: 12),
            Text(loc.t('log'),
                style: Theme.of(context).textTheme.titleMedium),
            _LogList(state: state),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context, AppState state) {
    final loc = state.loc;
    showAboutDialog(
      context: context,
      applicationName: loc.t('title'),
      applicationVersion: state.version,
      children: [Text(loc.t('aboutText', [state.version, 'GitHub']))],
    );
  }

  void _showSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _SettingsDialog(),
    );
  }
}

/// Language + theme preferences. Every change is written to disk
/// immediately, so the choices survive a restart.
class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.loc;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings),
          const SizedBox(width: 8),
          Text(loc.t('settings')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('lang')),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(loc.t('enItem'))),
              ButtonSegment(value: 'zh', label: Text(loc.t('zhItem'))),
            ],
            selected: {state.lang},
            onSelectionChanged: (v) => state.setLanguage(v.first),
          ),
          const SizedBox(height: 20),
          Text(loc.t('theme')),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.light_mode),
                label: Text(loc.t('themeLight')),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.dark_mode),
                label: Text(loc.t('themeDark')),
              ),
            ],
            selected: {state.dark},
            onSelectionChanged: (v) => state.setTheme(v.first),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.t('close')),
        ),
      ],
    );
  }
}

class _RootField extends StatelessWidget {
  const _RootField({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final loc = state.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.t('lblRoot')),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: state.rootText,
                onChanged: (v) => state.rootText = v,
                decoration: InputDecoration(
                  hintText: loc.t('dragTip'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.isBusy ? null : state.pickRoot,
              child: Text(loc.t('browse')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(loc.t('lblOut')),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: state.manifestPath,
                onChanged: (v) => state.manifestPath = v,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.isBusy ? null : state.pickManifest,
              child: Text(loc.t('browse')),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionsRow extends StatelessWidget {
  const _OptionsRow({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final loc = state.loc;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        CheckboxListTile(
          title: Text(loc.t('preview')),
          value: state.preview,
          onChanged: (v) => state.preview = v!,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
        CheckboxListTile(
          title: Text(loc.t('force')),
          value: state.force,
          onChanged: (v) => state.force = v!,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
        CheckboxListTile(
          title: Text(loc.t('backup')),
          value: state.backup,
          onChanged: (v) => state.backup = v!,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
      ],
    );
  }
}

class _ScanOptions extends StatelessWidget {
  const _ScanOptions({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final loc = state.loc;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('scanDepth'),
                style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: state.maxDepth.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${state.maxDepth}',
                    onChanged: (v) => state.setMaxDepth(v.toInt()),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text('${state.maxDepth} ${loc.t('level')}'),
                ),
              ],
            ),
            const Divider(),
            CheckboxListTile(
              title: Text(loc.t('skipLargeDirs')),
              value: state.filterLargeDirs,
              onChanged: (v) => state.setFilterLargeDirs(v!),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            if (state.filterLargeDirs)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.maxFilesPerDir.toDouble(),
                        min: 10,
                        max: 1000,
                        divisions: 99,
                        label: '${state.maxFilesPerDir}',
                        onChanged: (v) => state.setMaxFilesPerDir(v.toInt()),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                          '${loc.t('maxFilesPerDir')}: ${state.maxFilesPerDir}'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final loc = state.loc;
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: state.isBusy ? null : state.scan,
          icon: const Icon(Icons.search),
          label: Text(loc.t('scan')),
        ),
        ElevatedButton.icon(
          onPressed: state.isBusy ? null : state.apply,
          icon: const Icon(Icons.upload),
          label: Text(loc.t('apply')),
        ),
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : state.clearLog,
          icon: const Icon(Icons.clear_all),
          label: Text(loc.t('clear')),
        ),
        if (state.isBusy)
          FilledButton.icon(
            onPressed: state.stop,
            icon: const Icon(Icons.stop),
            label: Text(loc.t('stop')),
          ),
      ],
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Card(
        child: ListView.builder(
          itemCount: state.results.length,
          itemBuilder: (_, i) => ListTile(
            dense: true,
            leading: const Icon(Icons.description, size: 18),
            title: Text(state.results[i], style: const TextStyle(fontSize: 12)),
            onTap: () => _open(state.results[i]),
          ),
        ),
      ),
    );
  }

  void _open(String path) {
    try {
      // Best-effort: open containing folder in the OS file manager.
      if (Platform.isWindows) {
        Process.run('explorer', [p.dirname(path)]);
      }
    } on Exception {
      // ignore - opening is a convenience only
    }
  }
}

class _LogList extends StatelessWidget {
  const _LogList({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Card(
        child: ListView.builder(
          itemCount: state.logs.length,
          itemBuilder: (_, i) {
            final e = state.logs[i];
            final color = switch (e.level) {
              'error' => Colors.red,
              'warn' => Colors.orange,
              'muted' => Colors.grey,
              _ => Theme.of(context).textTheme.bodyMedium?.color,
            };
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Text(e.text,
                  style: TextStyle(fontSize: 12, color: color)),
            );
          },
        ),
      ),
    );
  }
}
