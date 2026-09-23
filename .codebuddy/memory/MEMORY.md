# 长期记忆（MEMORY.md）

## 用户偏好
- 对话必须始终使用简体中文，不因任务类型/上下文语言（英文文件、英文输入）而改变。
- 输出必须精简：结论先行，省略冗余解释，避免长篇铺陈与重复。能用表格/短列表就不写大段文字。
- 大批量分批任务（如全站 SEO、PO 翻译）自动继续分批，无需每批询问确认，直到全部完成。
- （用户重申）保持中文对话、精简输出——见上两条。
- 模型请求（工具调用/网络请求）失败后，等待 30 秒自动重试并继续，不中断任务、不卡死。
- 代码里所有容器（UI 主区域、卡片、区块根节点等）加语义化 id（kebab-case），便于调试/测试/无障碍。

## 项目约定（SyncthingIgnorePatterns）
- 提交信息遵循 Git 规范（type: 描述，首字母小写、动词开头、≤50字）。
- **版本三轨独立**（docs/project.md §4，v1.18.6 确立；文档/配置变更升 PATCH、新功能升 MINOR）：
  - ① **Flutter 主实现轨**（当前 v1.20.1，随开发快速演进，动版本前务必 `cat VERSION` + `git log` 实查，勿凭记忆）= 根 `VERSION` 文件（CI 单一来源）↔ `app/pubspec.yaml` `version:` ↔ `app/lib/state/app_state.dart` `AppState.version` ↔ `app/lib/models/manifest.dart` 示例值 ↔ `README.md`/`README_EN.md` 徽章与正文版本引用。**须彼此一致**。
  - ② **PowerShell 遗留轨**（当前 v1.18.5）= `SyncthingIgnoreGUI.ps1` 头 `//Version` 与 `$ScriptVersion`，**独立演进**。
  - ③ **`.stignore` 规则集轨**（当前 v1.18.5）= 根 `.stignore` 与 `app/assets/.stignore` 头 `//Version` **须内部一致**，`//Updated` 为修订日。改规则集必须同步打包副本。
  - 跨轨版本不同步属正常（如 Flutter 1.18.10 vs 遗留/规则集 1.18.5）。
- **CI/CD**（`.github/workflows/ci.yml`，4 作业）：`version`（读根 `VERSION`，校验 `v*` 标签 == VERSION）/`validate`（ps1 语法 `Parser::ParseFile` + `.stignore` 规则集 + **规则副本漂移报告** + **三轨版本一致性**）/`build-windows`（windows-latest：flutter pub get / analyze / test --coverage / build windows --release；上传 LCOV 并输出覆盖率摘要）/`release`（仅 `v*` 标签；softprops/action-gh-release，发布说明取自 `CHANGELOG.md` 对应小节 `body_path`）。触发：push main/dev + tags `v*`、PR main/dev、手动 `workflow_dispatch`；顶层最小权限 `contents: read`（release 作业提权 `contents: write`）；各作业 `timeout-minutes`；`concurrency` 对标签运行不取消。`env.APP_NAME=SyncthingIgnoreGUI`；产物 `SyncthingIgnoreGUI-v<版本>-windows-x64.zip`（版本取自根 `VERSION`）。注意 `flutter analyze` 对 error/warning/info 任一即 exit 1，须全部清零（v1.18.7 已修 52 项）。`validate` 的 Flutter 轨版本校验固定 6 处：`VERSION` + `app/pubspec.yaml`(`version:`)/`README.md`/`README_EN.md`(`version-v`)/`app/lib/state/app_state.dart`(`this.version = '...'`)/`app/lib/models/manifest.dart`(`"version": "..."`)，正则提取后须全部相等。
- **CI 依赖更新**：`.github/dependabot.yml` 每周检查 `github-actions` 与 `pub`（目录 `/app`）依赖；README/README_EN 已加 CI 徽章（仓库 `github.com/sutchan/Syncthing_Ignore_Patterns`）。
- **已知规则副本身份漂移（待裁决）**：根 `.stignore` 与 `app/assets/.stignore` 内容不一致——`13e0d94` 从根删除 7 条 AI 工具规则（`**/.codex/` `**/.gemini/` `**/.qwen/` `**/.trae/` `**/.opencode/` `**/.qoder/` `**/.workbuddy/`），副本仍保留；两文件 `//Version` 均为 1.18.5。CI 漂移步骤当前**仅告警不阻断**，待用户决定同步方向后再改为阻断。
- **多 agent 并发提交风险**：本仓库会话间隙会被其他会话/agent（作者 Sut）提交，未提交改动会被其 `git add -A` 扫入他人提交（本会话临时文件 `__check_ver_tmp.ps1`、`app/_pubget.log` 曾被误提交）。故：临时脚本勿放仓库根；动版本/规则集前必先 `git show HEAD:<file>` 核对已提交真值（勿凭本会话记忆）；`.gitignore` 已加 `_pubget.log`、`__*_tmp.ps1`、`_elevate.ps1`。
- **构建产物命名规范**（`docs/project.md` §9.5，v1.18.11 确立；与全局约定一致）：`<产品名>-v<语义版本>-<os>-<arch>.<扩展名>`。产品名取 workflow 常量 `env.APP_NAME`（PascalCase、无空格，当前 `SyncthingIgnoreGUI`）；版本取根 `VERSION` 经 `needs.version.outputs.version` 注入（**禁硬编码**）；`os` ∈ `windows|macos|linux`、`arch` ∈ `x64|arm64`；Windows/macOS 用 `zip`、Linux 用 `tar.gz`。Release **仅上传归档**（不上传构建目录树）；预发布以 Release `prerelease` 标记区分（`contains(needs.version.outputs.version, '-')`），**不在文件名加后缀**。Actions 产物名与归档名保持一致（`SyncthingIgnoreGUI-v<版本>-windows-x64`，upload/download 两处须同值）。当前归档示例 `SyncthingIgnoreGUI-v1.18.11-windows-x64.zip`。已知未统一：产物内 exe 名为 `syncthing_ignore_gui.exe`（源自 pubspec `name:`）。
- CHANGELOG 双副本：根 `CHANGELOG.md` 与 `docs/project.md` §7 必须同时写，历史上多次只写一处（v1.16.0 曾漏根 CHANGELOG）。
- **用户偏好持久化（v1.19.0 起）**：语言/主题存 `%APPDATA%\SyncthingIgnoreGUI\settings.json`（`app/lib/services/settings_store.dart`，纯 `dart:io` JSON，**刻意不用 `shared_preferences`**——不在本机 pub 缓存、离线无法验证）；`AppState.loadSettings()` 启动恢复，`setLanguage()`/`setTheme()` 变更即写盘（best-effort）；`main.dart` 在 `runApp` 前 `await` 加载以保证首帧即恢复。UI 侧重：语言/主题已从 AppBar 的语言下拉 + 主题按钮**收敛为单一齿轮按钮的 `_SettingsDialog`**，改动这两处 UI 时须同步 `app/test/widget_test.dart` 的语言切换用例（它通过点齿轮进入对话框）。
- **扫描/替换跳过应用自身目录（v1.19.1 起）**：`scanner.dart` 始终把 `p.dirname(Platform.resolvedExecutable)` 加入跳过集、`skipDir` 为「目录+全部子目录」整体跳过（`_isWithinOrEquals` 大小写不敏感）；`applier.dart` 的 `applyRules` 新增可选 `skipRoots` 兜底，命中即静默跳过（`skippedAppDir`，不写不备份）。`app_state.scan()`/`apply()` 分别注入 `appDirectory` getter。`app_state.apply()` 的 `sourcePath` 仅作 SHA 比对占位（指向 `manifestPath`），真正的规则源由 rootBundle 加载、靠 exe 目录跳过保护。改这两处服务时须同步 `app/test/scanner_test.dart`/`applier_test.dart`。
- **扫描深度 + 大目录过滤（v1.20.0 起）**：`scanner.dart` 的 `findStignoreFilesRaw` 现为 `async`，参数 `maxDepth`(默认3, 根=1级)/`skipLargeDirs`(默认true)/`maxFilesPerDir`(默认100)；大目录用 `Directory(dir).list().take(threshold+1).length` 流式提前判定（避免巨目录卡死），不可读目录按「大」跳过。`app_state` 对应 `_maxDepth`/`_filterLargeDirs`/`_maxFilesPerDir`（**会话内、未持久化**），`scan()` 传参；`home_page` 的 `_ScanOptions` 卡片提供 UI（深度 Slider 1–10、阈值 Slider 10–1000）。`findStignoreFiles` 现返回 `Future`——测试中须 `await`。
- **文档目录**：规范文档原存于 `openspec/`，已于 v1.18.5 迁移至 `docs/`（`docs/project.md` + `docs/specs/stignore-gui/spec.md`）。后续引用一律用 `docs/`。
- **Dart+Flutter 重写（主实现，v1.18.7 起 `flutter analyze` 零告警）**：`SyncthingIgnoreGUI.ps1` 正重构为 `app/` 下 Flutter Windows 桌面应用，构建为独立 `.exe`；纯逻辑拆为 `lib/services/*` + `lib/state/app_state.dart` 等可单测模块；规则集作为 `app/assets/.stignore` 资源打包；依赖含 `ffi`（`toNativeUtf16`）。详见 `docs/project.md` §9。**本机可离线验证**（v1.18.10 实测）：`flutter pub get --offline`（用 pub 缓存）→ `flutter analyze`（0 问题）/ `flutter test`（7/7）均可本机跑；`flutter build windows` 交 CI。
- **依赖升级破坏性变更（v1.18.10 实测，升级 `file_picker`/`win32` 须同步改调用点）**：`file_picker 13.1.0` 的 `saveFile` 改为写入字节并返回 `Uri?`（新增必填 `bytes`，无 `getSavePath`）→ 用占位空字节 + `uri.toFilePath()`；`win32 6.4.0` 的 `GetLogicalDrives()` 返回 `Win32Result<int>`（取 `.value`）、`GetDriveType()` 参数为扩展类型 `PCWSTR`（须 `PCWSTR(ptr)` 包装 `Pointer<Utf16>`）。`Uint8List` 由 `package:flutter/foundation.dart` 提供，勿另加 `dart:typed_data`（否则 info 失败）。
- 中文存储用纯 ASCII + `\u` 转义，规避 GBK 乱码；GUI 字典 en/zh 分离。
- 后台任务用 runspace + Timer 轮询 `DoEvents`。
- **后台 runspace 必须自包含**（v1.18.4 实测结论，此前 Scan/Apply 因此完全不可用）：
  - `[powershell]::Create()` 新 runspace **看不到脚本作用域函数与变量**；`AddCommand('MyFunc')` 抛 `CommandNotFoundException`。须用 `InitialSessionState::CreateDefault()`（**不可用 `Create()`，它无 FileSystem 提供程序，`Get-Content` 读文件返回空**）+ `SessionStateFunctionEntry` 复制所需函数。
  - `[InitialSessionState]::CreateFromSessionState()` 在本机 PowerShell **不存在**；`SessionStateVariableEntry` 复制的变量**不绑定到复制函数的作用域**。因此作业所需变量（`$T`/`$lang` 等）须经「包装 scriptblock 用 `AddScript`+`AddArgument` 注入后再调用函数」。
  - `[powershell]::Create()` **无接收 Runspace 的重载**，只能传 `InitialSessionState`；释放用 `$ps.Runspace.Dispose()`。
- **`Control.Invoke` 闭包不可靠**：PowerShell 闭包经 `form.Invoke([Action]{...})` 执行时**无法捕获脚本变量**（改控件/属性均不生效）。UI 更新一律用「`Synchronized` 共享状态 + UI Timer 轮询」，禁止用 `form.Invoke` 回调传值。
- `ProgressBar` 在 `Style=Marquee` 时赋值 `Value` 会抛异常，切模式/赋值须先回 Blocks。
- **中文 `Lmsg` 格式化坑**：`(Decode-Uni $X -f $a)` 中 `-f` 会被解析为 `Decode-Uni` 的参数而非格式化运算符，导致显示未替换的字面量（如 `已找到 {0}`）。必须写 `((Decode-Uni $X) -f $a)`。
- 校验 `.ps1` 语法用临时脚本调 `[System.Management.Automation.Language.Parser]::ParseFile`；本机 shell 会吞 `$`，需写临时 `.ps1` 文件执行（勿用 `powershell -Command` 内联含 `$` 的代码）。
- 验证 GUI 脚本逻辑（不弹窗）的有效手段：用 AST `FindAll(FunctionDefinitionAst)` 抽取真实函数定义 `Invoke-Expression` 进测试会话，再在后台 runspace 端到端跑。

## 环境约束
- 本机可运行 `powershell -File`，但 GUI 脚本不实跑（会弹窗）；git 提交由用户本地执行。
- **本机 Flutter 现状（v1.18.10 复核，已推翻旧"不可用"结论）**：SDK 写权限问题已由 UAC `icacls` 修复；`flutter pub get --offline` 借 `C:\Users\Admin\AppData\Local\Pub\Cache` 缓存可离线解析依赖，`flutter analyze`（0 问题）与 `flutter test`（7/7）均可本机跑。仍无外网，故**非 `--offline` 的 pub get 会失败**；`flutter build windows` 交 CI。`dart format --output=none` 可做语法解析，但 Dart 3.11 新版 formatter 会对 >80 列既有行重排——勿全量套用，以免产生无关 diff。
