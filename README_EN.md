# Syncthing Ignore Patterns

> A curated, ready-to-use `.stignore` rule set: 21 categories · 329 patterns that exclude system files, caches, build artifacts, and app data.

![Version](https://img.shields.io/badge/version-v1.21.0-blue)
![CI](https://github.com/sutchan/Syncthing_Ignore_Patterns/actions/workflows/ci.yml/badge.svg)
![Updated](https://img.shields.io/badge/updated-2026--09--22-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)
![Categories](https://img.shields.io/badge/categories-21-blueviolet)

[English](#english) | [中文](README.md)

---

## English

- ✅ **21 categories / 329 patterns** covering system files, caches, build artifacts, databases, and more
- ✅ **Zero-config**: drop it at the sync folder root and it works
- ✅ **Bilingual docs** plus a batch-sync GUI tool
- ✅ **Actively maintained** as the ecosystem evolves

> The `Updated` date in the `.stignore` header (`2026-09-22`) is the ruleset revision date; the tool release version lives in CHANGELOG (currently `v1.21.0`). One tracks "ruleset revision", the other "tool release" — they may differ and that is expected.

### Quick Start

1. Download `.stignore` and place it at the **root** of your Syncthing sync folder
2. Restart Syncthing or trigger a rescan — patterns take effect on the next scan

You can also paste the contents into the Web UI (default `http://localhost:8384`) → folder → **Edit** → **Ignore Patterns** and save; it applies immediately.

To split patterns across files, use `// #include`:

```text
#include .stignore-base
// Your custom rules below
**/my-secret-folder
*.local
```

### Pattern Syntax

| Pattern | Description |
|---------|-------------|
| `(?d)` | Allow deletion when the blocked parent dir is removed |
| `(?i)` | Case-insensitive matching |
| `!` | Negation (re-include) |
| `*` / `**` | Single-level / multi-level wildcard |
| `//` | Comment |

### Categories

See the `.stignore` file for the full rule set:

| # | Category | Typical patterns |
|---|----------|------------------|
| 1 | System & OS Files | `$RECYCLE.BIN/`, `.DS_Store`, `Thumbs.db`, `desktop.ini`, `System Volume Information/` |
| 2 | Database Files | `ibdata1`, `*.ibd`, `pg_wal/`, `*.sqlite3`, `*.db-wal` (no blanket `*.db`) |
| 3 | Backup & Temp Files | `*.tmp`, `*.bak`, `.delete/`, `Backup_of_*`, `.stignore.bak.*` |
| 4 | App Data & Caches | `.dropbox.cache/`, `WeChat Files/`, `BaiduNetdiskDownload/`, `SteamLibrary/` (keeps `.stfolder/`, `.stversions`) |
| 5 | Version Control | `.svn/`, `.hg/` (`.git/` synced by default, keeps branch info) |
| 6 | Package Manager Caches | `node_modules/`, `.npm/`, `.venv/`, `.cargo/`, `.gradle/`, `.m2/`, `vendor/`, `.conda/`, `.uv/`, `.opam/` |
| 7 | Frontend Build Caches | `.next/`, `.nuxt/`, `.svelte-kit/`, `.vite/`, `.turbo/`, `.vercel/` |
| 8 | Python & Test Caches | `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `.tox/`, `.ipynb_checkpoints/`, `.cypress/`, `.playwright/`, `.allure/` |
| 9 | C/C++ & Rust Builds | `CMakeCache.txt`, `CMakeFiles/`, `cmake-build-*/`, `.clangd/` |
| 10 | JVM & Scala Builds | `.bloop/`, `.metals/`, `.scala-build/`, `.mvn/` |
| 11 | IDE & Tool Caches | `.idea/`, `.history/`, `.terraform/`, `.terragrunt-cache/`, `.helm/`, `.kube/` |
| 12 | Editors & Dev Tools | `.vscode/` (keeps `settings.json`), `.vim/`, `*.swp`, `*~`, `.cursor/`, `.claude/`, `.windsurf/`, `.aider/`, `*.iml` |
| 13 | Archives & Partial Downloads | `*.part`, `*.aria2`, `*.crdownload`, `downloading/` |
| 14 | Virtualization & Containers | `*.vmdk`, `*.qcow2`, `*.ova`, `.docker/`, `.vagrant/`, `.buildkit/`, `.podman/`, `.containerd/` |
| 15 | Media & Player Caches | `Spotify/`, `iTunes/Album Artwork/`, `PotPlayerMini*`, `.Spotlight-V100/` |
| 16 | Lock & Log Files | `*.lock` (re-includes `Cargo.lock`, `package-lock.json`, `yarn.lock`), `*.log`, `nohup.out`, `.zsh_history`, `.bash_history` |
| 17 | Build Artifacts | `target/`, `dist/`, `build/`, `bin/`, `obj/`, `*.pyc`, `*.class`, `*.o` |
| 18 | Cache & Temp Directories | `(?i)**/cache/`, `temp/`, `tmp/`, `.cache/`, `thumbnails/`, `.eslintcache` |
| 19 | Browser & Electron Caches | `Code Cache/`, `GPUCache/`, `ShaderCache/`, `IndexedDB/`, `blob_storage/` |
| 20 | OS Temp & Cache Locations | `/tmp/`, `/var/tmp/`, `/var/cache/`, `/Windows/Temp/` (root-anchored) |
| 21 | AI Coding Assistants & Vibecoding | `.codex/`, `.gemini/`, `.qwen/`, `.codeium/`, `.continue/`, `.cline/`, `.roo/`, `.kilocode/`, `.cody/`, `.trae/`, `.junie/`, `.supermaven/`, `.opencode/`, `.goose/`, `.openhands/`, `.augment/`, `.tabnine/`, `.qoder/`, `.workbuddy/`, `.amp/` (tool data dirs only; not CLAUDE.md etc.) |

> Heads-up 1: `dist/`, `build/`, `bin/`, `target/`, `cache/`, `temp/` in categories 17–18 are generic names. If you need to sync a folder with one of those names, delete the matching line.
> Heads-up 2: category 18 uses `(?i)` for case-insensitive matching and matches **whole directory names only**, so `MyCacheFolder/`, `Template/` and `Tempura/` are safe.

### Customization Tips

```text
!**/keep-this/     // whitelist: force-sync a folder (overrides ignore rules)
(?i)**.jpg         // case-insensitive
(?d)**/temp/**     // allow deletion with parent dir
```

Use the "Ignore Patterns" preview in the Web UI to verify matches before saving.

### Batch Sync Tool

The project ships two implementations with identical behavior (scan / apply / backup rotation / bilingual UI / light & dark themes):

#### Option 1: Dart + Flutter Desktop (recommended, primary · v1.21.0)

Located in `app/`, built into a standalone `.exe` — no PowerShell required on the target machine:

```bash
cd app
flutter config --enable-windows-desktop
flutter pub get
flutter build windows        # output: build/windows/x64/runner/Release/syncthing_ignore_gui.exe
```

- **UI**: root / manifest-path inputs, Preview / Force / Backup toggles, Scan / Apply / Stop / Clear-log buttons, progress bar, results & log lists
- **Language / Theme**: switch `English` / `中文` and `Light` / `Dark` at the top-right, applied instantly
- **Scan**: one isolate per root (4 by default), skips `.git` and the rules-source dir, tolerates access-denied folders
- **Apply**: SHA-256 compare skips identical files, `.bak.<timestamp>` backup before writing, `<base>.bak.*` rotation ≤3, `Force` cleans stale paths
- **Standard rules**: bundled as `assets/.stignore`, loaded via `rootBundle` at runtime; sync that copy when rules change

#### Option 2: PowerShell WinForms (legacy · maintenance · v1.18.5)

`SyncthingIgnoreGUI.ps1` is a single self-contained script for environments without Flutter:

```powershell
.\SyncthingIgnoreGUI.ps1                                   # auto-restarts on an STA thread (required by WinForms)
powershell -STA -NoProfile -File .\SyncthingIgnoreGUI.ps1   # equivalent
```

- **Language / Theme**: top-left switch, applied live and persisted to `config.json`
- **Scan**: runspace pool (≤4 threads) with `-Filter .stignore`; blank root scans all fixed drives, drag & drop supported
- **Options / Manifest**: Preview / Force / Back-up; manifest defaults to `config/stignore-paths.json`
- **Live status**: while scanning, the status line shows roots done, files found, the **current directory** and elapsed time; results stream in
- **More**: background execution keeps the UI responsive, double-click a result to open it, **Stop** aborts the background job

```mermaid
flowchart LR
    A[Scan<br/>parallel drives / isolates] --> B[Manifest stignore-paths.json<br/>backup rotate ≤3]
    B --> C[Apply<br/>write rules, per-file backup ≤3]
```

**Backup rotation**: `.stignore.bak.<timestamp>` and `stignore-paths.json.bak.<timestamp>` each keep **at most 3** copies — older ones are deleted automatically.

### Contributing

- [Contributing Guide](.github/CONTRIBUTING.md) — ruleset conventions, architecture red lines, and PR workflow
- [Code of Conduct](.github/CODE_OF_CONDUCT.md) · [Security Policy](.github/SECURITY.md) · [Support](.github/SUPPORT.md)

### License

Released under the [MIT License](https://opensource.org/licenses/MIT).
