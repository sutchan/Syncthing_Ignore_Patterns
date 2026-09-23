// Widget smoke test: the app shell builds and shows the localized title.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:syncthing_ignore_gui/app.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';

void main() {
  testWidgets('App builds and shows the English title', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Syncthing .stignore Manager'), findsOneWidget);
    expect(find.text('Scan .stignore files'), findsOneWidget);
    expect(find.text('Apply standard rules'), findsOneWidget);
  });

  testWidgets('Settings button opens the dialog and switching language works',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();

    // The dialog is localized now, so close it via the Chinese label.
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    expect(find.text('Syncthing .stignore 管理器'), findsOneWidget);
  });

  testWidgets('option checkboxes update their state when tapped',
      (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(value: state, child: const App()),
    );
    await tester.pumpAndSettle();

    CheckboxListTile previewTile() => tester.widget<CheckboxListTile>(
          find.byKey(const Key('preview-checkbox')),
        );

    expect(state.preview, isFalse);
    expect(previewTile().value, isFalse);

    await tester.ensureVisible(find.byKey(const Key('preview-checkbox')));
    await tester.tap(find.byKey(const Key('preview-checkbox')));
    await tester.pumpAndSettle();

    expect(state.preview, isTrue);
    expect(previewTile().value, isTrue);

    await tester.tap(find.byKey(const Key('preview-checkbox')));
    await tester.pumpAndSettle();
    expect(state.preview, isFalse);
  });

  testWidgets('Apply asks for confirmation, and cancelling aborts it',
      (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(value: state, child: const App()),
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(const Key('apply-button'));
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('apply-confirm-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('apply-confirm-cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('apply-confirm-dialog')), findsNothing);
    // Cancelled at the dialog: no apply run was started.
    expect(state.isBusy, isFalse);
  });
}
