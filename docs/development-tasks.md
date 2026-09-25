# 开发任务清单（单一来源）

> 本清单仅列未完成任务；已完成任务一律移除，历史见 `CHANGELOG.md` 与 `docs/project.md` §7。
> 后续功能 / UI 完善建议集中维护于 [`docs/specs/stignore-gui-flutter/spec.md`](specs/stignore-gui-flutter/spec.md) 的「改进建议（评估中）」一节（按 P0/P1/P2 分级），采纳时再转入本清单。

## 进度状态（2026-09-25 核对）

- 原始需求 REQ-1 ~ REQ-10 全部完成，无已知功能缺口：扫描（含映射网络盘 / UNC 路径，v1.26.0）、应用（SHA-256 比对 + 写前备份 + ≤3 轮转 + 应用阶段可停止）、中英双语 / 明暗主题、窗口几何记忆、忽略清单在线更新、应用前确认 + 扫描实时状态行、应用更新检查（含一键下载安装）、窗口拖拽填入。
- 健康度：`flutter analyze` 零告警；`flutter test` 全量 **82/82** 通过；版本三轨一致（Flutter `1.26.1` / PowerShell `1.18.5` / 规则集 `1.18.5`）。
- 待采纳增强：13 条评估中建议（P0×3 / P1×5 / P2×5，见 `docs/specs/stignore-gui-flutter/spec.md`「改进建议（评估中）」），未列入待办。

## 剩余任务

**无。**

## 版本说明
- Flutter 桌面版：v1.26.1（pubspec `1.26.1+1`、`AppState.version`）
- PowerShell 遗留版：v1.18.5（独立演进）
- 规则集 `.stignore`：v1.18.5（独立版本，`Updated` 为规则集修订日）

## 后续方向（评估中，非待办）
- **P0**：① 扫描中途真正可取消（`scanRoots` 增 `isCancelled`）；② 结果列表增强（搜索 / 计数 / 复制 / 多选）；③ 多扫描根（可增删列表 + 拖拽追加）
- **P1**：备份管理与一键恢复、扫描后预检一致状态、清单「打开」按钮、启动自动检查更新、设置项扩充
- **P2**：主容器语义化 id、键盘快捷键、规则更新变更摘要、日志导出、进度 ETA
- 完整条目与影响范围见 `docs/specs/stignore-gui-flutter/spec.md`「改进建议（评估中）」
