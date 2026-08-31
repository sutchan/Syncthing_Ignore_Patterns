<!-- SyncthingIgnorePatterns v1.16.2 -->

# 贡献指南

感谢你愿意为 SyncthingIgnorePatterns 做出贡献。本仓库由两部分组成，贡献前请先确认你要改动的是哪一部分：

| 组成部分 | 文件 | 说明 |
|---------|------|------|
| 规则集 | `.stignore` | 20 个分类、285 条 Syncthing 忽略模式 |
| GUI 工具 | `SyncthingIgnoreGUI.ps1` | WinForms 批量扫描/应用工具（单一自包含脚本） |
| 文档 | `README.md` / `README_EN.md` / `CHANGELOG.md` / `openspec/` | 中英双语文档与项目规范 |

---

## 一、架构红线（违反会被退回）

这三条是本项目最高优先级约束，优先级高于通用的编码习惯：

1. **纯 ASCII 脚本**：`SyncthingIgnoreGUI.ps1` 必须保持纯 ASCII。中文界面文案一律写成 `\uXXXX` 转义，运行时由 `Decode-Uni` 还原。
   *原因*：文件一旦被 GBK 重新编码，UTF-8 中文字节会被破坏，PowerShell 直接解析失败（历史已踩坑）。
2. **单一自包含脚本**：GUI 的扫描/应用逻辑全部内联，不允许拆分出外部 `.ps1` 依赖。此红线**优先于**通用的「单文件超 200 行即拆分」规则——`SyncthingIgnoreGUI.ps1` 作为发布交付物必须能单文件分发。
   *推论*：脚本内部仍应按职责分区并加清晰的段落注释，只是不拆文件。
3. **PowerShell 5.1（Windows PowerShell）**：不得使用 PowerShell 7 专有语法（如 `ForEach-Object -Parallel`）。并行请用 runspace 线程池（当前固定 4 线程）。

---

## 二、修改规则集 `.stignore`

### 编写约定

| 约定 | 说明 |
|------|------|
| 分类注释 | 写 `//CategoryName`（`//` 后**无空格**），自研校验脚本靠此识别分类标题 |
| 说明注释 | 写 `// NOTE: ...`（`//` 后**有空格**），不会被视为分类标题 |
| 目录模式 | 以 `/` 结尾，如 `**/node_modules/` |
| 文件模式 | 统一 `**/*.ext` 前缀，如 `**/*.swp`（不要写 `**/.swp`，匹配不到 vim 真实交换文件） |
| 取反规则 | `!` 取反为「后匹配优先」，取反行**必须紧跟**对应的正向行 |
| 嵌套与根级 | `**/vendor/` 未必匹配同步根级的 `vendor/`，需要时并列写 `/vendor/` 与 `**/vendor/` |

### 禁止事项（历史教训，勿回退）

- **不要忽略 `.stfolder/` 与 `.stversions`** —— 会破坏远端 folder marker 检测，并静默禁用版本控制。
- **不要写通配 `**/*.db`** —— 会误伤 SQLite / KeePass 真实数据文件；只忽略 `*.db-wal`、`*.db-shm`、`*.db-journal` 这类临时文件。
- **不要写 `*.lock` 而不加例外** —— 必须反转保留 `Cargo.lock`、`package-lock.json`、`pnpm-lock.yaml`、`yarn.lock`、`composer.lock`、`poetry.lock`、`go.sum`、`flake.lock`。
- **不要用宽泛前缀通配**（如 `**Cache*`、`**Temp/`、`**log/`）—— 曾造成大量误伤。需要大小写不敏感时用 `(?i)` + **完整目录名**，例如 `(?i)**/cache/`，这样 `MyCacheFolder/`、`Template/`、`Tempura/` 不会被命中。

### 提交前自检

```powershell
# 1) 统计有效规则条数（排除空行与注释）
(Get-Content .stignore | Where-Object { $_ -and -not $_.StartsWith('//') }).Count

# 2) 查完全重复行（应为空）
Get-Content .stignore | Where-Object { $_ -and -not $_.StartsWith('//') } | Group-Object | Where-Object Count -gt 1

# 3) 确认文件为纯 ASCII（非 ASCII 字符数应为 0）
[regex]::Matches((Get-Content .stignore -Raw), '[^\x00-\x7F]').Count
```

还请在 Syncthing Web 界面 → 文件夹 → **编辑** → **忽略模式** 的预览中实际验证：既能命中目标噪音文件，又**没有**命中需要同步的真实文件。

> 提交规则时请在描述里说明「解决了什么噪音」+「验证了哪些不会被误伤」。

---

## 三、修改 GUI 脚本 `SyncthingIgnoreGUI.ps1`

```powershell
# 语法检查（无输出即通过）
$errs = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path .\SyncthingIgnoreGUI.ps1), [ref]$null, [ref]$errs)
$errs

# 纯 ASCII 检查（应为 0）
[regex]::Matches((Get-Content .\SyncthingIgnoreGUI.ps1 -Raw), '[^\x00-\x7F]').Count

# 运行（脚本会自动检测并以 STA 线程重启自身）
.\SyncthingIgnoreGUI.ps1
```

注意事项：

- 新增界面文案必须**中英双份**，分别写入字典的 `en` / `zh` 两个分支，中文以 `\u` 转义内嵌。
- 跨线程更新控件一律走 `form.Invoke`；按 `Name` 查找控件，不要直接捕获控件变量（runspace 内可能为 null）。
- 后台任务用 runspace + Timer 轮询 `DoEvents` 保持 UI 响应；「停止」按钮必须能真正中止 job 并停止写入。
- 备份文件（`.stignore.bak.<时间戳>`、`stignore-paths.json.bak.<时间戳>`）保持**轮转 ≤3**。

---

## 四、文档与版本同步（必做）

每次改动都要升级一次最小版本号（patch），并同步以下**全部**位置：

- `SyncthingIgnoreGUI.ps1`：文件头 `//Version: x.y.z` 与变量 `$ScriptVersion`
- `.stignore`：文件头 `//Version: x.y.z`
- `README.md` / `README_EN.md`：版本徽章与正文中的版本引用（两份必须同时改）
- `openspec/project.md`：第 3 节目录结构注记 **与** 第 7 节 CHANGELOG
- `CHANGELOG.md`：新增对应版本小节（**根目录 `CHANGELOG.md` 与 `openspec/project.md` §7 是双副本，两处都要写**）

未改动的文件**不要**批量刷写头注释版本号。

---

## 五、提交与 PR

提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/) 风格：

```
feat: 新增浏览器缓存分类
fix: 修复嵌套 node_modules 漏网
docs: 同步 README 分类列表至 20 类
chore: 升级版本至 v1.16.2
```

PR 前请确认：

- [ ] 规则集改动已在 Syncthing 忽略模式预览中验证，且无新增误伤
- [ ] 脚本为纯 ASCII、无语法错误、GUI 实际启动通过
- [ ] 界面文案中英双份齐全
- [ ] 版本号已在上述全部位置同步
- [ ] `CHANGELOG.md` 与 `openspec/project.md` §7 均已追加条目
- [ ] 中文与英文 README 同步更新

---

## 六、行为准则

参与本项目即代表你同意遵守 [行为准则](CODE_OF_CONDUCT.md)。
