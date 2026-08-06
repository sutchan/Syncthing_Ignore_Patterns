<#
.SYNOPSIS
    批量将本仓库的标准 .stignore 规则同步到电脑中所有 .stignore 文件。

.DESCRIPTION
    扫描指定根目录（默认全盘）下所有名为 .stignore 的文件，
    在替换前自动备份原文件，然后将标准规则写入。
    支持预览模式、强制模式，并自动跳过本仓库目录与 .git 目录。

.PARAMETER Source
    标准规则源文件路径。默认指向脚本所在仓库的 .stignore。

.PARAMETER Path
    扫描根目录。默认扫描所有固定驱动器（C:, D:, E: ...）。

.PARAMETER WhatIf
    仅列出将会被替换的文件，不实际写入。

.PARAMETER Force
    无需逐文件确认，直接替换。

.EXAMPLE
    .\sync-stignore.ps1 -WhatIf
    预览所有将被替换的 .stignore 文件。

.EXAMPLE
    .\sync-stignore.ps1 -Path "D:\Sync" -Force
    仅扫描 D:\Sync 并直接替换其中所有 .stignore。
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$Source = (Join-Path $PSScriptRoot '.stignore'),
    [string]$Path = '',
    [switch]$WhatIf,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# 校验源文件
if (-not (Test-Path $Source -PathType Leaf)) {
    Write-Error "找不到标准规则源文件: $Source"
    exit 1
}
$sourceContent = Get-Content -Path $Source -Raw
$sourceBytes = [System.IO.File]::ReadAllBytes($Source)
$sourceHash = (Get-FileHash -Path $Source -Algorithm SHA256).Hash
Write-Host "标准规则源: $Source" -ForegroundColor Cyan
Write-Host "源文件 SHA256: $sourceHash" -ForegroundColor DarkGray

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

$repoRoot = $PSScriptRoot
$processed = 0
$skippedSame = 0
$replaced = 0
$errors = 0
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

foreach ($root in $roots) {
    Write-Host "`n扫描根目录: $root" -ForegroundColor Cyan
    try {
        $files = Get-ChildItem -Path $root -Filter '.stignore' -Recurse -File -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "无法访问 $root : $($_.Exception.Message)"
        continue
    }

    foreach ($file in $files) {
        $full = $file.FullName

        # 跳过本仓库自身
        if ($full -eq $Source) { continue }

        # 跳过 .git 目录
        if ($full -like '*\.git\*') { continue }

        $processed++

        try {
            $fileHash = (Get-FileHash -Path $full -Algorithm SHA256).Hash
            if ($fileHash -eq $sourceHash) {
                Write-Host "  跳过(已一致): $full" -ForegroundColor DarkGray
                $skippedSame++
                continue
            }

            if ($WhatIf) {
                Write-Host "  [预览] 将替换: $full" -ForegroundColor Yellow
                $replaced++
                continue
            }

            $doReplace = $Force -or $PSCmdlet.ShouldProcess($full, '替换为标准 .stignore 规则')

            if ($doReplace) {
                # 备份原文件
                $bak = "$full.bak.$timestamp"
                Copy-Item -Path $full -Destination $bak -Force
                # 写入标准规则（保留原始换行符风格：使用源字节直接覆盖）
                [System.IO.File]::WriteAllBytes($full, $sourceBytes)
                Write-Host "  已替换(备份: $bak): $full" -ForegroundColor Green
                $replaced++
            }
        } catch {
            Write-Warning "  处理失败 $full : $($_.Exception.Message)"
            $errors++
        }
    }
}

Write-Host "`n==== 执行摘要 ====" -ForegroundColor Cyan
Write-Host "扫描文件总数 : $processed"
Write-Host "已一致跳过   : $skippedSame"
Write-Host "已替换/将替换: $replaced"
Write-Host "处理错误     : $errors"
if ($WhatIf) {
    Write-Host "（预览模式，未做实际修改）" -ForegroundColor Yellow
}
