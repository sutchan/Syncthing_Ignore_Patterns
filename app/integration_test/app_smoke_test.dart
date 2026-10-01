// app/integration_test/app_smoke_test.dart
//
// 真正的端到端冒烟：启动真实 app，验证首帧渲染出 MaterialApp 主窗口。
//
// 需要显示器（真实 GUI 窗口）。GitHub Actions 的 Windows runner 没有交互式
// 桌面会话，无法创建窗口，故在无显示环境下自动跳过——保证 Release 不被环境
// 限制阻断；开发者本机（有显示器）会真实跑通此端到端用例。

library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:syncthing_ignore_gui/app.dart';
import 'package:syncthing_ignore_gui/state/app_state.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and renders the main window', (tester) async {
    // 无显示环境（headless CI）无法创建真实窗口，跳过以保 Release 可重复；
    // 开发者本机会真实执行此端到端冒烟。
    if (Platform.environment.containsKey('GITHUB_ACTIONS')) {
      markTestSkipped('GUI e2e requires a display; skipped on headless CI');
    }

    final state = AppState();
    runApp(ChangeNotifierProvider<AppState>.value(value: state, child: const App()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Syncthing .stignore Manager'), findsOneWidget);
  });
}
