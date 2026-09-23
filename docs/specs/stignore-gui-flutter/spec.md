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
- 里程碑：v1.21.0 窗口记忆 + 选项刷新修复 + ≤200 行拆分；v1.22.0 忽略清单在线更新；v1.23.0 应用确认 + 应用阶段停止 + 扫描实时状态行 + 双击打开文件 + 启动加载清单（本地 34/34 测试通过）；v1.23.1 补齐根 `LICENSE`（MIT）+ CI 规则副本一致性检查改阻断；v1.23.2 补充测试使 `lib/` 行覆盖率达 83.46%（55/55 用例通过）+ CI 覆盖率门禁 ≥80%；v1.24.0 应用更新检查 + exe 名统一为 `SyncthingIgnoreGUI` + 发布包说明（本地 64/64，覆盖率 85.67%）；v1.25.0 窗口拖拽填入 + 一键下载并安装更新（本地 79/79，覆盖率 85.60%；原生拖放与替换环节由 CI 编译验证）；v1.25.1 文档口径统一（任务清单仅列未完成项，当前为空）
