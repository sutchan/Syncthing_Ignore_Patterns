<#
//File: scan-stignore.ps1
//Version: 1.1.0
//Updated: 2026-08-06
.SYNOPSIS
    扫描电脑中所有 .stignore 文件，并将结果保存到路径清单文件。

.DESCRIPTION
    递归扫描指定根目录（默认所有固定驱动器）下的 .stignore 文件，
    记录每个文件的完整路径、SHA256、大小与最后修改时间，
    输出为 JSON 清单（默认 stignore-paths.json）。
    扫描会跳过 .git 目录与本仓库自身目录。

.PARAMETER Path
    扫描根目录。默认扫描所有固定驱动器（C:, D:, E: ...）。

.PARAMETER Output
    清单输出路径。默认位于脚本所在目录的 stignore-paths.json。

.PARAMETER WhatIf
    仅显示将要扫描的根目录，不实际写入清单。

.EXAMPLE
    .\scan-stignore.ps1
    全盘扫描并生成 stignore-paths.json。

.EXAMPLE
    .\scan-stignore.ps1 -Path "D:\Sync" -Output "D:\Sync\list.json"
    仅扫描 D:\Sync 并输出到指定清单文件。
#>
[CmdletBinding()]
param(
    [string]$Path = '',
    [string]$Output = (Join-Path $PSScriptRoot 'stignore-paths.json'),
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '1.1.0'

# 确定扫描根目录
if ([string]::IsNullOrWhiteSpace($Path)) {
    $roots = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }).Root
    Write-Host "未指定 -Path，将扫描以下驱动器根目录: $($roots -join ', ')" -ForegroundColor Yellow
} else {
    if (-not (Test-Path $Path)) {
        Write-Error "扫描根目录不存在: $Path"
        exit 1
    }
    $roots = @($Path)
}

if ($WhatIf) {
    Write-Host "[预览] 将扫描根目录: $($roots -join ', ')" -ForegroundColor Yellow
    Write-Host "[预览] 清单输出: $Output" -ForegroundColor Yellow
    return
}

$repoRoot = $PSScriptRoot
$records = @()
$scanned = 0

foreach ($root in $roots) {
    Write-Host "`n扫描根目录: $root" -ForegroundColor Cyan
    try {
        $files = Get-ChildItem -Path $root -Filter '.stignore' -Recurse -File -Force -Attributes !ReparsePoint -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "无法访问 $root : $($_.Exception.Message)"
        continue
    }

    foreach ($file in $files) {
        $full = $file.FullName

        # 跳过 .git 目录
        if ($full -like '*\.git\*') { continue }
        # 跳过本仓库目录内的 .stignore（即扫描工具自身所在仓库）
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
            Write-Host "  已记录: $full" -ForegroundColor Green
        } catch {
            Write-Warning "  读取失败 $full : $($_.Exception.Message)"
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
Write-Host "`n==== 扫描完成 ====" -ForegroundColor Cyan
Write-Host "扫描到文件数 : $($records.Count)"
Write-Host "清单已保存   : $Output"
