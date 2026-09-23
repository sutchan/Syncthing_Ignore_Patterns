# 开发任务清单（单一来源）

> **本文件是项目任务跟踪的唯一权威来源**。`docs/project.md` §8 与 `docs/specs/stignore-gui-flutter/spec.md`「状态」段仅作指针引用，不再重复待办，避免多处漂移。
> 跟踪 Flutter 桌面版（主实现，v1.23.1）相较 PowerShell 遗留版（v1.18.5）的功能对等项与工程化待办。
> 状态图例：🔲 待办 · 🔧 进行中 · ✅ 已完成（见文末归档）
> 主表仅列**当前待办与进行中**项；已完成项统一归档至文末「已完成项（历史追溯）」，不再散落各处。

## A. 功能对等（vs PowerShell 版）

| 项 | 状态 | 说明 |
|----|------|------|
| 拖拽填入（文件夹 / `.stignore` 拖入窗口） | 🔲 | 当前仅 `file_picker` 浏览；需原生 OS 文件拖放（`desktop_drop` 等插件，受本机离线 pub 限制，待评估） |

## B. 工程化 / 质量

| 项 | 状态 | 说明 |
|----|------|------|
| 测试覆盖率 ≥80%（dart-collect-coverage） | 🔧 | CI 已采集 LCOV 并输出覆盖率摘要，暂未设门禁 |
| UI 部件测试（flutter_test + mockito，覆盖交互分支） | 🔲 | 已有 `widget_test.dart` 冒烟，mockito 规划项 |
| 覆盖率忽略指令校验（`--check-ignore`） | 🔲 | 可选 |

## C. 构建与发布

| 项 | 状态 | 说明 |
|----|------|------|
| 发布包说明（VC++ 运行库 / Flutter AOT 运行时） | 🔲 | 或 Inno Setup 安装包 |
| 自动更新 | 🔲 | 可选，未规划 |
| 产物内 exe 名与产品名一致 | 🔲 | 当前 exe 为 `syncthing_ignore_gui.exe`（源自 pubspec `name:`），与产品名 `SyncthingIgnoreGUI` 不一致，待裁决（`windows/CMakeLists.txt` BINARY_NAME） |

## 已完成项（历史追溯，v1.23.1 及之前）

### A. 功能对等（已完成）
- 应用阶段 Stop 取消 — `applyRules` 新增 `isCancelled` 回调 + `ApplyResult.cancelled`（v1.23.0）
- 应用前安全确认框（非预览且非强制时）— `ui/action_row.dart` 确认框 + `pendingApplyCount()`（v1.23.0）
- 实时状态行（当前正在扫描的根目录 + 已找到数 + 耗时）— `scanRoots` 的 `onProgress` + `scan_flow._reportScanProgress`（v1.23.0）
- 双击结果列表打开文件 — `ui/results_list.dart` 单击定位目录 / 双击默认程序打开（v1.23.0）
- 启动时显示「已加载现有清单：N 个」— `scan_flow.loadExistingManifest()` + `main.dart`（v1.23.0）
- 扫描：isolate 并行（默认 4）、跳过 `.git`/规则源、跳过无权限目录 — `scanner.dart`
- 应用：SHA-256 比对跳过一致、写前 `.bak` 备份、轮转 ≤3、源文件豁免 — `applier.dart`
- 清单 manifest JSON（version/scannedAt/roots/files），结构与 PowerShell 一致 — `manifest.dart`
- 中英双语 + 明暗主题 — `i18n.dart` / `app.dart`
- 设置按钮 / 设置对话框（语言 + 主题集中管理）— `ui/settings_dialog.dart`（v1.19.0；v1.21.0 拆分）
- 扫描 / 替换时跳过应用自身目录的 `.stignore` — `scanner.dart` + `applier.dart` `skipRoots`（v1.19.1）
- 扫描深度调节（1–10，默认 3）+ 大目录过滤 — `scanner.dart` + `ui/scan_options.dart`（v1.20.0）
- 仅预览 / 强制 / 备份 选项 — `state/scan_options_state.dart` + `ui/options_row.dart`（v1.21.0 修复刷新）
- Stop 取消（扫描阶段）— `app_state.stop()` + `scan()` 检查
- 语言 / 主题持久化到磁盘 — `settings_store.dart`（v1.19.0）
- 记住窗口大小与位置 — `models/window_bounds.dart` + `services/window_bounds.dart`（v1.21.0）
- 忽略清单在线更新：版本显示 + 「检查更新」按钮 + 下载采纳 — `ruleset_*` + `ui/ruleset_card.dart`（v1.22.0）

### B. 工程化 / 质量（已完成）
- 纯逻辑单测 `scanner_test` / `applier_test` / `settings_store_test` — `app/test/`
- UI 冒烟测试（应用壳 + 设置对话框语言切换 + 选项点击生效）— `app/test/widget_test.dart`
- `flutter analyze` 零 warning（flutter_lints 4）— v1.18.7 清零 52 项，CI 强制校验

### C. 构建与发布（已完成）
- 构建 Windows exe（`flutter build windows`）— CI `build-windows` 构建并发布 zip
- GitHub Actions CI：构建并打包命名归档 `SyncthingIgnoreGUI-v1.23.1-windows-x64.zip`
- 应用图标与品牌资产 — `tools/generate-brand-assets.ps1` + `app_icon.ico`（v1.21.1）
- 应用目录携带 `.stignore`（构建后复制到 exe 同目录）— `CMakeLists.txt` POST_BUILD（v1.22.0）
- 发布包附带 VC++ 运行库（CI `Stage release files` 复制 VC++ CRT DLL）— v1.22.0（48b4f10）

### D. 规则集维护（已完成）
- 规则集版本（`.stignore` 头 `//Version`）独立演进（当前 v1.18.5，与工具版本解耦）
- 根 `.stignore` 与 `app/assets/.stignore` 保持一致（当前均 397 行、`//Version: 1.18.5`）；CI 漂移检查由「仅告警」改为「阻断」，规则更新漏同步副本将直接失败（v1.23.1）

### E. 项目治理（已完成）
- 补充仓库根 `LICENSE`（MIT，版权 Sut），与 README / README_EN 的 MIT 声明一致（v1.23.1）

## 版本说明
- Flutter 桌面版：v1.23.1（pubspec `1.23.1+1`，`AppState.version`）
- PowerShell 遗留版：v1.18.5（独立演进）
- 规则集 `.stignore`：v1.18.5（独立版本，`Updated` 为规则集修订日）
