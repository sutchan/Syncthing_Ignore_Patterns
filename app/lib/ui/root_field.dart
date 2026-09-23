/// Root directory and manifest path inputs.
///
/// Uses explicit controllers so picks made via the Browse buttons (which update
/// the state programmatically) are reflected in the fields.
library;

import 'package:flutter/material.dart';

import '../state/app_state.dart';

class RootField extends StatefulWidget {
  const RootField({super.key, required this.state});

  final AppState state;

  @override
  State<RootField> createState() => _RootFieldState();
}

class _RootFieldState extends State<RootField> {
  late final TextEditingController _root =
      TextEditingController(text: widget.state.rootText);
  late final TextEditingController _out =
      TextEditingController(text: widget.state.manifestPath);

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_syncFromState);
  }

  @override
  void dispose() {
    widget.state.removeListener(_syncFromState);
    _root.dispose();
    _out.dispose();
    super.dispose();
  }

  /// Mirrors programmatic changes (e.g. folder/file pickers) into the fields
  /// without clobbering text the user is currently typing.
  void _syncFromState() {
    if (_root.text != widget.state.rootText) _root.text = widget.state.rootText;
    if (_out.text != widget.state.manifestPath) {
      _out.text = widget.state.manifestPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final loc = state.loc;
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
                key: const Key('manifest-input'),
                controller: _out,
                onChanged: (v) => state.manifestPath = v,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              key: const Key('manifest-browse'),
              onPressed: state.isBusy ? null : state.pickManifest,
              child: Text(loc.t('browse')),
            ),
          ],
        ),
      ],
    );
  }
}
