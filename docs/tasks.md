# 任务清单（单一来源 · Single Source of Truth）

> 本文件是项目**所有任务记录的唯一来源**。其他文档（如 `docs/specs/stignore-gui-flutter/spec.md`、`docs/project.md`）仅作引用，不得重复维护任务内容，避免多处漂移。
> 约定：
> ① **剩余任务** = 已采纳、尚未完成的开发项；
> ② **评估中建议（Backlog）** = 功能 / UI 完善提案（PROP 编号），采纳后转入剩余任务；
> ③ 已完成任务一律移除，历史见 `CHANGELOG.md` 与 `docs/project.md` §7。

## 进度状态（2026-09-30 核对）

- 原始需求 REQ-1 ~ REQ-10 全部完成，无已知功能缺口：扫描（含映射网络盘 / UNC 路径，v1.26.0）、应用（SHA-256 比对 + 写前备份 + ≤3 轮转 + 应用阶段可停止）、中英双语 / 明暗主题、窗口几何记忆、忽略清单在线更新、应用前确认 + 扫描实时状态行、应用更新检查（含一键下载安装）、窗口拖拽填入。
- 健康度：`flutter analyze` 零告警；`flutter test` 全量 **90/90** 通过（`lib/`）；版本三轨一致（Flutter `1.29.1` / PowerShell `1.18.5` / 规则集 `1.18.5`）。性能基准与实测数据见 [performance.md](performance.md)。
- 评估中建议：13 条（P0×3 / P1×5 / P2×5，见下方「评估中建议」），部分已采纳转入「剩余任务」开始实现。
- 2026-10-01：首批增量增强 PROP-9 / PROP-6 / PROP-12 / PROP-10 已实现（v1.29.0）；其余建议继续按 P0→P2 推进，本文件作为单一来源实时同步采纳 / 完成状态。

## 剩余任务（已采纳待办）

> 以下由「评估中建议」采纳，按 P0→P2 推进；完整规格见下方 Backlog。完成时移入 CHANGELOG 并从本清单移除。

- [待实现] **PROP-1** 扫描真正可取消（isolate 取消令牌，状态行立即反馈「已取消」）
- [待实现] **PROP-2** 结果列表增强（±模式过滤 / 仅目录 / 仅文件，注意 `results_list` 防 >200 行拆分）
- [待实现] **PROP-3** 多扫描根（逗号 / 换行 / 「+」追加，`pickers_state` 维护根列表）
- [待实现] **PROP-4** 备份管理 UI（列表 / 还原 / 删除，新增 `backup_screen` + `backup_manager`）
- [待实现] **PROP-5** 应用前预检 + 限流（仅列待改 / 单次最大改动数）
- [待实现] **PROP-7** 启动自动检查更新（设置项，默认关）
- [待实现] **PROP-8** 扫描默认值持久化（深度 / 跳大目录 / 每目录文件数 → `SettingsStore`）
- [待实现] **PROP-11** 规则更新变更摘要（新增 / 移除规则数）
- [待实现] **PROP-13** 进度 ETA（已知总量时预计剩余时间）

## 评估中建议（Backlog，非待办）

> 对当前 Flutter 主实现的功能与 UI 完善建议，供后续版本评估采纳。
> 均为现有对外行为契约（REQ-1~REQ-10）之外的增量增强；采纳时须保持既有契约稳定。
> 本清单自 `docs/specs/stignore-gui-flutter/spec.md`「改进建议（评估中）」迁移并集中维护于此（v1.28.5）。

### P0（高价值 / 修复真实缺口）

**PROP-1 扫描中途真正可取消**
- 现状：`scanner.scanRoots` 仅接受 `onProgress`，无 `isCancelled` 参数；`scan_flow.scan()` 只在 `scanRoots` 跑完全部根后才检查 `cancelled`（`scan_flow.dart:62`）。故扫描中点「停止」并不中断正在运行的 isolate，仍会跑完所有根再丢弃结果——与 `applier.applyRules` 的逐路径 `isCancelled` 形成对比。
- 建议：为 `scanRoots` 增加 `bool Function()? isCancelled`，在每批/每个根派发前判定；命中即终止后续 isolate 并提前返回，使「停止」在扫描阶段即时生效。
- 影响：`services/scanner.dart`、`state/scan_flow.dart`、`scanner_test`。

**PROP-2 结果列表增强（搜索 / 计数 / 复制 / 多选）**
- 现状：`ui/results_list.dart` 高度写死 160px，纯文本行，无搜索、无计数徽标、无复制 / 多选。扫描出成百上千个 `.stignore` 时难以定位。
- 建议：① 顶部搜索框按路径过滤；② 标题显示 `N 个` 计数；③ 行右键复制路径；④ 多选后「打开选中所在文件夹」「导出选中路径」。
- 影响：`ui/results_list.dart`、`i18n.dart`（新增 `resultCount` / `copyPath` / `filterResults` 等键）。

**PROP-3 支持多扫描根**
- 现状：`scan_flow._resolveRoots()` 仅支持「留空=固定 + 映射网络驱动器」或「单个目录 / UNC 路径」；拖拽填入（`pickers_state.applyDrop`）也只替换单根 `rootText`。
- 建议：将扫描根改为可增删列表；`file_picker` 多选目录 + 拖拽追加（而非替换）；`_resolveRoots` 展开为多个根。`scanRoots` 已接受 `List<String>`，改动成本低。
- 影响：`state/pickers_state.dart`、`state/scan_flow.dart`、`ui/root_field.dart`、`i18n.dart`。

### P1（明显增益）

**PROP-4 备份管理与一键恢复**
- 现状：Apply 写前生成 `.stignore.bak.<时间戳>` 并按 `<Base>.bak.*` 轮转保留 ≤3，但界面无任何查看 / 恢复入口。
- 建议：新增「备份」入口，列出当前 `.stignore` 的备份、显示时间、提供「恢复」（用备份覆盖当前并自身再备份）。
- 影响：新增 `ui/backup_card.dart` / `state/backup_state.dart` / `services/backup_store.dart`。

**PROP-5 扫描后预检「是否已符合标准规则」**
- 现状：Apply 逐文件 SHA-256 比对跳过一致项，但 UI 在扫描后不揭示哪些已符合、哪些需应用（结果列表仅列路径）。
- 建议：扫描完成后对每条记录与生效清单做轻量 SHA 比对，结果列表用 ✓/✗ 标记；Apply 预览只统计「需更新 N / 已一致 M」。无新依赖。
- 影响：`state/scan_flow.dart`、`ui/results_list.dart`、`i18n.dart`。

**PROP-7 启动时可选项自动检查更新**
- 现状：应用更新（§9.8）与清单更新（§9.6）均为手动触发。
- 建议：设置项增加「启动时检查应用更新 / 清单更新」开关（默认关），启动后后台静默检查并提示；复用既有 `checkAppUpdate` / `checkRulesetUpdate`。
- 影响：`state/preferences_state.dart`、`ui/settings_dialog.dart`、`services/settings_store.dart`、`i18n.dart`。

**PROP-8 设置项扩充（扫描默认值）**
- 现状：设置对话框仅语言 / 主题。
- 建议：加入「默认扫描深度」「默认跳过超大目录」「默认开启备份」等默认值，启动时载入，减少每次重设。
- 影响：`settings_dialog.dart`、`settings_store.dart`、`scan_options_state.dart`。

### P2（体验打磨）

- **PROP-11 规则更新变更摘要**：`ruleset_card` 检查更新后除版本号外，展示「新增 / 移除规则数」差异（解析新旧 `.stignore` 行数）。
- **PROP-13 进度 ETA**：状态行在已知总量（多根）时给出预计剩余时间，提升大扫描可预期性。

## 版本说明
- Flutter 桌面版：v1.29.1（pubspec `1.29.1+1`、`AppState.version`）
- PowerShell 遗留版：v1.18.5（独立演进）
- 规则集 `.stignore`：v1.18.5（独立版本，`Updated` 为规则集修订日）
