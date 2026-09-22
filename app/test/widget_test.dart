// Widget smoke test: the app shell builds and shows the localized title.
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

  testWidgets('Language switch updates the title to Chinese', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文').last);
    await tester.pumpAndSettle();

    expect(find.text('Syncthing .stignore 管理器'), findsOneWidget);
  });
}
