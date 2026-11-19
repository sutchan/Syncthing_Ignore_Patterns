# SyncthingIgnorePatterns 全面代码审查报告

> 审查日期：2026-11-19 · 审查对象：`HEAD` = `d293935`（v1.33.0）+ 当前工作区
> 范围：`app/lib/`（Dart/Flutter 主实现，50 文件）、`app/windows/`（C++ runner）、`SyncthingIgnoreGUI.ps1`（遗留）、CI 与文档
> 方式：只读静态审查 + 关键路径逐行核实 + 实算数据 + `flutter analyze`（转后台，结果待确认）
> 本次审查**未修改任何文件**。工作区存在未提交改动：`.gitignore`、`.stignore`、`.code-workspace`、`?? app/lib/services/window_bounds.dart`。

---

## 一、总体质量评估

| 维度 | 结论 |
|------|------|
| 代码结构 | 优。`services`/`state`/`ui`/`models` 分层清晰，mixin 拆分到位，单一职责落实良好 |
| 可读性/命名 | 良。注释充分、文档库与源码库分离；仅 1 个文件超 200 行红线 |
| 异常处理 | 中。主流程有 try/finally，但 Apply 链路存在 3 处关键遗漏 |
| 数据安全 | 中。备份恢复、清单重写存在可导致数据错误/状态锁死的边界缺陷 |
| 性能 | 良。isolate 并行、Sliver 懒加载、环形缓冲、共享 HTTP 连接池均已到位，留有少量优化点 |
| 安全 | 良。无命令注入、无密钥泄露、版本/URL 校验到位；更新包缺完整性校验 |
| 测试 | 良。≥80% 覆盖率门禁 + e2e，但文档数据口径漂移 |
| 文档一致性 | 中。版本三轨一致，但测试数量口径混用、规则集副本已分叉 |

**整体评级：中上（B+）**。工程质量在同类工具中属较高水平，风险集中在**应用（Apply）流程的正确性与备份恢复的数据安全**，以及**当前工作区导致的 CI 阻断状态**。

---

## 二、P1 — 重要问题（建议尽快修复）

### P1-1 Apply 异常时 `isBusy` 永久锁死，全部按钮失效
- 位置：`app/lib/state/apply_flow.dart:49-163`（尤其 `:142`、`:160`）
- 现象：`apply()` 未用整体 `try/finally`。清单重写 `writeAsString`（:142）与 `refreshCompliance()`（:160）都在 try 块之外。任一抛异常 → `:162 finish()` 不执行 → `isBusy` 恒为 `true`。
- 原因：对比 `scan_flow.dart:83-122` 的 `try/catch/finally` 结构，Apply 缺少同等的最终兜底；而清单写入、合规重算都是可能失败（权限/损坏文件/磁盘满）的 I/O。
- 建议：将 `apply()` 主体包入 `try { ... } catch { 记录失败状态行+error 日志 } finally { finish(); }`，确保任何路径都释放忙碌状态。

### P1-2 清单重写绕过 `force` 且在取消判定之前执行
- 位置：`app/lib/state/apply_flow.dart:129-144`
- 现象：`if (!preview && (replaced>0 || errors>0))` 时无条件剔除不存在的路径并回写清单，**不检查 `force`**；且该段在 `result.cancelled` 检查（:146）**之前**执行。
- 原因：`applier.dart:8,126-132` 明确契约「stale path 仅在 force 时清理」，并返回 `result.cleaned`；此处另行实现清理，绕过了服务层契约。用户中途点"停止"后清单仍被改写，与 PROP-1/PROP-16「停止即不再写入」的承诺冲突。
- 建议：仅当 `force` 为真时清理失效路径；把 `if (result.cancelled) return` 上移到清单重写之前；或直接依据 `result.cleaned` 决定是否回写，避免两处逻辑分叉。

### P1-3 单个坏文件导致整批 Apply 中断
- 位置：`app/lib/services/applier.dart:135`
- 现象：`sha256OfString(await target.readAsString())` 位于循环内、但在 `try`（:146-162）之外。某个 `.stignore` 编码非法、被占用或无权限时，`readAsString()` 抛 `FileSystemException` 会冒泡终止整个循环。
- 原因：项目文档与日志设计声称"逐文件容错、跳过失败"，但读取阶段未纳入保护。
- 建议：把哈希读取纳入 `try/catch`，失败时 `errors++`、`log('errorWriting::…','error')` 并 `continue`；对超大文件可考虑流式哈希 + 大小上限。

### P1-4 备份恢复可能删除待恢复的备份，导致恢复失败
- 位置：`app/lib/services/backup_manager.dart:57-68`
- 现象：`restore()` 先对当前 target 复制成新 `.bak.$ts`（:63-64）并 `limitBackups()` 轮转（:65），**然后**才执行 `File(entry.bakPath).copy(entry.target)`（:67）。
- 原因：若要恢复的 `entry.bakPath` 恰是轮转范围的较旧备份，:65 可能先把它删除，:67 随即 `FileNotFoundException`。轮转顺序与恢复顺序颠倒。
- 建议：先校验 `entry.bakPath` 存在 → 执行恢复 → 最后再轮转；并在轮转时显式排除 `entry.bakPath`。

### P1-5 工作区规则集副本分叉 + 未跟踪重复文件（CI 会阻断）
- 位置：根目录 `.stignore` vs `app/assets/.stignore`；`?? app/lib/services/window_bounds.dart`
- 现象：
  - 根 `.stignore` 版本头 `1.18.6`/`Updated 2026-11-19`、多一条 `**/.sync/`；`app/assets/.stignore` 仍为 `1.18.5`/`2026-09-22`。CI `validate` 作业自 v1.23.1 起要求两者**完全一致即阻断**，当前状态会红。
  - `services/window_bounds.dart`（未跟踪）与已跟踪的 `window_bounds_service.dart` 内容约 95% 重复（仅少 `isWindowGeometrySupported()`），且全仓无任何代码 import 前者——是重复死文件。
- 原因：并行改动未同步打包副本；重命名遗留文件未清理。
- 建议：确认两处改动的意图后统一版本头并同步资产副本；删除未跟踪的 `window_bounds.dart` 或将其改动合并进 `window_bounds_service.dart`。**此项涉及你的未提交改动，请人工决定处理方式，审查未擅自改动。**

---

## 三、P2 — 建议改进

| # | 位置 | 问题与原因 | 建议 |
|---|------|-----------|------|
| P2-1 | `services/updater_script.dart:67`、`update_installer.dart:80` | 更新包仅校验 4 字节 zip 魔数，无 SHA256/签名；`Expand-Archive -Force` 覆盖应用目录 | 对归档计算并校验 CHANGELOG/Release 提供的 SHA256；显式检查条目路径无 `..` 穿越 |
| P2-2 | `services/settings_store.dart:75` | `lang` 仅判 `is String`，任意字符串可写入，而 `AppSettings` 契约限定 `en`/`zh` | 加枚举白名单，非法值回退默认（对齐全局"语言偏好枚举校验"规则） |
| P2-3 | `services/http_client.dart:18-27` | `connectionTimeout` 由 `??=` 在首次创建时固化，后续传入的不同超时被静默忽略 | 去掉参数或改为可变配置；调用点目前均为默认 15s，暂无实害但 API 语义有陷阱 |
| P2-4 | `services/scanner.dart:182`、`:78` | `maxThreads<=0` 时 `i += maxThreads` 死循环；主遍历 `listSync()` 全量驻留，巨目录内存峰值高 | 入口钳制 `maxThreads>=1`；主遍历改流式 `list()` 消费 |
| P2-5 | `state/results_view_state.dart:93`、`ui/results_filter.dart:35-38` | header 与列表各执行一次 `filterResults`，每次对最多 5000 路径同步 `isDirectorySync`；搜索按键触发两次全量 stat | 缓存过滤结果与类型判定，或在一次过滤中复用 |
| P2-6 | `state/log_state.dart:43-46` | `clearLog()` 直接 `notifyListeners()`，但 `_notifyScheduled` 可能仍为 `true`，同帧二次通知或回调状态错乱 | 统一走 `_scheduleNotify()` |
| P2-7 | `state/ruleset_state.dart:71` | `RulesetInfo.parse(stored)` 在 try 之外，畸形磁盘内容理论上可中断 `main.dart` 的 `Future.wait` | 纳入 try 并回退内置规则 |
| P2-8 | `services/scanner.dart`（208 行） | 唯一超过项目「单文件 ≤200 行」红线的源码文件 | 将 isolate 编排/进度上报拆为子模块 |
| P2-9 | 文档 `tasks.md:12,15`、`project.md §9.3` | 测试数量口径混用：`116/116`、`90/90`、`30 个文件`；磁盘实为 29 单元 + 2 集成 = 31 文件 | 统一为实算口径并标注统计范围（`lib/` 或含 integration_test） |
| P2-10 | `services/update_installer.dart:64-79` | 下载异常时 `finally` 只 `close()` sink，半截 zip 留在临时目录 | 在 `catch` 中删除目标文件 |
| P2-11 | `ui/root_field.dart` | `onChanged` 直接赋值不 notify，"清除"按钮联动不及时；`build` 中写 controller | 用带 notify 的 setter，仅在值变化时镜像 |
| P2-12 | i18n 测试 | `i18n_zh.dart`/`i18n_en.dart` 实测 135 个 key 完全对齐（正面），但缺"key 集合相等"单测，未来易单边漂移 | 增加 key 集合相等断言 |

### 待确认（中低置信度）
- `state/pickers_state.dart:62` 使用 `Uint8List(0)` 但该文件未见 `import 'dart:typed_data'`（同项目 `ui/results_filter.dart:9` 有显式导入）。若 `file_picker 13.1.0` 未 re-export `dart:typed_data` 则编译失败。已发起 `flutter analyze`（转后台），结果待核；若确认缺失，按 P0 处理。

---

## 四、安全与校验专项结论

- ✅ 无 `cmd /c` 字符串拼接注入：`Process.start` 用参数数组，`psQuote()` 正确转义单引号（双写）
- ✅ 版本经 `version_util.dart` 正则 `^[0-9]+(\.[0-9]+)*$` 校验，阻断 `..`/`/` 路径穿越
- ✅ 下载 URL 固定为官方 HTTPS，三处网络调用共享超时客户端
- ⚠️ 更新归档缺完整性校验（P2-1）——唯一实质安全短板
- ⚠️ 语言偏好缺枚举校验（P2-2）

## 五、性能与资源专项结论

- ✅ isolate 每根并行（≤4）、Sliver 懒加载、日志 1000 条 + 结果 5000 条环形上限、进程级 HTTP 连接池、按帧合并通知——设计成熟
- ⚠️ 过滤路径的重复同步 `stat`（P2-5）、`listSync` 全量驻留（P2-4）为主要剩余热点

## 六、主要风险点（Top 3）

1. **Apply 流程状态机不变量被破坏**：P1-1（锁死）+ P1-2（停止后仍写清单）叠加，可能导致用户无法恢复 UI 控制权、且清单内容与用户预期不符。
2. **备份恢复的数据安全**：P1-4 在最需要可靠性的一键恢复路径上可能删错文件。
3. **规则集双副本分叉**：P1-5 会使 CI 阻断发布，并使"内置规则"与"生效规则"版本不一致。

## 七、修复优先级建议

1. 先处理 P1-5（工作区一致性，恢复 CI 绿灯）
2. 再修 P1-1 / P1-2 / P1-3 / P1-4（Apply + 备份正确性），并为每条补单测
3. 确认 `pickers_state.dart` 的 import 问题
4. 按节奏清理 P2 项，同步修正文档数据口径
