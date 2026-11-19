## 变更类型

- [ ] `feat` 新功能 / 新规则
- [ ] `fix` 修复缺陷
- [ ] `docs` 文档更新
- [ ] `refactor` 重构（不改变外部行为）
- [ ] `perf` 性能优化
- [ ] `chore` 版本升级 / 配置变更

关联 Issue：Closes #

## 变更说明

<!-- 改了什么、为什么改、影响范围 -->

## 检查清单

### 规则集（改动 `.stignore` 时）

- [ ] 遵循编写约定：分类注释 `//Name`、说明注释 `// NOTE:`、目录模式带尾 `/`、文件模式 `**/*.ext`
- [ ] `!` 取反行紧跟对应正向行
- [ ] 未忽略 `.stfolder/` 与 `.stversions`
- [ ] 未引入宽泛通配；大小写不敏感场景用 `(?i)` + 完整目录名
- [ ] 已在 Syncthing「忽略模式」预览中验证命中与不误伤

### Flutter 主实现（改动 `app/` 时）

- [ ] `flutter analyze` 零告警、`flutter test` 全量通过、行覆盖率 ≥80%
- [ ] 单文件 ≤200 行；主要容器补语义化 Key
- [ ] 新增/改动文案已同步 `i18n_zh.dart` 与 `i18n_en.dart`（key 齐全）

### GUI 脚本（改动 `SyncthingIgnoreGUI.ps1` 时）

- [ ] 文件为纯 ASCII，中文以 `\uXXXX` 转义（未破坏编码）
- [ ] 无 PowerShell 5.1 不支持的 PS7 专有语法
- [ ] 新增界面文案中英双份齐全
- [ ] 跨线程更新控件走 `form.Invoke`；未直接捕获可能为 null 的控件变量
- [ ] 本地实际启动 GUI 验证通过

### 版本与文档（按改动轨道同步）

- [ ] Flutter 主实现：`VERSION` / `app/pubspec.yaml` / `AppState.version` / README 徽章 / `docs/project.md` / `docs/tasks.md` 一致
- [ ] PowerShell 遗留版：`SyncthingIgnoreGUI.ps1` 文件头 `//Version` 与 `$ScriptVersion` 已升级
- [ ] 规则集：根 `.stignore` 与 `app/assets/.stignore` 完全一致（含 `//Version`/`//Updated` 头）
- [ ] `README.md` 与 `README_EN.md`：徽章与正文版本引用已同步
- [ ] 根目录 `CHANGELOG.md` 与 `docs/project.md` §7 均已追加版本小节
- [ ] 未改动的文件未批量刷写头注释版本号
