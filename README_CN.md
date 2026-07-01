# Syncthing 忽略模式

[English](README.md) | [中文](#中文说明)

---

## 中文说明

### 概述

精心整理的 Syncthing 忽略模式（`.stignore`）集合，帮助您只同步需要的文件。本仓库提供了一份全面、分类清晰的 `.stignore` 文件，可将系统文件、缓存目录、构建产物和应用数据排除在 Syncthing 同步之外。

Syncthing 使用每个同步文件夹内的 `.stignore` 文件来定义哪些文件和文件夹应排除在同步之外。您可以通过 Syncthing Web 界面（配置 → 忽略模式）进行设置，或直接编辑 `.stignore` 文件。

### 通配符语法

| 模式 | 说明 |
|------|------|
| `(?d)` | 前缀，表示如果删除了阻止目录则文件可被删除 |
| `(?i)` | 前缀，表示该模式匹配时忽略大小写差异 |
| `!` | 取反条件（例如：`!**/.git/` 表示不要排除 `.git` 文件夹） |
| `*` | 单级通配符（仅匹配单层文件夹） |
| `**` | 多级通配符（用以匹配多层嵌套文件夹） |
| `//` | 注释（行首使用） |

### 已包含的忽略模式分类

`.stignore` 文件按以下章节组织：

#### 1. 通用排除项

各平台通用的系统文件、回收站和临时文件。

- **系统文件**：`.DS_Store`、`desktop.ini`、`Thumbs.db`、`pagefile.sys`、`swapfile.sys`、`~$*`（Office 临时文件）
- **回收站**：`$RECYCLE.BIN`、`@Recycle`、`.Recovery`、`.Recycle_bin`、`trashbox*`、`LOST.DIR/`
- **临时/缓存文件**：`.tmp`、`.cache`、`.log`、`.crdownload`、`.bak`、`.delete`
- **版本控制**：`.git/`、`.sync/`
- **云同步内部文件**：`.dropbox.cache/`、`.stfolder/`、`.stversions`、`sync.ffs_db`
- **应用数据**：微信文件、QQ、百度网盘、阿里工作台、腾讯文件、优酷文件
- **系统目录**：`Program Files/`、`Program Files (x86)/`、`System Volume Information/`

#### 2. 包管理器缓存与依赖

- **Node.js**：`.npm/`、`.pnpm-store/`、`.pnpm-local-store`、`.yarn/cache/`、`.bun/`、`node_modules/`
- **Python**：`.venv/`、`__pycache__/`、`.ipynb_checkpoints/`
- **Rust**：`.cargo/`
- **Java/JVM**：`.gradle/`、`.m2/`
- **.NET**：`.nuget/`
- **Deno**：`.deno/`
- **Dart/Flutter**：`.dart_tool/`、`.pub-cache/`
- **Haskell**：`.stack-work/`

#### 3. 构建产物

- **目录**：`bin/`、`build/`、`dist/`、`out/`、`output/`、`target/`、`vendor/`
- **二进制文件**：`*.exe`、`*.dll`、`*.so`、`*.dylib`、`*.a`、`*.lib`、`*.o`、`*.obj`、`*.pyc`、`*.pyo`

#### 4. 前端框架构建缓存

- **Astro**：`.astro/`
- **Next.js**：`.next/`
- **Nuxt**：`.nuxt/`
- **SvelteKit**：`.svelte-kit/`
- **Vite**：`.vite/`、`.turbo/`
- **Parcel**：`.parcel-cache/`
- **Docusaurus**：`.docusaurus/`
- **VuePress**：`.vuepress/dist/`
- **部署平台**：`.vercel/`、`.netlify/`

#### 5. Python 与测试缓存

- **Python**：`.eggs/`、`.coverage`、`htmlcov/`
- **测试框架**：`.pytest_cache/`、`.jest-cache/`、`.vitest/`、`.nyc_output/`、`.tox/`、`.nox/`
- **类型检查**：`.mypy_cache/`、`.ruff_cache/`
- **Jupyter**：`.ipynb_checkpoints/`

#### 6. C/C++ 与 Rust 构建缓存

- **CMake**：`CMakeCache.txt`、`CMakeFiles/`、`cmake-build-debug/`、`cmake-build-release/`
- **编译器**：`compile_commands.json`、`.ccls-cache/`、`.clangd/`
- **Rust**：`.rustc_cache/`

#### 7. JVM 与 Scala 构建缓存

- **Scala**：`.ammonite/`、`.bloop/`、`.metals/`
- **Kotlin**：`.kotlintest/`

#### 8. IDE 与工具缓存

- **JetBrains**：`.idea/`
- **VS Code**：`.vscode/`、`.vs/`、`.history/`
- **基础设施**：`.terraform/`、`.terragrunt-cache/`、`.helm/`、`.kube/`、`.flyway/`

#### 9. 锁文件与日志

- `*.lock`、`*.log.*`

### 使用方法

1. **复制文件**：将本仓库中的 `.stignore` 文件复制到您的 Syncthing 同步文件夹根目录
2. **或使用 Web 界面**：打开 Syncthing Web 界面 → 点击文件夹 → "Ignored Files" → 粘贴模式内容
3. **实时生效**：模式会立即应用；Syncthing 将重新扫描以强制执行这些规则

### 示例

```
// 递归排除回收站文件夹
**$RECYCLE.BIN

// 排除 macOS 系统文件
**.DS_Store

// 排除 Windows 缩略图缓存
**Thumbs.db

// 递归排除 node_modules
**/node_modules/*

// 排除临时/下载文件
**.tmp
**.crdownload

// 忽略大小写匹配
(?i)**.JPG
```

### 项目结构

```
SyncthingIgnorePatterns/
├── .stignore                              # 忽略模式文件
├── .gitignore                             # Git 忽略规则
├── README.md                              # 英文文档
├── README_CN.md                           # 中文文档
└── SyncthingIgnorePatterns.code-workspace # VS Code 工作区配置
```

### 开源许可

本项目为开源项目，基于 MIT 许可证发布。
