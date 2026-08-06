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
- **PowerShell 5.1（Windows PowerShell）** 目标运行时；不依赖 PowerShell 7
  专有语法（如 `ForEach-Object -Parallel`）。并行改用 runspace 线程池实现。

## 3. 目录结构

```
SyncthingIgnorePatterns/
├── .stignore                 # 标准规则源文件（Apply 依赖，版本 v1.8.0）
├── SyncthingIgnoreGUI.ps1    # 主工具（GUI + 扫描/应用逻辑，纯 ASCII）
├── README.md                 # 中文文档
├── README_EN.md              # 英文文档
├── .gitignore                # 忽略运行时产物（stignore-paths.json / *.bak.*）
├── stignore-paths.json       # 扫描清单输出（运行时生成，已被 .gitignore 忽略）
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
- 每次版本变更需同步更新 CHANGELOG（见第 7 节）与 README 的"版本与项目地址"。

## 5. GUI 功能规格

| 功能 | 说明 |
|------|------|
| 语言切换 | 右上角下拉框 `English` / `中文`，实时切换全部界面与日志文案 |
| 扫描根目录 | 留空=扫描所有固定驱动器；或浏览选择指定目录 |
| 并行扫描 | runspace 线程池（最多 4 线程）+ `-Filter .stignore`，排除 `.git` 与脚本目录 |
| 后台防卡顿 | 扫描在后台 runspace 执行，Timer 轮询 `DoEvents` 保持 UI 响应（v1.7.0） |
| 仅预览 | 勾选后不写文件，仅预览结果 |
| 强制 | 跳过逐文件确认直接执行 |
| 写回前备份 | 写回清单前备份原 `.stignore` 为 `.stignore.bak.<时间戳>` |
| 备份轮转 | 每种 `.bak.*` 最多保留 3 个，超出自动删最旧（v1.8.0） |
| 版本/地址 | 底部状态栏显示版本号与可点击项目主页 |
| 实时日志 | 底部日志框输出全部执行信息 |

## 6. 扫描/应用工作流

1. 默认直接 **Scan** → 并行扫描所有根目录 → 生成 `stignore-paths.json`
   （记录 path / size / lastWriteUtc）。
2. 规则更新后，勾选 **强制** 点 **Apply** → 对每个历史路径用标准 `.stignore`
   替换（替换前自动备份）。规则一致的文件跳过，不重复备份。
3. 失效路径（源文件已删除）仅在勾选 **强制** 时从清单清理。

## 7. CHANGELOG

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
