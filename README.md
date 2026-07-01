# Syncthing Ignore Patterns

[English](#english) | [中文](README_CN.md)

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

The `.stignore` file covers the following categories (see the file for full details):

- **System & Temp Files** — OS-generated files, recycle bins, caches, logs
- **Version Control & Cloud Sync** — `.git/`, `.stfolder/`, `.stversions`, etc.
- **Dependencies & Caches** — `node_modules/`, `.venv/`, `.cargo/`, `.gradle/`, etc.
- **Build Outputs** — `bin/`, `dist/`, `target/`, `*.exe`, `*.pyc`, etc.
- **Framework Caches** — `.next/`, `.nuxt/`, `.vite/`, `.turbo/`, etc.
- **Testing & Type Checking** — `.pytest_cache/`, `.mypy_cache/`, `.coverage`, etc.
- **IDE & Tools** — `.idea/`, `.vscode/`, `.terraform/`, `.kube/`, etc.
- **App Data** — WeChat, QQ, Baidu Netdisk, Tencent Files, etc.
- **Lock & Logs** — `*.lock`, `*.log.*`

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
