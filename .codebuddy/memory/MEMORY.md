# 长期记忆（MEMORY.md）

> 维护约定：仅保留跨会话可复用、高可信的事实与坑；失效/重复内容及时清理。
> 时效标签：✅ 已验证（代码/构建实证）｜🔶 历史（某版本结论，可能随重构失效）｜📌 约定（项目规则，长期有效）。

## 用户偏好
- 简体中文对话；输出精简、结论先行，表格/短列表优先。
- 大批量任务自动继续，无需每批确认。
- 模型/网络请求失败 → 等 30s 自动重试继续。
- 代码主要容器/区块加语义化 id（kebab-case）。
- 每次改动（代码/文档/配置）须 bump 最小版本号；仅被改文件头注释同步、禁止全仓库批量刷写（📌 约定）。

## 版本三轨（📌 约定）
- ① Flutter 主轨（CI 单一来源 `VERSION`，当前 **v1.32.4**）：`VERSION`↔`pubspec.yaml version`↔`app_state.dart AppState.version`↔`manifest.dart` 示例↔`README*` 徽章，6 处全等。
- ② PowerShell 遗留轨：`SyncthingIgnoreGUI.ps1` 头 `//Version`+`$ScriptVersion`，**v1.18.5**，仅修复性维护。
- ③ 规则集轨：根与 `app/assets/.stignore` 一致，头 `//Version: 1.18.5`，`Updated` 为修订日，独立演进。
- 动版本前必 `cat VERSION`+`git log` 实查（会话间隙常被外部 bump）。

## CI/CD（✅ 已验证，v1.32.1 起）
- 作业：`version`(读 VERSION 校验 v* 标签) / `validate`(ps1 语法 + 规则副本一致性[不一致 exit 1] + 三轨版本一致性[6 处正则] + 文档/CHANGELOG 当前版本引用检查) / `lint`(`flutter analyze` 零告警) / `test-unit`(`flutter test --coverage` + 行覆盖率 ≥80% 门禁) / `e2e`(`flutter test integration_test`) / `build`(暂存产物目录) / `commitlint`(仅 PR) / `release`(仅 v* 标签，附 SHA256 + SLSA 证明)。
- 版本均取自 `needs.version.outputs.version`，禁硬编码。
- 归档命名 `<产品名>-v<语义版本>-<os>-<arch>.<zip|tar.gz>`（`env.APP_NAME=SyncthingIgnoreGUI`），归档内以 `SyncthingIgnoreGUI/` 为顶层目录。

## 关键实现坑（✅ 已验证，除非标注🔶）
- **Dart isolate 闭包捕获**：`Isolate.run(f)` 序列化 `f` 与捕获上下文；同作用域捕获不可发送对象（`AppState`/`SettingsStore`/`_Future`）→ 抛 `object is unsendable`。修复：闭包抽顶层函数仅捕获纯参数（v1.25.2 真实扫描曾因此中断）。
- **全局错误边界勿 `return true`**（v1.28.2）：`PlatformDispatcher.onError` 返回 `true` 压制错误界面致「有进程无窗口」；须 `return false` 并兜底 `loadRulesetInfo`。
- **偏好写入串行化**（v1.22.0）：`SettingsStore.save` 队列+`flush:true`，避免并发写竞态（`--coverage` 间歇红灯多查未 await 的 Future）。
- **SliverList 内禁用 `context.select`**（v1.32.2）：`SliverList.builder` 的 `itemBuilder` 上下文是 `SliverWithKeepAliveWidget`，provider `context.select` 抛断言；选中态移入行组件自身 context 读取。
- **UI 可写通知态须走 setter**：`setPreview`/`setForce`/`setBackup`；`root_field` 用 `TextEditingController`+监听 `AppState`（v1.21.0 修复不刷新）。
- **mixin 顺序**：`app_state` 的 `with` 列表 `ScanOptionsState` 须排在 `PreferencesState on ChangeNotifier, ScanOptionsState` 之前，否则 mixin 约束报错。
- **backup_manager 是顶层函数非类**：导 `listForTargets`/`restore`/`deleteEntry`，勿写 `BackupManager.xxx`。
- **file_picker ^13.1.0 API**：无 `getDirectoryPaths`（仅 `getDirectoryPath` 单目录）；`saveFile` 的 `bytes` 必填（`bytes: Uint8List(0)`），返回 `Uri?`（用 `uri.toFilePath()`）。
- **规则副本一致性（v1.23.1 阻断）**：改规则集须同步根 `.stignore` 与 `app/assets/.stignore`，否则 CI 失败。
- **扫描约定**：始终跳 `dirname(Platform.resolvedExecutable)`；`maxDepth`(默认3)/`skipLargeDirs`(默认true)/`maxFilesPerDir`(默认100)。

## 已实现功能（✅，按批次）
- v1.21.0 窗口几何记忆（ffi `calloc`）。v1.22.0 忽略规则集在线更新（`dart:io` 注入式下载器不触网）。v1.23.0 应用确认+停止+实时状态行+双击打开（`pendingApplyCount()`）。v1.24.0 应用更新检查（GitHub Releases API，仅提示无静默安装）。v1.25.0 窗口拖拽填入（C++ `WM_DROPFILES`+MethodChannel `syncthing_ignore_gui/drop`）+ 一键下载安装更新（`update_installer.dart` PowerShell 助手）。v1.26.0 扫描支持映射网络盘/UNC（`listScanDrives`+`normalizeRootPath`+`isDirectorySync` 校验）。
- 增量增强：v1.29.0（PROP-9/6/12/10）｜v1.30.0（PROP-8/11/13）｜v1.31.0（PROP-4/5/7）｜v1.32.0（PROP-1/2/3）。PROP-1~13 全部实现；PROP-14~18 列入 Backlog（见 `docs/tasks.md`）。
- 性能/内存（v1.28.0）：共享 `HttpClient` 连接池、日志 1000/结果 5000 环形缓冲、`CustomScrollView`+Sliver 懒加载。

## 质量基线（✅ 实测，2026-10-01）
- `flutter analyze` 零告警；`flutter test` **90/90** 通过；行覆盖率 **81.69%**（1285/1573）满足 ≥80% 门禁。测试文件 **30 个**（28 单元 + 2 集成：`app/integration_test/`）。须 `flutter test --coverage`（非 `test_with_coverage`）。
- 规则集：**329 条规则 / 21 分类**（实算，v1.18.6 修正 off-by-one）。

## 文档约定（📌）
- `docs/tasks.md` 为任务唯一来源（Single Source of Truth）；`spec.md` 仅指针，不重复任务内容。
- `CHANGELOG.md` 双副本：根 `CHANGELOG.md` + `docs/project.md` §7 须同步。
- 文档/规范术语统一：「忽略规则集」=`.stignore`；「扫描清单」=`stignore-paths.json`。

## 环境约束（✅）
- 本机 Flutter SDK：`E:\Program Files\Flutter`（beta 3.40 / Dart 3.11）；可离线 `pub get`/`analyze`/`test`，`build windows` 交 CI。
- **勿并行跑 `flutter analyze` 与 `flutter test`**：争抢启动锁致 `flutter test` 大量假阴性（曾 19 异步用例误判失败），须分开跑。
- 本机可 `powershell -File` 但 GUI 脚本不实跑；git 提交由用户本地执行。
- 工作树会话间隙常被外部改写，编辑前重新读取，避免 `replace_in_file` old_str 不符写坏文件。
- 多 agent 并发提交风险：临时脚本勿放仓库根；动版本/规则集前 `git show HEAD:<file>` 核对真值。
