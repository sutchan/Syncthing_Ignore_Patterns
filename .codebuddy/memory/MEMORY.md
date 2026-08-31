# 长期记忆（MEMORY.md）

## 用户偏好
- 对话必须始终使用简体中文，不因任务类型/上下文语言（英文文件、英文输入）而改变。
- 输出必须精简：结论先行，省略冗余解释，避免长篇铺陈与重复。能用表格/短列表就不写大段文字。
- 大批量分批任务（如全站 SEO、PO 翻译）自动继续分批，无需每批询问确认，直到全部完成。

## 项目约定（SyncthingIgnorePatterns）
- 提交信息遵循 Git 规范（type: 描述，首字母小写、动词开头、≤50字）。
- 版本管理：构建默认升级 MINOR 版本，同步所有文件头/脚本变量/.stignore/README/openspec 版本号。同步清单（易漏）：`SyncthingIgnoreGUI.ps1` 头 `//Version` 与 `$ScriptVersion`、`.stignore` 头 `//Version`、两份 README 徽章+正文版本引用、openspec/project.md（目录结构注记 + 第 7 节）、CHANGELOG.md。
- CHANGELOG 双副本：根 `CHANGELOG.md` 与 `openspec/project.md` §7 必须同时写，历史上多次只写一处（v1.16.0 曾漏根 CHANGELOG）。
- 中文存储用纯 ASCII + `\u` 转义，规避 GBK 乱码；GUI 字典 en/zh 分离。
- 后台任务用 runspace + Timer 轮询 `DoEvents`；跨线程用 `form.Invoke` 更新控件。

## 环境约束
- 本机环境跳过 PowerShell / git 执行命令，改动需用户本地手动校验与提交。
