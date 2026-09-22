# Spec: SyncthingIgnoreGUI (Flutter Desktop)

## 功能范围

Dart + Flutter Windows 桌面应用，提供 `.stignore` 规则的批量扫描与应用能力，
支持中英文界面，构建为独立 `.exe` 分发（无需目标机安装 PowerShell）。

## 需求

### REQ-1 扫描
- 系统：Windows 桌面（Flutter Windows target）；非 Windows 下驱动器枚举回退到当前目录以可测
- 输入：扫描根目录（留空=所有固定驱动器；或指定单目录），由 `file_picker` 选择
- 行为：
  - 每根目录一个 isolate 并行（默认 4），根目录分批送入（`scanRoots`）
  - 显式栈深度优先遍历 + `listSync`；一次枚举同时取文件与子目录
  - 排除 `.git` 目录与规则源目录（避免重扫工具自带 `.stignore`）；无权限目录跳过并累计，不中断整根
  - 扫描阶段不做逐文件 UI 刷新，不做哈希计算
- 输出：`stignore-paths.json`（UTF-8，含 version/scannedAt/roots/files）
  - 每条记录：path / size / lastWriteUtc / foundAtUtc
  - 清单备份 `stignore-paths.json.bak.<时间戳>` 同样适用"最多保留 3 个"轮转

### REQ-2 应用
- 输入：扫描清单 `stignore-paths.json` + 标准规则源（打包资源 `assets/.stignore`）
- 行为：
  - 对每个清单路径，用标准 `.stignore` 替换其现有内容
  - 替换前自动备份为 `.stignore.bak.<时间戳>`（被替换目标恰为标准源 `.stignore` 自身时跳过备份）
  - SHA-256 比对：内容一致的文件跳过，不重复备份
  - 源文件已删除的路径为失效路径，仅 `强制` 时清理（`force`）
  - 应用同样在后台（`async`）执行，进度条显示不确定/完成态，GUI 不卡顿
  - 非预览（`whatIf=false`）且实际发生替换/错误后，重写清单仅保留仍存在的路径
- 选项：仅预览（不写文件）、强制（跳过确认）、写回前备份
- 备份轮转：每种备份 `<Base>.bak.*` 最多保留 3 个，超出自动删除最旧的（按修改时间排序）

### REQ-3 国际化
- 右上角语言下拉 `English` / `中文`，即时切换全部界面与日志文案
- 字典 `i18n.dart` 键与 PowerShell `$T` 对齐；`t(key, args)` 支持 `{0}` 占位
- 语言选择当前为会话内状态（未持久化到磁盘，待办见开发任务清单）

### REQ-4 版本与项目信息
- 「关于」对话框显示版本（`AppState.version`）与项目地址
- 版本号与 `pubspec.yaml` `version:` 及 README 徽章保持一致

### REQ-5 主题与外观
- 右上角主题切换 `浅色` / `深色`，即时切换全部配色（`ThemeMode` 跟随设置）
- Material 3 主题，`colorSchemeSeed` 取 teal

### REQ-6 交互
- 根目录 / 清单路径输入（支持 `file_picker` 浏览；当前未实现拖拽填入）
- 选项勾选：仅预览 / 强制 / 备份
- 按钮：扫描 / 应用 / 停止 / 清空日志
- 进度条 + 状态行 + 结果与日志列表（日志按级别着色）
- 结果列表点击打开所在文件夹（当前未实现双击打开文件本身）
- 标准规则随资源打包，运行时 `rootBundle` 加载；更新规则须同步 `app/assets/.stignore` 副本

## 非目标
- 不做云端同步、不做规则冲突合并
- 不依赖 PowerShell 运行时（纯 Dart/Flutter 实现）

## 状态
- 代码已完成：扫描 / 应用 / 备份轮转 / 中英双语 / 明暗主题 / 清单 manifest
- `flutter analyze` 零告警已达成（v1.18.7 清零 52 项，CI `build-windows` 强制校验）；GitHub Actions `build-windows` 已落地，自动构建并发布 `SyncthingIgnoreGUI-vX.Y.Z-windows-x64.zip`（版本取自根 `VERSION`）
- 待办：测试覆盖率门禁（≥80%）、UI 部件测试（flutter_test + mockito）、发布包说明（VC++ 运行库 / Flutter AOT）或 Inno Setup
- 详见 [开发任务清单](../../development-tasks.md)
