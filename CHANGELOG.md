# 变更日志 (Changelog)

> 本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/) `MAJOR.MINOR.PATCH`；文档/配置类变更默认升级 `PATCH`，新功能升级 `MINOR`。
> 版本号同步位置：主实现（Flutter）以 `app/pubspec.yaml` `version:` 与 `app/lib/state/app_state.dart` `AppState.version` 为单一来源，并同步 `README.md` / `README_EN.md` 徽章；遗留 PowerShell 版（`SyncthingIgnoreGUI.ps1` 头 `//Version` / `$ScriptVersion`）与规则集（`.stignore` 头 `//Version`）独立演进。

---

## [v1.19.1] - 2026-09-23

### 修复
- fix(app): 扫描与替换时自动忽略应用自身目录（运行中的 exe 所在目录）子树内的 `.stignore`，避免工具扫描/覆盖自带的打包规则（`assets/.stignore`）而自伤
  - `services/scanner.dart`：`findStignoreFilesRaw` 始终把 `p.dirname(Platform.resolvedExecutable)` 加入跳过集；`skipDir` 由「精确匹配单个目录」改为「目录及其全部子目录」整体跳过
  - `services/applier.dart`：`applyRules` 新增 `skipRoots` 参数；命中应用目录的清单项直接跳过（不备份/不写），作为既存清单的兜底
  - `state/app_state.dart`：新增 `appDirectory` getter；`scan()` 传 `skipDir: appDirectory`、`apply()` 传 `skipRoots: [appDirectory]`
  - `i18n.dart`：新增 `skippedAppDir`（en/zh），替换时命中应用目录即静默跳过
- chore: 同步版本至 v1.19.1（VERSION / pubspec `1.19.1+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### 测试
- `scanner_test`：`skipDir` 改为子树跳过（嵌套 `.stignore` 同样被排除）
- `applier_test`：新增 `applyRules skips paths inside skipRoots`（命中 `skipRoots` 的 `.stignore` 不被替换/不备份）
- 本地 `flutter analyze` 无问题、`flutter test` **13/13** 通过

## [v1.19.0] - 2026-09-22

### 新增
- feat(app): 新增「设置」按钮与设置对话框，集中管理界面语言与明暗主题（AppBar 的语言下拉与主题切换按钮收敛为单一齿轮按钮）

### 修复
- fix(app): 语言与明暗主题选择持久化到磁盘，重启后自动恢复；此前仅保存在会话内存中，关闭窗口即丢失
  - 新增 `lib/services/settings_store.dart`：纯 `dart:io` JSON 读写（`%APPDATA%\SyncthingIgnoreGUI\settings.json`），**无新增依赖**；文件缺失或损坏时回退默认值
  - `lib/state/app_state.dart`：新增 `loadSettings()`，`setLanguage()` / `setTheme()` 变更即写盘（best-effort，写盘失败不影响 UI）；语言码按 `AppLocalizations.supported` 校验
  - `lib/main.dart`：`runApp` 前先 `await loadSettings()`，首帧即为上次的语言/主题，避免闪烁默认值
  - `lib/i18n.dart`：新增 `settings` / `close` 文案（en + zh）
- chore: 同步版本至 v1.19.0（VERSION / pubspec `1.19.0+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### 测试
- 新增 `app/test/settings_store_test.dart`：缺省值 / 存读往返 / 损坏 JSON 回退 / `AppState` 启动恢复 / 变更写盘（5 项）
- `app/test/widget_test.dart`：语言切换用例改走设置对话框（新增设置按钮打开断言）
- 本地 `flutter analyze` 无问题、`flutter test` **12/12** 通过

## [v1.18.11] - 2026-09-22

### CI / 规范
- ci: 规范化构建产物的命名（对齐全局约定，见 `docs/project.md` §9.5「构建产物命名规范」）
  - 规范：`<产品名>-v<语义版本>-<os>-<arch>.<扩展名>`；产品名由 workflow 常量 `env.APP_NAME` 统一定义，版本取自根 `VERSION`（`needs.version.outputs.version` 注入，禁止硬编码）
  - CI 工作流头补注该命名规则；Actions 产物名由 `windows-x64-release` 改为 `SyncthingIgnoreGUI-v<版本>-windows-x64`（与归档名一致）
  - `release` 作业补 `prerelease` 标记：版本号含 `-`（如 `1.19.0-rc.1`）自动标预发布，不在文件名加后缀
- chore: 同步版本至 v1.18.11（VERSION / pubspec `1.18.11+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

## [v1.18.10] - 2026-09-22

### 依赖 / 修复
- fix(app): 适配 `file_picker` `13.1.0` 与 `win32` `6.4.0` 的破坏性 API 变更，恢复 `flutter analyze` 通过
  - `lib/services/platform_io.dart`：`GetLogicalDrives()` 现返回 `Win32Result<int>`，改取 `.value`；`GetDriveType()` 参数类型改为 `PCWSTR`，用 `PCWSTR(ptr)` 包装原生指针
  - `lib/state/app_state.dart`：`FilePicker.saveFile()` 改为写入字节并返回 `Uri?`（新增必填 `bytes`），`pickManifest` 改传占位空字节并取 `uri.toFilePath()`
- chore: 同步版本至 v1.18.10（VERSION / pubspec `1.18.10+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

## [v1.18.9] - 2026-09-22

### 依赖 / 修复
- fix: 升级 `file_picker` 至 `^11.0.0` 并改用其静态 API（`FilePicker.getDirectoryPath()` / `FilePicker.saveFile()`），移除已废弃的 `FilePicker.platform` getter 调用（`lib/state/app_state.dart`）
  - 原 `^8.0.0` 约束在解析到 11+ 版本时 `FilePicker.platform` getter 已被移除，导致 `flutter analyze` 报 `undefined_getter` 失败
- chore: 同步版本至 v1.18.9（VERSION / pubspec `1.18.9+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

## [v1.18.8] - 2026-09-22

### CI
- ci: 完善 GitHub Actions 工作流 `.github/workflows/ci.yml`
  - 新增手动触发 `workflow_dispatch`；标签（发布）运行不再被 `concurrency` 取消
  - 顶层权限收敛为最小权限 `contents: read`，仅 `release` 作业提权 `contents: write`
  - 各作业新增 `timeout-minutes`；`build-windows` 增加 `flutter test --coverage`、覆盖率摘要（写入 Step Summary）与 LCOV 产物上传
  - `validate` 新增规则集副本身份报告（`.stignore` vs `app/assets/.stignore` 漂移，当前仅告警不阻断）
  - `release` 的发布说明改为从 `CHANGELOG.md` 提取对应版本小节（`body_path`），替代默认提交列表
- ci: 新增 `.github/dependabot.yml`（每周检查 `github-actions` 与 `pub` 依赖更新）
- docs: README / README_EN 新增 CI 状态徽章
- chore: 同步版本至 v1.18.8（VERSION / pubspec `1.18.8+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

### 文档
- docs: 修正 `docs/project.md` §3 规则集版本标注（1.18.6→1.18.5，对齐 `.stignore` 头 `//Version: 1.18.5`）
- docs: 同步 `docs/project.md` 内部 Flutter 版本引用至 1.18.8；更新 `docs/development-tasks.md` 与 Flutter 规格状态（`flutter analyze` 零告警已达成、CI `build-windows` 已落地产出 exe/zip）

## [v1.18.7] - 2026-09-22

### 构建
- chore(gitignore): 新增 coding 临时文件/目录忽略规则（`*.log` `*.log.*` `*.swp` `*.swo` `*~` `.DS_Store` `Thumbs.db` `desktop.ini` `app/.dart_tool/` `app/build/` `app/.flutter-plugins-dependencies` `app/coverage/`）
- chore(gitignore): 注释明确编程工具配置目录（`.codebuddy/` `.github/` `.vscode/` `.cursor/` `.claude/` `.idea/`）放行——保持跟踪、不忽略
- chore: 同步版本至 v1.18.7（VERSION / pubspec `1.18.7+1` / `AppState.version` / `manifest.dart` 示例 / README 徽章）

## [v1.18.6] - 2026-09-22

### 文档
- docs: 将主实现说明从 PowerShell 版切换为 Dart + Flutter 桌面版（README / README_EN 批量同步工具改为双方案：Flutter 主实现 + PowerShell 遗留）
- docs: 更新 `docs/project.md` §2/§3/§4/§8/§9/§9.4，明确实现分工与版本单一来源（Flutter 主实现 v1.18.6、PowerShell 遗留 v1.18.5、规则集独立版本）
- docs: 标记 `docs/specs/stignore-gui/spec.md` 为遗留实现，新增 Flutter 版规格 `docs/specs/stignore-gui-flutter/spec.md`
- docs: 新增开发任务清单 `docs/development-tasks.md`（剩余未完成任务跟踪）

### 构建
- chore: 同步版本至 v1.18.6（pubspec `1.18.6+1`、`AppState.version`、README 徽章）

### CI
- ci: 新增 GitHub Actions 工作流 `.github/workflows/ci.yml`
  - `version` 作业从根 `VERSION` 读取主实现版本，校验 `v*` 标签与 `VERSION` 一致
  - `validate` 作业校验 `SyncthingIgnoreGUI.ps1` 语法、`.stignore` 规则集，并分三轨校验版本一致性
    （Flutter 主实现 == VERSION / PowerShell 遗留内部一致 / 规则集内部一致）
  - `build-windows` 作业在 `windows-latest` 执行 `flutter pub get` / `analyze` / `test` / `build windows --release`
  - `release` 作业仅在 `v*` 标签推送时创建 GitHub Release 并上传 `SyncthingIgnoreGUI-vX.Y.Z-windows-x64.zip`
- chore: 新增根 `VERSION` 文件（v1.18.6），作为主实现版本单一来源供 CI 读取

### 修复（Flutter）
- fix(app): 修复 Flutter 桌面版编译错误，使 `flutter analyze` 通过（52 项 → 0）
  - `services/platform_io.dart`：补 `package:ffi` 导入并新增 `ffi` 依赖（`toNativeUtf16` / `free` 未定义）
  - `services/scanner.dart`：`Directory` / `File` 无 `name` getter → 改用 `p.basename(e.path)`；`Isolate.run` 误用双类型参数与双位置参数 → 改为 `Isolate.run<R>(() => _scanRoot(...))`
  - `test/scanner_test.dart` / `test/applier_test.dart`：`package:test/test.dart` → `package:flutter_test/flutter_test.dart`
  - 清理 8 处 dangling library doc comment（补 `library;`）及未用 import / 字段 / 局部变量 / 多余非空断言 / 未用 catch 变量

## [v1.18.5] - 2026-09-22

### 文档
- docs: 将 `openspec/` 规范文档迁移至 `docs/`（`docs/project.md` 与 `docs/specs/stignore-gui/spec.md`），更新目录结构树与内部引用
- docs: 同步版本号至 v1.18.5（脚本头 `//Version` / `$ScriptVersion` / `.stignore` 头 / README 徽章）

## [v1.18.4] - 2026-09-21

### 修复（GUI）
- fix(gui): 后台作业由克隆会话状态的 runspace 运行（`InitialSessionState::CreateDefault` + 复制脚本函数），修复 Scan/Apply 因 runspace 隔离抛 `CommandNotFoundException`、脚本变量不可见，导致**两个核心功能完全不可用**的严重缺陷
- fix(gui): Apply 进度/状态/摘要/日志改走 `Synchronized` 共享状态 + UI Timer 轮询；移除失效的 `Control.Invoke` 闭包（PowerShell 闭包无法跨 `Control.Invoke` 捕获脚本变量）
- fix(gui): 中文 `Lmsg` 分支 `Decode-Uni $X -f ...` 运算符优先级错误，致中文状态/摘要/进度/确认框/关于框显示未替换模板字面量，改为 `((Decode-Uni $X) -f ...)`
- fix(gui): `Write-LogLine` 的 `Color` 参数此前被忽略，日志框改用 `RichTextBox` 实现逐行着色
- fix(gui): 语言下拉框项本地化（中文界面显示 英文/中文）；`Pick-File` 初始目录跟随当前清单路径；修正停止应用提示中误用的全角小于号 `\uff1c` → `\uff1b`

### 文档
- docs: 版本同步至 v1.18.4（脚本头 `//Version` / `$ScriptVersion` / `.stignore` 头 / README 徽章 / docs）

## [v1.18.3] - 2026-09-21

### 新增（规则集）
- feat(stignore): 新增第 21 类「AI 编码助手与 Vibecoding 临时文件」，覆盖 20 个 AI 结对编程工具的数据/缓存目录（`.codex/` `.gemini/` `.qwen/` `.codeium/` `.continue/` `.cline/` `.roo/` `.kilocode/` `.cody/` `.trae/` `.junie/` `.supermaven/` `.opencode/` `.goose/` `.openhands/` `.augment/` `.tabnine/` `.qoder/` `.workbuddy/` `.amp/`），规则总数 310 → 330
- 仅忽略工具自有数据目录，不忽略 `CLAUDE.md` / `.cursorrules` / `AGENTS.md` / `GEMINI.md` 等项目指令文件

### 文档
- README / README_EN 分类概览新增第 21 类，徽章分类 20 → 21、规则数 310 → 330；版本同步至 v1.18.3

## [v1.18.2] - 2026-08-31

### 修复（GUI）
- fix(scan): 后台 job/timer 提升为脚本作用域（`$script:scanBg`/`scanHandle`/`scanTimer`）；点击开头清理上一次遗留任务，避免快速重击产生并行 runspace 池
- fix(scan): 取消分支 `$bg.Dispose()` 后置 handles 为 `$null`，完成判定加 `$null` 守卫，避免已释放对象被排队 tick 误调 `EndInvoke` 刷假错误
- fix(apply): 同上升级脚本作用域 + 清理 + 取消分支置 `$null` 守卫
- fix(apply): `finally` 仅恢复 UI，成功提示/清单刷新移入成功路径；job 抛错不再误报「Apply finished」（#6）
- fix(apply): `Get-FileHash` 包 `try/catch`，锁定/不可读文件计入 `errors` 并保留记录，不再终止整个 job（#5）
- fix(apply): 进度推送改为闭包直访问 `$progress`/`$lblPct`/`$lblStatus`，去除 `Controls.Find` 字符串查找（#3）
- fix(log): 移除 `Write-LogLine` 内 `DoEvents`，规避 `form.Invoke` 内的消息泵重入（#4）
- docs: 版本同步至 v1.18.2（脚本头 / `$ScriptVersion` / README 徽章与版本引用）

## [v1.18.1] - 2026-08-31

### 修复（GUI）
- fix(gui): 扫描/应用 Timer 的 `OnTick` 回调缺少顶层异常捕获，控件或后台任务句柄为 `$null` 时抛「不能对 Null 值表达式调用方法」并触发 JIT 调试弹窗
  - 为 `$btnScan` / `$btnApply` 两个 Timer tick 回调包裹 `try/catch`：捕获后写入日志（含 `$_.Exception.Message` 与 `$_.ScriptStackTrace`）、停止 Timer、调用 `Set-Busy $false` 恢复 UI，不再崩溃
  - `$bgHandle.IsCompleted` 判定加 `$null` 守卫
- docs: 版本同步至 v1.18.1（脚本头 / `$ScriptVersion` / README 徽章与版本引用）

## [v1.18.0] - 2026-08-31

### 新增（规则集）
- 补齐高频过滤缺口，新增 22 条规则（287 → 309），0 重复
- 编辑器/AI 工具：`.claude/`、`.windsurf/`、`.aider/`、`*.iml`、`.serverless/`
- Shell/REPL 历史：`.zsh_history`、`.bash_history`、`.sqlite_history`、`.node_repl_history`、`.python_history`
- 包管理器缓存：`.conda/`、`.spack/`、`.opam/`、`.stack-work/`、`.uv/`
- 测试/覆盖率缓存：`.cypress/`、`.playwright/`、`.allure/`
- 容器运行时：`.buildkit/`、`.podman/`、`.containerd/`

### 文档
- README / README_EN 分类概览同步新增项，徽章规则数 287 → 309；版本同步至 v1.18.0

---

## [v1.17.2] - 2026-08-31

### 新增（规则集）
- 新增 `**/logs/`、`**/log/` 日志目录忽略规则，归位至「Backup & Temporary Files」类；规则总数 285 → 287

### 重构（规则集）
- 原误置于「Database Files」类的 `logs/`、`log/` 移出，避免与数据库语义混淆

### 文档
- 版本同步至 v1.17.2：脚本头 `//Version`、`$ScriptVersion`、`.stignore` 头、README 徽章与版本引用

## [v1.17.1] - 2026-08-31

### 新增（GUI）
- 扫描时实时显示**当前正在遍历的目录**（此前只显示最新命中的 `.stignore` 文件路径）：状态行改为 `已完成根数/总数 | 已找到 N | 当前：<目录> | 耗时`，单根目录时省略根计数

### 重构（GUI）
- 扫描遍历由 `Get-ChildItem -Recurse -Filter` 改为显式栈深度优先 + `DirectoryInfo.EnumerateFileSystemInfos()`：管道无法上报当前位置，显式遍历才能把「当前目录」写入共享状态；一次枚举同时拿到文件与子目录，避免逐条额外 IO
- 无权限目录不再整体中断该根目录：改为跳过并累计 `ErrDirs`，扫描结束日志输出一行总数（不刷屏）；根目录不存在仍返回一条 `__error`

### 文档
- 版本同步至 v1.17.1：脚本头 `//Version`、`$ScriptVersion`、`.stignore` 头、README 徽章与版本引用

## [v1.17.0] - 2026-08-31

### 新增（GUI）
- 底部新增实时状态行：扫描/应用过程中显示「已完成根目录数 / 总数 · 已找到文件数 · 最新命中路径 · 耗时（mm:ss）」，路径过长自动截断
- 扫描结果边扫边出：命中即追加到结果列表，摘要同步显示「正在扫描... 当前已找到 N 个」
- 应用阶段实时显示「正在应用 N/M | 当前路径」

### 优化（GUI）
- 单一根目录（总量未知）时进度条改为滚动模式，不再显示 0%→100% 的假百分比；多根目录仍按根数显示真实百分比，此时状态行显示找到的文件数
- 进度驱动由后台 `form.Invoke` 回调改为共享状态 + UI Timer 拉取，去掉跨线程封送开销，并规避 Marquee 模式下赋值 Value 抛异常

### 修复（GUI）
- Apply 进度计数只在成功写入分支递增，跳过/一致/清理路径不计导致进度条偏慢 → 计数移到循环入口，每条有效路径均计入
- 版本同步至 v1.17.0：脚本头 `//Version`、`$ScriptVersion`、`.stignore` 头、README 徽章与版本引用

## [v1.16.0] - 2026-08-31

### 新增（规则集）
- 新增第 18 类「缓存与临时目录」：用 `(?i)` 前缀做**大小写不敏感**匹配，覆盖 `cache/`、`caches/`、`temp/`、`tmp/`、`.cache/`、`.tmp/`、`cachedata/`、`thumbnails/`、`thumbnail/`、`thumbs/` 等通用缓存/临时目录
- 新增第 19 类「浏览器与 Electron 存储缓存」：`CacheStorage/`、`Cache_Data/`、`CachedData/`、`CachedExtensions/`、`Code Cache/`、`GPUCache/`、`ShaderCache/`、`DawnCache/`、`D3DSCache/`、`INetCache/`、`Application Cache/`、`Local Storage/`、`Session Storage/`、`IndexedDB/`、`blob_storage/`、`Crashpad/`、`Crash Reports/`
- 新增第 20 类「系统临时与缓存位置」（根锚定）：`/tmp/`、`/var/tmp/`、`/var/cache/`、`/private/tmp/`、`/private/var/folders/`、`/Windows/Temp/`
- 补充开发缓存文件：`.eslintcache`、`.sass-cache/`、`.rollup.cache/`、`*.tsbuildinfo`

### 重构（规则集）
- 去重归位：把原先散落在「媒体与播放器缓存」类的 `.cache/`、`.thumbnails/`、`Cache/`、`Caches/`、`CacheStorage/`、`Code Cache/`、`GPUCache/`、`ShaderCache/`、`INetCache/` 统一移入新增的 18/19 类，消除 5 条重复规则
- 原 `**/Temp/`、`**/.tmp/` 由新类 `(?i)**/temp/`、`(?i)**/.tmp/`、`(?i)**/tmp/` 覆盖后删除，避免冗余

### 文档
- README / README_EN 分类列表同步为 20 类，徽章 17 → 20，规则数 258 → 285
- 新增两条提示：通用目录名（含 `cache/`、`temp/`、`tmp/`）可能误伤同名业务目录；`(?i)` 只匹配完整目录名不误伤 `MyCacheFolder/`、`Template/`
- 版本同步至 v1.16.0：脚本头、`$ScriptVersion`、`.stignore` 头、README 徽章与界面版本引用、`config.json`

## [v1.16.2] - 2026-08-31

### 文档
- 新增 `.github/` Community Health Files：`CONTRIBUTING.md`（架构红线、规则集编写约定、版本同步清单、PR 检查项）、`CODE_OF_CONDUCT.md`（Contributor Covenant v2.1 中文改编）、`SECURITY.md`（私有报告渠道与响应时限）、`SUPPORT.md`（文档索引 + 常见问题）
- 新增 `PULL_REQUEST_TEMPLATE.md` 与 `ISSUE_TEMPLATE/`（bug_report / rule-request / feature_request + `config.yml` 关闭空白 Issue 并指向 Discussions）
- README / README_EN 增补「参与贡献 / Contributing」入口，链接到上述文件
- 版本同步至 v1.16.2：脚本头 `//Version`、`$ScriptVersion`、`.stignore` 头、README 徽章与版本引用

## [v1.16.1] - 2026-08-31

### 文档
- 精简 README / README_EN：删除重复的界面布局图（mermaid + ASCII）与重复的「使用方式」段落，分类列表改为紧凑表格，合并快速开始与自定义建议
- 版本同步至 v1.16.1：脚本头 `//Version`、`$ScriptVersion`、`.stignore` 头、README 徽章与版本引用

## [v1.15.0] - 2026-08-31

### 修复（规则集）
- `/node_modules/**` 为根锚定，嵌套 `node_modules`（monorepo 子包）漏网 → 改 `**/node_modules/`
- `**/.vscode/*` 只匹配直接子项，`.vscode/extensions/**` 等深层文件仍同步 → 改 `**/.vscode/**`，`!` 行同步改为 `!**/.vscode/settings.json`
- `**/.swp` / `**/.swp` 类模式匹配不到 vim 真实交换文件（`.foo.swp`）→ 改 `**/*.swp` / `**/*.swo`，补充 `**/*.un~`
- `**/vendor/` 不匹配同步根级 `vendor/` → 并列 `/vendor/` 与 `**/vendor/`
- `**/*.db` 误伤 SQLite/KeePass 真实数据文件 → 移除，改保留 `*.db-wal` / `*.db-shm` / `*.db-journal` 临时文件
- `*.lock` 误伤 `Cargo.lock` → 收窄并反转保留 `Cargo.lock`、`package-lock.json`、`pnpm-lock.yaml`、`yarn.lock`、`composer.lock`、`poetry.lock`、`go.sum`、`flake.lock`
- 移除与注释自相矛盾的 `**.stfolder/` 与 `**.stversions`（忽略会破坏远端 folder marker 检测并静默禁用版本控制）
- 移除误伤面过宽的 `**Cache*`、`**Internet*`、`**download/`、`**downloads/`、`**log/`、`**logs/`、`**metadata/`、`**thumb/`、`**packages/`、`**Temp/`，改为具名缓存目录（`Code Cache/`、`GPUCache/`、`ShaderCache/`、`INetCache/` 等）
- `**Program Files/`、`**System Volume Information/` 改为根锚定，避免多级同名目录误伤
- 统一目录模式尾斜杠、文件模式 `**/*.ext` 前缀；去重 `**.cache` 与 `**/.cache/`、`**Cache*` 与 `/Cache/` 等冗余覆盖

### 新增（规则集）
- 新增第 17 个分类「构建产物与语言输出」：`target/`、`dist/`、`build/`、`bin/`、`obj/`、`out/`、`*.pyc`、`*.pyo`、`*.class`、`*.o`、`*.obj`、`*.pdb`、`*.ilk`、`*.dSYM/`
- 补充 `.svn/`、`.hg/`、`.scala-build/`、`.mvn/`、`cmake-build-*/`、`found.000/`、`ehthumbs.db`、`hiberfil.sys`、`.Trash-*/`、`nohup.out`、`*.log.*`
- 补充项目自身备份 `**/.stignore.bak.*`、`**/stignore-paths.json.bak.*`，避免 GUI 备份被同步

### 文档
- README / README_EN 分类列表同步新规则集，补齐第 17 项（此前徽章写 17 却只列 16 项）
- 修正 README 版本说明文案过时引用（v1.14.0 / 2026-08-07）与特性列表错位
- 版本同步至 v1.15.0：脚本头、`$ScriptVersion`、`.stignore` 头、README 徽章与界面版本引用、`config.json`

## [v1.14.1] - 2026-08-13

### 文档
- 统一分类数量描述：README/README_EN 徽章、特性列表、分类小节均修正为 17 个分类，与 `.stignore` 实际一致（原 16/12 表述错误）
- 补充 `.stignore` 头 `Updated` 日期与 CHANGELOG 发布日期差异说明，消除歧义
- 在 `openspec/project.md` 记录架构裁决：单一自包含脚本红线优先于全局「200 行拆分」规则

## [v1.14.0] - 2026-08-07

### 修复
- 修复 GUI 无法打开（致命）：PowerShell `-Command` 默认 MTA 线程，而 WinForms 要求 STA。脚本开头检测非 STA 时自动以 `powershell -STA -File` 重启自身（并透传退出码）；STA 重启块加异常兜底，失败时弹错误框而非静默退出。
- `EnableVisualStyles` 移至程序集加载后、控件创建前，确保视觉样式生效。
- 修复 `Apply-Language` 设 `SelectedIndex` 触发 `SelectedIndexChanged` 事件递归调用（加 `$script:applyingLang` 防重入标志），语言/主题切换事件均受保护。
- 给消息循环 `Application::Run` 外包全局异常兜底，未捕获异常弹出明细框而非静默闪退。
- 修复 `Apply-Theme` 对无 `BorderStyle` 属性的控件赋值导致的 `PropertyAssignmentException`；改为递归遍历所有控件（含嵌套容器）。
- 修复扫描/应用任务在独立 runspace 中通过 `form.Invoke` 进度回调引用 `$script:progress`/`$script:lblPct` 为 `$null` 引发的崩溃（改为按 `Name` 查找控件）。
- 深色模式视觉优化：输入控件改用自定义暗灰自绘边框（取代系统亮色 3D 边），按钮改为 Flat 风格 + 暗灰边框消除亮轮廓；清单输出路径框使用更醒目的中灰边框。
- 清单输出默认路径迁移至 `config/stignore-paths.json`，运行前确保 `config/` 目录存在；`.gitignore` 与文档同步更新。

## [v1.13.0] - 2026-08-07

### 修复
- 修复主题切换错位 bug：关闭窗体 `AutoScroll`（切换主题时重绘触发滚动条并把控件推出可视区）。
- 修复窗口滚动条问题：`AutoScroll` 改为 `false`，固定 720×640 布局，内容已全部收进范围内不再出现滚动条。
- `Apply-Theme` 末尾增加 `PerformLayout` + `Refresh`，确保主题切换重绘同步、消除残影/错位。

## [v1.12.0] - 2026-08-07

### 修复
- 修复 GUI 窗口溢出：重排所有控件坐标，使其全部收进窗体 640 高度内。
- 顶部语言/主题选择器同行对齐；按钮行统一 Y=212 并防右缘溢出。
- 结果列表/日志/进度条/状态栏 Y 坐标整体压缩，状态栏降至 Y=600，窗体 `MinimumSize` 调整为 640×560。

## [v1.11.0] - 2026-08-07

### 修复
- 取消竞态（扫描/应用）：点「停止」后强制中止后台 job，确保不再写入清单/文件。
- 版本栏本地化偏差：中文模式正确显示中文项目链接文案。
- 删除恒等死代码 `txtRoot` 赋值。
- 删除死代码 `Start-ScanJob`、`Update-Progress`。
- 完成/异常分支统一清零 `cancelFlag`，避免 Scan/Apply 间状态串扰。

## [v1.10.0] - 2026-08-06

### 新增
- 浅色/深色主题切换，并持久化到 `config.json`。
- 语言选择持久化到 `config.json`，下次启动自动恢复。
- 支持文件夹/`.stignore` 拖拽到窗口自动填充输入框。
- 结果显示 ListBox，双击可打开对应文件。
- 「停止」按钮，运行中可立即收回 UI 控制权。
- 「关于」按钮，显示版本与项目地址。

### 优化
- 进度条旁显示实时百分比文字。

### 修复
- 日志框自动滚动到底，始终可见最新行。

### 构建
- `config.json` 加入 `.gitignore`。

## [v1.9.0] - 2026-08-06

### 新增
- Apply 改为后台 runspace 执行，进度条显示真实百分比，消除界面卡顿。
- 扫描/应用后窗体显示文件数量摘要，启动自动加载现有清单。
- 非预览且非强制时 Apply 前弹出安全确认框，避免误写大量路径。
- 「清空日志」按钮。

### 修复
- 被替换目标恰为标准源 `.stignore` 自身时跳过备份，不生成无意义备份。

## [v1.8.0] - 2026-08-06

### 新增
- 备份轮转：`.stignore.bak.*` 与清单备份均最多保留 3 个，超出自动删除最旧。

## [v1.7.0] - 2026-08-06

### 修复
- 扫描改为后台 runspace + Timer 轮询，消除 GUI 线程阻塞导致的进度卡顿。

## [v1.6.0] - 2026-08-06

### 修复
- 语言切换下拉项混用真实中文导致乱码 → 改为纯 ASCII + `\u` 转义。

### 新增
- 底部状态栏显示版本号与可点击项目主页链接。

### 修复
- runspace 并行扫描改用内联脚本块，修复"无法识别 Find-StignoreFiles"错误。

## [v1.5.0] - 2026-08-06

### 性能
- runspace 线程池并行扫描 + `-Filter` 替代 `-Include`，扫描提速。

### 修复
- 统一日志函数为 `Write-LogLine`（修复旧调用未定义导致崩溃）。

## [v1.4.0] - 2026-08-06

### 新增
- 中英文界面切换（右上角下拉框，默认跟随系统区域）。

## [v1.3.0]

### 重构
- 合并命令行脚本为单一 GUI 工具，扫描/应用逻辑内联。

---

## 待办 / 已知限制
- [ ] 多驱动器并行度固定 4 线程，未根据驱动器数量自适应。
- [ ] 未做 git push 远程（需用户手动操作）。
- [ ] 无自动化测试（PowerShell GUI 测试成本高，暂以语法解析 + 最小复现验证）。
