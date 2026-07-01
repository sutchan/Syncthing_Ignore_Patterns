# Syncthing Ignore Patterns

[English](#english) | [中文](README_CN.md)

---

## English

### Overview

A curated collection of Syncthing ignore patterns (`.stignore`) to help you sync only the files you need. This repository provides a comprehensive, well-organized `.stignore` file that excludes system files, cache directories, build artifacts, and application data from Syncthing synchronization.

Syncthing uses `.stignore` files in each sync folder to define which files and folders to exclude from synchronization. You can configure these patterns either through the Syncthing Web GUI (Config → Ignore Patterns) or by directly editing the `.stignore` file.

### Pattern Syntax

| Pattern | Description |
|---------|-------------|
| `(?d)` | Prefix that allows files to be deleted if the blocked parent directory is removed |
| `(?i)` | Case-insensitive matching prefix |
| `!` | Negation — include this pattern (e.g., `!**/.git/` to sync `.git` folders) |
| `*` | Single-level wildcard (matches one directory level only) |
| `**` | Multi-level wildcard (matches across nested directories) |
| `//` | Comment — lines starting with `//` are ignored |

### Included Pattern Categories

The `.stignore` file is organized into the following sections:

#### 1. General Exclusions

Common system files, recycle bins, and temporary files across platforms.

- **System files**: `.DS_Store`, `desktop.ini`, `Thumbs.db`, `pagefile.sys`, `swapfile.sys`, `~$*` (Office temp files)
- **Recycle bins**: `$RECYCLE.BIN`, `@Recycle`, `.Recovery`, `.Recycle_bin`, `trashbox*`, `LOST.DIR/`
- **Temp/cache files**: `.tmp`, `.cache`, `.log`, `.crdownload`, `.bak`, `.delete`
- **Version control**: `.git/`, `.sync/`
- **Cloud sync internals**: `.dropbox.cache/`, `.stfolder/`, `.stversions`, `sync.ffs_db`
- **App data**: WeChat Files, QQ, Baidu Netdisk, AliWorkbench, Tencent Files, Youku Files
- **System directories**: `Program Files/`, `Program Files (x86)/`, `System Volume Information/`

#### 2. Package Manager Caches & Dependencies

- **Node.js**: `.npm/`, `.pnpm-store/`, `.pnpm-local-store`, `.yarn/cache/`, `.bun/`, `node_modules/`
- **Python**: `.venv/`, `__pycache__/`, `.ipynb_checkpoints/`
- **Rust**: `.cargo/`
- **Java/JVM**: `.gradle/`, `.m2/`
- **.NET**: `.nuget/`
- **Deno**: `.deno/`
- **Dart/Flutter**: `.dart_tool/`, `.pub-cache/`
- **Haskell**: `.stack-work/`

#### 3. Build Outputs & Artifacts

- **Directories**: `bin/`, `build/`, `dist/`, `out/`, `output/`, `target/`, `vendor/`
- **Binary files**: `*.exe`, `*.dll`, `*.so`, `*.dylib`, `*.a`, `*.lib`, `*.o`, `*.obj`, `*.pyc`, `*.pyo`

#### 4. Frontend Framework Build Caches

- **Astro**: `.astro/`
- **Next.js**: `.next/`
- **Nuxt**: `.nuxt/`
- **SvelteKit**: `.svelte-kit/`
- **Vite**: `.vite/`, `.turbo/`
- **Parcel**: `.parcel-cache/`
- **Docusaurus**: `.docusaurus/`
- **VuePress**: `.vuepress/dist/`
- **Deployment**: `.vercel/`, `.netlify/`

#### 5. Python & Testing Caches

- **Python**: `.eggs/`, `.coverage`, `htmlcov/`
- **Testing**: `.pytest_cache/`, `.jest-cache/`, `.vitest/`, `.nyc_output/`, `.tox/`, `.nox/`
- **Type checking**: `.mypy_cache/`, `.ruff_cache/`
- **Notebooks**: `.ipynb_checkpoints/`

#### 6. C/C++ & Rust Build Caches

- **CMake**: `CMakeCache.txt`, `CMakeFiles/`, `cmake-build-debug/`, `cmake-build-release/`
- **Compiler**: `compile_commands.json`, `.ccls-cache/`, `.clangd/`
- **Rust**: `.rustc_cache/`

#### 7. JVM & Scala Build Caches

- **Scala**: `.ammonite/`, `.bloop/`, `.metals/`
- **Kotlin**: `.kotlintest/`

#### 8. IDE & Tool Caches

- **JetBrains**: `.idea/`
- **VS Code**: `.vscode/`, `.vs/`, `.history/`
- **Infrastructure**: `.terraform/`, `.terragrunt-cache/`, `.helm/`, `.kube/`, `.flyway/`

#### 9. Lock & Log Files

- `*.lock`, `*.log.*`

### Usage

1. **Copy the file**: Copy the `.stignore` file from this repository into your Syncthing sync folder root
2. **Or use the Web GUI**: Open Syncthing Web UI → click the folder → "Ignored Files" → paste the patterns
3. **Real-time effect**: Patterns are applied immediately; Syncthing will re-scan to enforce them

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

// Case-insensitive match
(?i)**.JPG
```

### Project Structure

```
SyncthingIgnorePatterns/
├── .stignore                              # The ignore patterns file
├── .gitignore                             # Git ignore rules
├── README.md                              # English documentation
├── README_CN.md                           # Chinese documentation
└── SyncthingIgnorePatterns.code-workspace # VS Code workspace config
```

### License

This project is open source and available under the MIT License.
