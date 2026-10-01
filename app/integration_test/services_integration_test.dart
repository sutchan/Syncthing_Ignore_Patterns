// app/integration_test/services_integration_test.dart
//
// 服务级端到端测试：在临时工程里「扫描 → 应用内置标准规则」，跨 scanner /
// rules_source / applier 三个模块的边界跑通完整链路，并校验磁盘文件被改写。
//
// 无 GUI 窗口依赖（headless-safe），可在 CI（windows-latest）直接运行。

library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import 'package:syncthing_ignore_gui/models/manifest.dart';
import 'package:syncthing_ignore_gui/services/applier.dart';
import 'package:syncthing_ignore_gui/services/rules_source.dart';
import 'package:syncthing_ignore_gui/services/scanner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scan -> apply standard rules end-to-end on a temp project',
      (tester) async {
    final root = Directory.systemTemp.createTempSync('sig_e2e_');
    try {
      // 一个会被工具发现并重写的嵌套 .stignore
      final nested =
          Directory(p.join(root.path, 'project', 'sub'))..createSync(recursive: true);
      File(p.join(nested.path, '.stignore'))
          .writeAsStringSync('// legacy placeholder\n');

      // 1) 扫描：找出临时根目录下所有 .stignore
      final records = await scanRoots(
        [root.path],
        maxDepth: 6,
        skipLargeDirs: false,
      );
      expect(records, isNotEmpty,
          reason: 'scanner should find the nested .stignore');
      final target = records.firstWhere((r) => r.path.endsWith('.stignore'));

      // 2) 加载随应用发布的内置标准规则
      final source = await loadStandardRules();
      final sourceHash = sha256OfString(source);
      expect(source, isNotEmpty, reason: 'bundled standard rules must load');

      // 3) 应用：用标准规则重写发现的 .stignore
      final manifest = Manifest(
        version: '0.0.0',
        scannedAt: DateTime.now().toUtc().toIso8601String(),
        roots: [root.path],
        files: records,
      );
      final result = await applyRules(
        manifest: manifest,
        sourceContent: source,
        sourceHash: sourceHash,
        sourcePath: p.join(root.path, 'rules-source.stignore'),
        whatIf: false,
        force: false,
        backup: true,
        log: (_, __) {},
      );

      expect(result.errors, 0,
          reason: 'apply should not error on a writable temp file');
      expect(result.replaced, greaterThanOrEqualTo(1),
          reason: 'the legacy .stignore should be rewritten');

      // 4) 校验磁盘文件已与内置标准规则逐字一致
      final written = await File(target.path).readAsString();
      expect(written, source,
          reason: 'applied file must equal the bundled standard rules');
    } finally {
      root.deleteSync(recursive: true);
    }
  });
}
