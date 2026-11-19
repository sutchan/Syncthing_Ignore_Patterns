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

- [ ] GUI 工具（Flutter 主实现 `app/`）
- [ ] GUI 工具（PowerShell 遗留版 `SyncthingIgnoreGUI.ps1`）
- [ ] 规则集（`.stignore`）
- [ ] 文档（README / README_EN / docs）

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
使用的实现（Flutter 版 / PowerShell 版）：
工具版本：
规则集版本（作用于哪版均请填）：
Windows 版本：
PowerShell 版本（仅 PowerShell 版需要）：
```

获取方式：

```powershell
Get-Content .\VERSION                                          # Flutter 主实现版本
Select-String -Path .\SyncthingIgnoreGUI.ps1 -Pattern '^\$ScriptVersion'  # PS 遗留版版本
Select-String -Path .\.stignore -Pattern '^//Version'          # 规则集版本
$PSVersionTable.PSVersion
[System.Environment]::OSVersion.VersionString
```

Flutter 版亦可在「关于」对话框直接查看应用版本。

## 日志输出

<!-- 粘贴 GUI 底部日志框的内容。注意：请先脱敏，把真实路径替换为 C:\Users\<user>\... 之类占位 -->

```text

```

## 补充信息

<!-- 其他上下文、是否稳定复现、 workaround 等 -->
