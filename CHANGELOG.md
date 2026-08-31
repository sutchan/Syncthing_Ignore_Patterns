# 变更日志 (Changelog)

> 本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/) `MAJOR.MINOR.PATCH`，构建默认升级 `MINOR`。
> 版本号同步位置：脚本头 `//Version`、变量 `$ScriptVersion`、`.stignore` 头、`README.md` / `README_EN.md` 徽章与功能引用。

---

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

## [v1.16.0] - 2026-08-31

### 新增（规则集）
- 新增第 18 类「缓存与临时目录」：`(?i)` 大小写不敏感覆盖 `cache/`、`caches/`、`temp/`、`tmp/`、`.cache/`、`.tmp/`、`cachedata/`、`thumbnails/`、`thumbs/` 等
- 新增第 19 类「浏览器与 Electron 存储缓存」：`CacheStorage/`、`Code Cache/`、`GPUCache/`、`ShaderCache/`、`DawnCache/`、`INetCache/`、`Local Storage/`、`IndexedDB/`、`blob_storage/`、`Crashpad/` 等
- 新增第 20 类「系统临时与缓存位置」：根锚定 `/tmp/`、`/var/tmp/`、`/var/cache/`、`/private/var/folders/`、`/Windows/Temp/`
- 补充开发缓存文件 `.eslintcache`、`.sass-cache/`、`.rollup.cache/`、`*.tsbuildinfo`

### 重构（规则集）
- 散落在「媒体与播放器缓存」的 9 条 cache 规则归位至新类，消除 5 条重复；`Temp/` 与 `.tmp/` 由 `(?i)` 规则覆盖后删除

### 文档
- README / README_EN 分类列表同步 20 类，徽章 17→20、规则数 258→285；版本同步至 v1.16.0

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
