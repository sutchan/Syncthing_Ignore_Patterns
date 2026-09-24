# Spec: SyncthingIgnoreGUI (Flutter Desktop)

## 功能范围

Dart + Flutter Windows 桌面应用，提供 `.stignore` 规则的批量扫描与应用能力，
支持中英文界面，构建为独立 `.exe` 分发（无需目标机安装 PowerShell）。

## 需求

### REQ-1 扫描
- 系统：Windows 桌面（Flutter Windows target）；非 Windows 下驱动器枚举回退到当前目录以可测
- 输入：扫描根目录（留空=所有固定驱动器 + 映射网络驱动器；或指定单目录 / UNC 路径 `\\server\share`），由 `file_picker` 选择或窗口拖拽填入
- 行为：
  - 每根目录一个 isolate 并行（默认 4），根目录分批送入（`scanRoots`）
  - 显式栈深度优先遍历 + 异步流式 `list`（v1.20.0 起改为异步，避免巨目录卡死）；支持扫描深度上限 `maxDepth`（默认 3，1–10 可调）与大目录过滤 `skipLargeDirs`/`maxFilesPerDir`（默认跳过 >100 文件子目录，可开闭/调值）
  - 自动跳过应用自身目录子树（`p.dirname(Platform.resolvedExecutable)`，v1.19.1 起）：扫描与替换均不触及 exe 目录内 `.stignore`，避免工具自伤打包规则；同时排除 `.git` 与规则源目录；无权限目录跳过并累计，不中断整根
  - 扫描范围覆盖映射网络驱动器（DRIVE_REMOTE）：`platform_io.listScanDrives` 由仅枚举固定盘扩展为固定 + 远程盘（v1.26.0）；`normalizeRootPath` 归一化裸盘符 `Z:`→`Z:\`、正斜杠→反斜杠，UNC 路径（如 `\\server\share`）可直接填入根目录（v1.26.0）
  - `_resolveRoots` 改用 `FileSystemEntity.isDirectorySync` 校验根目录（替代原盘符枚举假设），留空根目录回退到 `listScanDrives()` 结果（v1.26.0）
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
- 根目录 / 清单路径输入（支持 `file_picker` 浏览**与窗口拖拽填入**，v1.25.0）；v1.21.0 起改用 `TextEditingController`，「浏览」选择即时反映到输入框
- 选项勾选：仅预览 / 强制 / 备份；v1.21.0 修复：勾选即时反映到界面（`setPreview`/`setForce`/`setBackup` 触发 `notifyListeners`，此前裸字段赋值不刷新）
- 按钮：扫描 / 应用 / 停止 / 清空日志
- 进度条 + 状态行 + 结果与日志列表（日志按级别着色）
- 结果列表：单击打开所在文件夹、双击用系统默认程序打开文件（v1.23.0）
- 应用前安全确认：非预览且非强制时弹确认框，显示待写路径数，取消则不执行（v1.23.0）
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

### REQ-9 应用安全与实时反馈（v1.23.0）
- 应用阶段可停止：`applyRules` 接受 `isCancelled` 回调，在每个路径写入前检查；停止后中止后续写入，已完成部分保留，结果以 `ApplyResult.cancelled` 标记
- 应用前安全确认：非预览且非强制时先弹确认框（显示待写路径数，来自清单），点「取消」则不执行
- 扫描实时状态行：`scanRoots` 的 `onProgress` 回调按根目录刷新「正在扫描 x/y 个根目录 | 已找到 N | 当前：<目录> | 耗时」
- 启动加载既有清单：读取既有清单回填结果列表，并日志提示「已加载现有清单：N 个文件」

### REQ-10 应用更新检查（v1.24.0）
- 入口：「关于」对话框的「检查应用更新」按钮（`ui/about_dialog.dart`）
- 检查：`GET https://api.github.com/repos/sutchan/Syncthing_Ignore_Patterns/releases/latest`（15 s 超时、1 MiB 上限，`Accept: application/vnd.github+json`），取 `tag_name` 去掉 `v` 前缀
- 结果：高于当前版本则提示「发现新版本 vX（当前 vY）」并提供「打开下载页」；否则提示已是最新；失败时给出原因并写入日志
- **一键下载并安装**（v1.25.0）：校验应用目录可写 → 下载归档（zip 魔数 / 200 MiB 上限）→ 生成 PowerShell 助手脚本（等待退出 → 解压覆盖应用目录 → 重启 → 自删）→ 退出应用；失败原因写入应用目录 `update.log`
- 应用目录不可写时明确报错且不改动任何文件（回退为「打开下载页」手动更新）

## 非目标
- 不做云端同步、不做规则冲突合并
- 不依赖 PowerShell 运行时（纯 Dart/Flutter 实现）

## 状态

> 完整任务跟踪（仅列未完成项）与验证边界统一维护在
> [开发任务清单](../../development-tasks.md)。本文档不再重复列出任务，避免多处漂移。

- 代码已完成：扫描 / 应用 / 备份轮转 / 中英双语 / 明暗主题 / 清单 manifest / 窗口记忆 / 忽略清单在线更新 / 应用确认与停止 / 扫描实时状态行 / 应用更新检查 / 窗口拖拽填入 / 一键下载并安装更新
- `flutter analyze` 零告警已达成（v1.18.7 清零 52 项，CI `build-windows` 强制校验）
- GitHub Actions `build-windows` 已落地，自动构建并发布 `SyncthingIgnoreGUI-vX.Y.Z-windows-x64.zip`（版本取自根 `VERSION`）
- 里程碑：v1.21.0 窗口记忆 + 选项刷新修复 + ≤200 行拆分；v1.22.0 忽略清单在线更新；v1.23.0 应用确认 + 应用阶段停止 + 扫描实时状态行 + 双击打开文件 + 启动加载清单（本地 34/34 测试通过）；v1.23.1 补齐根 `LICENSE`（MIT）+ CI 规则副本一致性检查改阻断；v1.23.2 补充测试使 `lib/` 行覆盖率达 83.46%（55/55 用例通过）+ CI 覆盖率门禁 ≥80%；v1.24.0 应用更新检查 + exe 名统一为 `SyncthingIgnoreGUI` + 发布包说明（本地 64/64，覆盖率 85.67%）；v1.25.0 窗口拖拽填入 + 一键下载并安装更新（本地 79/79，覆盖率 85.60%；原生拖放与替换环节由 CI 编译验证）；v1.25.1 文档口径统一（任务清单仅列未完成项，当前为空）；v1.25.2 修复扫描崩溃（`scanner.scanRoots` 的 `Isolate.run` 闭包误捕获不可发送的 `AppState` 上下文，真实扫描会中断）；v1.25.3 新增功能与 UI 完善改进建议（`docs/specs/stignore-gui-flutter/spec.md`「改进建议（评估中）」按 P0/P1/P2 分级）；v1.26.0 扫描支持局域网路径与映射盘符（空根目录扩展为固定 + 映射网络驱动器，`listScanDrives`/`normalizeRootPath`/`_resolveRoots` 改进）

## 改进建议（评估中）

> 汇总对当前 Flutter 主实现的功能与 UI 完善建议，供后续版本评估采纳。
> 均为现有对外行为契约之外的增量增强；采纳时须保持 REQ-1~REQ-10 的既有契约稳定。

### P0（高价值 / 修复真实缺口）

**PROP-1 扫描中途真正可取消**
- 现状：`scanner.scanRoots` 仅接受 `onProgress`，无 `isCancelled` 参数；`scan_flow.scan()` 只在 `scanRoots` 跑完全部根后才检查 `cancelled`（`scan_flow.dart:62`）。故扫描中点「停止」并不中断正在运行的 isolate，仍会跑完所有根再丢弃结果——与 `applier.applyRules` 的逐路径 `isCancelled` 形成对比。
- 建议：为 `scanRoots` 增加 `bool Function()? isCancelled`，在每批/每个根派发前判定；命中即终止后续 isolate 并提前返回，使「停止」在扫描阶段即时生效。
- 影响：`services/scanner.dart`、`state/scan_flow.dart`、`scanner_test`。

**PROP-2 结果列表增强（搜索 / 计数 / 复制 / 多选）**
- 现状：`ui/results_list.dart` 高度写死 160px，纯文本行，无搜索、无计数徽标、无复制 / 多选。扫描出成百上千个 `.stignore` 时难以定位。
- 建议：① 顶部搜索框按路径过滤；② 标题显示 `N 个` 计数；③ 行右键复制路径；④ 多选后「打开选中所在文件夹」「导出选中路径」。
- 影响：`ui/results_list.dart`、`i18n.dart`（新增 `resultCount` / `copyPath` / `filterResults` 等键）。

**PROP-3 支持多扫描根**
- 现状：`scan_flow._resolveRoots()` 仅支持「留空=固定 + 映射网络驱动器」或「单个目录 / UNC 路径」；拖拽填入（`pickers_state.applyDrop`）也只替换单根 `rootText`。
- 建议：将扫描根改为可增删列表；`file_picker` 多选目录 + 拖拽追加（而非替换）；`_resolveRoots` 展开为多个根。`scanRoots` 已接受 `List<String>`，改动成本低。
- 影响：`state/pickers_state.dart`、`state/scan_flow.dart`、`ui/root_field.dart`、`i18n.dart`。

### P1（明显增益）

**PROP-4 备份管理与一键恢复**
- 现状：Apply 写前生成 `.stignore.bak.<时间戳>` 并按 `<Base>.bak.*` 轮转保留 ≤3，但界面无任何查看 / 恢复入口。
- 建议：新增「备份」入口，列出当前 `.stignore` 的备份、显示时间、提供「恢复」（用备份覆盖当前并自身再备份）。
- 影响：新增 `ui/backup_card.dart` / `state/backup_state.dart` / `services/backup_store.dart`。

**PROP-5 扫描后预检「是否已符合标准规则」**
- 现状：Apply 逐文件 SHA-256 比对跳过一致项，但 UI 在扫描后不揭示哪些已符合、哪些需应用（结果列表仅列路径）。
- 建议：扫描完成后对每条记录与生效清单做轻量 SHA 比对，结果列表用 ✓/✗ 标记；Apply 预览只统计「需更新 N / 已一致 M」。无新依赖。
- 影响：`state/scan_flow.dart`、`ui/results_list.dart`、`i18n.dart`。

**PROP-6 清单「打开」按钮（复用未用 i18n 键）**
- 现状：`i18n.dart` 已定义 `open`('Open manifest') 与 `openFile`('Open file')，但 UI 无按钮打开 `manifestPath` 所指 JSON，仅能「浏览」另存。
- 建议：在清单路径旁加「打开」按钮（`cmd /c start`），与结果列表双击打开保持一致。
- 影响：`ui/root_field.dart`。

**PROP-7 启动时可选项自动检查更新**
- 现状：应用更新（§9.8）与清单更新（§9.6）均为手动触发。
- 建议：设置项增加「启动时检查应用更新 / 清单更新」开关（默认关），启动后后台静默检查并提示；复用既有 `checkAppUpdate` / `checkRulesetUpdate`。
- 影响：`state/preferences_state.dart`、`ui/settings_dialog.dart`、`services/settings_store.dart`、`i18n.dart`。

**PROP-8 设置项扩充（扫描默认值）**
- 现状：设置对话框仅语言 / 主题。
- 建议：加入「默认扫描深度」「默认跳过超大目录」「默认开启备份」等默认值，启动时载入，减少每次重设。
- 影响：`settings_dialog.dart`、`settings_store.dart`、`scan_options_state.dart`。

### P2（体验打磨）

- **PROP-9 主容器语义化 id**：`home_page.dart` 的 `body` 缺 `Key('main-content')`，补全以对齐「主要容器加语义化 id」约定（便于测试 / 无障碍）。
- **PROP-10 键盘快捷键**：`Ctrl/Cmd+S` 扫描、`Ctrl/Cmd+A` 应用、`Delete` 清空日志。
- **PROP-11 规则更新变更摘要**：`ruleset_card` 检查更新后除版本号外，展示「新增 / 移除规则数」差异（解析新旧 `.stignore` 行数）。
- **PROP-12 日志导出 / 复制**：`log_list` 增加「复制全部」按钮，便于问题反馈。
- **PROP-13 进度 ETA**：状态行在已知总量（多根）时给出预计剩余时间，提升大扫描可预期性。
