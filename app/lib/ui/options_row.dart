/// Preview / force / backup checkboxes.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state/app_state.dart';

class OptionsRow extends StatelessWidget {
  const OptionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    final preview = context.select<AppState, bool>((s) => s.preview);
    final force = context.select<AppState, bool>((s) => s.force);
    final backup = context.select<AppState, bool>((s) => s.backup);
    final state = context.read<AppState>();

    return Wrap(
      key: const Key('options-row'),
      spacing: 16,
      runSpacing: 4,
      children: [
        _OptionCheckbox(
          id: 'preview-checkbox',
          label: loc.t('preview'),
          value: preview,
          onChanged: state.setPreview,
        ),
        _OptionCheckbox(
          id: 'force-checkbox',
          label: loc.t('force'),
          value: force,
          onChanged: state.setForce,
        ),
        _OptionCheckbox(
          id: 'backup-checkbox',
          label: loc.t('backup'),
          value: backup,
          onChanged: state.setBackup,
        ),
      ],
    );
  }
}

/// Checkbox with a stable key, used for debugging and widget tests.
class _OptionCheckbox extends StatelessWidget {
  const _OptionCheckbox({
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String id;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: Key(id),
      title: Text(label),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}
