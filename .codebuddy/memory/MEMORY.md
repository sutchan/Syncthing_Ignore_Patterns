# 长期记忆（MEMORY.md）

## 用户偏好
- 对话必须始终使用简体中文，不因任务类型/上下文语言（英文文件、英文输入）而改变。
- 输出必须精简：结论先行，省略冗余解释，避免长篇铺陈与重复。能用表格/短列表就不写大段文字。
- 大批量分批任务（如全站 SEO、PO 翻译）自动继续分批，无需每批询问确认，直到全部完成。

## 项目约定（SyncthingIgnorePatterns）
- 提交信息遵循 Git 规范（type: 描述，首字母小写、动词开头、≤50字）。
- 版本管理：构建默认升级 MINOR 版本，同步所有文件头/脚本变量/.stignore/README/docs 版本号。同步清单（易漏）：`SyncthingIgnoreGUI.ps1` 头 `//Version` 与 `$ScriptVersion`、`.stignore` 头 `//Version`、两份 README 徽章+正文版本引用、docs/project.md（目录结构注记 + 第 7 节）、CHANGELOG.md。
- CHANGELOG 双副本：根 `CHANGELOG.md` 与 `docs/project.md` §7 必须同时写，历史上多次只写一处（v1.16.0 曾漏根 CHANGELOG）。
- **文档目录**：规范文档原存于 `openspec/`，已于 v1.18.5 迁移至 `docs/`（`docs/project.md` + `docs/specs/stignore-gui/spec.md`）。后续引用一律用 `docs/`。
- **Dart+Flutter 重写（进行中）**：`SyncthingIgnoreGUI.ps1` 正重构为 `app/` 下 Flutter Windows 桌面应用，构建为独立 `.exe`；纯逻辑拆为 `lib/services/*` + `lib/state/app_state.dart` 等可单测模块；规则集作为 `app/assets/.stignore` 资源打包。详见 `docs/project.md` §9。本机有 flutter/dart 但无外网，pub get/构建需在有网环境执行。
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
