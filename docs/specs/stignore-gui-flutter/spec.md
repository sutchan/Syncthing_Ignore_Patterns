# Spec: SyncthingIgnoreGUI (Flutter Desktop)

## 功能范围

Dart + Flutter Windows 桌面应用，提供 `.stignore` 规则的批量扫描与应用能力，
支持中英文界面，构建为独立 `.exe` 分发（无需目标机安装 PowerShell）。

## 需求

### REQ-1 扫描
- 系统：Windows 桌面（Flutter Windows target）；非 Windows 下驱动器枚举回退到当前目录以可测
- 输入：扫描根目录（留空=所有固定驱动器；或指定单目录），由 `file_picker` 选择
- 行为：
  - 每根目录一个 isolate 并行（默认 4），根目录分批送入（`scanRoots`）
  - 显式栈深度优先遍历 + 异步流式 `list`（v1.20.0 起改为异步，避免巨目录卡死）；支持扫描深度上限 `maxDepth`（默认 3，1–10 可调）与大目录过滤 `skipLargeDirs`/`maxFilesPerDir`（默认跳过 >100 文件子目录，可开闭/调值）
  - 自动跳过应用自身目录子树（`p.dirname(Platform.resolvedExecutable)`，v1.19.1 起）：扫描与替换均不触及 exe 目录内 `.stignore`，避免工具自伤打包规则；同时排除 `.git` 与规则源目录；无权限目录跳过并累计，不中断整根
  - 扫描阶段不做逐文件 UI 刷新，不做哈希计算
- 输出：`stignore-paths.json`（UTF-8，含 version/scannedAt/roots/files）
  - 每条记录：path / size / lastWriteUtc / foundAtUtc
  - 清单备份 `stignore-paths.json.bak.<时间戳>` 同样适用"最多保留 3 个"轮转

### REQ-2 应用
- 输入：扫描清单 `stignore-paths.json` + 标准规则源（打包资源 `assets/.stignore`）
- 行为：
  - 对每个清单路径，用标准 `.stignore` 替换其现有内容
  - 替换前自动备份为 `.stignore.bak.<时间戳>`（被替换目标恰为标准源 `.stignore` 自身时跳过备份）
  - SHA-256 比对：内容一致的文件跳过，不重复备份
  - 源文件已删除的路径为失效路径，仅 `强制` 时清理（`force`）
  - 自动跳过应用自身目录子树（`skipRoots`，v1.19.1 起）：命中即静默跳过（`skippedAppDir`），不写不备份
  - 应用同样在后台（`async`）执行，进度条显示不确定/完成态，GUI 不卡顿
  - 非预览（`whatIf=false`）且实际发生替换/错误后，重写清单仅保留仍存在的路径
- 选项：仅预览（不写文件）、强制（跳过确认）、写回前备份
- 备份轮转：每种备份 `<Base>.bak.*` 最多保留 3 个，超出自动删除最旧的（按修改时间排序）

### REQ-3 国际化
- AppBar「设置」齿轮按钮 → 语言/主题设置对话框（v1.19.0 起，原右上角独立下拉收敛为单一入口）；即时切换全部界面与日志文案
- 字典 `i18n.dart` 键与 PowerShell `$T` 对齐；`t(key, args)` 支持 `{0}` 占位
- 语言/主题选择持久化到 `%APPDATA%\SyncthingIgnoreGUI\settings.json`（`settings_store.dart`，v1.19.0 起，纯 `dart:io` JSON；`AppState.loadSettings()` 启动恢复、`setLanguage()`/`setTheme()` 变更即写盘）；v1.21.0 起该文件亦记录窗口几何（`window` 字段，见 REQ-7）

### REQ-4 版本与项目信息
- 「关于」对话框显示版本（`AppState.version`）与项目地址
- 版本号与 `pubspec.yaml` `version:` 及 README 徽章保持一致

### REQ-5 主题与外观
- 主题切换 `浅色` / `深色`，经 AppBar「设置」齿轮按钮的设置对话框即时切换全部配色（`ThemeMode` 跟随设置，v1.19.0 起）
- Material 3 主题，`colorSchemeSeed` 取 teal

### REQ-6 交互
- 根目录 / 清单路径输入（支持 `file_picker` 浏览；当前未实现拖拽填入）；v1.21.0 起改用 `TextEditingController`，「浏览」选择即时反映到输入框
- 选项勾选：仅预览 / 强制 / 备份；v1.21.0 修复：勾选即时反映到界面（`setPreview`/`setForce`/`setBackup` 触发 `notifyListeners`，此前裸字段赋值不刷新）
- 按钮：扫描 / 应用 / 停止 / 清空日志
- 进度条 + 状态行 + 结果与日志列表（日志按级别着色）
- 结果列表点击打开所在文件夹（当前未实现双击打开文件本身）
- 标准规则随资源打包，运行时 `rootBundle` 加载；更新规则须同步 `app/assets/.stignore` 副本

### REQ-7 窗口（v1.21.0）
- 记忆主窗口大小与位置：下次启动恢复到上次几何
- 实现：`lib/services/window_bounds.dart` 经 win32 按窗口类名 `FLUTTER_RUNNER_WIN32_WINDOW` 定位宿主窗口，`GetWindowRect` 读取 / `SetWindowPos` 恢复；无新增依赖、无原生插件
- 持久化：随偏好写入 `settings.json` 的 `window` 字段；启动首帧后 `restoreWindowBounds()` 恢复，运行中每 2 秒采样一次变更并落盘（移动/缩放通知需原生钩子，故采用轮询）
- 稳健性：过小（<320×240）或完全落在虚拟屏幕（所有显示器并集）之外的几何被忽略，避免显示器变更后窗口出现在屏幕外

### REQ-8 忽略清单在线更新（v1.22.0）
- 清单来源优先级：exe 同目录 `.stignore`（随构建由 CMake `POST_BUILD` 携带，更新优先写回）> `%APPDATA%\SyncthingIgnoreGUI\.stignore` > 内置资源 `assets/.stignore`
- 界面显示当前清单版本（`//Version`）、来源（内置 / 已下载）、修订日（`//Updated`）与存放路径（悬停）
- 「检查清单更新」按钮：`GET https://raw.githubusercontent.com/sutchan/Syncthing_Ignore_Patterns/main/.stignore`（15 s 超时、5 MiB 上限）；远端版本更高则写盘生效并提示新版本号，否则提示已是最新；缺少版本头 / 网络失败保留本地并说明原因
- 应用（Apply）使用生效清单，并在日志记录在用清单的版本与修订日；清单版本与应用版本相互独立

## 非目标
- 不做云端同步、不做规则冲突合并
- 不依赖 PowerShell 运行时（纯 Dart/Flutter 实现）

## 状态
- 代码已完成：扫描 / 应用 / 备份轮转 / 中英双语 / 明暗主题 / 清单 manifest
- `flutter analyze` 零告警已达成（v1.18.7 清零 52 项，CI `build-windows` 强制校验）；GitHub Actions `build-windows` 已落地，自动构建并发布 `SyncthingIgnoreGUI-vX.Y.Z-windows-x64.zip`（版本取自根 `VERSION`）
- v1.21.0：新增窗口大小/位置记忆（REQ-7）；修复选项勾选不刷新与输入框不反映「浏览」选择；按 ≤200 行规则拆分 `app_state.dart`/`home_page.dart`（本地 `flutter analyze` 0 问题、`flutter test` 19/19）
- v1.22.0：新增忽略清单在线更新（REQ-8）——应用目录随构建携带 `.stignore`，界面显示当前清单版本并提供「检查清单更新」按钮从仓库下载；Apply 使用生效清单（本地 31/31 测试通过）
- 待办：测试覆盖率门禁（≥80%）、UI 部件测试（flutter_test + mockito）、发布包说明（VC++ 运行库 / Flutter AOT）或 Inno Setup
- 详见 [开发任务清单](../../development-tasks.md)
