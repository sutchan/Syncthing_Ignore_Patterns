<!-- SyncthingIgnorePatterns v1.16.2 -->

# 获取帮助

## 先查文档

大部分问题都能在文档里直接找到答案：

| 想了解 | 看这里 |
|--------|--------|
| 规则集内容、分类、安装方法 | [`README.md`](../README.md)（中文）/ [`README_EN.md`](../README_EN.md)（English） |
| GUI 工具的每个功能、选项、工作流 | README 的「批量同步工具」一节 |
| 版本历史与已知修复 | [`CHANGELOG.md`](../CHANGELOG.md) |
| 项目架构红线与完整功能规格 | [`openspec/project.md`](../openspec/project.md) |
| 贡献代码/规则 | [`CONTRIBUTING.md`](CONTRIBUTING.md) |

## 提交 Issue

请使用对应的模板，信息越全解决越快：

- 🐛 **功能异常** → [Bug 报告](../../issues/new?template=bug_report.md)
- 📏 **想加/想改某条忽略规则** → [规则请求](../../issues/new?template=rule-request.md)
- ✨ **新功能建议** → [功能请求](../../issues/new?template=feature_request.md)

提交 Bug 报告前请准备好：

```powershell
# 工具版本
Select-String -Path .\SyncthingIgnoreGUI.ps1 -Pattern '^\$ScriptVersion'

# PowerShell 版本
$PSVersionTable.PSVersion

# Windows 版本
[System.Environment]::OSVersion.VersionString
```

同时请附上：复现步骤（点了哪些按钮、勾了哪些选项）、GUI 底部日志框的输出（**请先脱敏路径**）、期望结果与实际结果。

## 常见问题

**Q：GUI 双击后一闪而过 / 打不开？**
A：WinForms 需要 STA 线程。直接运行脚本即可，它会自动以 `powershell -STA` 重启自身；也可显式执行
`powershell -STA -NoProfile -File .\SyncthingIgnoreGUI.ps1`。若 PowerShell 执行策略阻止，加上 `-ExecutionPolicy Bypass`。

**Q：界面中文显示成乱码？**
A：脚本为纯 ASCII，中文以 `\u` 转义内嵌。若文件被 GBK 工具重新保存过就会坏掉，请重新从仓库下载原始文件，**不要用会转编码的编辑器保存**。

**Q：扫描太慢？**
A：扫描用 runspace 线程池（4 线程）+ `-Filter .stignore`。首次全盘扫描慢属正常，之后用清单 `config/stignore-paths.json` 直接 Apply，无需重复全盘扫描。也可指定扫描根目录缩小范围。

**Q：备份文件堆积很多？**
A：备份默认轮转保留 3 份。若发现更多，说明是旧版本产生的，可手动清理 `*.bak.*`。

**Q：某条规则误伤了我需要同步的文件？**
A：先用「仅预览」确认影响范围，然后在 `.stignore` 中删除对应行，或用 `!` 取反重新包含（取反行必须紧跟对应正向行）。欢迎提交 [规则请求](../../issues/new?template=rule-request.md) 帮我们修正默认规则集。

## 其他渠道

- Syncthing 本身的使用问题（同步、设备配对、版本控制等）请前往 [Syncthing 官方论坛](https://forum.syncthing.net/) 或 [官方文档](https://docs.syncthing.net/)。
- 安全漏洞请**不要**开公开 Issue，参见 [安全策略](SECURITY.md)。
