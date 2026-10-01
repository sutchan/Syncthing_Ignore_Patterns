import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/ruleset_store.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';
import 'package:syncthing_ignore_gui/state/results_view_state.dart';

void main() {
  group('filterResults', () {
    final results = ['/a/one.stignore', '/b/two.stignore', '/c/three.stignore'];
    final compliance = {'/a/one.stignore': true, '/b/two.stignore': false};

    test('search query filters case-insensitively and trims', () {
      expect(filterResults(results, compliance, 'TWO', 'all', 'all'),
          ['/b/two.stignore']);
      expect(filterResults(results, compliance, '  ONE ', 'all', 'all'),
          ['/a/one.stignore']);
      expect(filterResults(results, compliance, 'zzz', 'all', 'all'), isEmpty);
    });

    test('compliance filter keeps ok or need', () {
      expect(filterResults(results, compliance, '', 'ok', 'all'),
          ['/a/one.stignore']);
      expect(filterResults(results, compliance, '', 'need', 'all'),
          ['/b/two.stignore', '/c/three.stignore']);
    });

    test('type filter separates files from directories', () async {
      final dir = Directory.systemTemp.createTempSync('rv_type');
      final file = File(p.join(dir.path, 'f.stignore'))..writeAsStringSync('x');
      final r = [file.path, dir.path];
      expect(filterResults(r, {}, '', 'all', 'file'), [file.path]);
      expect(filterResults(r, {}, '', 'all', 'dir'), [dir.path]);
      dir.deleteSync(recursive: true);
    });
  });

  group('ResultsViewState mixin', () {
    late Directory tmp;

    AppState newState() => AppState(
          settingsStore: SettingsStore(directory: tmp.path),
          rulesetStore: RulesetStore(directory: tmp.path),
          rulesetBundled: () async => '//Version: 9.9.9\n',
        );

    setUp(() => tmp = Directory.systemTemp.createTempSync('rv_state'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('setters notify once per real change and ignore no-ops', () {
      final s = newState();
      var n = 0;
      s.addListener(() => n++);
      s.setResultQuery('q');
      s.setResultQuery('q'); // no change -> no notify
      s.setComplianceFilter('need');
      s.setTypeFilter('dir');
      expect(n, 3);
      expect(s.resultQuery, 'q');
      expect(s.complianceFilter, 'need');
      expect(s.typeFilter, 'dir');
    });

    test('selection toggles and clears', () {
      final s = newState();
      s.toggleSelected('/x');
      expect(s.isSelected('/x'), isTrue);
      s.toggleSelected('/x');
      expect(s.isSelected('/x'), isFalse);
      s.toggleSelected('/x');
      s.toggleSelected('/y');
      expect(s.selected, {'/x', '/y'});
      s.clearSelection();
      expect(s.selected, isEmpty);
    });

    test('filteredResults reflects the active query', () {
      final s = newState();
      s.replaceResults(['/a/one.stignore', '/b/two.stignore']);
      s.setResultQuery('two');
      expect(s.filteredResults, ['/b/two.stignore']);
    });

    test('exportSelected writes one path per line', () async {
      final s = newState();
      final out =
          p.join(Directory.systemTemp.createTempSync('rv_export').path, 'sel.txt');
      s.toggleSelected('/a');
      s.toggleSelected('/b');
      await s.exportSelected(out);
      expect(File(out).readAsLinesSync(), ['/a', '/b']);
    });
  });
}
