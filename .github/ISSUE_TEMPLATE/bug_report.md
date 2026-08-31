---
name: Bug 报告
about: 报告 GUI 工具或规则集的实际异常行为
title: "[Bug] "
labels: bug
assignees: ''
---

## 问题描述

<!-- 清晰简洁地描述遇到的问题 -->

## 影响范围

- [ ] GUI 工具（`SyncthingIgnoreGUI.ps1`）
- [ ] 规则集（`.stignore`）
- [ ] 文档（README / README_EN / openspec）

## 复现步骤

1. 打开 GUI / 执行操作：
2. 勾选的选项（仅预览 / 强制 / 写回前备份）：
3. 点击的按钮：
4. 出现的现象：

## 期望结果

<!-- 你期望发生什么 -->

## 实际结果

<!-- 实际发生了什么，可附截图 -->

## 环境信息

```text
工具版本：
Windows 版本：
PowerShell 版本（$PSVersionTable.PSVersion）：
```

获取方式：

```powershell
Select-String -Path .\SyncthingIgnoreGUI.ps1 -Pattern '^\$ScriptVersion'
$PSVersionTable.PSVersion
[System.Environment]::OSVersion.VersionString
```

## 日志输出

<!-- 粘贴 GUI 底部日志框的内容。注意：请先脱敏，把真实路径替换为 C:\Users\<user>\... 之类占位 -->

```text

```

## 补充信息

<!-- 其他上下文、是否稳定复现、 workaround 等 -->
