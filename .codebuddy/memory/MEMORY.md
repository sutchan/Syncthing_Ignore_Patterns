# 长期记忆（MEMORY.md）

## 用户偏好
- 对话必须始终使用简体中文，不因任务类型/上下文语言（英文文件、英文输入）而改变。
- 输出必须精简：结论先行，省略冗余解释，避免长篇铺陈与重复。能用表格/短列表就不写大段文字。
- 大批量分批任务（如全站 SEO、PO 翻译）自动继续分批，无需每批询问确认，直到全部完成。

## 项目约定（SyncthingIgnorePatterns）
- 提交信息遵循 Git 规范（type: 描述，首字母小写、动词开头、≤50字）。
- **版本三轨独立**（docs/project.md §4，v1.18.6 确立；文档/配置变更升 PATCH、新功能升 MINOR）：
  - ① **Flutter 主实现轨**（当前 v1.18.8）= 根 `VERSION` 文件（CI 单一来源）↔ `app/pubspec.yaml` `version:` ↔ `app/lib/state/app_state.dart` `AppState.version` ↔ `app/lib/models/manifest.dart` 示例值 ↔ `README.md`/`README_EN.md` 徽章与正文版本引用。**须彼此一致**。
  - ② **PowerShell 遗留轨**（当前 v1.18.5）= `SyncthingIgnoreGUI.ps1` 头 `//Version` 与 `$ScriptVersion`，**独立演进**。
  - ③ **`.stignore` 规则集轨**（当前 v1.18.5）= 根 `.stignore` 与 `app/assets/.stignore` 头 `//Version` **须内部一致**，`//Updated` 为修订日。改规则集必须同步打包副本。
  - 跨轨版本不同步属正常（如 Flutter 1.18.8 vs 遗留/规则集 1.18.5）。
- **CI/CD**（`.github/workflows/ci.yml`，4 作业）：`version`（读根 `VERSION`，校验 `v*` 标签 == VERSION）/`validate`（ps1 语法 `Parser::ParseFile` + `.stignore` 规则集 + **规则副本漂移报告** + **三轨版本一致性**）/`build-windows`（windows-latest：flutter pub get / analyze / test --coverage / build windows --release；上传 LCOV 并输出覆盖率摘要）/`release`（仅 `v*` 标签；softprops/action-gh-release，发布说明取自 `CHANGELOG.md` 对应小节 `body_path`）。触发：push main/dev + tags `v*`、PR main/dev、手动 `workflow_dispatch`；顶层最小权限 `contents: read`（release 作业提权 `contents: write`）；各作业 `timeout-minutes`；`concurrency` 对标签运行不取消。`env.APP_NAME=SyncthingIgnoreGUI`；产物 `SyncthingIgnoreGUI-v<版本>-windows-x64.zip`（版本取自根 `VERSION`）。注意 `flutter analyze` 对 error/warning/info 任一即 exit 1，须全部清零（v1.18.7 已修 52 项）。
- **CI 依赖更新**：`.github/dependabot.yml` 每周检查 `github-actions` 与 `pub`（目录 `/app`）依赖；README/README_EN 已加 CI 徽章（仓库 `github.com/sutchan/Syncthing_Ignore_Patterns`）。
- **已知规则副本身份漂移（待裁决）**：根 `.stignore` 与 `app/assets/.stignore` 内容不一致——`13e0d94` 从根删除 7 条 AI 工具规则（`**/.codex/` `**/.gemini/` `**/.qwen/` `**/.trae/` `**/.opencode/` `**/.qoder/` `**/.workbuddy/`），副本仍保留；两文件 `//Version` 均为 1.18.5。CI 漂移步骤当前**仅告警不阻断**，待用户决定同步方向后再改为阻断。
- **多 agent 并发提交风险**：本仓库会话间隙会被其他会话/agent（作者 Sut）提交，未提交改动会被其 `git add -A` 扫入他人提交（本会话临时文件 `__check_ver_tmp.ps1`、`app/_pubget.log` 曾被误提交）。故：临时脚本勿放仓库根；动版本/规则集前必先 `git show HEAD:<file>` 核对已提交真值（勿凭本会话记忆）；`.gitignore` 已加 `_pubget.log`、`__*_tmp.ps1`、`_elevate.ps1`。
- CHANGELOG 双副本：根 `CHANGELOG.md` 与 `docs/project.md` §7 必须同时写，历史上多次只写一处（v1.16.0 曾漏根 CHANGELOG）。
- **文档目录**：规范文档原存于 `openspec/`，已于 v1.18.5 迁移至 `docs/`（`docs/project.md` + `docs/specs/stignore-gui/spec.md`）。后续引用一律用 `docs/`。
- **Dart+Flutter 重写（主实现，v1.18.7 起 `flutter analyze` 零告警）**：`SyncthingIgnoreGUI.ps1` 正重构为 `app/` 下 Flutter Windows 桌面应用，构建为独立 `.exe`；纯逻辑拆为 `lib/services/*` + `lib/state/app_state.dart` 等可单测模块；规则集作为 `app/assets/.stignore` 资源打包；依赖含 `ffi`（`toNativeUtf16`）。详见 `docs/project.md` §9。本机无外网 + Flutter SDK 树只读，pub get/analyze/build 须在 CI 执行。
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
- **本机 Flutter 不可用**：SDK 树 `E:\Program Files\Flutter` 对当前用户只读，`flutter pub get` 无法重建 tool snapshot 而失败；且无外网。故 Flutter analyze/test/build 一律在 GitHub Actions（windows-latest）验证；纯文本校验（三轨版本一致性、`dart format --output=none` 语法解析）本地可跑。
