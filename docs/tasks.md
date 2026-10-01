# 任务清单（单一来源 · Single Source of Truth）

> 本文件是项目**所有任务记录的唯一来源**。其他文档（如 `docs/specs/stignore-gui-flutter/spec.md`、`docs/project.md`）仅作引用，不得重复维护任务内容，避免多处漂移。
> 约定：
> ① **剩余任务** = 已采纳、尚未完成的开发项；
> ② **评估中建议（Backlog）** = 功能 / UI 完善提案（PROP 编号），采纳后转入剩余任务；
> ③ 已完成任务一律移除，历史见 `CHANGELOG.md` 与 `docs/project.md` §7。

## 进度状态（2026-10-01 核对）

- 原始需求 REQ-1 ~ REQ-10 全部完成，无已知功能缺口：扫描（含映射网络盘 / UNC 路径，v1.26.0）、应用（SHA-256 比对 + 写前备份 + ≤3 轮转 + 应用阶段可停止）、中英双语 / 明暗主题、窗口几何记忆、忽略清单在线更新、应用前确认 + 扫描实时状态行、应用更新检查（含一键下载安装）、窗口拖拽填入。
- 健康度：`flutter analyze` 零告警；`flutter test` 全量 **90/90** 通过（`lib/`）；版本三轨一致（Flutter `1.32.0` / PowerShell `1.18.5` / 规则集 `1.18.5`）。性能基准与实测数据见 [performance.md](performance.md)。
- 评估中建议：13 条（P0×3 / P1×5 / P2×5）；PROP-9/6/12/10（v1.29.0）+ PROP-8/11/13（v1.30.0）+ PROP-4/5/7（v1.31.0）+ PROP-1/2/3（v1.32.0）已实现并移出 Backlog；所有 Backlog 项均已完成，无剩余任务。
- 2026-10-01：首批 PROP-9/6/12/10（v1.29.0）+ 第二批 PROP-8/11/13（v1.30.0）+ 第三批 PROP-4/5/7（v1.31.0）+ 第四批 PROP-1/2/3（v1.32.0）已实现；所有 Backlog 项完成，本文件为单一来源。

## 剩余任务（已采纳待办）

> 以下由「评估中建议」采纳，按 P0→P2 推进；完整规格见下方 Backlog。完成时移入 CHANGELOG 并从本清单移除。

（无 — 所有已采纳任务均已完成，历史见 `CHANGELOG.md` 与 `docs/project.md` §7。）

## 评估中建议（Backlog，非待办）

> 对当前 Flutter 主实现的功能与 UI 完善建议，供后续版本评估采纳。
> 均为现有对外行为契约（REQ-1~REQ-10）之外的增量增强；采纳时须保持既有契约稳定。
> 本清单自 `docs/specs/stignore-gui-flutter/spec.md`「改进建议（评估中）」迁移并集中维护于此（v1.28.5）。

（全部 13 条评估建议已实现并移出，历史见 `CHANGELOG.md` 与 `docs/project.md` §7。）

## 版本说明
- Flutter 桌面版：v1.32.0（pubspec `1.32.0+1`、`AppState.version`）
- PowerShell 遗留版：v1.18.5（独立演进）
- 规则集 `.stignore`：v1.18.5（独立版本，`Updated` 为规则集修订日）
