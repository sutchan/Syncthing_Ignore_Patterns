# 开发任务清单（单一来源）

> **本文件是项目任务跟踪的唯一权威来源**。`docs/project.md` §8 与
> `docs/specs/stignore-gui-flutter/spec.md`「状态」段仅作指针引用。
> 本清单**仅列未完成任务**；已完成任务一律移除，历史见 `CHANGELOG.md` 与 `docs/project.md` §7。

## 剩余任务

**无。**

A（功能对等）/ B（工程化 / 质量）/ C（构建与发布）/ D（规则集维护）/ E（项目治理）各组项
均已实现，最后一批为 v1.25.0 的「窗口拖拽填入」与「一键下载并安装更新」。

## 验证边界（非待办）

- **窗口拖拽填入**：原生接收由 Windows runner 实现（`DragAcceptFiles` + `WM_DROPFILES` +
  MethodChannel `syncthing_ignore_gui/drop`）。本机无 MSVC，无法编译或实机验证；仅由 CI
  `build-windows` 编译 + 本地单测（`file_drop_test`、`state_mixins_test`）覆盖。
- **一键下载并安装更新**：下载、zip 校验与脚本生成有单测（`update_installer_test`），但
  **替换可执行文件与重启环节无法本机验证**，需在真实 Windows 上执行一次确认；失败详情写入
  应用目录 `update.log`。
- **Inno Setup 安装器**：未采用——自动更新已覆盖该需求，且 Release 资产规范仅上传 `*.zip` / `*.tar.gz`。

## 版本说明
- Flutter 桌面版：v1.25.3（pubspec `1.25.3+1`，`AppState.version`）
- PowerShell 遗留版：v1.18.5（独立演进）
- 规则集 `.stignore`：v1.18.5（独立版本，`Updated` 为规则集修订日）
