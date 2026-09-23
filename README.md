<p align="center"><img src="docs/assets/logo-128.png" alt="SyncthingIgnoreGUI" width="104" height="104"></p>

# Syncthing 忽略模式

> 开箱即用的 `.stignore` 规则集：21 个分类 · 329 条规则，自动排除系统文件、缓存、构建产物与应用数据。

![Version](https://img.shields.io/badge/version-v1.25.2-blue)
![CI](https://github.com/sutchan/Syncthing_Ignore_Patterns/actions/workflows/ci.yml/badge.svg)
![Updated](https://img.shields.io/badge/updated-2026--09--22-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)
![Categories](https://img.shields.io/badge/categories-21-blueviolet)

[中文](#中文说明) | [English](README_EN.md)

---

## 中文说明

- ✅ **21 分类 / 329 条规则**，覆盖系统、缓存、构建产物、数据库等噪音文件
- ✅ **开箱即用**：复制到同步根目录即可生效
- ✅ **中英双语文档**，附批量同步 GUI 工具
- ✅ **持续维护**，随生态更新规则

> `.stignore` 文件头 `Updated`（`2026-09-22`）是规则集修订日；工具发布版本见 CHANGELOG（当前 `v1.25.2`）。两者分别对应"规则集修订"与"工具发布"，不同步属正常。

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
| 5 | 版本控制系统 | `.svn/`、`.hg/`（`.git/` 默认同步，保留分支信息） |
| 6 | 包管理器缓存 | `node_modules/`、`.npm/`、`.venv/`、`.cargo/`、`.gradle/`、`.m2/`、`vendor/`、`.conda/`、`.uv/`、`.opam/` |
| 7 | 前端构建缓存 | `.next/`、`.nuxt/`、`.svelte-kit/`、`.vite/`、`.turbo/`、`.vercel/` |
| 8 | Python 与测试缓存 | `.pytest_cache/`、`.mypy_cache/`、`.ruff_cache/`、`.tox/`、`.ipynb_checkpoints/`、`.cypress/`、`.playwright/`、`.allure/` |
| 9 | C/C++ 与 Rust 构建 | `CMakeCache.txt`、`CMakeFiles/`、`cmake-build-*/`、`.clangd/` |
| 10 | JVM 与 Scala 构建 | `.bloop/`、`.metals/`、`.scala-build/`、`.mvn/` |
| 11 | IDE 与工具缓存 | `.idea/`、`.history/`、`.terraform/`、`.terragrunt-cache/`、`.helm/`、`.kube/` |
| 12 | 编辑器与开发工具 | `.vscode/`（保留 `settings.json`）、`.vim/`、`*.swp`、`*~`、`.cursor/`、`.claude/`、`.windsurf/`、`.aider/`、`*.iml` |
| 13 | 压缩包与分卷下载 | `*.part`、`*.aria2`、`*.crdownload`、`downloading/` |
| 14 | 虚拟化与容器 | `*.vmdk`、`*.qcow2`、`*.ova`、`.docker/`、`.vagrant/`、`.buildkit/`、`.podman/`、`.containerd/` |
| 15 | 媒体与播放器缓存 | `Spotify/`、`iTunes/Album Artwork/`、`PotPlayerMini*`、`.Spotlight-V100/` |
| 16 | 锁文件与日志 | `*.lock`（保留 `Cargo.lock`、`package-lock.json`、`yarn.lock`）、`*.log`、`nohup.out`、`.zsh_history`、`.bash_history` |
| 17 | 构建产物与语言输出 | `target/`、`dist/`、`build/`、`bin/`、`obj/`、`*.pyc`、`*.class`、`*.o` |
| 18 | 缓存与临时目录 | `(?i)**/cache/`、`temp/`、`tmp/`、`.cache/`、`thumbnails/`、`.eslintcache` |
| 19 | 浏览器与 Electron 缓存 | `Code Cache/`、`GPUCache/`、`ShaderCache/`、`IndexedDB/`、`blob_storage/` |
| 20 | 系统临时与缓存位置 | `/tmp/`、`/var/tmp/`、`/var/cache/`、`/Windows/Temp/`（根锚定） |
| 21 | AI 编码助手与 Vibecoding | `.codex/`、`.gemini/`、`.qwen/`、`.codeium/`、`.continue/`、`.cline/`、`.roo/`、`*.iml`、`.cody/`、`.trae/`、`.junie/`、`.supermaven/`、`.opencode/`、`.goose/`、`.openhands/`、`.augment/`、`.tabnine/`、`.qoder/`、`.workbuddy/`、`.amp/`（仅工具数据目录，不含 `CLAUDE.md` 等指令文件） |

> 提示一：第 17、18 类的 `dist/`、`build/`、`bin/`、`target/`、`cache/`、`temp/` 等是通用目录名，若需同步同名目录请删除对应行。
> 提示二：第 18 类用 `(?i)` 大小写不敏感，且只匹配**完整目录名**，`MyCacheFolder/`、`Template/`、`Tempura/` 不会被误伤。

### 自定义建议

```text
!**/keep-this/     // 白名单：强制同步某目录（覆盖上方忽略规则）
(?i)**.jpg         // 忽略大小写
(?d)**/temp/**     // 父目录删除时同步删除
```

在 Web 界面"忽略模式"预览中可验证匹配结果，确认无误再保存。

### 批量同步工具

项目提供两种实现，功能与行为一致（扫描 / 应用 / 备份轮转 / 中英双语 / 明暗主题）：

#### 方案一：Dart + Flutter 桌面版（推荐，主实现 · v1.25.2）

位于 `app/`，构建为独立 `.exe` 分发，目标机无需安装 PowerShell：

```bash
cd app
flutter config --enable-windows-desktop
flutter pub get
flutter build windows        # 产物：build/windows/x64/runner/Release/SyncthingIgnoreGUI.exe
```

- **界面**：根目录 / 清单路径输入、仅预览 / 强制 / 备份三项勾选、扫描 / 应用 / 停止 / 清空日志、进度条、结果与日志列表
- **语言 / 主题**：右上角切换 `English` / `中文` 与 `浅色` / `深色`，即时生效
- **扫描**：每根目录一个 isolate 并行（默认 4），跳过 `.git` 与规则源目录，无权限目录跳过并累计
- **应用**：SHA-256 比对跳过一致文件、写前 `.bak.<时间戳>` 备份、`<base>.bak.*` 轮转 ≤3、`force` 才清理失效路径
- **标准规则**：随 `assets/.stignore` 资源打包，运行时 `rootBundle` 加载；更新规则须同步该副本
- **拖拽填入**：把文件夹或 `.stignore` / `.json` 文件拖入窗口，即填入扫描根目录 / 清单路径（v1.25.0）
- **更新**：忽略清单可在线检查并下载最新版本；应用自身在「关于」中检查更新，并可一键下载安装（v1.25.0）
- **运行要求**：Windows 10/11 x64；发布包**已自带** Flutter AOT 运行时与 Visual C++ 运行库（`vcruntime140.dll` / `msvcp140.dll` / `vcruntime140_1.dll`），无需另装任何运行库；解压后直接运行 `SyncthingIgnoreGUI.exe`
- **发布包说明**：`SyncthingIgnoreGUI-vX.Y.Z-windows-x64.zip` 内含 `SyncthingIgnoreGUI.exe`、`flutter_windows.dll`、`data/`（`app.so` 与 `flutter_assets/`）、标准规则副本 `.stignore` 与上述 VC++ 运行库 DLL；**不含**调试符号（`*.pdb`/`*.exp`/`*.lib`）

#### 方案二：PowerShell WinForms（遗留 · 维护态 · v1.18.5）

`SyncthingIgnoreGUI.ps1` 单一自包含脚本，适用于未安装 Flutter 的环境：

```powershell
.\SyncthingIgnoreGUI.ps1                                   # 自动以 STA 线程重启（WinForms 必需）
powershell -STA -NoProfile -File .\SyncthingIgnoreGUI.ps1   # 等价写法
```

- **语言 / 主题**：左上角切换，实时生效并记忆到 `config.json`
- **扫描**：runspace 线程池（≤4 线程）+ `-Filter .stignore`；根目录留空扫描所有固定驱动器，支持拖拽填充
- **选项 / 清单**：仅预览 / 强制 / 写回前备份；清单默认 `config/stignore-paths.json`
- **实时状态**：扫描时显示「已完成根目录数 / 已找到文件数 / 当前目录 / 耗时」，结果边扫边出
- **其他**：后台执行不卡顿、双击结果打开文件、「停止」中止后台任务

```mermaid
flowchart LR
    A[扫描 Scan<br/>并行多驱动器/isolate] --> B[清单 stignore-paths.json<br/>备份轮转≤3]
    B --> C[应用 Apply<br/>写入标准规则<br/>逐文件备份≤3]
```

**备份轮转**：`.stignore.bak.<时间戳>` 与 `stignore-paths.json.bak.<时间戳>` 各**最多保留 3 个**，超出自动删除最旧的。

### 参与贡献

- [贡献指南](.github/CONTRIBUTING.md) — 规则集编写约定、架构红线与 PR 流程
- [行为准则](.github/CODE_OF_CONDUCT.md) · [安全策略](.github/SECURITY.md) · [获取帮助](.github/SUPPORT.md)

### 开源许可

基于 [MIT 许可证](LICENSE) 开源，全文见仓库根目录 [`LICENSE`](LICENSE)。
