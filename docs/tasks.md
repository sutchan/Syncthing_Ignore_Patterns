# 任务清单（单一来源 · Single Source of Truth）

> 本文件是项目**所有任务记录的唯一来源**。其他文档（如 `docs/specs/stignore-gui-flutter/spec.md`、`docs/project.md`）仅作引用，不得重复维护任务内容，避免多处漂移。
> 约定：
> ① **剩余任务** = 已采纳、尚未完成的开发项；
> ② **评估中建议（Backlog）** = 功能 / UI 完善提案（PROP 编号），采纳后转入剩余任务；
> ③ 已完成任务一律移除，历史见 `CHANGELOG.md` 与 `docs/project.md` §7。

## 进度状态（2026-10-01 核对）

- 原始需求 REQ-1 ~ REQ-10 全部完成，无已知功能缺口：扫描（含映射网络盘 / UNC 路径，v1.26.0）、应用（SHA-256 比对 + 写前备份 + ≤3 轮转 + 应用阶段可停止）、中英双语 / 明暗主题、窗口几何记忆、忽略清单在线更新、应用前确认 + 扫描实时状态行、应用更新检查（含一键下载安装）、窗口拖拽填入。
- 健康度：`flutter analyze` 零告警；`flutter test` 全量 **116/116** 通过（`lib/`）；行覆盖率满足 CI **≥80%** 门禁（v1.32.2 实测 81.69%，新增 PROP-14~18 代码保持覆盖）；版本三轨一致（Flutter `1.33.0` / PowerShell `1.18.5` / 规则集 `1.18.5`）。性能基准与实测数据见 [performance.md](performance.md)。
- 评估中建议：18 条（PROP-1~18）现已全部实现并移出，无剩余任务、无 Backlog：PROP-9/6/12/10（v1.29.0）+ PROP-8/11/13（v1.30.0）+ PROP-4/5/7（v1.31.0）+ PROP-1/2/3（v1.32.0）+ PROP-14/15/16/17/18（v1.33.0）。
- 2026-10-01：首批 PROP-9/6/12/10（v1.29.0）+ 第二批 PROP-8/11/13（v1.30.0）+ 第三批 PROP-4/5/7（v1.31.0）+ 第四批 PROP-1/2/3（v1.32.0）已实现；所有 Backlog 项完成，本文件为单一来源。
- 2026-10-01：功能正常化——清理 PROP-2 新增文件 4 个 lint info（`flutter analyze` 零问题），修复设置对话框 `RenderFlex` 溢出（`widget_test` 语言切换用例恢复 90/90）；版本展示位同步至 v1.32.1。
- 2026-10-01：质量门禁修复——补齐 `backup_manager` / `backup_state` / `results_view_state` / `pickers_state` / `preferences_state` 单测与 results 组件 widget 测试，行覆盖率 72.77% → **81.69%** 越过 ≥80% 门禁；修复 `ResultsListSliver` 在 `SliverList.builder` `itemBuilder` 中误用 `context.select` 的潜在崩溃（结果有数据时触发 provider 断言）；版本展示位同步至 v1.32.2。
- 2026-10-01：代码审查补充 Backlog——新增 PROP-14（应用后刷新合规/结果）、PROP-15（跨平台窗口几何记忆）、PROP-16（失败状态行透出）、PROP-17（日志持久化/导出）、PROP-18（PowerShell 遗留版功能对账），均含优先级与预期成果；版本展示位同步至 v1.32.3。
- 2026-10-01（本次更新时间戳）：采纳并实现 PROP-14~18 全部 5 项（v1.33.0），`flutter analyze` 零告警、`flutter test` 116/116 通过；版本展示位同步至 v1.33.0。

## 剩余任务（已采纳待办）

> 所有已采纳任务（PROP-1~18）均已实现并移出，无剩余任务。完整规格与历史见下方 Backlog 与 `CHANGELOG.md`、`docs/project.md` §7。
> 2026-10-01：PROP-14~18 全部实现（v1.33.0），详见 `CHANGELOG.md` 与 `docs/project.md` §7。

## 评估中建议（Backlog，非待办）

> 对当前 Flutter 主实现的功能与 UI 完善建议，供后续版本评估采纳。
> 均为现有对外行为契约（REQ-1~REQ-10）之外的增量增强；采纳时须保持既有契约稳定。
> 本清单自 `docs/specs/stignore-gui-flutter/spec.md`「改进建议（评估中）」迁移并集中维护于此（v1.28.5）。

（PROP-1~13 已实现并移出，历史见 `CHANGELOG.md` 与 `docs/project.md` §7。）

### 新增评估建议（2026-10-01 代码审查补充，PROP-14~18 · 已实现 v1.33.0）

- **PROP-14（优先级 P1 · 应用后状态一致性 · ✅ 已实现 v1.33.0）**
  - 现状：`apply()` 完成后未重算 `_compliance`、也未刷新 `results`；仅 `scan()` 后调用 `_computeCompliance()`，故应用后「待应用/已符合」计数与结果行首 ✓/✗ 停留于应用前。
  - 预期成果：Apply 成功（非预览、非取消）后自动重算合规并刷新结果列表，UI 即时显示「全部已符合」，`needsApplyCount`/`compliantCount` 准确。
- **PROP-15（优先级 P2 · 跨平台窗口几何记忆 · ✅ 已实现 v1.33.0）**
  - 现状：`window_bounds_service` 仅 Windows（ffi `user32`），macOS/Linux 启动时不恢复窗口位置/尺寸。
  - 预期成果：抽象窗口边界存取；非 Windows 平台以 `window_manager` 等方案记忆几何，或于 UI/文档明确标注「仅 Windows 记忆窗口」，避免误用。
- **PROP-16（优先级 P1 · 失败状态行透出 · ✅ 已实现 v1.33.0）**
  - 现状：`scan()`/`apply()` 异常仅写日志；`finish()`（progress_state.dart:65）不清 `status`，状态行仍显示上一步文案（如「准备中…」），无日志场景难定位失败；`apply()` 中 `applyRules` 未 try-catch，异常直接冒泡至全局 onError。
  - 预期成果：根目录不存在、清单损坏、规则读取失败、`applyRules` 异常等关键路径捕获后于状态行显示失败文案（`loc.t('failed')` + 摘要）并记 `error` 级日志，与成功路径状态一致；`apply()` 对 `applyRules` 就地 try-catch。
- **PROP-17（优先级 P2 · 日志持久化/导出 · ✅ 已实现 v1.33.0）**
  - 现状：`log_state` 仅内存环缓冲（maxLogEntries 1000），应用关闭即丢失，无文件导出（仅「复制全部」）。
  - 预期成果：提供「导出日志为文件」入口（落盘到应用数据目录或用户选定路径）便于离线排障；可选持久化最近一次运行日志。
- **PROP-18（优先级 P2 · PowerShell 遗留版功能对账 · ✅ 已实现 v1.33.0）**
  - 现状：遗留 `SyncthingIgnoreGUI.ps1`（v1.18.5）与 Flutter 主实现功能边界未成文，用户易误用旧版缺失能力。
  - 预期成果：产出功能对账清单（逐项标注 Flutter 具备 / ps1 具备 / 差异），并在 README 与 ps1 头部明确废弃状态与使用边界。

## 版本说明
- Flutter 桌面版：v1.33.0（pubspec `1.33.0+5`、`AppState.version`）
- PowerShell 遗留版：v1.18.5（独立演进）
- 规则集 `.stignore`：v1.18.5（独立版本，`Updated` 为规则集修订日）
