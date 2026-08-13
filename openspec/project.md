# Project Specification: SyncthingIgnorePatterns

> 标准化 `.stignore` 规则集 + 配套批量管理 GUI 工具的项目规范（OpenSpec 风格）。

## 1. 项目背景

Syncthing 同步文件夹时默认包含大量系统文件、缓存、构建产物与应用数据，
造成带宽与存储浪费。本项目提供：

1. **规则集** `.stignore` — 开箱即用的 17 类忽略模式（系统/OS 文件、数据库、
   备份临时文件、应用缓存、版本控制、包管理器、前端/Python/C++/JVM 构建缓存、
   IDE/编辑器、归档与部分下载、虚拟化、媒体、锁与日志等噪音）。
2. **批量管理 GUI** `SyncthingIgnoreGUI.ps1` — WinForms 图形界面，将标准规则
   批量应用到本机所有 Syncthing 同步目录，无需每次全盘扫描。

## 2. 关键约束（架构红线）

- **纯 ASCII 文件**：所有 `.ps1` 脚本必须保持纯 ASCII。中文界面文案一律以
  `\uXXXX` 转义存储，运行时由 `Decode-Uni` 还原。原因：文件被 GBK 编码
  重编码会破坏 UTF-8 中文字节，导致 PowerShell 解析失败（历史已踩坑）。
- **单一自包含脚本**：GUI 工具的扫描/应用逻辑全部内联，无外部脚本依赖。
  此架构红线优先于通用「单文件超 200 行即拆分」规则——`SyncthingIgnoreGUI.ps1`
  作为发布交付物须保持单文件自包含，不因行数拆分（见 CHANGELOG v0.1.0 设计决策）。
- **PowerShell 5.1（Windows PowerShell）** 目标运行时；不依赖 PowerShell 7
  专有语法（如 `ForEach-Object -Parallel`）。并行改用 runspace 线程池实现。

## 3. 目录结构

```
SyncthingIgnorePatterns/
├── .stignore                 # 标准规则源文件（Apply 依赖，版本 v1.14.0）
├── SyncthingIgnoreGUI.ps1    # 主工具（GUI + 扫描/应用逻辑，纯 ASCII）
├── README.md                 # 中文文档
├── README_EN.md              # 英文文档
├── CHANGELOG.md              # 独立变更日志（Keep a Changelog 风格）
├── .gitignore                # 忽略运行时产物（config/stignore-paths.json / *.bak.*）
├── config/                   # 运行时配置与产物目录
│   ├── stignore-paths.json   # 扫描清单输出（运行时生成，已被 .gitignore 忽略）
│   └── *.bak.*               # 清单备份（轮转 ≤3，已被忽略）
├── openspec/                 # 本规范目录
│   ├── project.md
│   └── specs/stignore-gui/spec.md
└── SyncthingIgnorePatterns.code-workspace
```

## 4. 版本管理

- 语义化版本 `MAJOR.MINOR.PATCH`；构建默认升级 `MINOR`。
- 版本号同步位置（必须一致）：
  - `SyncthingIgnoreGUI.ps1` 文件头 `//Version: x.y.z`
  - `SyncthingIgnoreGUI.ps1` 变量 `$ScriptVersion = 'x.y.z'`
  - `.stignore` 文件头 `//Version: x.y.z`（规则集独立版本，随工具同步）
  - `README.md` / `README_EN.md` 版本徽章与界面功能版本号引用
- 每次版本变更需同步更新 CHANGELOG（根目录 `CHANGELOG.md`，与第 7 节内容一致）与 README 的"版本与项目地址"。

## 5. GUI 功能规格

| 功能 | 说明 |
|------|------|
| 语言切换 | 左上角下拉框 `English` / `中文`（与主题选择器同行），实时切换全部界面与日志文案，选择记忆到 `config.json`（v1.10.0，v1.12.0 改左上角同行对齐） |
| 主题切换 | 左上角下拉框 `浅色` / `深色`，即时换肤，选择同样持久化（v1.10.0）；深色模式下输入控件改为自定义暗灰自绘边框（取代系统亮色 3D 边），按钮改为 Flat 风格 + 暗灰边框消除亮轮廓，清单输出路径框用中灰边框（v1.13.0 / v1.14.0） |
| 扫描根目录 | 留空=扫描所有固定驱动器；或浏览选择指定目录；支持文件夹/`.stignore` 拖拽自动填充（v1.10.0） |
| 并行扫描 | runspace 线程池（最多 4 线程）+ `-Filter .stignore`，排除 `.git` 与脚本目录 |
| 后台防卡顿 | 扫描/应用均在后台 runspace 执行，Timer 轮询 `DoEvents` 保持 UI 响应，进度条显示真实百分比与数字（v1.7.0 / v1.9.0） |
| 结果列表 | 扫描/应用结果显示在专属 ListBox，双击可打开对应文件（v1.10.0） |
| 停止按钮 | 运行中点击「停止」强制中止后台 job，确保不再写入清单/文件（v1.10.0 / v1.11.0 真正中止） |
| 扫描摘要 | 窗体显示「已找到 N 个 .stignore 文件」；启动自动加载现有清单数量 |
| 安全确认 | 非预览且非强制时，Apply 前弹确认框，避免误写大量路径（v1.9.0） |
| 清空日志 | 日志框旁「清空日志」按钮，一键清空（v1.9.0） |
| 关于 | 「关于」按钮显示版本与项目地址（v1.10.0，v1.12.0 按钮行调整至左上区域） |
| 仅预览 | 勾选后不写文件，仅预览结果 |
| 强制 | 跳过逐文件确认直接执行 |
| 写回前备份 | 写回清单前备份原 `.stignore` 为 `.stignore.bak.<时间戳>` |
| 备份轮转 | 每种 `.bak.*` 最多保留 3 个，超出自动删最旧（v1.8.0） |
| 源文件豁免 | 被替换目标恰为标准源 `.stignore` 自身时跳过备份，不生成无意义备份（v1.9.0） |
| 版本/地址 | 底部状态栏显示版本号与可点击项目主页 |
| 实时日志 | 底部日志框输出全部执行信息（自动滚动到底） |

## 6. 扫描/应用工作流

1. 默认直接 **Scan** → 并行扫描所有根目录 → 生成 `stignore-paths.json`
   （记录 path / size / lastWriteUtc）。
2. 规则更新后，勾选 **强制** 点 **Apply** → 对每个历史路径用标准 `.stignore`
   替换（替换前自动备份）。规则一致的文件跳过，不重复备份。
3. 失效路径（源文件已删除）仅在勾选 **强制** 时从清单清理。

## 7. CHANGELOG

### v1.14.0 (2026-08-07)
- 修复 GUI 无法打开（致命）：PowerShell `-Command` 默认 MTA 线程，WinForms 要求 STA。脚本开头检测非 STA 时自动以 `powershell -STA -File` 重启自身（exit 透传退出码）；STA 重启块加异常兜底，失败弹错误框而非静默退出
- EnableVisualStyles 移至程序集加载后、控件创建前，确保视觉样式生效
- 修复 Apply-Language 设 SelectedIndex 触发 SelectedIndexChanged 事件递归调用（加 `$script:applyingLang` 防重入标志），语言/主题切换事件均受保护
- 消息循环 `Application::Run` 外包全局异常兜底，未捕获异常弹明细框而非闪退
- 修复 Apply-Theme 对无 BorderStyle 属性控件赋值崩溃；改为递归遍历所有控件
- 修复扫描/应用 runspace 中 `form.Invoke` 进度回调引用 `$script:progress`/`$script:lblPct` 为 null 崩溃（改为按 Name 查找控件）
- 深色模式视觉优化：输入控件自定义暗灰自绘边框，按钮 Flat 风格 + 暗灰边框，清单输出路径框中灰边框
- 清单默认路径迁移至 `config/stignore-paths.json`，运行前确保 config/ 目录存在

### v1.13.0 (2026-08-07)
- 修复主题切换错位 bug：关闭窗体 AutoScroll（原因切换主题时重绘触发滚动条并把控件推出可视区）
- 修复窗口滚动条问题：AutoScroll 改为 false，固定 720×640 布局，内容已全部收进范围内不再出现滚动条
- Apply-Theme 末尾增加 PerformLayout + Refresh 确保主题切换重绘同步、消除残影/错位

### v1.12.0 (2026-08-07)
- 修复 GUI 窗口溢出：重排所有控件坐标，使其全部收进窗体 640 高度内
- 顶部语言/主题选择器同行对齐；按钮行统一 Y=212 并防右缘溢出
- 结果列表/日志/进度条/状态栏 Y 坐标整体压缩，状态栏降至 Y=600，窗体 MinimumSize 调整为 640×560

### v1.11.0 (2026-08-07)
- 修复取消竞态：扫描/应用点击「停止」后强制中止后台 job，确保不再写入清单/文件（#3 #4）
- 修复版本栏本地化偏差，中文模式正确显示中文项目链接文案（#1）
- 删除恒等死代码 `txtRoot` 赋值（#2）
- 删除死代码 `Start-ScanJob`、`Update-Progress`（#5 #6）
- 完成/异常分支统一清零 `cancelFlag`，避免 Scan/Apply 间状态串扰（#9）

### v1.10.0 (2026-08-06)
- feat(gui): 新增浅色/深色主题切换，并持久化到 `config.json`
- feat(gui): 语言选择持久化到 `config.json`，下次启动自动恢复
- feat(gui): 支持文件夹/`.stignore` 拖拽到窗口自动填充输入框
- feat(gui): 新增结果显示 ListBox，双击可打开对应文件
- feat(gui): 新增「停止」按钮，运行中可立即收回 UI 控制权
- feat(gui): 新增「关于」按钮，显示版本与项目地址
- perf(gui): 进度条旁显示实时百分比文字
- fix(gui): 日志框自动滚动到底，始终可见最新行
- chore: `config.json` 加入 `.gitignore`

### v1.9.0 (2026-08-06)
- feat(gui): Apply 改为后台 runspace 执行，进度条显示真实百分比，消除界面卡顿
- feat(gui): 扫描/应用后窗体显示文件数量摘要，启动自动加载现有清单
- feat(gui): 非预览且非强制时 Apply 前弹出安全确认框，避免误写大量路径
- feat(gui): 新增「清空日志」按钮
- fix(gui): 被替换目标恰为标准源 `.stignore` 自身时跳过备份，不生成无意义备份

### v1.8.0 (2026-08-06)
- feat(gui): 备份轮转，`.stignore.bak.*` 与清单备份均最多保留 3 个，超出自动删除最旧

### v1.7.0 (2026-08-06)
- fix(gui): 扫描改为后台 runspace + Timer 轮询，消除 GUI 线程阻塞导致的进度卡顿

### v1.6.0 (2026-08-06)
- fix(gui): 语言切换下拉项混用真实中文导致乱码 → 改为纯 ASCII + `\u` 转义
- feat(gui): 底部状态栏显示版本号与可点击项目主页链接
- fix(gui): runspace 并行扫描改用内联脚本块，修复"无法识别 Find-StignoreFiles"错误

### v1.5.0 (2026-08-06)
- perf(gui): runspace 线程池并行扫描 + `-Filter` 替代 `-Include`，扫描提速
- fix(gui): 统一日志函数为 `Write-LogLine`（修复旧调用未定义导致崩溃）

### v1.4.0 (2026-08-06)
- feat(gui): 中英文界面切换（右上角下拉框，默认跟随系统区域）

### v1.3.0
- refactor: 合并命令行脚本为单一 GUI 工具，扫描/应用逻辑内联

## 8. 待办 / 已知限制

- [ ] 多驱动器并行度固定 4 线程，未根据驱动器数量自适应
- [ ] 未做 git push 远程（需用户手动操作）
- [ ] 无自动化测试（PowerShell GUI 测试成本高，暂以语法解析 + 最小复现验证）
