# Spec: SyncthingIgnoreGUI.ps1

## 功能范围

单一自包含 PowerShell 5.1 WinForms 脚本，提供 `.stignore` 规则的批量扫描与
应用能力，支持中英文界面切换。

## 需求

### REQ-1 扫描
- 系统：Windows PowerShell 5.1
- 输入：扫描根目录（留空=所有固定驱动器；或指定单目录）
- 行为：
  - 使用 runspace 线程池（最多 4 线程）并行检索各根目录
  - 使用 `Get-ChildItem -Filter '.stignore' -Recurse -File -Force`
  - 排除 `.git` 目录与脚本自身所在目录
  - 扫描阶段不做逐文件 UI 刷新（结束统一汇总），不做哈希计算
  - 后台 runspace 执行 + Timer 轮询 `DoEvents`，GUI 线程不阻塞（v1.7.0）
  - 扫描完成后窗体显示「已找到 N 个 .stignore 文件」摘要
  - 启动时若已存在清单，自动加载并显示「已加载现有清单：N 个文件」
- 输出：`stignore-paths.json`（UTF-8，含 version/scannedAt/count/roots/files）
  - 每条记录：path / size / lastWriteUtc / foundAtUtc
  - 清单备份 `stignore-paths.json.bak.<时间戳>` 同样适用"最多保留 3 个"轮转

### REQ-2 应用
- 输入：扫描清单 `stignore-paths.json` + 标准规则源 `.stignore`
- 行为：
  - 对每个清单路径，用标准 `.stignore` 替换其现有内容
  - 替换前自动备份为 `.stignore.bak.<时间戳>`（被替换目标恰为标准源 `.stignore` 自身时跳过备份）
  - 规则一致的文件跳过，不重复备份
  - 源文件已删除的路径为失效路径，仅 `强制` 时清理
  - 应用同样在后台 runspace 执行，进度条显示真实百分比，GUI 不卡顿
  - 非预览且非强制时，应用前弹出确认框，避免误写大量路径
- 选项：仅预览（不写文件）、强制（跳过确认）、写回前备份
- 备份轮转（v1.8.0）：每种备份 `<Base>.bak.*`（含 `.stignore.bak.*` 与清单 `stignore-paths.json.bak.*`）**最多保留 3 个**，超出自动删除最旧的（按 LastWriteTimeUtc 排序）

### REQ-3 国际化
- 右上角语言下拉框 `English` / `中文`，默认跟随系统区域
- 所有中文界面文案以 `\uXXXX` 转义存储，运行时 `Decode-Uni` 还原
- 脚本文件保持纯 ASCII，规避 GBK 重编码乱码
- 语言选择持久化到 `config.json`，下次启动自动恢复（v1.10.0）

### REQ-4 版本与项目信息
- 窗口底部状态栏显示当前版本号与可点击项目主页链接
- 版本号与脚本头、`$ScriptVersion`、`.stignore` 文件头、README 徽章保持一致
- 右上角「关于」按钮显示版本与项目地址（v1.10.0）

### REQ-5 主题与外观（v1.10.0）
- 右上角主题下拉框 `浅色` / `深色`，即时切换全部控件配色
- 主题选择持久化到 `config.json`，与语言一并恢复

### REQ-6 交互增强（v1.10.0）
- 拖拽：可将文件夹拖入窗口自动填充扫描根目录；将 `.stignore` 或 `.json` 拖入自动填充清单路径
- 结果列表：扫描/应用后路径显示在专属 ListBox；双击条目用系统默认程序打开其所在文件
- 停止：运行中提供「停止」按钮，点击即收回 UI 控制权（后台任务静默收尾）
- 进度：进度条旁实时显示百分比文字
- 日志：日志框自动滚动到底，始终可见最新行
- `config.json` 不纳入版本控制（加入 `.gitignore`）

## 非目标

- 不依赖 PowerShell 7 专有语法
- 不做云端同步、不做规则冲突合并
- 不提供自动化测试框架（以语法解析 + 最小复现验证）
