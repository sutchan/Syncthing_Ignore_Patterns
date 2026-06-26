# Syncthing Ignore Patterns / Syncthing 忽略模式

A curated collection of Syncthing ignore patterns (.stignore) to help you sync only the files you need.

精心整理的 Syncthing 忽略模式 (.stignore) 集合，帮助您只同步需要的文件。

---

## Table of Contents / 目录

- [English](#english)
- [中文说明](#中文说明)

---

## English

### Overview

Syncthing uses `.stignore` files in each sync folder to define which files and folders to exclude from synchronization. You can configure these patterns either through the Syncthing Web GUI (Config → Ignore Patterns) or by directly editing the `.stignore` file.

### Supported Pattern Syntax

| Pattern | Description |
|---------|-------------|
| `(?d)` | Prefix that allows files to be deleted if the blocked parent directory is removed |
| `(?i)` | Case-insensitive matching prefix |
| `!` | Negation — include this pattern (e.g., `!**/.git/` to sync `.git` folders) |
| `*` | Single-level wildcard (matches one directory level only) |
| `**` | Multi-level wildcard (matches across nested directories) |
| `//` | Comment — lines starting with `//` are ignored |

### Examples

```
// Exclude Recycle Bin folders recursively
**$RECYCLE.BIN

// Exclude macOS system files
**.DS_Store

// Exclude Windows thumbnail caches
**Thumbs.db

// Exclude node_modules recursively
**/node_modules/*

// Exclude temporary/download files
**.tmp
**.crdownload
```

### Included Patterns

This repository contains a comprehensive `.stignore` file covering:

- **System files**: `.DS_Store`, `desktop.ini`, `Thumbs.db`, `pagefile.sys`, `swapfile.sys`
- **Recycle bins**: `$RECYCLE.BIN`, `@Recycle`, `trashbox*`
- **Temp/cache files**: `**.tmp`, `**.cache`, `**.log`, `**.crdownload`
- **Version control**: `.git/`, `**.sync/`
- **App data**: WeChat Files, QQ, Baidu Netdisk, AliWorkbench, Tencent Files
- **Media apps**: Youku Files, nplayerdisk, hls*, **.midownloading
- **Build artifacts**: `node_modules/*`, `**.stversions`, `**.stfolder/`
- **Cloud sync**: Dropbox cache, Syncthing internal files

### Usage

1. Copy the `.stignore` file from this repository into your Syncthing sync folder
2. Or add the patterns manually via Syncthing Web GUI: Settings → Ignore Patterns
3. Patterns are applied in real-time; Syncthing will re-scan to enforce them

---

## 中文说明

### 概述

Syncthing 使用每个同步文件夹内的 `.stignore` 文件来定义哪些文件和文件夹应排除在同步之外。您可以通过 Syncthing Web 界面（配置 → 忽略模式）进行设置，或直接编辑 `.stignore` 文件。

### 支持的通配符语法

| 模式 | 说明 |
|------|------|
| `(?d)` | 前缀，表示如果删除了阻止目录则文件可被删除 |
| `(?i)` | 前缀，表示该模式匹配时忽略大小写差异 |
| `!` | 取反条件（例如：`!**/.git/` 表示不要排除 `.git` 文件夹） |
| `*` | 单级通配符（仅匹配单层文件夹） |
| `**` | 多级通配符（用以匹配多层嵌套文件夹） |
| `//` | 注释（行首使用） |

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
```

### 已包含的忽略模式

本仓库提供了全面的 `.stignore` 文件，涵盖以下内容：

- **系统文件**: `.DS_Store`、`desktop.ini`、`Thumbs.db`、`pagefile.sys`、`swapfile.sys`
- **回收站**: `$RECYCLE.BIN`、`@Recycle`、`trashbox*`
- **临时/缓存文件**: `**.tmp`、`**.cache`、`**.log`、`**.crdownload`
- **版本控制**: `.git/`、`**.sync/`
- **应用数据**: 微信文件、QQ、百度网盘、阿里工作台、腾讯文件
- **媒体应用**: 优酷文件、nplayerdisk、hls*、**.midownloading
- **构建产物**: `node_modules/*`、`**.stversions`、`**.stfolder/`
- **云同步**: Dropbox 缓存、Syncthing 内部文件

### 使用方法

1. 将此仓库中的 `.stignore` 文件复制到您的 Syncthing 同步文件夹
2. 或通过 Syncthing Web 界面手动添加这些模式：设置 → 忽略模式
3. 模式会实时生效；Syncthing 将重新扫描以强制执行这些规则
