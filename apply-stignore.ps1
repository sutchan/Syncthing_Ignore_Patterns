<#
//File: apply-stignore.ps1
//Version: 1.1.0
//Updated: 2026-08-06
.SYNOPSIS
    依据扫描清单，将标准 .stignore 规则应用到各已记录路径。

.DESCRIPTION
    读取由 scan-stignore.ps1 生成的路径清单（JSON），
    对每个记录的文件：若文件仍存在则备份并写入标准规则；
    若文件已不存在则从清单中移除（路径失效）。
    规则源文件更新后，直接重跑本脚本即可同步所有历史路径，
    无需再次全盘扫描。

.PARAMETER Source
    标准规则源文件路径。默认指向脚本所在仓库的 .stignore。

.PARAMETER List
    扫描清单路径。默认位于脚本所在目录的 stignore-paths.json。

.PARAMETER WhatIf
    借助 PowerShell 的 WhatIf 机制，仅列出将要替换/清理的项，不实际写入或删除。

.PARAMETER Force
    无需逐文件确认，直接替换并清理失效项。

.PARAMETER BackupList
    写回清单前先备份原清单为 <原名>.bak.<时间戳>，防止中途异常导致清单丢失。

.EXAMPLE
    .\apply-stignore.ps1 -WhatIf
    预览将要执行的替换与清理。

.EXAMPLE
    .\apply-stignore.ps1 -Force
    直接应用标准规则并清理失效路径，不弹确认。
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$Source = (Join-Path $PSScriptRoot '.stignore'),
    [string]$List = (Join-Path $PSScriptRoot 'stignore-paths.json'),
    [switch]$Force,
    [switch]$BackupList
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Source -PathType Leaf)) {
    Write-Error "找不到标准规则源文件: $Source"
    exit 1
}
if (-not (Test-Path $List -PathType Leaf)) {
    Write-Error "找不到清单文件: $List （请先运行 .\scan-stignore.ps1）"
    exit 1
}

$sourceBytes = [System.IO.File]::ReadAllBytes($Source)
$sourceHash = (Get-FileHash -Path $Source -Algorithm SHA256).Hash
Write-Host "标准规则源 : $Source" -ForegroundColor Cyan
Write-Host "源 SHA256  : $sourceHash" -ForegroundColor DarkGray

$manifest = Get-Content -Path $List -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -eq $manifest -or $null -eq $manifest.files) {
    Write-Error "清单文件格式无效或缺少 files 字段: $List"
    exit 1
}
$records = [System.Collections.ArrayList]::new()
$kept = 0
$replaced = 0
$skippedSame = 0
$cleaned = 0
$errors = 0
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

foreach ($item in $manifest.files) {
    $full = $item.path
    if ([string]::IsNullOrWhiteSpace($full)) { continue }

    if (-not (Test-Path $full -PathType Leaf)) {
        # 路径失效：从清单中移除（清理动作本身也需要确认/受 WhatIf 约束）
        $doClean = $Force -or $PSCmdlet.ShouldProcess($full, '清理失效路径(从清单移除)')
        if ($doClean) {
            if (-not $WhatIf) {
                Write-Host "  已清理失效路径: $full" -ForegroundColor DarkGray
            } else {
                Write-Host "  [预览] 将清理失效路径: $full" -ForegroundColor Yellow
            }
            $cleaned++
            continue
        }
        # 用户取消确认，则保留该项
        [void]$records.Add($item)
        continue
    }

    $kept++
    $fileHash = (Get-FileHash -Path $full -Algorithm SHA256).Hash
    if ($fileHash -eq $sourceHash) {
        Write-Host "  跳过(已一致): $full" -ForegroundColor DarkGray
        $skippedSame++
        [void]$records.Add($item)
        continue
    }

    $doReplace = $Force -or $PSCmdlet.ShouldProcess($full, '替换为标准 .stignore 规则')
    if ($doReplace) {
        try {
            $bak = "$full.bak.$timestamp"
            Copy-Item -Path $full -Destination $bak -Force
            [System.IO.File]::WriteAllBytes($full, $sourceBytes)
            Write-Host "  已替换(备份: $bak): $full" -ForegroundColor Green
            $replaced++
            [void]$records.Add($item)
        } catch {
            Write-Warning "  处理失败 $full : $($_.Exception.Message)"
            $errors++
            [void]$records.Add($item)
        }
    } else {
        [void]$records.Add($item)
    }
}

# 写回清单（移除失效项）
if (-not $WhatIf) {
    # 写回前备份原清单，防止中途异常导致清单丢失
    if ($BackupList) {
        $listBak = "$List.bak.$timestamp"
        Copy-Item -Path $List -Destination $listBak -Force
        Write-Host "清单已备份: $listBak" -ForegroundColor DarkGray
    }
    $newManifest = [pscustomobject]@{
        version   = $manifest.version
        scannedAt = $manifest.scannedAt
        updatedAt = (Get-Date).ToUniversalTime().ToString('o')
        count     = $records.Count
        roots     = $manifest.roots
        files     = $records
    }
    $json = $newManifest | ConvertTo-Json -Depth 4
    Set-Content -Path $List -Value $json -Encoding UTF8
}

Write-Host "`n==== 执行摘要 ====" -ForegroundColor Cyan
Write-Host "清单原项数   : $($manifest.files.Count)"
Write-Host "仍有效路径   : $kept"
Write-Host "已一致跳过   : $skippedSame"
Write-Host "已替换/将替换: $replaced"
Write-Host "已清理失效   : $cleaned"
Write-Host "处理错误     : $errors"
if ($WhatIfPreference) { Write-Host "（预览模式，未做实际修改）" -ForegroundColor Yellow }
