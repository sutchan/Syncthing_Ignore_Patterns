/// Root directory and manifest path inputs.
///
/// Uses explicit controllers so picks made via the Browse buttons (which update
/// the state programmatically) are reflected in the fields. The narrow
/// `context.select` subscriptions replace a manual add/remove listener pair:
/// only changes to these two text values (or the busy flag) rebuild the field,
/// and programmatic updates are mirrored into the controllers during build
/// without touching text the user is typing (typing updates state without
/// notifying, so no rebuild is triggered for it).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state/app_state.dart';

class RootField extends StatefulWidget {
  const RootField({super.key});

  @override
  State<RootField> createState() => _RootFieldState();
}

class _RootFieldState extends State<RootField> {
  late final TextEditingController _root =
      TextEditingController(text: _state.rootText);
  late final TextEditingController _out =
      TextEditingController(text: _state.manifestPath);

  AppState get _state => context.read<AppState>();

  @override
  void dispose() {
    _root.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    final rootText = context.select<AppState, String>((s) => s.rootText);
    final manifestPath =
        context.select<AppState, String>((s) => s.manifestPath);
    final isBusy = context.select<AppState, bool>((s) => s.isBusy);

    // Mirror programmatic changes (pickers / drag & drop) into the fields.
    if (_root.text != rootText) _root.text = rootText;
    if (_out.text != manifestPath) _out.text = manifestPath;

    return Column(
      key: const Key('root-field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.t('lblRoot')),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('root-input'),
                controller: _root,
                onChanged: (v) => state.rootText = v,
                decoration: InputDecoration(
                  hintText: loc.t('dragTip'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              key: const Key('root-browse'),
              onPressed: isBusy ? null : state.pickRoot,
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
                key: const Key('manifest-input'),
                controller: _out,
                onChanged: (v) => state.manifestPath = v,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              key: const Key('manifest-browse'),
              onPressed: isBusy ? null : state.pickManifest,
              child: Text(loc.t('browse')),
            ),
          ],
        ),
      ],
    );
  }
}
