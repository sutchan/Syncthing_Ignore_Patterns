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

### GUI 脚本（改动 `SyncthingIgnoreGUI.ps1` 时）

- [ ] 文件为纯 ASCII，中文以 `\uXXXX` 转义（未破坏编码）
- [ ] 无 PowerShell 5.1 不支持的 PS7 专有语法
- [ ] 新增界面文案中英双份齐全
- [ ] 跨线程更新控件走 `form.Invoke`；未直接捕获可能为 null 的控件变量
- [ ] 本地实际启动 GUI 验证通过

### 版本与文档（所有改动）

- [ ] `SyncthingIgnoreGUI.ps1`：文件头 `//Version` 与 `$ScriptVersion` 已升级
- [ ] `.stignore`：文件头 `//Version` 已升级
- [ ] `README.md` 与 `README_EN.md`：徽章与正文版本引用已同步
- [ ] `openspec/project.md`：第 3 节注记 + 第 7 节 CHANGELOG 已同步
- [ ] 根目录 `CHANGELOG.md` 已追加版本小节（与 openspec §7 双副本一致）
- [ ] 未改动的文件未批量刷写头注释版本号
