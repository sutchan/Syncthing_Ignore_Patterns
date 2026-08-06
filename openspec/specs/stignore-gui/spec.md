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
- 输出：`stignore-paths.json`（UTF-8，含 version/scannedAt/count/roots/files）
  - 每条记录：path / size / lastWriteUtc / foundAtUtc

### REQ-2 应用
- 输入：扫描清单 `stignore-paths.json` + 标准规则源 `.stignore`
- 行为：
  - 对每个清单路径，用标准 `.stignore` 替换其现有内容
  - 替换前自动备份为 `.stignore.bak.<时间戳>`
  - 规则一致的文件跳过，不重复备份
  - 源文件已删除的路径为失效路径，仅 `强制` 时清理
- 选项：仅预览（不写文件）、强制（跳过确认）、写回前备份

### REQ-3 国际化
- 右上角语言下拉框 `English` / `中文`，默认跟随系统区域
- 所有中文界面文案以 `\uXXXX` 转义存储，运行时 `Decode-Uni` 还原
- 脚本文件保持纯 ASCII，规避 GBK 重编码乱码

### REQ-4 版本与项目信息
- 窗口底部状态栏显示当前版本号与可点击项目主页链接
- 版本号与脚本头、`$ScriptVersion`、README 徽章三处保持一致

## 非目标

- 不依赖 PowerShell 7 专有语法
- 不做云端同步、不做规则冲突合并
- 不提供自动化测试框架（以语法解析 + 最小复现验证）
