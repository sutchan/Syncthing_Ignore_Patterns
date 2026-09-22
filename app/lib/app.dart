/// Root widget: material theme (light/dark) + locale wiring.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'i18n.dart';
import 'state/app_state.dart';
import 'ui/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.loc;
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
      themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
      home: const HomePage(),
    );
  }
}
