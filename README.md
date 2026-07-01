# Syncthing 忽略模式

[中文](#中文说明) | [English](README_EN.md)

---

## 中文说明

精心整理的 `.stignore` 集合，可将系统文件、缓存、构建产物和应用数据排除在 Syncthing 同步之外。

**当前版本：v1.0.0**（更新于 2026-07-01）

### 通配符语法

| 模式 | 说明 |
|------|------|
| `(?d)` | 删除阻止目录时允许删除文件 |
| `(?i)` | 忽略大小写匹配 |
| `!` | 取反（包含此模式） |
| `*` | 单级通配符 |
| `**` | 多级通配符 |
| `//` | 注释 |

### 已包含的分类

`.stignore` 文件按以下 11 个分类组织（完整内容请查看文件本身）：

1. **系统与 OS 文件** — `$RECYCLE.BIN`、`.DS_Store`、`Thumbs.db`、`desktop.ini`、`pagefile.sys`、`Program Files/`、`System Volume Information/`、`LOST.DIR/` 等
2. **备份与临时文件** — `.cache`、`.tmp`、`.delete`、`Temp/`、`Backup_of_*` 等
3. **应用数据与缓存** — `.stfolder/`、`.stversions`、`.dropbox.cache/`、`WeChat Files/`、`Tencent Files/`、`BaiduNetdiskDownload/`、`AliWorkbenchData/`、`Youku Files/`、`SteamLibrary/` 等
4. **版本控制系统** — `.git/`
5. **包管理器缓存与依赖** — `node_modules/`、`.npm/`、`.pnpm-store/`、`.venv/`、`__pycache__/`、`.cargo/`、`.gradle/`、`.m2/`、`.nuget/`、`.bun/`、`.deno/`、`.dart_tool/`、`.stack-work/` 等
6. **前端框架构建缓存** — `.next/`、`.nuxt/`、`.svelte-kit/`、`.vite/`、`.turbo/`、`.astro/`、`.docusaurus/`、`.parcel-cache/`、`.vercel/`、`.netlify/`、`.vuepress/dist/` 等
7. **Python 与测试缓存** — `.pytest_cache/`、`.mypy_cache/`、`.ruff_cache/`、`.coverage`、`.jest-cache/`、`.vitest/`、`.tox/`、`.nox/`、`.ipynb_checkpoints/`、`htmlcov/` 等
8. **C/C++ 与 Rust 构建缓存** — `CMakeCache.txt`、`CMakeFiles/`、`cmake-build-debug/`、`cmake-build-release/`、`compile_commands.json`、`.ccls-cache/`、`.clangd/`、`.rustc_cache/` 等
9. **JVM 与 Scala 构建缓存** — `.ammonite/`、`.bloop/`、`.metals/`、`.kotlintest/`
10. **IDE 与工具缓存** — `.idea/`、`.history/`、`.terraform/`、`.terraform.lock.hcl`、`.terragrunt-cache/`、`.helm/`、`.kube/`、`.flyway/` 等
11. **锁文件与日志文件** — `*.lock`、`*.log.*`、`**.log`

### 使用方法

#### 前置条件

- 已安装并运行的 [Syncthing](https://syncthing.net/) 实例
- 至少配置了一个同步文件夹

#### 方法一：直接复制文件

1. 从本仓库下载 `.stignore` 文件
2. 将其放置在 Syncthing 同步文件夹的**根目录**
3. 重启 Syncthing 或触发重新扫描 — 模式将在下次扫描时生效

#### 方法二：通过 Syncthing Web 界面

1. 打开 Syncthing Web 界面（默认地址：`http://localhost:8384`）
2. 点击目标文件夹 → **编辑** → **忽略模式（Ignore Patterns）**
3. 将 `.stignore` 内容粘贴到编辑框中
4. 点击 **保存** — 模式立即生效并触发重新扫描

#### 方法三：引入外部文件

Syncthing 支持 `// #include` 指令，可将模式拆分到多个文件中：

```
// 引入本仓库的模式
#include .stignore-base

// 在下方添加您的自定义规则
**/my-secret-folder
*.local
```

#### 自定义建议

- **白名单**：使用 `!` 重新包含模式，例如 `!**/.git/` 可让 `.git` 文件夹继续同步
- **忽略大小写**：使用 `(?i)` 前缀，例如 `(?i)**.jpg` 可匹配 `.JPG`、`.jpg`、`.Jpg`
- **安全删除**：使用 `(?d)` 前缀，允许在父目录被删除时同步删除文件
- **注释**：以 `//` 开头的行会被忽略，可用于规则说明
- **提交前测试**：在 Web 界面的"忽略模式"预览中验证哪些文件被匹配

#### 验证生效

应用模式后：

1. 打开 Syncthing Web 界面 → 文件夹 → **忽略模式** 确认规则已加载
2. 检查文件夹状态 — 匹配模式的文件不应再出现在同步队列中
3. 使用 **最近更改** 验证被忽略的文件未被同步

### 示例

```
// 递归排除回收站
**$RECYCLE.BIN

// macOS 系统文件
**.DS_Store

// node_modules
**/node_modules/*

// 忽略大小写匹配
(?i)**.JPG

// 白名单 .git 文件夹
!**/.git/
```

### 开源许可

MIT
