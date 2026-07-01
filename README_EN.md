# Syncthing Ignore Patterns

![Version](https://img.shields.io/badge/version-v1.0.0-blue)
![Updated](https://img.shields.io/badge/updated-2026--07--01-brightgreen)

[English](#english) | [中文](README.md)

---

## English

A curated `.stignore` collection to exclude system files, caches, build artifacts, and app data from Syncthing sync.

### Pattern Syntax

| Pattern | Description |
|---------|-------------|
| `(?d)` | Allow deletion when blocked parent dir is removed |
| `(?i)` | Case-insensitive matching |
| `!` | Negation (include this pattern) |
| `*` | Single-level wildcard |
| `**` | Multi-level wildcard |
| `//` | Comment |

### Included Categories

The `.stignore` file is organized into the following 11 categories (see the file for full details):

1. **System & OS Files** — `$RECYCLE.BIN`, `.DS_Store`, `Thumbs.db`, `desktop.ini`, `pagefile.sys`, `Program Files/`, `System Volume Information/`, `LOST.DIR/`, etc.
2. **Backup & Temporary Files** — `.cache`, `.tmp`, `.delete`, `Temp/`, `Backup_of_*`, etc.
3. **Application Data & Caches** — `.stfolder/`, `.stversions`, `.dropbox.cache/`, `WeChat Files/`, `Tencent Files/`, `BaiduNetdiskDownload/`, `AliWorkbenchData/`, `Youku Files/`, `SteamLibrary/`, etc.
4. **Version Control Systems** — `.git/`
5. **Package Manager Caches & Dependencies** — `node_modules/`, `.npm/`, `.pnpm-store/`, `.venv/`, `__pycache__/`, `.cargo/`, `.gradle/`, `.m2/`, `.nuget/`, `.bun/`, `.deno/`, `.dart_tool/`, `.stack-work/`, etc.
6. **Frontend Framework Build Caches** — `.next/`, `.nuxt/`, `.svelte-kit/`, `.vite/`, `.turbo/`, `.astro/`, `.docusaurus/`, `.parcel-cache/`, `.vercel/`, `.netlify/`, `.vuepress/dist/`, etc.
7. **Python & Testing Caches** — `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `.coverage`, `.jest-cache/`, `.vitest/`, `.tox/`, `.nox/`, `.ipynb_checkpoints/`, `htmlcov/`, etc.
8. **C/C++ & Rust Build Caches** — `CMakeCache.txt`, `CMakeFiles/`, `cmake-build-debug/`, `cmake-build-release/`, `compile_commands.json`, `.ccls-cache/`, `.clangd/`, `.rustc_cache/`, etc.
9. **JVM & Scala Build Caches** — `.ammonite/`, `.bloop/`, `.metals/`, `.kotlintest/`
10. **IDE & Tool Caches** — `.idea/`, `.history/`, `.terraform/`, `.terraform.lock.hcl`, `.terragrunt-cache/`, `.helm/`, `.kube/`, `.flyway/`, etc.
11. **Lock & Log Files** — `*.lock`, `*.log.*`, `**.log`

### Usage

#### Prerequisites

- A running [Syncthing](https://syncthing.net/) instance
- At least one configured sync folder

#### Method 1: Copy the file directly

1. Download `.stignore` from this repository
2. Place it at the **root** of your Syncthing sync folder
3. Restart Syncthing or trigger a rescan — patterns take effect on the next scan

#### Method 2: Use the Syncthing Web GUI

1. Open the Syncthing Web UI (default: `http://localhost:8384`)
2. Click the target folder → **Edit** → **Ignore Patterns**
3. Paste the contents of `.stignore` into the editor
4. Click **Save** — patterns apply immediately and a rescan is triggered

#### Method 3: Include external files

Syncthing supports `// #include` directives to split patterns across files:

```
// Include this repo's patterns
#include .stignore-base

// Add your own custom rules below
**/my-secret-folder
*.local
```

#### Customization Tips

- **Whitelist files**: Use `!` to re-include patterns, e.g. `!**/.git/` keeps `.git` folders in sync
- **Case-insensitive**: Prefix with `(?i)` to match across cases, e.g. `(?i)**.jpg` matches `.JPG`, `.jpg`, `.Jpg`
- **Safe deletion**: Use `(?d)` prefix to allow Syncthing to delete files when their parent directory is removed
- **Comments**: Lines starting with `//` are ignored — use them to document your rules
- **Test before committing**: Use the "Ignore Patterns" preview in the Web UI to verify which files are matched

#### Verification

After applying the patterns:

1. Open the Syncthing Web UI → folder → **Ignore Patterns** to confirm rules are loaded
2. Check the folder status — files matching the patterns should no longer appear in the sync queue
3. Use **Recent Changes** to verify ignored files are not being synced

### Examples

```
// Recursively exclude Recycle Bin
**$RECYCLE.BIN

// macOS system files
**.DS_Store

// node_modules
**/node_modules/*

// Case-insensitive match
(?i)**.JPG

// Whitelist .git folders
!**/.git/
```

### License

MIT
