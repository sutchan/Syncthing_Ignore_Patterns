<#
//File: scan-stignore.ps1
//Version: 1.1.0
//Updated: 2026-08-06
.SYNOPSIS
    Scan the computer for all .stignore files and save the results to a path manifest.

.DESCRIPTION
    Recursively scan the given root (default: all fixed drives) for .stignore files,
    recording each file's full path, SHA256, size and last-write time, and output a
    JSON manifest (default stignore-paths.json). Skips .git directories and this repo.

.PARAMETER Path
    Scan root. Defaults to all fixed drives (C:, D:, E: ...).

.PARAMETER Output
    Manifest output path. Defaults to stignore-paths.json in the script directory.

.PARAMETER WhatIf
    Only show the root directories that would be scanned; do not write the manifest.

.EXAMPLE
    .\scan-stignore.ps1
    Full-disk scan and generate stignore-paths.json.

.EXAMPLE
    .\scan-stignore.ps1 -Path "D:\Sync" -Output "D:\Sync\list.json"
    Scan only D:\Sync and output to the specified manifest file.
#>
[CmdletBinding()]
param(
    [string]$Path = '',
    [string]$Output = (Join-Path $PSScriptRoot 'stignore-paths.json'),
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '1.1.0'

trap {
    Write-Host "`n[FATAL] Script terminated: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    Safe-Pause
    exit 1
}

function Safe-Pause {
    try {
        Write-Host "`nPress Enter to exit..." -ForegroundColor DarkGray
        $null = Read-Host
    } catch {
        Start-Sleep -Seconds 3
    }
}

# Determine scan roots
if ([string]::IsNullOrWhiteSpace($Path)) {
    $roots = @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
        Where-Object { $_.Free -ne $null } | Select-Object -ExpandProperty Root)
    if ($roots.Count -eq 0) {
        Write-Error "No filesystem drives enumerated. Use -Path to specify a directory."
        Safe-Pause
        exit 1
    }
    Write-Host "No -Path given; scanning drive roots: $($roots -join ', ')" -ForegroundColor Yellow
} else {
    if (-not (Test-Path $Path)) {
        Write-Error "Scan root does not exist: $Path"
        exit 1
    }
    $roots = @($Path)
}

if ($WhatIf) {
    Write-Host "[preview] roots to scan: $($roots -join ', ')" -ForegroundColor Yellow
    Write-Host "[preview] manifest output: $Output" -ForegroundColor Yellow
    return
}

$repoRoot = $PSScriptRoot
$records = @()
$scanned = 0

foreach ($root in $roots) {
    Write-Host "`nScanning root: $root" -ForegroundColor Cyan
    try {
        $files = Get-ChildItem -Path $root -Filter '.stignore' -Recurse -File -Force -Attributes !ReparsePoint -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "Cannot access $root : $($_.Exception.Message)"
        continue
    }

    foreach ($file in $files) {
        $full = $file.FullName

        # Skip .git directories
        if ($full -like '*\.git\*') { continue }
        # Skip .stignore inside this repo (the scanner itself)
        if ($full -like "$repoRoot*") { continue }

        $scanned++
        try {
            $hash = (Get-FileHash -Path $full -Algorithm SHA256).Hash
            $records += [pscustomobject]@{
                path         = $full
                sha256       = $hash
                size         = $file.Length
                lastWriteUtc = $file.LastWriteTimeUtc.ToString('o')
                foundAtUtc   = (Get-Date).ToUniversalTime().ToString('o')
            }
            Write-Host "  recorded: $full" -ForegroundColor Green
        } catch {
            Write-Warning "  read failed $full : $($_.Exception.Message)"
        }
    }
}

$manifest = [pscustomobject]@{
    version   = $ScriptVersion
    scannedAt = (Get-Date).ToUniversalTime().ToString('o')
    count     = $records.Count
    roots     = $roots
    files     = $records
}

$json = $manifest | ConvertTo-Json -Depth 4 -Compress:$false
Set-Content -Path $Output -Value $json -Encoding UTF8
Write-Host "`n==== Scan complete ====" -ForegroundColor Cyan
Write-Host "Files found   : $($records.Count)"
Write-Host "Manifest saved: $Output"
Safe-Pause
