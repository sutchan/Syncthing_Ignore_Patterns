# Syncthing 忽略模式

> 开箱即用的 `.stignore` 规则集：20 个分类 · 285 条规则，自动排除系统文件、缓存、构建产物与应用数据。

![Version](https://img.shields.io/badge/version-v1.16.2-blue)
![Updated](https://img.shields.io/badge/updated-2026--08--31-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)
![Categories](https://img.shields.io/badge/categories-20-blueviolet)

[中文](#中文说明) | [English](README_EN.md)

---

## 中文说明

- ✅ **20 分类 / 285 条规则**，覆盖系统、缓存、构建产物、数据库等噪音文件
- ✅ **开箱即用**：复制到同步根目录即可生效
- ✅ **中英双语文档**，附批量同步 GUI 工具
- ✅ **持续维护**，随生态更新规则

> `.stignore` 文件头 `Updated`（`2026-08-31`）是规则集修订日；工具发布版本见 CHANGELOG（当前 `v1.16.2`）。两者分别对应"规则集修订"与"工具发布"，不同步属正常。

### 快速开始

1. 下载 `.stignore`，放到 Syncthing 同步文件夹**根目录**
2. 重启 Syncthing 或触发重新扫描，模式在下次扫描时生效

也可在 Web 界面（默认 `http://localhost:8384`）→ 文件夹 → **编辑** → **忽略模式** 粘贴内容并保存，立即生效。

如需拆分维护，使用 `// #include` 引入外部文件：

```text
#include .stignore-base
// 下方写自定义规则
**/my-secret-folder
*.local
```

### 通配符语法

| 模式 | 说明 |
|------|------|
| `(?d)` | 父目录被删除时允许同步删除文件 |
| `(?i)` | 忽略大小写匹配 |
| `!` | 取反（重新包含） |
| `*` / `**` | 单级 / 多级通配符 |
| `//` | 注释 |

### 分类概览

完整规则见 `.stignore` 文件本身：

| # | 分类 | 典型规则 |
|---|------|---------|
| 1 | 系统与 OS 文件 | `$RECYCLE.BIN/`、`.DS_Store`、`Thumbs.db`、`desktop.ini`、`System Volume Information/` |
| 2 | 数据库文件 | `ibdata1`、`*.ibd`、`pg_wal/`、`*.sqlite3`、`*.db-wal`（不含通配 `*.db`） |
| 3 | 备份与临时文件 | `*.tmp`、`*.bak`、`.delete/`、`Backup_of_*`、`.stignore.bak.*` |
| 4 | 应用数据与缓存 | `.dropbox.cache/`、`WeChat Files/`、`BaiduNetdiskDownload/`、`SteamLibrary/`（保留 `.stfolder/`、`.stversions`） |
| 5 | 版本控制系统 | `.git/`、`.svn/`、`.hg/` |
| 6 | 包管理器缓存 | `node_modules/`、`.npm/`、`.venv/`、`.cargo/`、`.gradle/`、`.m2/`、`vendor/` |
| 7 | 前端构建缓存 | `.next/`、`.nuxt/`、`.svelte-kit/`、`.vite/`、`.turbo/`、`.vercel/` |
| 8 | Python 与测试缓存 | `.pytest_cache/`、`.mypy_cache/`、`.ruff_cache/`、`.tox/`、`.ipynb_checkpoints/` |
| 9 | C/C++ 与 Rust 构建 | `CMakeCache.txt`、`CMakeFiles/`、`cmake-build-*/`、`.clangd/` |
| 10 | JVM 与 Scala 构建 | `.bloop/`、`.metals/`、`.scala-build/`、`.mvn/` |
| 11 | IDE 与工具缓存 | `.idea/`、`.history/`、`.terraform/`、`.terragrunt-cache/`、`.helm/`、`.kube/` |
| 12 | 编辑器与开发工具 | `.vscode/`（保留 `settings.json`）、`.vim/`、`*.swp`、`*~`、`.cursor/` |
| 13 | 压缩包与分卷下载 | `*.part`、`*.aria2`、`*.crdownload`、`downloading/` |
| 14 | 虚拟化与容器 | `*.vmdk`、`*.qcow2`、`*.ova`、`.docker/`、`.vagrant/` |
| 15 | 媒体与播放器缓存 | `Spotify/`、`iTunes/Album Artwork/`、`PotPlayerMini*`、`.Spotlight-V100/` |
| 16 | 锁文件与日志 | `*.lock`（保留 `Cargo.lock`、`package-lock.json`、`yarn.lock`）、`*.log`、`nohup.out` |
| 17 | 构建产物与语言输出 | `target/`、`dist/`、`build/`、`bin/`、`obj/`、`*.pyc`、`*.class`、`*.o` |
| 18 | 缓存与临时目录 | `(?i)**/cache/`、`temp/`、`tmp/`、`.cache/`、`thumbnails/`、`.eslintcache` |
| 19 | 浏览器与 Electron 缓存 | `Code Cache/`、`GPUCache/`、`ShaderCache/`、`IndexedDB/`、`blob_storage/` |
| 20 | 系统临时与缓存位置 | `/tmp/`、`/var/tmp/`、`/var/cache/`、`/Windows/Temp/`（根锚定） |

> 提示一：第 17、18 类的 `dist/`、`build/`、`bin/`、`target/`、`cache/`、`temp/` 等是通用目录名，若需同步同名目录请删除对应行。
> 提示二：第 18 类用 `(?i)` 大小写不敏感，且只匹配**完整目录名**，`MyCacheFolder/`、`Template/`、`Tempura/` 不会被误伤。

### 自定义建议

```text
!**/.git/          // 白名单：.git 继续同步
(?i)**.jpg         // 忽略大小写
(?d)**/temp/**     // 父目录删除时同步删除
```

在 Web 界面"忽略模式"预览中可验证匹配结果，确认无误再保存。

### 批量同步工具

`SyncthingIgnoreGUI.ps1` 是单一自包含脚本（WinForms），把标准规则批量应用到全机所有 Syncthing 目录，**无需每次全盘扫描**：

```powershell
.\SyncthingIgnoreGUI.ps1                                   # 自动以 STA 线程重启（WinForms 必需）
powershell -STA -NoProfile -File .\SyncthingIgnoreGUI.ps1   # 等价写法
```

- **语言**：左上角切换 `English` / `中文`，实时生效并记忆到 `config.json`（中文以 `\u` 转义内嵌，脚本保持纯 ASCII）
- **主题**：`浅色` / `深色` 即时换肤，选择持久化
- **扫描**：runspace 线程池（≤4 线程）+ `-Filter .stignore`；根目录留空则扫描所有固定驱动器，支持拖拽填充
- **选项**：`仅预览`（不写文件）、`强制`（跳过逐文件确认）、`写回清单前备份`
- **清单**：默认 `config/stignore-paths.json`，记录路径/大小/修改时间；规则一致自动跳过，失效路径需 `强制` 才清理
- **其他**：后台执行不卡顿（进度条显示真实百分比）、结果列表双击打开文件、「停止」可中止后台任务、底部状态栏显示版本与项目链接

```mermaid
flowchart LR
    A[扫描 Scan<br/>并行多驱动器] --> B[清单 stignore-paths.json<br/>备份轮转≤3]
    B --> C[应用 Apply<br/>写入标准规则<br/>逐文件备份≤3]
```

**备份轮转**：`.stignore.bak.<时间戳>` 与 `stignore-paths.json.bak.<时间戳>` 各**最多保留 3 个**，超出自动删除最旧的。

### 参与贡献

- [贡献指南](.github/CONTRIBUTING.md) — 规则集编写约定、架构红线与 PR 流程
- [行为准则](.github/CODE_OF_CONDUCT.md) · [安全策略](.github/SECURITY.md) · [获取帮助](.github/SUPPORT.md)

### 开源许可

基于 [MIT 许可证](https://opensource.org/licenses/MIT) 开源。
