# 性能基准报告（v1.28.0）

> 本文用可复现的实测数据量化 v1.28.0 的三项优化：①日志/结果缓冲上限、
> ②进程级共享 `HttpClient`、③`CustomScrollView` + Sliver 单滚动布局。
> 基准脚本与基准测试均纳入仓库，任何提交都可重新运行核对。

## 1. 测试环境

| 项 | 值 |
|----|----|
| 操作系统 | Microsoft Windows 11 IoT 企业版 LTSC（x64） |
| CPU | Intel64 Family 6 Model 85 Stepping 4 |
| Flutter / Dart | Flutter 3.40.0-0.2.pre（beta）/ Dart 3.11.0-200.1.beta |
| 测量日期 | 2026-09-30 |

数据与具体机器相关，关注**量级与倍数**而非绝对值；跨机器对比请在同一环境重跑。

## 2. 复现方法

```bash
cd app
dart run tool/perf_benchmark.dart       # 缓冲策略 + HTTP 连接复用（纯 Dart）
flutter test test/perf_layout_bench_test.dart  # 首帧构建计数（需 Flutter 引擎）
```

- 纯 Dart 基准：[`app/tool/perf_benchmark.dart`](../app/tool/perf_benchmark.dart)
- 布局基准（兼性能回归守卫）：[`app/test/ui/perf_layout_bench_test.dart`](../app/test/ui/perf_layout_bench_test.dart)

## 3. 日志缓冲：增长式复制 → 环形上限

v1.28.0 之前，每条日志执行 `_logs = [..._logs, LogEntry(...)]`：为让
`context.select` 感知身份变化，每次追加都**整表复制**，复制成本随已缓冲行数
线性增长（整次运行为 O(n²)），且缓冲无上限。v1.28.0 复制后裁剪到最新
`maxLogEntries = 1000` 条，单次追加成本恒定，占用有界。

基准：模拟 50,000 次追加（约对应一次触及 5 万个文件的 Apply，压力量级），
每条消息为 ~104 字符的真实形态字符串（路径 + SHA-256 摘要）。

| 策略 | 50,000 次追加耗时 | 保留条目 | 保留字符数 |
|------|------------------:|---------:|-----------:|
| 旧（无上限，整表复制） | 52,035 ms | 50,000 | 5,178,890 |
| 新（上限 1,000，裁剪） | 754 ms | 1,000 | 103,800 |
| **差异** | **约 69×** | 50× | **约 50× 更少** |

说明：日常 Apply 通常数百个文件，旧策略在该量级尚可接受；但成本随规模二次
增长，超大目录（映射网络盘上数万同步目录）会把 Apply 的 CPU 消耗在列表复制
上。上限后每次追加只复制 ≤1000 个引用，与运行总规模无关。

## 4. 扫描结果：无界保留 → 5,000 条上限

扫描结束时一次性替换结果列表（`replaceResults`），耗时两者相近（单次复制
10 ms 量级），差异在**内存保留量**。基准：一次替换 200,000 条路径。

| 策略 | 替换耗时 | 保留条目 | 保留字符数 |
|------|---------:|---------:|-----------:|
| 旧（无上限） | 11 ms | 200,000 | 20,848,890 |
| 新（上限 5,000） | 9 ms | 5,000 | 524,000 |
| **差异** | 持平 | 40× | **约 40× 更少** |

清单文件（`stignore-paths.json`）仍保留**全部**记录，内存上限只影响 UI
列表；基准验证裁剪后最后一条仍为最新扫描结果。

## 5. HTTP：每请求新客户端 → 共享 keep-alive 连接池

v1.28.0 之前每处网络调用（规则集更新检查、应用更新检查、安装包下载）都
`HttpClient()` 新建并在 `finally` 中 `close()`，连接池随客户端一起丢弃，
每次请求都重新建立 TCP 连接。v1.28.0 起共用进程级
[`sharedHttpClient`](../app/lib/services/http_client.dart)（15 s 连接超时 /
30 s 空闲保活）。

基准：本机 loopback `HttpServer` 返回 ~1 KiB JSON，100 个顺序 GET × 5 轮
（各 20 次预热不计），服务端按客户端 TCP 端口统计新建连接数。

| 策略 | 每轮中位耗时 | 单请求均耗时 | 每轮新建 TCP 连接 |
|------|-------------:|-------------:|------------------:|
| 旧（每请求新建并关闭客户端） | 353 ms | 3.53 ms | 100 |
| 新（共享 keep-alive 客户端） | 181 ms | 1.81 ms | 2 |
| **差异** | **约 1.95×** | — | **50× 更少** |

连接数从 100 降到 2（客户端在连接池首请求竞态时建立第 2 条，随后持续
复用），直接证明连接被复用而非反复握手。loopback 只含 TCP 握手；真实更新
源（GitHub API / raw 文件，HTTPS）每次新连接还需额外支付 TLS 握手
（通常 1–2 个 RTT + 非对称加密计算），公网环境的实际收益**大于**本机
测得的 1.95×。

## 6. 界面布局：嵌套定高 ListView → 单滚动 Sliver

v1.28.0 之前页面为 `SingleChildScrollView` > `Column`，内嵌两个定高
（160 / 200 px）`ListView.builder`。它们各自是独立视口：首帧布局时即使
整块列表在屏幕折叠线以下，两个内部视口仍会分别构建各自窗口（含
`cacheExtent`）内的行，且页面与列表滚动位置相互独立。v1.28.0 起改为单一
`CustomScrollView`：表单为 `SliverToBoxAdapter`，结果/日志为
`SliverList.builder`，行只在进入真实视口时构建。

基准（widget test，视口 800×600，表单占位高 560 px 使两个列表首帧均在
折叠线以下；结果行高 24 px × 10,000 行，日志行高 18 px × 1,000 行）：

| 布局 | 首帧构建结果行 | 首帧构建日志行 | 首帧合计 |
|------|---------------:|---------------:|---------:|
| 旧（嵌套定高 ListView） | 17 | 25 | **42** |
| 新（Sliver 单滚动） | 13 | 1 | **14** |

- 旧布局两个离屏视口合计白建 42 行；新布局仅构建真实视口 + 缓存区内的
  13 个结果行，日志区仅 1 行——该行是 `RenderSliverList` 为估算滚动范围
  构建的末端探测行，非视口窗口。
- 向下拖拽 500 px 后：新布局累计构建结果行 33（按需增量），日志行仍为 1。
- 定性收益：结果/日志不再被锁死在 160/200 px 的小窗里，整页共享一个滚动
  位置；列表越长，首帧与滚动构建量的优势越大。

基准测试同时是**回归守卫**：断言日志区首帧构建 ≤1 行、结果区 <30 行，
一旦回退为嵌套视口结构即失败。

## 7. 测量口径与局限

- **字符数 ≠ 堆内存**：表中字符数为字符串逻辑长度，未计 `LogEntry`/`List`
  对象开销与 Dart 堆碎片；保留量用于对比量级，进程 RSS 受 GC 时机影响不
  具备可重复性，故不采用。
- **HTTP 基准走 loopback**：排除了网络 RTT 与 TLS 握手，公网 HTTPS 场景的
  收益被低估（见 §5）。
- **界面基准为结构等价夹具**：固定行高、表单以占位块替代，用于隔离"构建
  多少行"这一调度行为；真实行内容（图标、文本布局）成本更高，方向一致。
- 基准数据为单台机器单次采集；HTTP 轮次已取 5 轮中位数，其余为确定性
  算法级对比。重跑命令见 §2。

## 8. 相关代码

| 文件 | 关联优化 |
|------|----------|
| [`app/lib/state/log_state.dart`](../app/lib/state/log_state.dart) | `maxLogEntries = 1000`，追加后裁剪最旧 |
| [`app/lib/state/progress_state.dart`](../app/lib/state/progress_state.dart) | `maxResultEntries = 5000`，仅 UI 列表有界 |
| [`app/lib/services/http_client.dart`](../app/lib/services/http_client.dart) | 进程级共享 `HttpClient`（连接池 / 15 s / 30 s） |
| [`app/lib/ui/home_page.dart`](../app/lib/ui/home_page.dart) | 单一 `CustomScrollView`（表单盒 + 结果/日志 Sliver） |
| [`app/lib/ui/results_list.dart`](../app/lib/ui/results_list.dart) / [`log_list.dart`](../app/lib/ui/log_list.dart) | `SliverList.builder` 懒加载区段 |
