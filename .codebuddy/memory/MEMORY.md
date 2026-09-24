# 长期记忆（MEMORY.md）

## 用户偏好
- 简体中文对话；输出精简，结论先行，表格/短列表优先。
- 大批量分批任务自动继续，无需每批确认。
- 模型/网络请求失败 → 等 30s 自动重试继续。
- 代码主要容器/区块加语义化 id（kebab-case）。

## 项目约定（SyncthingIgnorePatterns）
- 提交：`type: 描述`（首字母小写、动词开头、≤50字）。
- **版本三轨独立**：① Flutter 主轨（当前 **v1.26.0**，CI 单一来源 `VERSION`；同步 `VERSION`↔`pubspec.yaml`↔`app_state.dart`的`AppState.version`↔`manifest.dart`示例↔`README*`徽章/正文，共 6 处须全等）② PowerShell 遗留轨（`SyncthingIgnoreGUI.ps1` 头 `//Version`+`$ScriptVersion`，v1.18.5）③ `.stignore` 规则集轨（根与 `app/assets/.stignore` 一致，头 `//Version: 1.18.5`，`//Updated` 为修订日）。动版本前必 `cat VERSION`+`git log` 实查（会话间隙常被外部 bump）。
- **CI/CD**（`.github/workflows/ci.yml`，4 作业）：`version` 读根 `VERSION` 校验 `v*` 标签；`validate` 做 ps1 语法 + 规则副本一致性(不一致即 exit 1) + 三轨版本一致性(6 处正则全等)；`build-windows`(windows-latest) pub get / analyze(零告警) / test --coverage / build --release，覆盖率门禁 ≥80%；`release`(仅 `v*` 标签) 产 `SyncthingIgnoreGUI-v<版本>-windows-x64.zip`（版本取自 `needs.version.outputs.version`，禁硬编码）。
- **规则副本一致性（v1.23.1 起阻断）**：改规则集须同时改根 `.stignore` 与 `app/assets/.stignore`，否则 CI 失败。
- **CHANGELOG 双副本**：根 `CHANGELOG.md` + `docs/project.md` §7 同写。
- **许可**：根 `LICENSE`=MIT（`Copyright (c) 2019-2026 Sut`）。
- **多 agent 并发提交风险**：会话间隙会被他人 `git add -A` 扫入；临时脚本勿放仓库根；动版本/规则集前 `git show HEAD:<file>` 核对真值。
- **Dart isolate 闭包捕获陷阱**：`Isolate.run(f)` 序列化 `f` 及其捕获上下文；若 `f` 与捕获不可发送对象（`AppState`/`SettingsStore`/`_Future`）的闭包同作用域，Dart 共用 context→抛 `object is unsendable` 致真实运行中断。修复：闭包抽顶层函数仅捕获纯参数，回调只在主 isolate `.then` 调用。
- **偏好写入须串行化**（v1.22.0）：`SettingsStore.save` 用队列+`flush:true` 避免并发写竞态；`--coverage` 间歇红灯多查并发写/未 await 的 Future。
- **构建产物/品牌**：`<产品名>-v<语义版本>-<os>-<arch>.<zip|tar.gz>`（`env.APP_NAME=SyncthingIgnoreGUI`）；exe=`SyncthingIgnoreGUI.exe`（`windows/CMakeLists.txt` `BINARY_NAME`，勿改 pubspec `name: syncthing_ignore_gui`）。品牌资产 `tools/generate-brand-assets.ps1` 产 logo+PNG+ico，改色/几何同步 SVG+脚本+`BRAND.md`。
- **已实现功能（含复用坑）**：窗口几何记忆(v1.21.0 ffi `calloc` 是 Allocator 实例)、忽略清单在线更新(v1.22.0 `dart:io` 注入式下载器不触网)、应用确认+停止+实时状态行+双击打开(v1.23.0 `pendingApplyCount()` 同步读清单)、应用更新检查(v1.24.0 GitHub Releases API 仅提示无静默安装)、拖拽填入(v1.25.0 C++ `WM_DROPFILES`+MethodChannel `syncthing_ignore_gui/drop`，通道名须一致)+一键下载安装更新(v1.25.0 `update_installer.dart` PowerShell 助手，替换/重启须真实 Windows 验证)。
- **扫描支持局域网/映射盘（v1.26.0）**：`listFixedDrives`→`listScanDrives`（`platform_io.dart`）纳入 DRIVE_REMOTE 映射网络盘；新增 `normalizeRootPath`（`Z:`→`Z:\`、/→\）；UNC（`\\server\share`）可直接填根目录；`_resolveRoots` 改用 `FileSystemEntity.isDirectorySync` 校验（文件作根目录会被拒绝而非静默无结果）；i18n 标签/提示更新。扫描 UNC/映射盘依赖网络可达与权限，已断开的映射盘在 isolate 内被跳过不报错。
- **UI 选项不刷新坑**：可写通知态须走会 notify 的 setter（`setPreview`/`setForce`/`setBackup`），`root_field` 用 `TextEditingController`+监听 `AppState`。
- **扫描约定**：始终跳 `dirname(Platform.resolvedExecutable)`；`maxDepth`(默认3)/`skipLargeDirs`(默认true)/`maxFilesPerDir`(默认100) 大目录流式判定。
- **覆盖率基线**（v1.25.0）：`lib/` 85.60%（927/1083），`flutter test` 79/79；低覆盖 `results_list` 25%/`pickers_state` 38%/`window_bounds` 51%。须 `flutter test --coverage`（非 `test_with_coverage`）。
- **Dart+Flutter 重写**（v1.18.7 起 `flutter analyze` 零告警）：本机可离线 `pub get`/`analyze`/`test`；非 offline 的 pub get 失败，`build windows` 交 CI。`dart format` 新版对 >80 列重排勿全量套用。
- **任务文档约定**：`docs/development-tasks.md` 仅列未完成任务（已完成移除不归档），历史见 CHANGELOG+project.md §7；当前（v1.26.0）剩余任务为空，文档含「版本说明」与「后续方向（评估中）」指针（链接 spec.md 改进建议）。

## 环境约束
- 本机可 `powershell -File` 但 GUI 脚本不实跑；git 提交由用户本地执行。
- 本机 Flutter SDK 经 UAC `icacls` 修复，借 pub 缓存可离线 `pub get`/`analyze`/`test`；无外网，非 offline pub get 失败，`build windows` 交 CI。
