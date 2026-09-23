# 长期记忆（MEMORY.md）

## 用户偏好
- 始终简体中文对话；输出精简，结论先行，表格/短列表优先，避免冗余铺垫。
- 大批量分批任务（SEO/翻译等）自动继续，无需每批确认。
- 模型/网络请求失败 → 等 30s 自动重试继续，不中断。
- 代码容器/区块加语义化 id（kebab-case）便于调试/测试/无障碍。

## 项目约定（SyncthingIgnorePatterns）
- 提交遵循 Git 规范：`type: 描述`（首字母小写、动词开头、≤50字）。
- **版本三轨独立**（docs/project.md §4）：
  - ① Flutter 主轨（当前 **v1.25.1**，CI 单一来源 `VERSION`）= `VERSION` ↔ `app/pubspec.yaml` ↔ `app/lib/state/app_state.dart` `AppState.version` ↔ `app/lib/models/manifest.dart` 示例 ↔ `README*` 徽章/正文。动版本前必 `cat VERSION`+`git log` 实查。
  - ② PowerShell 遗留轨（v1.18.5）= `SyncthingIgnoreGUI.ps1` 头 `//Version`+`$ScriptVersion`，独立演进。
  - ③ `.stignore` 规则集轨（v1.18.5，头 `//Version: 1.18.5`）= 根与 `app/assets/.stignore` 须内部一致，`//Updated` 为修订日。跨轨不同步属正常。
- **CI/CD**（`.github/workflows/ci.yml`，4 作业，ubuntu `release` 用 `shell: pwsh` 有 .NET8）：
  - `version`：读根 `VERSION`，校验 `v*` 标签==VERSION。
  - `validate`：ps1 语法 `Parser::ParseFile` + `.stignore` 规则集 + **规则副本一致性（不一致即 `exit 1`）** + **三轨版本一致性**（Flutter 轨固定 6 处正则须全等）。
  - `build-windows`（windows-latest）：pub get / analyze（error/warning/info 任一即 exit 1，须清零）/ test --coverage / build windows --release（`--tree-shake-icons`）；上传 LCOV 并执行**覆盖率门禁**（`Coverage check (>= 80% lines)`，<80% 即 exit 1）。
  - `release`（仅 `v*` 标签）：softprops/action-gh-release，说明取自 `CHANGELOG.md` 对应小节。
  - 产物：CI 不再产 zip（v1.20.4 起 `build-windows` 上传 `app/build/package` **目录**），归档仅在 `release` 的 `Package release archive` 用 .NET `SmallestSize` 压缩一次（避 zip 套 zip），剔除 `*.pdb/*.exp/*.lib`；命名 `SyncthingIgnoreGUI-v<版本>-windows-x64.zip`，版本取自 `needs.version.outputs.version`（禁硬编码）。
- **规则副本一致性（v1.23.1 起 CI 阻断）**：根 `.stignore` 与 `app/assets/.stignore` 当前完全一致（397 行、`//Version: 1.18.5`，`//Updated: 2026-09-22`）；CI `validate` 的「Ruleset copy consistency」步骤已由「仅告警」改为**不一致即 `exit 1`**。改规则集必须同时改两处（或复制根文件覆盖副本），否则 CI 直接失败。
- **许可**：仓库根 `LICENSE` = MIT（`Copyright (c) 2019-2026 Sut`），README / README_EN 的许可段落互链该文件。
- **多 agent 并发提交风险**：会话间隙会被他人 `git add -A` 扫入提交；临时脚本勿放仓库根；动版本/规则集前 `git show HEAD:<file>` 核对真值。`.gitignore` 已加 `_pubget.log`/`__*_tmp.ps1`/`_elevate.ps1`。
- **CHANGELOG 双副本**：根 `CHANGELOG.md` + `docs/project.md` §7 必须同写。
- **构建产物命名规范**（`docs/project.md` §9.5）：`<产品名>-v<语义版本>-<os>-<arch>.<扩展名>`，`env.APP_NAME=SyncthingIgnoreGUI`，Windows/macOS=zip、Linux=tar.gz；预发布用 Release `prerelease` 标记区分（文件名不加后缀）。产物内 exe 名为 `SyncthingIgnoreGUI.exe`（`windows/CMakeLists.txt` 的 `BINARY_NAME`，v1.24.0 起与产品名一致；`Runner.rc` 的 `FileDescription`/`InternalName`/`OriginalFilename`/`ProductName` 与 `main.cpp` 窗口标题同步，`CompanyName`/`LegalCopyright` 由 `com.example` 占位更正为 `Sut`）。注意 pubspec `name: syncthing_ignore_gui` 是 Dart 包名（`package:` 导入用），**不要改**。
- **品牌资产**（v1.21.1，`tools/generate-brand-assets.ps1`，纯 .NET `System.Drawing` 离线可跑）：产 `docs/assets/logo.svg`+PNG+`BRAND.md` 与 `app/windows/runner/resources/app_icon.ico`（16/24/32/48/64/128/256 七帧 PNG 载荷）。标志=teal 垂直渐变圆角底板 `#22C6B4→#08665C`+白色同步环（两 130° 弧，缺口 135°/315°）+粗斜杠穿缺口；`<32px` 简化整环。改色/几何须同步 SVG+脚本+BRAND.md 三处。坑：PS5.1 `param()` 阶段 `$PSScriptRoot` 空须主体解析；`LinearGradientBrush` 渐变矩形须与填充区一致；函数返 `byte[]` 会被 pipeline 拆 `Object[]`，写前 `[byte[]](...)` 强转。
- **用户偏好持久化**（v1.19.0）：语言/主题存 `%APPDATA%\SyncthingIgnoreGUI\settings.json`（`settings_store.dart` 纯 `dart:io` JSON，刻意不用 shared_preferences）；`main.dart` `runApp` 前 `await` 加载。`_SettingsDialog`（齿轮按钮）收敛语言+主题 UI；改这两处须同步 `widget_test.dart` 语言切换用例。
- **窗口几何记忆**（v1.21.0，无新依赖）：`models/window_bounds.dart`+`services/window_bounds.dart`（win32 `FindWindow('FLUTTER_RUNNER_WIN32_WINDOW')`→`GetWindowRect`/`SetWindowPos`），写入 `settings.json.window`，启动恢复+每 2s 采样。坑：`ffi` 2.x `calloc` 是 `Allocator` 实例 → `calloc.allocate<RECT>(sizeOf<RECT>())`/`calloc.free(p)`。
- **偏好写入须串行化**（v1.22.0 修）：`SettingsStore.save` 原裸 `unawaited` 致并发写竞态（较旧快照最后落盘/半截 JSON）→ 改写队列+`flush:true`，新增回归用例。排查启示：`--coverage` 间歇红灯多为调度/时间敏感竞态，优先查并发写/未 await 的 Future。
- **忽略清单在线更新**（v1.22.0）：清单版本来自 `.stignore` 头 `//Version`，与应用版本独立。来源优先级 exe 同目录→APPDATA→内置资源；更新优先写回 exe 同目录。仓库 raw `https://raw.githubusercontent.com/sutchan/Syncthing_Ignore_Patterns/main/.stignore`（main 分支）。模块 `models/ruleset_info.dart`+`services/{app_paths,ruleset_store,ruleset_update}.dart`+`state/ruleset_state.dart`+`ui/ruleset_card.dart`；`dart:io HttpClient`（15s/5MiB，无新依赖）；下载器经 `AppState(rulesetStore:/rulesetFetcher:/rulesetBundled:)` 注入，测试不触网。
- **应用安全与实时反馈**（v1.23.0，对齐 PS 版）：`services/applier.dart` 的 `applyRules` 新增 `isCancelled` 回调（`ApplyResult.cancelled`），支持应用阶段「停止」；`ui/action_row.dart` 非预览非强制时 Apply 先弹确认框（`state/apply_flow.dart` `pendingApplyCount()` **同步**读清单，避免 async gap 令对话框在测试中不弹）；`services/scanner.dart` 的 `scanRoots` 新增 `onProgress` → `scan_flow._reportScanProgress` 刷新实时状态行；`ui/results_list.dart` 改用 `InkWell`（`ListTile` **无 `onDoubleTap`**）单击定位目录/双击默认程序打开；`main.dart` 启动 `loadExistingManifest()` 回填清单并日志提示条数。测试 **34/34**。
- **应用更新检查**（v1.24.0）：`services/app_update.dart`（GitHub Releases API `https://api.github.com/repos/sutchan/Syncthing_Ignore_Patterns/releases/latest`，取 `tag_name` 去 `v`；`dart:io HttpClient` 15s/1MiB，**无新依赖**；`latestTagFromReleaseJson` 纯解析可单测）+ `state/app_update_state.dart`（`checkAppUpdate()` 用 `compareRulesetVersions` 与 `AppState.version` 比对）+ `ui/about_dialog.dart`（自 `home_page.dart` 抽出的 `AppAboutDialog`：「检查应用更新」按钮 + 「打开下载页」）。**仅检查与提示，无静默安装**；下载器经 `AppState(releaseFetcher:)` 注入，测试不触网。
- **拖拽填入**（v1.25.0）：Windows runner 用 `DragAcceptFiles` + `WM_DROPFILES`（`windows/runner/CMakeLists.txt` 链接 `shell32.lib`）把拖入路径经 MethodChannel `syncthing_ignore_gui/drop` 转发给 Dart；`services/file_drop.dart` 的 `classifyDrop`（文件夹→扫描根 / `.stignore`·`.json`→清单 / 其余忽略）+ `state/pickers_state.dart` 的 `applyDrop`/`listenForFileDrops`（`main.dart` 启动注册）。**通道名须与 `flutter_window.cpp` 的 `kDropChannelName` 一致**。C++ 无法本机编译，仅 CI 编译 + 单测（`file_drop_test`）覆盖。
- **一键下载并安装更新**（v1.25.0）：`services/update_installer.dart` —— 校验应用目录可写 → 下载 Release zip（zip 魔数 `PK\x03\x04`、200 MiB 上限）→ 生成 PowerShell 助手脚本（等本进程退出 ≤120 s → `Expand-Archive` 覆盖应用目录 → `Start-Process` 重启 → 自删，日志写应用目录 `update.log`）→ `exit(0)`。`UpdateInstaller` 的 staging/downloader/launcher/exitApp/executablePath 均可注入（可单测）。**替换与重启无法本机验证**，需真实 Windows 确认。
- **任务文档约定（用户要求）**：`docs/development-tasks.md` 只列**未完成**任务；已完成任务从清单中**移除**（不再保留「已完成项」归档），历史由 `CHANGELOG.md` + `docs/project.md` §7 承载。当前（v1.25.1）剩余任务为空，仅保留「验证边界（非待办）」与「版本说明」。`docs/project.md` §8 已更名「任务与已知限制」。
- **覆盖率基线**（v1.25.0）：`lib/` 行覆盖率 **85.60%**（927/1083）；CI `build-windows` 已设 **≥80% 门禁**。测试文件 17 个、`flutter test` **79/79**。低覆盖：`ui/results_list.dart` 25%、`state/pickers_state.dart` 38%、`services/window_bounds.dart` 51%、`state/preferences_state.dart` 68%、`ui/ruleset_card.dart` 73%。
- **覆盖率工具坑**：`dart-collect-coverage` 的 `test_with_coverage` 对 Flutter 包不可用（跑 `dart run test`），须 `flutter test --coverage`。其 lcov **含每文件 `LF:`/`LH:` 汇总行**（32 个文件段），CI 直接累加 LF/LH 得总覆盖率（亦可按 `DA:行号,命中` 统计）；`SF:` 为反斜杠相对路径。
- **扫描/替换跳过应用自身目录**（v1.19.1）：`scanner.dart` 始终跳 `p.dirname(Platform.resolvedExecutable)`+`applier.dart` `skipRoots` 兜底（`skippedAppDir` 静默跳过）；改这两处须同步 `scanner_test`/`applier_test`。
- **扫描深度+大目录过滤**（v1.20.0）：`findStignoreFilesRaw` 改 `async`，增 `maxDepth`(默认3)/`skipLargeDirs`(默认true)/`maxFilesPerDir`(默认100)，大目录流式 `list().take(threshold+1).length` 提前判定；`home_page` `_ScanOptions` 提供 UI。测试须 `await`。
- **v1.21.0 结构**（≤200 行）：`app_state.dart` 拆 7 个 mixin（`on <多 mixin>` 互访；`version`/`appDirectory` 加 `@override`），`home_page.dart` 拆 7 个 `ui/` 子组件，主要容器/控件带语义化 `Key`。**选项不刷新坑**：UI 可写通知态须走会 notify 的 setter（`setPreview`/`setForce`/`setBackup`），`root_field` 改 `TextEditingController`+监听 `AppState`。
- **Dart+Flutter 重写**（主实现，v1.18.7 起 `flutter analyze` 零告警）；本机可 `flutter pub get --offline`/`analyze`/`test` 离线验证，但**非 offline 的 pub get 会失败**，`flutter build windows` 交 CI。`dart format` 新版对 >80 列重排，勿全量套用。
- **依赖升级破坏性**（v1.18.10）：`file_picker 13.1.0` 的 `saveFile` 改写字节返 `Uri?`（用占位空字节+`uri.toFilePath()`）；`win32 6.4.0` `GetLogicalDrives()` 返 `Win32Result<int>`（取 `.value`）、`GetDriveType()` 参数须 `PCWSTR(ptr)` 包装。`Uint8List` 取自 `package:flutter/foundation.dart`。
- 中文存储用纯 ASCII+`\u` 转义；GUI 字典 en/zh 分离。

## 环境约束
- 本机可 `powershell -File`，但 GUI 脚本不实跑（弹窗）；git 提交由用户本地执行。
- 本机 Flutter SDK 经 UAC `icacls` 修复写权限，借 pub 缓存可离线 `pub get`/`analyze`/`test`；无外网，非 offline 的 pub get 失败；`flutter build windows` 交 CI。
