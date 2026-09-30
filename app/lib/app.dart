/// Root widget: material theme (light/dark) + locale wiring.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'i18n.dart';
import 'state/app_state.dart';
import 'ui/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribe only to the pieces the root theme needs (dark + locale) so a
    // high-frequency notify during Scan/Apply does not rebuild MaterialApp.
    final dark = context.select<AppState, bool>((s) => s.dark);
    final loc = context.select<AppState, AppLocalizations>((s) => s.loc);
    return MaterialApp(
      title: loc.t('title'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.teal,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
      ),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: const HomePage(),
    );
  }
}
