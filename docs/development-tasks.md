# 开发任务清单（剩余未完成任务）

> 跟踪 Flutter 桌面版（主实现，v1.18.7）相较 PowerShell 遗留版（v1.18.5）的
> 功能对等项与工程化待办。已完成项亦列出以便追溯。
> 状态图例：✅ 已完成 · 🔲 待办 · 🔧 进行中

## A. 功能对等（vs PowerShell 版）

| 项 | 状态 | 说明 |
|----|------|------|
| 扫描：isolate 并行（默认 4）、跳过 `.git`/规则源、跳过无权限目录 | ✅ | `scanner.dart` |
| 应用：SHA-256 比对跳过一致、写前 `.bak` 备份、轮转 ≤3、源文件豁免 | ✅ | `applier.dart` |
| 清单 manifest JSON（version/scannedAt/roots/files），结构与 PowerShell 一致 | ✅ | `manifest.dart` |
| 中英双语 + 明暗主题 | ✅ | `i18n.dart` / `app.dart` |
| 仅预览 / 强制 / 备份 选项 | ✅ | `app_state.dart` / UI |
| Stop 取消（扫描阶段） | ✅ | `app_state.stop()` + `scan()` 检查 |
| Stop 取消（应用阶段） | 🔲 | 需将 `_cancelled` 接入 `applyRules` 循环 |
| 应用前安全确认框（非预览且非强制时） | 🔲 | i18n 已预留 `applyConfirm` 键，UI 未接 |
| 实时状态行（当前正在扫描的目录） | 🔲 | 扫描进度未回传 UI（isolate 不 emit） |
| 拖拽填入（文件夹 / `.stignore` 拖入窗口） | 🔲 | 当前仅 `file_picker` 浏览 |
| 双击结果列表打开文件 | 🔲 | 当前仅打开所在文件夹（`explorer <dir>`） |
| 启动时显示「已加载现有清单：N 个」 | 🔲 | `scan()` 每次重建清单 |
| 语言选择持久化到磁盘 | 🔲 | 当前为会话内状态 |

## B. 工程化 / 质量

| 项 | 状态 | 说明 |
|----|------|------|
| 纯逻辑单测 `scanner_test` / `applier_test` | ✅ | `app/test/` |
| `flutter analyze` 零 warning（flutter_lints 4） | 🔧 | 构建流水线中校验 |
| 测试覆盖率 ≥80%（dart-collect-coverage） | 🔲 | `flutter test --coverage` 已可用，未设门禁 |
| UI 部件测试（flutter_test + mockito） | 🔲 | 规划项 |
| 覆盖率忽略指令校验（`--check-ignore`） | 🔲 | 可选 |

## C. 构建与发布

| 项 | 状态 | 说明 |
|----|------|------|
| 构建 Windows exe（`flutter build windows`） | 🔧 | 依赖外网 `pub get`，本机会话触发 |
| GitHub Actions CI：构建并打包命名归档 | ✅ | `SyncthingIgnoreGUI-v1.18.7-windows-x64.zip`（`.github/workflows/ci.yml`） |
| 发布包说明（VC++ 运行库 / Flutter AOT 运行时） | 🔲 | 或 Inno Setup 安装包 |
| 自动更新 | 🔲 | 可选，未规划 |

## D. 规则集维护

| 项 | 状态 | 说明 |
|----|------|------|
| 规则更新后同步 `app/assets/.stignore` 副本 | 🔲 | 与根 `.stignore` 保持一致，否则运行时规则滞后 |
| 规则集版本（`.stignore` 头 `//Version`）独立演进 | ✅ | 当前 v1.18.5，与工具版本解耦 |

## 版本说明
- Flutter 桌面版：v1.18.7（pubspec `1.18.7+1`，`AppState.version`）
- PowerShell 遗留版：v1.18.5（独立演进）
- 规则集 `.stignore`：v1.18.5（独立版本，`Updated` 为规则集修订日）
