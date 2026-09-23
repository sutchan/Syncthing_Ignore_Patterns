# Project Specification: SyncthingIgnorePatterns

> 标准化 `.stignore` 规则集 + 配套批量管理 GUI 工具的项目规范（规范文档）。

## 1. 项目背景

Syncthing 同步文件夹时默认包含大量系统文件、缓存、构建产物与应用数据，
造成带宽与存储浪费。本项目提供：

1. **规则集** `.stignore` — 开箱即用的 21 类忽略模式（系统/OS 文件、数据库、
   备份临时文件、应用缓存、版本控制、包管理器、前端/Python/C++/JVM 构建缓存、
   IDE/编辑器、归档与部分下载、虚拟化、媒体、锁与日志、构建产物、缓存与临时
   目录、浏览器存储缓存、系统临时位置等噪音）。
2. **批量管理 GUI** `SyncthingIgnoreGUI.ps1` — WinForms 图形界面，将标准规则
   批量应用到本机所有 Syncthing 同步目录，无需每次全盘扫描。

## 2. 关键约束（架构红线）

- **纯 ASCII 文件**：所有 `.ps1` 脚本必须保持纯 ASCII。中文界面文案一律以
  `\uXXXX` 转义存储，运行时由 `Decode-Uni` 还原。原因：文件被 GBK 编码
  重编码会破坏 UTF-8 中文字节，导致 PowerShell 解析失败（历史已踩坑）。
- **单一自包含脚本**：GUI 工具的扫描/应用逻辑全部内联，无外部脚本依赖。
  此架构红线优先于通用「单文件超 200 行即拆分」规则——`SyncthingIgnoreGUI.ps1`
  作为发布交付物须保持单文件自包含，不因行数拆分（见 CHANGELOG v0.1.0 设计决策）。
- **PowerShell 5.1（Windows PowerShell）** 目标运行时；不依赖 PowerShell 7
  专有语法（如 `ForEach-Object -Parallel`）。并行改用 runspace 线程池实现。
- **GUI 已迁移至 Dart + Flutter 桌面版（主实现，见 §9）**，新实现位于 `app/`，构建为独立
  `.exe`；纯 ASCII 与单文件自包含两条红线**仅适用于旧版 `.ps1`**，Flutter 版
  按 Dart 模块拆分（单一职责），并遵守「单文件 ≤ 200 行」约束（v1.21.0 已拆分
  `lib/state/` 与 `lib/ui/`）。

## 3. 目录结构

```
SyncthingIgnorePatterns/
├── .stignore                 # 标准规则源文件（Apply 依赖，规则集版本 v1.18.5，独立演进）
├── SyncthingIgnoreGUI.ps1    # 遗留实现（PowerShell WinForms，纯 ASCII，维护态，v1.18.5）
├── app/                      # Dart + Flutter 桌面版（主实现，构建为 exe，v1.22.0）
│   ├── pubspec.yaml          # 依赖与 windows 桌面配置
│   ├── lib/
│   │   ├── main.dart         # 入口，注入 AppState；首帧后恢复/采样窗口几何
│   │   ├── app.dart          # MaterialApp + 明暗主题
│   │   ├── i18n.dart         # 中英双语字典（键对齐 $T）
│   │   ├── models/           # manifest.dart / window_bounds.dart / ruleset_info.dart
│   │   ├── services/         # scanner / applier / rules_source / platform_io / settings_store / window_bounds / app_paths / ruleset_store / ruleset_update
│   │   ├── state/            # app_state.dart（组合）+ preferences / scan_options / log / progress / pickers / ruleset + scan_flow / apply_flow
│   │   └── ui/               # home_page.dart（装配）+ settings_dialog / root_field / options_row / scan_options / ruleset_card / action_row / results_list / log_list
│   ├── windows/runner/resources/app_icon.ico   # Windows 应用图标（品牌资产，见 §10）
│   ├── assets/.stignore      # 标准规则集（运行时 rootBundle 加载）
│   └── test/                 # scanner_test / applier_test / settings_store_test / widget_test（覆盖率基线）
├── README.md                 # 中文文档
├── README_EN.md              # 英文文档
├── CHANGELOG.md              # 独立变更日志（Keep a Changelog 风格）
├── .gitignore                # 忽略运行时产物（config/stignore-paths.json / *.bak.*）
├── config/                   # 运行时配置与产物目录
│   ├── stignore-paths.json   # 扫描清单输出（运行时生成，已被 .gitignore 忽略）
│   └── *.bak.*               # 清单备份（轮转 ≤3，已被忽略）
├── docs/                     # 文档目录（原 openspec/）
│   ├── project.md
│   ├── assets/               # 品牌资产：logo.svg / logo-512.png / logo-128.png / BRAND.md
│   └── specs/                # stignore-gui/spec.md（遗留）+ stignore-gui-flutter/spec.md（主实现）
├── tools/                    # generate-brand-assets.ps1（品牌资产生成，见 §10）
└── SyncthingIgnorePatterns.code-workspace
```

## 4. 版本管理

- 语义化版本 `MAJOR.MINOR.PATCH`；文档/配置类变更默认升级 `PATCH`，新功能升级 `MINOR`。
- **主实现（Flutter 桌面版）版本单一来源**：
  - `app/pubspec.yaml` 的 `version:` 字段（如 `1.22.0+1`）
  - `app/lib/state/app_state.dart` 的 `AppState.version`（关于框 / 日志展示）
  - `README.md` / `README_EN.md` 版本徽章
  - 根目录 `VERSION` 文件（CI 读取的主实现版本单一来源）
  - 根目录 `CHANGELOG.md`（与本文档第 7 节一致）
- **遗留实现（PowerShell 版）** 版本独立演进：`SyncthingIgnoreGUI.ps1` 文件头 `//Version` 与 `$ScriptVersion`。
- **规则集 `.stignore`** 拥有独立版本（文件头 `//Version`），与工具发布版本可能不同步属正常（其 `Updated` 为规则集修订日）。
- 每次版本变更须同步上述对应位置并追加 CHANGELOG 条目。

## 5. GUI 功能规格

| 功能 | 说明 |
|------|------|
| 语言切换 | 左上角下拉框 `English` / `中文`（与主题选择器同行），实时切换全部界面与日志文案，选择记忆到 `config.json`（v1.10.0，v1.12.0 改左上角同行对齐） |
| 主题切换 | 左上角下拉框 `浅色` / `深色`，即时换肤，选择同样持久化（v1.10.0）；深色模式下输入控件改为自定义暗灰自绘边框（取代系统亮色 3D 边），按钮改为 Flat 风格 + 暗灰边框消除亮轮廓，清单输出路径框用中灰边框（v1.13.0 / v1.14.0） |
| 扫描根目录 | 留空=扫描所有固定驱动器；或浏览选择指定目录；支持文件夹/`.stignore` 拖拽自动填充（v1.10.0） |
| 并行扫描 | runspace 线程池（最多 4 线程）+ `-Filter .stignore`，排除 `.git` 与脚本目录 |
| 后台防卡顿 | 扫描/应用均在后台 runspace 执行，Timer 轮询 `DoEvents` 保持 UI 响应，进度条显示真实百分比与数字（v1.7.0 / v1.9.0） |
| 实时状态行 | 进度条上方单行实时状态：已完成根目录数/总数、已找到文件数、**当前正在遍历的目录**（长路径截断至 72 字符）、耗时 mm:ss；扫描命中即流式追加到结果列表，摘要同步显示「正在扫描…已找到 N 个」（v1.17.0，v1.17.1 改为显示当前目录） |
| 遍历方式 | 显式栈深度优先 + `DirectoryInfo.EnumerateFileSystemInfos()`：一次枚举同时取文件与子目录，并能把当前目录写入共享状态；跳过 `.git` 与脚本目录；无权限目录跳过并累计，结束后日志输出总数（v1.17.1） |
| 进度模式 | 多根目录按根数显示真实百分比；单根目录（总量未知）进度条转 Marquee，避免 0→100% 假百分比（v1.17.0）。进度由同步共享状态驱动，UI Timer 每 100ms 拉取，不再用 `form.Invoke` 回调 |
| 结果列表 | 扫描/应用结果显示在专属 ListBox，双击可打开对应文件（v1.10.0） |
| 停止按钮 | 运行中点击「停止」强制中止后台 job，确保不再写入清单/文件（v1.10.0 / v1.11.0 真正中止） |
| 扫描摘要 | 窗体显示「已找到 N 个 .stignore 文件」；启动自动加载现有清单数量 |
| 安全确认 | 非预览且非强制时，Apply 前弹确认框，避免误写大量路径（v1.9.0） |
| 清空日志 | 日志框旁「清空日志」按钮，一键清空（v1.9.0） |
| 关于 | 「关于」按钮显示版本与项目地址（v1.10.0，v1.12.0 按钮行调整至左上区域） |
| 仅预览 | 勾选后不写文件，仅预览结果 |
| 强制 | 跳过逐文件确认直接执行 |
| 写回前备份 | 写回清单前备份原 `.stignore` 为 `.stignore.bak.<时间戳>` |
| 备份轮转 | 每种 `.bak.*` 最多保留 3 个，超出自动删最旧（v1.8.0） |
| 源文件豁免 | 被替换目标恰为标准源 `.stignore` 自身时跳过备份，不生成无意义备份（v1.9.0） |
| 版本/地址 | 底部状态栏显示版本号与可点击项目主页 |
| 实时日志 | 底部日志框输出全部执行信息（自动滚动到底） |

## 6. 扫描/应用工作流

1. 默认直接 **Scan** → 并行扫描所有根目录 → 生成 `stignore-paths.json`
   （记录 path / size / lastWriteUtc）。
2. 规则更新后，勾选 **强制** 点 **Apply** → 对每个历史路径用标准 `.stignore`
   替换（替换前自动备份）。规则一致的文件跳过，不重复备份。
3. 失效路径（源文件已删除）仅在勾选 **强制** 时从清单清理。

## 7. CHANGELOG

### v1.22.0 (2026-09-23)
- feat(app): 忽略清单在线更新——界面新增「忽略清单」卡片显示当前清单版本/来源/修订日；「检查清单更新」按钮从仓库 raw 地址下载最新 `.stignore`，按 `//Version` 比较后写盘生效并提示新版本号（`清单已更新到 vX（原 vY）` / `已是最新版本（vX）`）；清单来源优先级 exe 同目录 → `%APPDATA%` → 内置资源，构建时 CMake `POST_BUILD` 把 `assets/.stignore` 复制到 exe 同目录；Apply 改用生效清单并记录在用版本；下载器/内置加载器可注入（无新增依赖，`dart:io HttpClient`）
- test(app): 新增 `ruleset_info_test`（头解析/容错/版本比较）与 `ruleset_update_test`（内置回退、采纳更新、远端不更新、缺少版本头、网络失败、已存副本优先）——`flutter test` 31/31
- fix(app): `SettingsStore.save` 串行化写入（写队列 + `flush: true`），修复语言/主题与窗口几何并发写盘时「旧快照最后落盘 / 半截 JSON」导致偏好丢失；此即 `flutter test --coverage` 下 `settings_store_test` 偶发 `Expected: 'zh' Actual: 'en'` 的根因（CI 间歇性红灯）
- chore: 同步版本至 v1.22.0（VERSION / pubspec `1.22.0+1` / `AppState.version` / `manifest.dart 示例` / README 徽章）

### v1.21.1 (2026-09-23)
- feat(brand): 设计与应用标志、建立品牌资产——`tools/generate-brand-assets.ps1` 生成 `docs/assets/logo.svg`/`logo-512.png`/`logo-128.png` 与多尺寸 `app_icon.ico`（替换 Flutter 默认图标）；新增 `docs/assets/BRAND.md` 品牌规范与 §10 章节；README 双语文档顶部加 logo
- chore: 同步版本至 v1.21.1（VERSION / pubspec / `AppState.version` / `manifest.dart 示例` / README 徽章）

### v1.21.0 (2026-09-23)
- feat(app): 记住窗口大小与位置——新增 `models/window_bounds.dart` + `services/window_bounds.dart`（win32 按窗口类名找宿主窗口，`GetWindowRect`/`SetWindowPos`）；几何随偏好写入 `settings.json`，启动恢复、每 2s 采样变更（越界/过小几何忽略）
- fix(app): 修复选项勾选后界面不刷新的 bug——预览/强制/备份原为裸字段，赋值不触发 `notifyListeners`，改为 `setPreview`/`setForce`/`setBackup`；根目录/清单输入改用 `TextEditingController` 以反映「浏览」结果
- refactor(app): 拆分超过 200 行的源码——`app_state.dart` 拆出 `preferences_state`/`scan_options_state`/`log_state`/`progress_state`/`pickers_state`/`scan_flow`/`apply_flow` 七个 mixin；`home_page.dart` 拆为 `settings_dialog`/`root_field`/`options_row`/`scan_options`/`action_row`/`results_list`/`log_list`，并为主要容器与交互控件补充语义化 `Key`
- test(app): 新增选项点击生效回归测试 + 窗口几何持久化/校验测试（`flutter test` 19/19）
- chore: 同步版本至 v1.21.0（VERSION / pubspec `1.21.0+1` / `AppState.version` / `manifest.dart 示例` / README 徽章）

### v1.20.4 (2026-09-23)
- fix(ci): 修复产物「二次压缩」——`build-windows` 暂存运行文件为目录产物、`release` 作业才压缩归档，避免 `upload-artifact` 自带压缩与 `.zip` 叠加（zip 套 zip）
- chore: 同步版本至 v1.20.4（VERSION / pubspec `1.20.4+1` / `AppState.version` / `manifest.dart 示例` / README 徽章）

### v1.20.3 (2026-09-23)
- fix(ci): 发布包打包改用 `ZipArchive.CreateEntry` + 流拷贝——`CreateEntryFromFile` 为扩展方法，PowerShell 不可作为静态成员调用，曾致 `build-windows` 打包失败
- chore: 同步版本至 v1.20.3（VERSION / pubspec `1.20.3+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### v1.20.2 (2026-09-23)
- perf(ci): 减小发布包体积——构建加 `--tree-shake-icons`、发布包改用 `SmallestSize` 高压缩并剔除 `*.pdb`/`*.exp`/`*.lib` 调试符号（`ci.yml` 打包步骤）
- chore: 同步版本至 v1.20.2（VERSION / pubspec `1.20.2+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### v1.20.1 (2026-09-23)
- docs: 修正 Flutter 规格与 §9.1 模块描述滞后——补 v1.19.0 设置对话框+磁盘持久化、v1.19.1 跳过 exe 目录子树、v1.20.0 异步遍历+扫描深度/大目录过滤
- chore: 同步版本至 v1.20.1（VERSION / pubspec `1.20.1+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### v1.20.0 (2026-09-23)
- feat(app): 扫描选项——扫描深度调节（默认 3 级，1–10 可调）；大目录过滤（默认跳过 >100 文件子目录，阈值 10–1000 可调、可开闭）。`scanner.dart` 改异步 + `maxDepth`/`skipLargeDirs`/`maxFilesPerDir`，流式计数避免巨目录卡死；`home_page` 新增 `_ScanOptions` 卡片（深度滑块 + 大目录过滤复选框/阈值滑块）；`i18n` 增 `scanDepth`/`skipLargeDirs`/`maxFilesPerDir`/`level`
- test(app): `scanner_test` 增深度限制 + 大目录过滤（共 15/15）—— `flutter analyze` 0 问题
- chore: 同步版本至 v1.20.0（VERSION / pubspec / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### v1.19.1 (2026-09-23)
- fix(app): 扫描/替换自动跳过运行中的 exe 目录子树内的 `.stignore`（`scanner.dart` 始终跳过 `p.dirname(Platform.resolvedExecutable)` 且 `skipDir` 改为目录+子目录整体跳过；`applier.dart` 增 `skipRoots` 兜底；`app_state` 在 `scan`/`apply` 注入 `appDirectory`）——避免工具自伤打包规则
- test(app): `scanner_test` 验证 `skipDir` 子树跳过；`applier_test` 新增 `skipRoots` 豁免；`flutter test` 13/13
- chore: 同步版本至 v1.19.1（VERSION / pubspec / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### v1.19.0 (2026-09-22)
- feat(app): 新增「设置」按钮与设置对话框，集中管理界面语言与明暗主题（AppBar 的语言下拉与主题切换收敛为单一齿轮按钮）
- fix(app): 语言/主题持久化到 `%APPDATA%\SyncthingIgnoreGUI\settings.json`（新增 `lib/services/settings_store.dart`，纯 `dart:io` 无新增依赖；`AppState.loadSettings()` 启动恢复、`setLanguage()`/`setTheme()` 变更即写盘；`main.dart` 在 `runApp` 前加载，首帧即恢复上次偏好）；此前仅为会话内状态，关闭即丢失
- test(app): 新增 `settings_store_test.dart`（缺省/往返/损坏回退/启动恢复/写盘）；`widget_test.dart` 语言切换改走设置对话框 —— `flutter test` 12/12
- chore: 同步版本至 v1.19.0（VERSION / pubspec / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### v1.18.11 (2026-09-22)
- ci: 规范化构建产物命名（对齐全局约定）——新增 §9.5「构建产物命名规范」（`<产品名>-v<语义版本>-<os>-<arch>.<扩展名>`，产品名取 `env.APP_NAME`、版本取根 `VERSION`）；CI 头补注该规则；Actions 产物名由 `windows-x64-release` 改为 `SyncthingIgnoreGUI-v<版本>-windows-x64`；`release` 作业补 `prerelease` 标记（版本含 `-` 时自动标预发布）
- chore: 同步版本至 v1.18.11（VERSION / pubspec / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### v1.18.10 (2026-09-22)
- fix(app): 适配 `file_picker` 13.1.0 / `win32` 6.4.0 破坏性变更（`GetLogicalDrives()` 返回 `Win32Result<int>` 需取 `.value`、`GetDriveType()` 用 `PCWSTR` 包装、`FilePicker.saveFile()` 返回 `Uri?` 且需必填 `bytes`），恢复 `flutter analyze` 通过
- chore: 同步版本至 v1.18.10（VERSION / pubspec / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### v1.18.9 (2026-09-22)
- fix(app): 升级 `file_picker` 至 `^11.0.0` 并改用静态 API（`FilePicker.getDirectoryPath()` / `FilePicker.saveFile()`），移除已废弃的 `FilePicker.platform` getter 调用
- chore: 同步版本至 v1.18.9（VERSION / pubspec / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### v1.18.8 (2026-09-22)
- ci: 完善 CI（手动触发、最小权限、作业超时、覆盖率与 LCOV 产物、规则集副本漂移报告、Release 说明取自 CHANGELOG）；新增 `.github/dependabot.yml` 与 README CI 徽章
- chore: 同步版本至 v1.18.8（VERSION / pubspec / `AppState.version` / `manifest.dart` 示例 / README 徽章）
- docs: 修正 `docs/project.md` §3 规则集版本标注（1.18.6→1.18.5）；更新 `docs/development-tasks.md` 与 Flutter 规格状态（`flutter analyze` 零告警已达成、CI `build-windows` 已落地产出 exe/zip）

### v1.18.7 (2026-09-22)
- chore(gitignore): 新增 coding 临时文件/目录忽略规则（`*.log` `*.swp` `.DS_Store` `app/.dart_tool/` `app/build/` 等），注释明确编程工具配置目录放行（保持跟踪）
- chore: 同步版本至 v1.18.7（VERSION / pubspec / `AppState.version` / README 徽章）

### v1.18.6 (2026-09-22)
- fix(stignore): 移除 `.git` 过滤规则（含注释行），使同步目录中的 Git 仓库完整同步、跨设备保留分支信息；`.svn/` `.hg/` 维持忽略
- fix(stignore): 同步打包副本 `app/assets/.stignore`，规则集头版本统一至 v1.18.6
- fix(docs): 修正 README / README_EN 规则计数 330 → 329（历史 off-by-one）；分类表第 5 类移除 `.git/`
- fix(app): 修复 Flutter 桌面版编译错误使 `flutter analyze` 通过（platform_io 补 `ffi`、scanner 的 `p.basename`/`Isolate.run`、测试改 `flutter_test`、清理 8 处 dangling library doc comment 与未用导入/字段/变量）
- note: v1.18.6 同时对应 Dart + Flutter 桌面版（主实现），详见 README §9

### v1.18.5 (2026-09-22)
- docs: 将 `openspec/` 规范文档迁移至 `docs/`（`docs/project.md` 与 `docs/specs/stignore-gui/spec.md`），更新目录结构树与内部引用
- docs: 同步版本号至 v1.18.5（脚本头 `//Version` / `$ScriptVersion` / `.stignore` 头 / README 徽章）

### v1.18.4 (2026-09-21)
- fix(gui): 后台作业改由克隆会话状态的 runspace 运行（`CreateDefault` + 复制脚本函数），修复 Scan/Apply 因 runspace 隔离抛 `CommandNotFoundException`、且 `$T`/`$lang` 等脚本变量不可见导致的**两个核心功能完全不可用**
- fix(gui): Apply 进度/状态/摘要/日志改走 `Synchronized` 共享状态 + UI Timer 轮询，移除失效的 `Control.Invoke` 闭包（PowerShell 闭包无法跨 `Control.Invoke` 捕获脚本变量）
- fix(gui): `Lmsg` 中文分支 `Decode-Uni $X -f ...` 运算符优先级错误，导致中文状态/摘要/进度/确认框/关于框显示未替换的模板字面量（如 `已找到 {0}`），改为 `((Decode-Uni $X) -f ...)`
- fix(gui): `Write-LogLine` 的 `Color` 参数此前被忽略，日志框改用 `RichTextBox` 实现逐行着色
- fix(gui): 语言下拉框项已本地化（中文界面显示 英文/中文）；`Pick-File` 初始目录跟随当前清单路径；修正停止应用提示中误用的全角小于号 `\uff1c` → `\uff1b`
- docs: 版本同步至 v1.18.4（脚本头 / `$ScriptVersion` / `.stignore` 头 / README 徽章 / docs）

### v1.18.3 (2026-09-21)
- feat(stignore): 新增第 21 类「AI 编码助手与 Vibecoding 临时文件」，覆盖 20 个 AI 结对编程工具数据/缓存目录（.codex/ .gemini/ .qwen/ .codeium/ .continue/ .cline/ .roo/ .kilocode/ .cody/ .trae/ .junie/ .supermaven/ .opencode/ .goose/ .openhands/ .augment/ .tabnine/ .qoder/ .workbuddy/ .amp/），规则总数 310 → 330
- docs: README / README_EN 分类概览同步新增第 21 类，徽章分类 20→21、规则数 310→330；版本同步至 v1.18.3

### v1.18.2 (2026-08-31)
- fix(gui): 扫描/应用后台 job 升脚本作用域 + 点击清理并行竞争；取消分支置 handles `$null` 守卫；apply 失败不再误报完成；`Get-FileHash` 锁文件容错；进度推送去 `Controls.Find`；日志去 `DoEvents` 重入
- docs: 版本同步至 v1.18.2（脚本头 / `$ScriptVersion` / README 徽章与版本引用）

### v1.18.1 (2026-08-31)
- fix(gui): 扫描/应用 Timer tick 回调补顶层 try/catch，修复 `$null` 调用引发的 JIT 崩溃；`$bgHandle.IsCompleted` 加 `$null` 守卫
- docs: 版本同步至 v1.18.1（脚本头 / `$ScriptVersion` / README 徽章与版本引用）

### v1.18.0 (2026-08-31)
- feat(stignore): 补齐高频过滤缺口，新增 22 条规则（287 → 309），0 重复
  - 编辑器/AI 工具：`.claude/` `.windsurf/` `.aider/` `*.iml` `.serverless/`
  - Shell/REPL 历史：`.zsh_history` `.bash_history` `.sqlite_history` `.node_repl_history` `.python_history`
  - 包管理器缓存：`.conda/` `.spack/` `.opam/` `.stack-work/` `.uv/`
  - 测试/覆盖率：`.cypress/` `.playwright/` `.allure/`
  - 容器：`.buildkit/` `.podman/` `.containerd/`
- docs: README / README_EN 分类概览同步新增项，徽章规则数 287→309；版本同步至 v1.18.0

### v1.17.2 (2026-08-31)
- feat(stignore): 新增 `**/logs/` `**/log/` 日志目录忽略规则（归位至「Backup & Temporary Files」类），规则总数 285 → 287
- refactor(stignore): 原误置在「Database Files」类的 `logs/` `log/` 移出，避免与数据库语义混淆
- docs: 版本同步至 v1.17.2（脚本头 / `$ScriptVersion` / `.stignore` 头 / README 徽章与版本引用）

### v1.17.1 (2026-08-31)
- feat(gui): 扫描时实时显示当前正在遍历的目录（原只显示最新命中文件），状态行改为「根进度 | 已找到 N | 当前目录 | 耗时」
- refactor(gui): 遍历改为显式栈 DFS + `DirectoryInfo.EnumerateFileSystemInfos()`（Get-ChildItem -Recurse 管道无法上报当前位置）；一次枚举同时取文件与子目录
- fix(gui): 无权限目录不再中断整个根，改为跳过并累计，结束输出总数；根目录不存在仍返回一条 __error
- docs: 版本同步至 v1.17.1

### v1.17.0 (2026-08-31)
- feat(gui): 新增底部实时状态行，扫描/应用期间显示已完成根目录数、已找到文件数、最新命中路径与耗时
- feat(gui): 扫描结果流式追加到结果列表，摘要实时刷新为「正在扫描... 当前已找到 N 个」
- perf(gui): 进度改为共享状态 + Timer 拉取（去掉 form.Invoke 回调），单根目录时进度条转 Marquee 避免假百分比
- fix(gui): Apply 进度计数仅在写入分支递增导致进度偏慢，移至循环入口逐路径计入
- docs: 版本同步至 v1.17.0（脚本头 / `$ScriptVersion` / `.stignore` 头 / README 徽章与版本引用）

### v1.16.2 (2026-08-31)
- docs: 新增 .github/ Community Health Files（CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / SUPPORT / PR 模板 / 3 个 Issue 模板 + config.yml），README 中英增补对应入口；版本同步至 v1.16.2

### v1.16.1 (2026-08-31)
- docs: 精简 README / README_EN（删除重复界面布局图与重复段落，分类改表格）；版本同步至 v1.16.1

### v1.16.0 (2026-08-31)
- feat(stignore): 新增第 18 类「缓存与临时目录」，用 `(?i)` 大小写不敏感覆盖 cache/ caches/ temp/ tmp/ .cache/ .tmp/ cachedata/ thumbnails/ thumbs/ 等
- feat(stignore): 新增第 19 类「浏览器与 Electron 存储缓存」（CacheStorage/ Code Cache/ GPUCache/ ShaderCache/ DawnCache/ INetCache/ Local Storage/ IndexedDB/ blob_storage/ Crashpad/ 等）
- feat(stignore): 新增第 20 类「系统临时与缓存位置」，根锚定 /tmp/ /var/tmp/ /var/cache/ /private/var/folders/ /Windows/Temp/
- feat(stignore): 补充开发缓存文件 .eslintcache / .sass-cache/ / .rollup.cache/ / *.tsbuildinfo
- refactor(stignore): 散落在「媒体与播放器缓存」的 9 条 cache 规则归位至新类，消除 5 条重复；Temp/ 与 .tmp/ 由 (?i) 规则覆盖后删除
- docs: README / README_EN 分类列表同步 20 类，徽章 17→20、规则数 258→285；版本同步至 v1.16.0

### v1.15.0 (2026-08-31)
- fix(stignore): `/node_modules/**` 根锚定导致嵌套 node_modules 漏网 → `**/node_modules/`；`**/vendor/` 不匹配根级 → 并列 `/vendor/` 与 `**/vendor/`
- fix(stignore): `**/.vscode/*` 只匹配直接子项 → `**/.vscode/**`（`!` 行同步改 `!**/.vscode/settings.json`）
- fix(stignore): vim 交换文件模式 `**/.swp` / `**/.swo` 永远匹配不到 → `**/*.swp` / `**/*.swo`，补 `**/*.un~`
- fix(stignore): 移除误伤真实数据的 `**/*.db`，保留 `*.db-wal` / `*.db-shm` / `*.db-journal`
- fix(stignore): `*.lock` 误伤 `Cargo.lock` → 收窄并反转保留 8 类依赖锁文件
- fix(stignore): 移除与注释自相矛盾的 `**.stfolder/` / `**.stversions`（破坏 folder marker 与版本控制）
- fix(stignore): 移除宽泛误伤 `**Cache*` / `**Internet*` / `**download*/` / `**log*/` / `**metadata/` / `**thumb/` / `**packages/`，改为具名缓存目录
- feat(stignore): 新增第 17 类「构建产物与语言输出」（target/dist/build/bin/obj/out/*.pyc/*.class/*.o/*.pdb 等）
- feat(stignore): 补 `.svn/` `.hg/` `.mvn/` `.scala-build/` `cmake-build-*/` `found.000/` `ehthumbs.db` `hiberfil.sys` `.Trash-*/` `nohup.out` `*.log.*` 与项目自身备份 `**/.stignore.bak.*`
- style(stignore): 统一目录尾斜杠与文件 `**/*.ext` 前缀，去重冗余覆盖；规则数 225 → 258
- docs: README / README_EN 分类列表补齐第 17 项并同步新规则，版本同步至 v1.15.0

### v1.14.0 (2026-08-07)
- 修复 GUI 无法打开（致命）：PowerShell `-Command` 默认 MTA 线程，WinForms 要求 STA。脚本开头检测非 STA 时自动以 `powershell -STA -File` 重启自身（exit 透传退出码）；STA 重启块加异常兜底，失败弹错误框而非静默退出
- EnableVisualStyles 移至程序集加载后、控件创建前，确保视觉样式生效
- 修复 Apply-Language 设 SelectedIndex 触发 SelectedIndexChanged 事件递归调用（加 `$script:applyingLang` 防重入标志），语言/主题切换事件均受保护
- 消息循环 `Application::Run` 外包全局异常兜底，未捕获异常弹明细框而非闪退
- 修复 Apply-Theme 对无 BorderStyle 属性控件赋值崩溃；改为递归遍历所有控件
- 修复扫描/应用 runspace 中 `form.Invoke` 进度回调引用 `$script:progress`/`$script:lblPct` 为 null 崩溃（改为按 Name 查找控件）
- 深色模式视觉优化：输入控件自定义暗灰自绘边框，按钮 Flat 风格 + 暗灰边框，清单输出路径框中灰边框
- 清单默认路径迁移至 `config/stignore-paths.json`，运行前确保 config/ 目录存在

### v1.13.0 (2026-08-07)
- 修复主题切换错位 bug：关闭窗体 AutoScroll（原因切换主题时重绘触发滚动条并把控件推出可视区）
- 修复窗口滚动条问题：AutoScroll 改为 false，固定 720×640 布局，内容已全部收进范围内不再出现滚动条
- Apply-Theme 末尾增加 PerformLayout + Refresh 确保主题切换重绘同步、消除残影/错位

### v1.12.0 (2026-08-07)
- 修复 GUI 窗口溢出：重排所有控件坐标，使其全部收进窗体 640 高度内
- 顶部语言/主题选择器同行对齐；按钮行统一 Y=212 并防右缘溢出
- 结果列表/日志/进度条/状态栏 Y 坐标整体压缩，状态栏降至 Y=600，窗体 MinimumSize 调整为 640×560

### v1.11.0 (2026-08-07)
- 修复取消竞态：扫描/应用点击「停止」后强制中止后台 job，确保不再写入清单/文件（#3 #4）
- 修复版本栏本地化偏差，中文模式正确显示中文项目链接文案（#1）
- 删除恒等死代码 `txtRoot` 赋值（#2）
- 删除死代码 `Start-ScanJob`、`Update-Progress`（#5 #6）
- 完成/异常分支统一清零 `cancelFlag`，避免 Scan/Apply 间状态串扰（#9）

### v1.10.0 (2026-08-06)
- feat(gui): 新增浅色/深色主题切换，并持久化到 `config.json`
- feat(gui): 语言选择持久化到 `config.json`，下次启动自动恢复
- feat(gui): 支持文件夹/`.stignore` 拖拽到窗口自动填充输入框
- feat(gui): 新增结果显示 ListBox，双击可打开对应文件
- feat(gui): 新增「停止」按钮，运行中可立即收回 UI 控制权
- feat(gui): 新增「关于」按钮，显示版本与项目地址
- perf(gui): 进度条旁显示实时百分比文字
- fix(gui): 日志框自动滚动到底，始终可见最新行
- chore: `config.json` 加入 `.gitignore`

### v1.9.0 (2026-08-06)
- feat(gui): Apply 改为后台 runspace 执行，进度条显示真实百分比，消除界面卡顿
- feat(gui): 扫描/应用后窗体显示文件数量摘要，启动自动加载现有清单
- feat(gui): 非预览且非强制时 Apply 前弹出安全确认框，避免误写大量路径
- feat(gui): 新增「清空日志」按钮
- fix(gui): 被替换目标恰为标准源 `.stignore` 自身时跳过备份，不生成无意义备份

### v1.8.0 (2026-08-06)
- feat(gui): 备份轮转，`.stignore.bak.*` 与清单备份均最多保留 3 个，超出自动删除最旧

### v1.7.0 (2026-08-06)
- fix(gui): 扫描改为后台 runspace + Timer 轮询，消除 GUI 线程阻塞导致的进度卡顿

### v1.6.0 (2026-08-06)
- fix(gui): 语言切换下拉项混用真实中文导致乱码 → 改为纯 ASCII + `\u` 转义
- feat(gui): 底部状态栏显示版本号与可点击项目主页链接
- fix(gui): runspace 并行扫描改用内联脚本块，修复"无法识别 Find-StignoreFiles"错误

### v1.5.0 (2026-08-06)
- perf(gui): runspace 线程池并行扫描 + `-Filter` 替代 `-Include`，扫描提速
- fix(gui): 统一日志函数为 `Write-LogLine`（修复旧调用未定义导致崩溃）

### v1.4.0 (2026-08-06)
- feat(gui): 中英文界面切换（右上角下拉框，默认跟随系统区域）

### v1.3.0
- refactor: 合并命令行脚本为单一 GUI 工具，扫描/应用逻辑内联

## 8. 待办 / 已知限制

完整任务跟踪见 [开发任务清单](development-tasks.md)。要点：

- [ ] Flutter 版相较 PowerShell 版仍缺：应用前安全确认框、实时状态行（当前扫描目录）、拖拽填入、双击打开文件、启动时「已加载清单」提示
- [ ] 应用阶段 `Stop` 取消尚未接入 `applyRules` 循环
- [ ] 测试覆盖率门禁（≥80%）、UI 部件测试（flutter_test + mockito）未建立
- [x] GitHub Actions CI：构建并打包命名归档 `SyncthingIgnoreGUI-v1.22.0-windows-x64.zip`（`.github/workflows/ci.yml`）
- [ ] 发布包说明（VC++ 运行库 / Flutter AOT 运行时）或 Inno Setup 安装包
- [ ] 规则更新后须同步 `app/assets/.stignore` 副本

## 9. Dart + Flutter 桌面版（主实现）

原 `SyncthingIgnoreGUI.ps1`（PowerShell WinForms）正被重写为 **Dart + Flutter Windows 桌面应用**，位于 `app/`，目标构建为独立 `.exe` 分发。功能与行为对齐原脚本（扫描 / 应用 / 备份轮转 / 中英双语 / 明暗主题）。

### 9.1 模块拆分（单一职责）

| 模块 | 职责 |
|------|------|
| `lib/main.dart` | 入口，`runApp` 前 `await AppState.loadSettings()` 恢复用户偏好；首帧后 `restoreWindowBounds()`/`startWindowTracking()` 恢复并采样窗口几何 |
| `lib/app.dart` | `MaterialApp` + 明暗主题（`ThemeMode` 跟随设置） |
| `lib/i18n.dart` | 中英双语字典，键与 PowerShell `$T` 一致；`t(key, args)` 支持 `{0}` 占位 |
| `lib/models/manifest.dart` | `StignoreRecord` / `Manifest`，对齐 PowerShell manifest JSON 结构 |
| `lib/models/window_bounds.dart` | `WindowBounds`（x/y/width/height 纯数据）：JSON 往返、可用性校验（v1.21.0） |
| `lib/models/ruleset_info.dart` | `RulesetInfo`：解析清单头 `//Version`/`//Updated`，并提供点分版本比较 `compareRulesetVersions`（v1.22.0） |
| `lib/services/scanner.dart` | DFS 异步遍历找 `.stignore`（跳过 `.git`/规则源/应用自身 exe 目录子树，v1.19.1），每根目录一个 isolate 并行（默认 4）；`findStignoreFilesRaw` 支持 `maxDepth`/`skipLargeDirs`/`maxFilesPerDir`（v1.20.0），流式计数避免巨目录卡死，纯函数可单测 |
| `lib/services/applier.dart` | 应用标准规则：SHA-256 比对跳过一致文件、写前 `.bak.<时间戳>` 备份、`<base>.bak.*` 轮转保留 ≤3、仅 `force` 清理失效路径；`applyRules` 支持 `skipRoots`（v1.19.1）自动跳过应用自身目录子树 |
| `lib/services/rules_source.dart` | 从 `assets/.stignore` 加载标准规则并计算 SHA-256 |
| `lib/services/platform_io.dart` | Windows 固定驱动器枚举（win32 `GetLogicalDrives` / `GetDriveType`） |
| `lib/services/window_bounds.dart` | 经 win32 按窗口类名 `FLUTTER_RUNNER_WIN32_WINDOW` 找宿主窗口，`GetWindowRect` 读取 / `SetWindowPos` 恢复几何；越界/过小几何忽略，非 Windows 为 no-op（v1.21.0） |
| `lib/services/settings_store.dart` | 用户偏好（语言 / 主题 / 窗口几何）JSON 持久化：`%APPDATA%\SyncthingIgnoreGUI\settings.json`；纯 `dart:io`，无新增依赖，缺失/损坏回退默认值 |
| `lib/services/app_paths.dart` | 共享的用户数据目录（`%APPDATA%\SyncthingIgnoreGUI`），`settings_store` 与清单缓存复用（v1.22.0） |
| `lib/services/ruleset_store.dart` | 清单（`.stignore`）读写：来源优先级 exe 同目录 → 用户数据目录 → 内置资源；写入优先 exe 同目录、失败回退（v1.22.0） |
| `lib/services/ruleset_update.dart` | 从仓库 raw 地址下载清单（`dart:io HttpClient`，15 s 超时 / 5 MiB 上限，**无新增依赖**），下载器可注入（v1.22.0） |
| `lib/state/app_state.dart` | 组合下列 mixin，仅保留 `version`/`appDirectory`/`stop()`/`rulesPathLabel`（v1.21.0 拆分） |
| `lib/state/preferences_state.dart` | mixin：语言/主题/窗口几何的恢复与写盘（含窗口几何采样 Timer） |
| `lib/state/scan_options_state.dart` | mixin：预览/强制/备份 + 扫描深度/大目录过滤阈值（改动即 `notifyListeners`） |
| `lib/state/log_state.dart` | mixin：`LogEntry` 与日志缓冲、`logTranslated` 解析 applier 的 `key::arg` |
| `lib/state/progress_state.dart` | mixin：`isBusy`/`cancelled`/`progress`/`status`/`summary`/`results` + `begin()`/`finish()`/`elapsed()` |
| `lib/state/pickers_state.dart` | mixin：`rootText`/`manifestPath` 字段与「浏览」选择（`pickRoot`/`pickManifest`） |
| `lib/state/ruleset_state.dart` | mixin：清单版本/来源/更新状态；`loadRulesetInfo()`（不联网）、`effectiveRules()`（Apply 实际使用的清单）、`checkRulesetUpdate()`（下载并按版本采纳）（v1.22.0） |
| `lib/state/scan_flow.dart` | mixin：`scan()`——解析根目录（留空=固定驱动器）→ `scanRoots` → 写清单 |
| `lib/state/apply_flow.dart` | mixin：`apply()`——载入标准规则 → `applyRules`（预览/强制/备份）→ 回写清单 |
| `lib/ui/home_page.dart` | 主界面装配壳（Scaffold + 子组件 + 关于对话框）；子组件按职责拆至同目录（v1.21.0） |
| `lib/ui/settings_dialog.dart` | 语言/主题设置对话框（`SettingsDialog.show`） |
| `lib/ui/root_field.dart` | 根目录/清单路径输入（`TextEditingController`，可反映「浏览」结果） |
| `lib/ui/options_row.dart` | 预览/强制/备份复选行（经 `setPreview`/`setForce`/`setBackup` 触发刷新） |
| `lib/ui/scan_options.dart` | 扫描深度滑块 + 大目录过滤开关/阈值滑块 |
| `lib/ui/ruleset_card.dart` | 忽略清单卡片：当前版本 / 来源（内置·已下载）/ 修订日 + 存放路径（悬停）+「检查清单更新」按钮 + 结果提示（v1.22.0） |
| `lib/ui/action_row.dart` | 扫描/应用/清空/停止按钮 |
| `lib/ui/results_list.dart` | 结果列表（点击打开所在目录） |
| `lib/ui/log_list.dart` | 分级着色的日志列表 |

### 9.2 构建为 exe

```bash
cd app
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release --tree-shake-icons        # 产物：build/windows/x64/runner/Release/syncthing_ignore_gui.exe
```

> 标准规则集随资源打包（`assets/.stignore`），运行时由 `rootBundle` 加载；
> 构建后 CMake `POST_BUILD` 还会把它复制为 exe 同目录的 `.stignore`（清单来源
> 优先级与在线更新见 §9.6）。更新规则后需同步该副本（见 §4 版本同步）。
> exe 分发需目标机具备 Visual C++
> 运行库与 Flutter AOT 运行时（发布包已自带）。
> CI 自动构建：推送 `v*` 标签时由 `.github/workflows/ci.yml` 的 `build-windows` 作业
> 构建并将运行文件暂存为**目录**产物，再由 `release` 作业压缩为并发布
> `SyncthingIgnoreGUI-vX.Y.Z-windows-x64.zip`（版本取自根 `VERSION`）。

### 9.3 测试与覆盖率（dart-collect-coverage）

`app/test/` 覆盖纯逻辑：`scanner_test.dart`（遍历/跳过/并行）、`applier_test.dart`
（替换/跳过/预览/备份轮转）、`settings_store_test.dart`（缺省/往返/损坏回退/`AppState`
启动恢复与写盘）与 `widget_test.dart`（应用壳渲染 + 设置对话框语言切换）。生成 LCOV：

```bash
cd app
flutter test --coverage                 # 生成 coverage/lcov.info
# 或用 coverage 包格式化 + 校验忽略指令
dart run coverage:format_coverage --packages=.dart_tool/package_config.json \
    --lcov -i coverage/coverage.json -o coverage/lcov.info --check-ignore
```

忽略指令：`// coverage:ignore-line` / `ignore-start..end` / `ignore-file`，
可用 `--check-ignore` 强制校验。UI 部件测试后续补 `flutter_test` + `mockito`。

### 9.4 实现分工

`SyncthingIgnoreGUI.ps1`（PowerShell WinForms，v1.18.5）已转为**遗留维护态**；
**Dart + Flutter 桌面版（v1.22.0）为主实现**，构建为独立 `.exe` 分发。两者共享同一
`.stignore` 规则集与文档。Flutter 版相较 PowerShell 版的功能对等项与工程化待办，
见 [开发任务清单](development-tasks.md)。

### 9.5 构建产物命名规范

CI 构建的发布包统一命名（与全局约定一致）：

```
<产品名>-v<语义版本>-<os>-<arch>.<扩展名>
```

| 占位 | 取值 |
|------|------|
| `<产品名>` | PascalCase、无空格；由 workflow 常量 `env.APP_NAME` 统一定义（当前 `SyncthingIgnoreGUI`） |
| `<语义版本>` | 取自根 `VERSION`，经 `version` 作业以 `needs.version.outputs.version` 注入（禁止硬编码） |
| `<os>` | `windows` / `macos` / `linux`（小写） |
| `<arch>` | `x64` / `arm64` |
| `<扩展名>` | Windows / macOS 用 `zip`；Linux 用 `tar.gz` |

- CI 作业间产物以**目录**形式传递：`build-windows` 暂存运行文件为目录产物，`release` 作业才压缩为归档；
  避免 `upload-artifact` 自带的一层压缩与发布 `.zip` 叠加导致「二次压缩」（zip 里套 zip）。
- 归档**仅在 `release` 作业**压缩：用 .NET `System.IO.Compression` `CompressionLevel.SmallestSize`
  （优于 `Compress-Archive` 默认 Deflate），暂存时剔除调试符号 `*.pdb`/`*.exp`/`*.lib`，以减小 `.zip` 体积
  （见 `ci.yml` `Stage release files` / `Package release archive` 步骤）。
- Release 资产**仅上传归档**（`*.zip` / `*.tar.gz`），不上传构建目录树。
- 预发布版本以 GitHub Release 的 `prerelease` 标记区分，**不在文件名加后缀**。

示例：`SyncthingIgnoreGUI-v1.22.0-windows-x64.zip`

### 9.6 忽略清单在线更新（v1.22.0）

规则集（`.stignore`）自带 `//Version` / `//Updated` 头，应用据此判断仓库是否有更新。

**清单来源优先级**（`services/ruleset_store.dart`）：

1. **exe 同目录的 `.stignore`** —— 随构建由 `windows/runner/CMakeLists.txt` 的
   `POST_BUILD` 复制，故应用目录始终含最新清单；更新也优先写回此处（用户可直接查看/替换）；
2. `%APPDATA%\SyncthingIgnoreGUI\.stignore` —— 应用目录不可写（如装在
   `Program Files`）时的兜底；
3. 内置资源 `assets/.stignore` —— 最终回退。

**界面**（`ui/ruleset_card.dart`）显示当前清单版本、来源（内置 / 已下载）、修订日与
存放路径（悬停查看），并提供「检查清单更新」按钮。

**更新流程**（`state/ruleset_state.dart` + `services/ruleset_update.dart`）：

- `GET https://raw.githubusercontent.com/sutchan/Syncthing_Ignore_Patterns/main/.stignore`
  （`dart:io HttpClient`，15 s 超时，5 MiB 上限，UTF-8，**无新增依赖**）
- 远端 `//Version` 高于当前 → 写盘并切换为生效清单，提示
  「清单已更新到 vX（原 vY）」；
- 不高于当前 → 提示「已是最新版本（vX）」，不改动本地；
- 缺少版本头 / 网络失败 → 保留本地并给出原因（同时写入日志）。

Apply 使用 `effectiveRules()`（下载副本优先），日志记录在用清单的版本与修订日。
清单版本（`.stignore` 头 `//Version`）与应用版本（`VERSION`）**相互独立**。

## 10. 品牌资产

标志与应用图标由 [`tools/generate-brand-assets.ps1`](../tools/generate-brand-assets.ps1)
统一生成（纯 .NET `System.Drawing`，本机离线可跑）：

- **标志**：teal 渐变圆角底板 + 白色同步环（两段圆弧）被粗斜杠截断——
  环=同步循环、斜杠=忽略、缺口=「同步被忽略规则截断」。
- **色板**：`#22C6B4 → #08665C`（垂直渐变）+ `#FFFFFF` 图形；界面主色种子 `Colors.teal`。
- **资产**：`docs/assets/logo.svg`（矢量母版）、`logo-512.png`、`logo-128.png`、
  `app/windows/runner/resources/app_icon.ico`（16/24/32/48/64/128/256，PNG 载荷，
  由 `runner.rc` 的 `IDI_APP_ICON` 编译进 exe）。
- **规范**（最小尺寸 / 留白 / 禁用项 / 再生成方式）见
  [docs/assets/BRAND.md](assets/BRAND.md)。
