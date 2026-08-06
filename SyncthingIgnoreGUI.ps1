<#
//File: SyncthingIgnoreGUI.ps1
//Version: 1.4.0
//Updated: 2026-08-06
.SYNOPSIS
    Graphical interface for scanning and applying Syncthing .stignore rules,
    with built-in English/Chinese UI switching.

.DESCRIPTION
    Self-contained WinForms GUI. Scan locates all .stignore files across the
    chosen roots and writes a JSON manifest; Apply writes the standard rules
    from .stignore into every recorded path (with auto-backup). No external
    script dependencies - all logic runs in-process. UI text supports English
    and Chinese, switchable at runtime via the language box.

.EXAMPLE
    .\SyncthingIgnoreGUI.ps1
    Launch the graphical tool.
#>

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = $PSScriptRoot
$ScriptVersion = '1.4.0'
$StandardRuleSource = Join-Path $scriptDir '.stignore'

# ---------- Localization ----------
# All Chinese strings are stored as \uXXXX escapes so the script file stays
# pure ASCII and never breaks under GBK/UTF-8 re-encoding.
function Decode-Uni($s) {
    [regex]::Replace($s, '\\u([0-9a-fA-F]{4})', {
        param($m)
        [char][int]('0x' + $m.Groups[1].Value)
    })
}

function Lmsg($en, $zh) {
    if ($lang -eq 'zh') { return Decode-Uni $zh }
    return $en
}

$T = @{
    en = [ordered]@{
        title       = 'Syncthing .stignore Manager'
        lblRoot     = 'Scan root (blank = all fixed drives):'
        lblOut      = 'Manifest output path:'
        browse      = 'Browse...'
        preview     = 'Preview only (no files written)'
        force       = 'Force (skip per-file confirmation)'
        backup      = 'Back up manifest before writing'
        scan        = 'Scan .stignore files'
        apply       = 'Apply standard rules'
        open        = 'Open manifest'
        log         = 'Log:'
        lang        = 'Language:'
        enItem      = 'English'
        zhItem      = '中文'
        folderTitle = 'Select scan root folder'
        fileTitle   = 'Manifest output'
        jsonFilter  = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
        ready       = 'Tool ready. Scripts dir: '
    }
    zh = [ordered]@{
        title       = 'Syncthing .stignore \u7ba1\u7406\u5668'
        lblRoot     = '\u626b\u63cf\u6839\u76ee\u5f55\uff08\u7559\u7a7a=\u6240\u6709\u56fa\u5b9a\u9a7e\u52a8\u5668\uff09\uff1a'
        lblOut      = '\u6e05\u5355\u8f93\u51fa\u8def\u5f84\uff1a'
        browse      = '\u6d4f\u89c8...'
        preview     = '\u4ec5\u9884\u89c8\uff08\u4e0d\u5199\u5165\u6587\u4ef6\uff09'
        force       = '\u5f3a\u5236\uff08\u8df3\u8fc7\u9010\u6587\u4ef6\u786e\u8ba4\uff09'
        backup      = '\u5199\u56de\u6e05\u5355\u524d\u5907\u4efd'
        scan        = '\u626b\u63cf .stignore \u6587\u4ef6'
        apply       = '\u5e94\u7528\u6807\u51c6\u89c4\u5219'
        open        = '\u6253\u5f00\u6e05\u5355'
        log         = '\u65e5\u5fd7\uff1a'
        lang        = '\u8bed\u8a00\uff1a'
        enItem      = 'English'
        zhItem      = '\u4e2d\u6587'
        folderTitle = '\u9009\u62e9\u626b\u63cf\u6839\u76ee\u5f55'
        fileTitle   = '\u6e05\u5355\u8f93\u51fa'
        jsonFilter  = 'JSON \u6587\u4ef6 (*.json)|*.json|\u6240\u6709\u6587\u4ef6 (*.*)|*.*'
        ready       = '\u5de5\u5177\u5df2\u5c31\u7eea\u3002\u811a\u672c\u76ee\u5f55\uff1a'
    }
}

# Default language from system UI culture
try { $uiCulture = (Get-Culture).Name } catch { $uiCulture = 'en-US' }
$lang = if ($uiCulture -like 'zh*') { 'zh' } else { 'en' }

# ---------- Form ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = $T[$lang].title
$form.Size = New-Object System.Drawing.Size(720, 560)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(640, 480)
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)

# ---------- Language selector ----------
$lblLang = New-Object System.Windows.Forms.Label
$lblLang.Location = New-Object System.Drawing.Point(420, 14)
$lblLang.AutoSize = $true
$form.Controls.Add($lblLang)

$cmbLang = New-Object System.Windows.Forms.ComboBox
$cmbLang.Location = New-Object System.Drawing.Point(490, 10)
$cmbLang.Size = New-Object System.Drawing.Size(200, 24)
$cmbLang.DropDownStyle = 'DropDownList'
$cmbLang.Items.Add($T.en.enItem) | Out-Null
$cmbLang.Items.Add($T.en.zhItem) | Out-Null
$form.Controls.Add($cmbLang)

# ---------- Inputs: scan root ----------
$lblRoot = New-Object System.Windows.Forms.Label
$lblRoot.Location = New-Object System.Drawing.Point(16, 44)
$lblRoot.AutoSize = $true
$form.Controls.Add($lblRoot)

$txtRoot = New-Object System.Windows.Forms.TextBox
$txtRoot.Location = New-Object System.Drawing.Point(16, 66)
$txtRoot.Size = New-Object System.Drawing.Size(540, 24)
$txtRoot.Text = ''
$form.Controls.Add($txtRoot)

$btnBrowseRoot = New-Object System.Windows.Forms.Button
$btnBrowseRoot.Location = New-Object System.Drawing.Point(566, 64)
$btnBrowseRoot.Size = New-Object System.Drawing.Size(120, 26)
$form.Controls.Add($btnBrowseRoot)

# ---------- Inputs: manifest output ----------
$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Location = New-Object System.Drawing.Point(16, 100)
$lblOut.AutoSize = $true
$form.Controls.Add($lblOut)

$txtOut = New-Object System.Windows.Forms.TextBox
$txtOut.Location = New-Object System.Drawing.Point(16, 122)
$txtOut.Size = New-Object System.Drawing.Size(540, 24)
$txtOut.Text = Join-Path $scriptDir 'stignore-paths.json'
$form.Controls.Add($txtOut)

$btnBrowseOut = New-Object System.Windows.Forms.Button
$btnBrowseOut.Location = New-Object System.Drawing.Point(566, 120)
$btnBrowseOut.Size = New-Object System.Drawing.Size(120, 26)
$form.Controls.Add($btnBrowseOut)

# ---------- Options ----------
$chkPreview = New-Object System.Windows.Forms.CheckBox
$chkPreview.Location = New-Object System.Drawing.Point(16, 158)
$chkPreview.AutoSize = $true
$chkPreview.Checked = $false
$form.Controls.Add($chkPreview)

$chkForce = New-Object System.Windows.Forms.CheckBox
$chkForce.Location = New-Object System.Drawing.Point(300, 158)
$chkForce.AutoSize = $true
$chkForce.Checked = $false
$form.Controls.Add($chkForce)

$chkBackupList = New-Object System.Windows.Forms.CheckBox
$chkBackupList.Location = New-Object System.Drawing.Point(16, 184)
$chkBackupList.AutoSize = $true
$chkBackupList.Checked = $true
$form.Controls.Add($chkBackupList)

# ---------- Action buttons ----------
$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Location = New-Object System.Drawing.Point(16, 218)
$btnScan.Size = New-Object System.Drawing.Size(180, 32)
$btnScan.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnScan.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnScan)

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Location = New-Object System.Drawing.Point(210, 218)
$btnApply.Size = New-Object System.Drawing.Size(180, 32)
$btnApply.BackColor = [System.Drawing.Color]::FromArgb(46, 138, 87)
$btnApply.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnApply)

$btnOpenManifest = New-Object System.Windows.Forms.Button
$btnOpenManifest.Location = New-Object System.Drawing.Point(404, 218)
$btnOpenManifest.Size = New-Object System.Drawing.Size(120, 32)
$form.Controls.Add($btnOpenManifest)

# ---------- Log ----------
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Location = New-Object System.Drawing.Point(16, 262)
$lblLog.AutoSize = $true
$form.Controls.Add($lblLog)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(16, 284)
$txtLog.Size = New-Object System.Drawing.Size(672, 212)
$txtLog.Multiline = $true
$txtLog.ScrollBars = 'Vertical'
$txtLog.ReadOnly = $true
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$txtLog.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($txtLog)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(16, 504)
$progress.Size = New-Object System.Drawing.Size(672, 14)
$progress.Style = 'Marquee'
$progress.MarqueeAnimationSpeed = 30
$progress.Visible = $false
$form.Controls.Add($progress)

# ---------- Apply language to all controls ----------
function Apply-Language {
    $d = $T[$lang]
    $form.Text      = if ($lang -eq 'zh') { Decode-Uni $d.title } else { $d.title }
    $lblLang.Text   = if ($lang -eq 'zh') { Decode-Uni $d.lang } else { $d.lang }
    $lblRoot.Text   = if ($lang -eq 'zh') { Decode-Uni $d.lblRoot } else { $d.lblRoot }
    $lblOut.Text    = if ($lang -eq 'zh') { Decode-Uni $d.lblOut } else { $d.lblOut }
    $btnBrowseRoot.Text = if ($lang -eq 'zh') { Decode-Uni $d.browse } else { $d.browse }
    $btnBrowseOut.Text  = if ($lang -eq 'zh') { Decode-Uni $d.browse } else { $d.browse }
    $chkPreview.Text    = if ($lang -eq 'zh') { Decode-Uni $d.preview } else { $d.preview }
    $chkForce.Text      = if ($lang -eq 'zh') { Decode-Uni $d.force } else { $d.force }
    $chkBackupList.Text = if ($lang -eq 'zh') { Decode-Uni $d.backup } else { $d.backup }
    $btnScan.Text       = if ($lang -eq 'zh') { Decode-Uni $d.scan } else { $d.scan }
    $btnApply.Text      = if ($lang -eq 'zh') { Decode-Uni $d.apply } else { $d.apply }
    $btnOpenManifest.Text = if ($lang -eq 'zh') { Decode-Uni $d.open } else { $d.open }
    $lblLog.Text        = if ($lang -eq 'zh') { Decode-Uni $d.log } else { $d.log }
    $cmbLang.SelectedIndex = if ($lang -eq 'zh') { 1 } else { 0 }
}

# ---------- Helpers ----------
function Add-Log {
    param([string]$Message, [string]$Color = 'Black')
    $ts = (Get-Date).ToString('HH:mm:ss')
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.AppendText("[$ts] $Message`r`n")
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-Busy {
    param([bool]$Busy)
    $btnScan.Enabled = -not $Busy
    $btnApply.Enabled = -not $Busy
    $progress.Visible = $Busy
    if ($Busy) { $progress.Value = 0 } else { $progress.Value = 100 }
    [System.Windows.Forms.Application]::DoEvents()
}

function Pick-Folder {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = Lmsg 'Select scan root folder' '\u9009\u62e9\u626b\u63cf\u6839\u76ee\u5f55'
    if ($dlg.ShowDialog() -eq 'OK') { return $dlg.SelectedPath }
    return $null
}

function Pick-File {
    param([string]$Title, [string]$Filter)
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Title = $Title
    $dlg.Filter = $Filter
    $dlg.FileName = [System.IO.Path]::GetFileName($txtOut.Text)
    $dlg.InitialDirectory = $scriptDir
    if ($dlg.ShowDialog() -eq 'OK') { return $dlg.FileName }
    return $null
}

function Start-ScanJob {
    param(
        [string]$Root,
        [string]$Output,
        [bool]$WhatIf
    )
    $roots = @()
    if ([string]::IsNullOrWhiteSpace($Root)) {
        $roots = @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
            Where-Object { $_.Free -ne $null } | Select-Object -ExpandProperty Root)
        if ($roots.Count -eq 0) { throw (Lmsg 'No filesystem drives found.' '\u672a\u627e\u5230\u6587\u4ef6\u7cfb\u7edf\u9a7e\u52a8\u5668\u3002') }
        Write-LogLine (Lmsg "No root given; scanning drives: $($roots -join ', ')" "\u672a\u6307\u5b9a\u6839\u76ee\u5f55\uff0c\u626b\u63cf\u9a7e\u52a8\u5668\uff1a$($roots -join ', ')") 'Yellow'
    } else {
        if (-not (Test-Path $Root)) { throw (Lmsg "Scan root does not exist: $Root" "\u626b\u63cf\u6839\u76ee\u5f55\u4e0d\u5b58\u5728\uff1a$Root") }
        $roots = @($Root)
    }

    if ($WhatIf) {
        Write-LogLine (Lmsg "[preview] roots: $($roots -join ', ')" "\u9884\u89c8 \u6839\u76ee\u5f55\uff1a$($roots -join ', ')") 'Yellow'
        Write-LogLine (Lmsg "[preview] output: $Output" "\u9884\u89c8 \u8f93\u51fa\uff1a$Output") 'Yellow'
        return
    }

    $records = [System.Collections.ArrayList]::new()
    foreach ($r in $roots) {
        Write-LogLine (Lmsg "Scanning root: $r" "\u6b63\u5728\u626b\u63cf\uff1a$r") 'Cyan'
        try {
            Get-ChildItem -Path $r -Include '.stignore' -Recurse -File -Force -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $full = $_.FullName
                    if ($full -like '*\.git\*') { return }
                    if ($full -like "$scriptDir*") { return }
                    [void]$records.Add([pscustomobject]@{
                        path         = $full
                        size         = $_.Length
                        lastWriteUtc = $_.LastWriteTimeUtc.ToString('o')
                        foundAtUtc   = (Get-Date).ToUniversalTime().ToString('o')
                    })
                    Write-LogLine (Lmsg "  recorded: $full" "  \u5df2\u8bb0\u5f55\uff1a$full") 'Green'
                }
        } catch {
            Write-LogLine (Lmsg "Cannot access $r : $($_.Exception.Message)" "\u65e0\u6cd5\u8bbf\u95ee $r \uff1a$($_.Exception.Message)") 'DarkOrange'
            continue
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
    Write-LogLine (Lmsg "Scan complete. Files: $($records.Count). Manifest: $Output" "\u626b\u63cf\u5b8c\u6210\u3002\u6587\u4ef6\u6570\uff1a$($records.Count)\u3002\u6e05\u5355\uff1a$Output") 'Green'
}

function Start-ApplyJob {
    param(
        [string]$List,
        [string]$Source,
        [bool]$WhatIf,
        [bool]$Force,
        [bool]$BackupList
    )
    if (-not (Test-Path $Source -PathType Leaf)) { throw (Lmsg "Standard rule source not found: $Source" "\u672a\u627e\u5230\u6807\u51c6\u89c4\u5219\u6e90\u6587\u4ef6\uff1a$Source") }
    if (-not (Test-Path $List -PathType Leaf)) { throw (Lmsg "Manifest not found: $List (run Scan first)" "\u672a\u627e\u5230\u6e05\u5355\uff1a$List\uff08\u8bf7\u5148\u626b\u63cf\uff09") }

    $sourceBytes = [System.IO.File]::ReadAllBytes($Source)
    if ($sourceBytes.Length -eq 0) { throw (Lmsg "Standard rule source is empty: $Source" "\u6807\u51c6\u89c4\u5219\u6e90\u6587\u4ef6\u4e3a\u7a7a\uff1a$Source") }
    $sourceHash = (Get-FileHash -Path $Source -Algorithm SHA256).Hash
    Write-LogLine (Lmsg "Source: $Source  SHA256: $sourceHash" "\u6e90\uff1a$Source  SHA256\uff1a$sourceHash") 'DarkGray'

    try {
        $manifest = Get-Content -Path $List -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        throw (Lmsg "Manifest parse failed (may be corrupted): $List - $($_.Exception.Message)" "\u6e05\u5355\u89e3\u6790\u5931\u8d25\uff08\u53ef\u80fd\u5df2\u635f\u574f\uff09\uff1a$List - $($_.Exception.Message)")
    }
    if ($null -eq $manifest -or $null -eq $manifest.files) { throw (Lmsg "Manifest invalid or missing 'files': $List" "\u6e05\u5355\u65e0\u6548\u6216\u7f3a\u5c11 'files'\uff1a$List") }

    $records = [System.Collections.ArrayList]::new()
    $kept = 0; $replaced = 0; $skippedSame = 0; $cleaned = 0; $errors = 0
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    foreach ($item in $manifest.files) {
        $full = $item.path
        if ([string]::IsNullOrWhiteSpace($full)) { continue }
        if (-not (Test-Path $full -PathType Leaf)) {
            $doClean = $Force
            if (-not $doClean) {
                Write-LogLine (Lmsg "  stale path (skipped, use Force to clean): $full" "  \u5931\u6548\u8def\u5f84\uff08\u5df2\u8df3\u8fc7\uff0c\u7528\u5f3a\u5236\u6e05\u7406\uff09\uff1a$full") 'DarkOrange'
                [void]$records.Add($item)
                continue
            }
            if ($WhatIf) {
                Write-LogLine (Lmsg "  [preview] will clean: $full" "  \u9884\u89c8 \u5c06\u6e05\u7406\uff1a$full") 'Yellow'
                $cleaned++
                continue
            }
            Write-LogLine (Lmsg "  cleaned stale path: $full" "  \u5df2\u6e05\u7406\u5931\u6548\u8def\u5f84\uff1a$full") 'DarkGray'
            $cleaned++
            continue
        }
        $kept++
        $fileHash = (Get-FileHash -Path $full -Algorithm SHA256).Hash
        if ($fileHash -eq $sourceHash) {
            Write-LogLine (Lmsg "  skipped (identical): $full" "  \u8df3\u8fc7\uff08\u5df2\u4e00\u81f4\uff09\uff1a$full") 'DarkGray'
            $skippedSame++
            [void]$records.Add($item)
            continue
        }
        if ($WhatIf) {
            Write-LogLine (Lmsg "  [preview] will replace: $full" "  \u9884\u89c8 \u5c06\u66ff\u6362\uff1a$full") 'Yellow'
            $replaced++
            [void]$records.Add($item)
            continue
        }
        if (-not $Force) {
            Write-LogLine (Lmsg "  skipped (use Force to replace): $full" "  \u8df3\u8fc7\uff08\u7528\u5f3a\u5236\u66ff\u6362\uff09\uff1a$full") 'DarkOrange'
            [void]$records.Add($item)
            continue
        }
        try {
            $bak = "$full.bak.$timestamp"
            Copy-Item -Path $full -Destination $bak -Force
            [System.IO.File]::WriteAllBytes($full, $sourceBytes)
            Write-LogLine (Lmsg "  replaced (backup: $bak): $full" "  \u5df2\u66ff\u6362\uff08\u5907\u4efd\uff1a$bak\uff09\uff1a$full") 'Green'
            $replaced++
            [void]$records.Add($item)
        } catch {
            Write-LogLine (Lmsg "  failed $full : $($_.Exception.Message)" "  \u5931\u8d25 $full \uff1a$($_.Exception.Message)") 'Red'
            $errors++
            [void]$records.Add($item)
        }
    }

    if (-not $WhatIf) {
        if ($BackupList) {
            $listBak = "$List.bak.$timestamp"
            Copy-Item -Path $List -Destination $listBak -Force
            Write-LogLine (Lmsg "Manifest backed up: $listBak" "\u6e05\u5355\u5df2\u5907\u4efd\uff1a$listBak") 'DarkGray'
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

    Write-LogLine (Lmsg "Summary: valid=$kept identical=$skippedSame replaced=$replaced cleaned=$cleaned errors=$errors" "\u6458\u8981\uff1a\u6709\u6548=$kept \u4e00\u81f4=$skippedSame \u66ff\u6362=$replaced \u6e05\u7406=$cleaned \u9519\u8bef=$errors") 'Cyan'
}

# ---------- Event handlers ----------
$cmbLang.Add_SelectedIndexChanged({
    $lang = if ($cmbLang.SelectedIndex -eq 1) { 'zh' } else { 'en' }
    Apply-Language
})

$btnBrowseRoot.Add_Click({
    $p = Pick-Folder
    if ($p) { $txtRoot.Text = $p }
})

$btnBrowseOut.Add_Click({
    $p = Pick-File -Title (Lmsg 'Manifest output' '\u6e05\u5355\u8f93\u51fa') -Filter (Lmsg 'JSON files (*.json)|*.json|All files (*.*)|*.*' 'JSON \u6587\u4ef6 (*.json)|*.json|\u6240\u6709\u6587\u4ef6 (*.*)|*.*')
    if ($p) { $txtOut.Text = $p }
})

$btnOpenManifest.Add_Click({
    $p = $txtOut.Text
    if (Test-Path $p) {
        try { Invoke-Item $p } catch { Add-Log (Lmsg "Cannot open: $_" "\u65e0\u6cd5\u6253\u5f00\uff1a$_") 'Red' }
    } else {
        Add-Log (Lmsg "Manifest not found: $p" "\u672a\u627e\u5230\u6e05\u5355\uff1a$p") 'DarkOrange'
    }
})

$btnScan.Add_Click({
    Set-Busy $true
    try {
        Add-Log (Lmsg '--- Starting scan ---' '--- \u5f00\u59cb\u626b\u63cf ---') 'Blue'
        $out = $txtOut.Text.Trim()
        if (-not $out) { $out = Join-Path $scriptDir 'stignore-paths.json'; $txtOut.Text = $out }
        if ($chkPreview.Checked) {
            Add-Log (Lmsg 'Preview mode ON: no files will be written.' '\u9884\u89c8\u6a21\u5f0f\uff1a\u4e0d\u4f1a\u5199\u5165\u4efb\u4f55\u6587\u4ef6\u3002') 'Yellow'
        } else {
            Add-Log (Lmsg "Writing manifest to: $out" "\u6b63\u5728\u5199\u5165\u6e05\u5355\uff1a$out") 'Yellow'
        }
        Start-ScanJob -Root $txtRoot.Text.Trim() -Output $out -WhatIf $chkPreview.Checked
    } catch {
        Add-Log (Lmsg "ERROR: $_" "\u9519\u8bef\uff1a$_") 'Red'
    } finally {
        Set-Busy $false
    }
})

$btnApply.Add_Click({
    Set-Busy $true
    try {
        Add-Log (Lmsg '--- Starting apply ---' '--- \u5f00\u59cb\u5e94\u7528 ---') 'Blue'
        $list = $txtOut.Text.Trim()
        Start-ApplyJob -List $list -Source $StandardRuleSource -WhatIf $chkPreview.Checked -Force $chkForce.Checked -BackupList $chkBackupList.Checked
        Add-Log (Lmsg 'Apply finished.' '\u5e94\u7528\u5b8c\u6210\u3002') 'Green'
    } catch {
        Add-Log (Lmsg "ERROR: $_" "\u9519\u8bef\uff1a$_") 'Red'
    } finally {
        Set-Busy $false
    }
})

# ---------- Run ----------
Apply-Language
Add-Log (Lmsg "Tool ready. Scripts dir: $scriptDir" "\u5de5\u5177\u5df2\u5c31\u7eea\u3002\u811a\u672c\u76ee\u5f55\uff1a$scriptDir") 'Gray'
[System.Windows.Forms.Application]::EnableVisualStyles() | Out-Null
[System.Windows.Forms.Application]::Run($form)
