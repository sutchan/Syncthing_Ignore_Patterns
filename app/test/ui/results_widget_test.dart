import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:syncthing_ignore_gui/services/ruleset_store.dart';
import 'package:syncthing_ignore_gui/services/settings_store.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';
import 'package:syncthing_ignore_gui/ui/results_filter.dart';
import 'package:syncthing_ignore_gui/ui/results_list.dart';

void main() {
  late Directory tmp;
  late AppState state;

  Widget buildApp() => MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AppState>.value(
            value: state,
            child: const CustomScrollView(
              slivers: [ResultsHeader(), ResultsListSliver()],
            ),
          ),
        ),
      );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('results_widget');
    state = AppState(
      settingsStore: SettingsStore(directory: tmp.path),
      rulesetStore: RulesetStore(directory: tmp.path),
      rulesetBundled: () async => '//Version: 9.9.9\n',
    );
  });

  tearDown(() {
    state.dispose();
    tmp.deleteSync(recursive: true);
  });

  testWidgets('header and list render; search, chips and selection work',
      (tester) async {
    state.replaceResults(
        ['/a/one.stignore', '/b/two.stignore', '/c/three.stignore']);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('results-label')), findsOneWidget);
    expect(find.byKey(const Key('result-row-/a/one.stignore')), findsOneWidget);

    // Search narrows the visible rows.
    await tester.enterText(find.byKey(const Key('result-search')), 'two');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result-row-/b/two.stignore')), findsOneWidget);
    expect(find.byKey(const Key('result-row-/a/one.stignore')), findsNothing);
    await tester.enterText(find.byKey(const Key('result-search')), '');
    await tester.pumpAndSettle();

    // Exercise the compliance and type chips (reset via the model between
    // taps to avoid the ambiguous 'all' labels and empty-compliance hiding).
    await tester.tap(find.text(state.loc.t('filterNeed')));
    await tester.pumpAndSettle();
    state.setComplianceFilter('all');
    await tester.pumpAndSettle();
    await tester.tap(find.text(state.loc.t('typeDir')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(state.loc.t('typeFile')));
    await tester.pumpAndSettle();
    state.setTypeFilter('all');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result-row-/a/one.stignore')), findsOneWidget);

    // Selecting an item reveals the bulk toolbar; clearing empties the set.
    state.toggleSelected('/a/one.stignore');
    await tester.pumpAndSettle();
    expect(state.isSelected('/a/one.stignore'), isTrue);
    expect(find.byKey(const Key('clear-sel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('clear-sel')));
    await tester.pumpAndSettle();
    expect(state.selected, isEmpty);
  });
}
