<#
//File: SyncthingIgnoreGUI.ps1
//Version: 1.3.0
//Updated: 2026-08-06
.SYNOPSIS
    Graphical interface for scanning and applying Syncthing .stignore rules.

.DESCRIPTION
    Self-contained WinForms GUI. Scan locates all .stignore files across the
    chosen roots and writes a JSON manifest; Apply writes the standard rules
    from .stignore into every recorded path (with auto-backup). No external
    script dependencies - all logic runs in-process.

.EXAMPLE
    .\SyncthingIgnoreGUI.ps1
    Launch the graphical tool.
#>

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = $PSScriptRoot
$ScriptVersion = '1.3.0'
$StandardRuleSource = Join-Path $scriptDir '.stignore'

# ---------- Form ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Syncthing .stignore Manager'
$form.Size = New-Object System.Drawing.Size(720, 560)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(640, 480)
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)

# ---------- Inputs: scan root ----------
$lblRoot = New-Object System.Windows.Forms.Label
$lblRoot.Text = 'Scan root (blank = all fixed drives):'
$lblRoot.Location = New-Object System.Drawing.Point(16, 16)
$lblRoot.AutoSize = $true
$form.Controls.Add($lblRoot)

$txtRoot = New-Object System.Windows.Forms.TextBox
$txtRoot.Location = New-Object System.Drawing.Point(16, 38)
$txtRoot.Size = New-Object System.Drawing.Size(540, 24)
$txtRoot.Text = ''
$form.Controls.Add($txtRoot)

$btnBrowseRoot = New-Object System.Windows.Forms.Button
$btnBrowseRoot.Text = 'Browse...'
$btnBrowseRoot.Location = New-Object System.Drawing.Point(566, 36)
$btnBrowseRoot.Size = New-Object System.Drawing.Size(120, 26)
$form.Controls.Add($btnBrowseRoot)

# ---------- Inputs: manifest output ----------
$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Text = 'Manifest output path:'
$lblOut.Location = New-Object System.Drawing.Point(16, 72)
$lblOut.AutoSize = $true
$form.Controls.Add($lblOut)

$txtOut = New-Object System.Windows.Forms.TextBox
$txtOut.Location = New-Object System.Drawing.Point(16, 94)
$txtOut.Size = New-Object System.Drawing.Size(540, 24)
$txtOut.Text = Join-Path $scriptDir 'stignore-paths.json'
$form.Controls.Add($txtOut)

$btnBrowseOut = New-Object System.Windows.Forms.Button
$btnBrowseOut.Text = 'Browse...'
$btnBrowseOut.Location = New-Object System.Drawing.Point(566, 92)
$btnBrowseOut.Size = New-Object System.Drawing.Size(120, 26)
$form.Controls.Add($btnBrowseOut)

# ---------- Options ----------
$chkPreview = New-Object System.Windows.Forms.CheckBox
$chkPreview.Text = 'Preview only (WhatIf - no changes written)'
$chkPreview.Location = New-Object System.Drawing.Point(16, 130)
$chkPreview.AutoSize = $true
$chkPreview.Checked = $false
$form.Controls.Add($chkPreview)

$chkForce = New-Object System.Windows.Forms.CheckBox
$chkForce.Text = 'Force (skip per-file confirmation)'
$chkForce.Location = New-Object System.Drawing.Point(300, 130)
$chkForce.AutoSize = $true
$chkForce.Checked = $false
$form.Controls.Add($chkForce)

$chkBackupList = New-Object System.Windows.Forms.CheckBox
$chkBackupList.Text = 'Back up manifest before writing'
$chkBackupList.Location = New-Object System.Drawing.Point(16, 156)
$chkBackupList.AutoSize = $true
$chkBackupList.Checked = $true
$form.Controls.Add($chkBackupList)

# ---------- Action buttons ----------
$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = 'Scan .stignore files'
$btnScan.Location = New-Object System.Drawing.Point(16, 190)
$btnScan.Size = New-Object System.Drawing.Size(180, 32)
$btnScan.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnScan.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnScan)

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text = 'Apply standard rules'
$btnApply.Location = New-Object System.Drawing.Point(210, 190)
$btnApply.Size = New-Object System.Drawing.Size(180, 32)
$btnApply.BackColor = [System.Drawing.Color]::FromArgb(46, 138, 87)
$btnApply.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnApply)

$btnOpenManifest = New-Object System.Windows.Forms.Button
$btnOpenManifest.Text = 'Open manifest'
$btnOpenManifest.Location = New-Object System.Drawing.Point(404, 190)
$btnOpenManifest.Size = New-Object System.Drawing.Size(120, 32)
$form.Controls.Add($btnOpenManifest)

# ---------- Log ----------
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = 'Log:'
$lblLog.Location = New-Object System.Drawing.Point(16, 234)
$lblLog.AutoSize = $true
$form.Controls.Add($lblLog)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(16, 256)
$txtLog.Size = New-Object System.Drawing.Size(672, 240)
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
    $dlg.Description = 'Select scan root folder'
    if ($dlg.ShowDialog() -eq 'OK') { return $dlg.SelectedPath }
    return $null
}

function Write-LogLine {
    param([string]$Message, [string]$Color = 'Black')
    Add-Log $Message $Color
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
        if ($roots.Count -eq 0) { throw 'No filesystem drives found.' }
        Write-LogLine "No root given; scanning drives: $($roots -join ', ')" 'Yellow'
    } else {
        if (-not (Test-Path $Root)) { throw "Scan root does not exist: $Root" }
        $roots = @($Root)
    }

    if ($WhatIf) {
        Write-LogLine "[preview] roots: $($roots -join ', ')" 'Yellow'
        Write-LogLine "[preview] output: $Output" 'Yellow'
        return
    }

    $records = @()
    foreach ($r in $roots) {
        Write-LogLine "Scanning root: $r" 'Cyan'
        try {
            $files = Get-ChildItem -Path $r -Include '.stignore' -Recurse -File -Force -ErrorAction SilentlyContinue
        } catch {
            Write-LogLine "Cannot access $r : $($_.Exception.Message)" 'DarkOrange'
            continue
        }
        foreach ($file in $files) {
            $full = $file.FullName
            if ($full -like '*\.git\*') { continue }
            if ($full -like "$scriptDir*") { continue }
            try {
                $hash = (Get-FileHash -Path $full -Algorithm SHA256).Hash
                $records += [pscustomobject]@{
                    path         = $full
                    sha256       = $hash
                    size         = $file.Length
                    lastWriteUtc = $file.LastWriteTimeUtc.ToString('o')
                    foundAtUtc   = (Get-Date).ToUniversalTime().ToString('o')
                }
                Write-LogLine "  recorded: $full" 'Green'
            } catch {
                Write-LogLine "  read failed $full : $($_.Exception.Message)" 'DarkOrange'
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
    Write-LogLine "Scan complete. Files: $($records.Count). Manifest: $Output" 'Green'
}

function Start-ApplyJob {
    param(
        [string]$List,
        [string]$Source,
        [bool]$WhatIf,
        [bool]$Force,
        [bool]$BackupList
    )
    if (-not (Test-Path $Source -PathType Leaf)) { throw "Standard rule source not found: $Source" }
    if (-not (Test-Path $List -PathType Leaf)) { throw "Manifest not found: $List (run Scan first)" }

    $sourceBytes = [System.IO.File]::ReadAllBytes($Source)
    if ($sourceBytes.Length -eq 0) { throw "Standard rule source is empty: $Source" }
    $sourceHash = (Get-FileHash -Path $Source -Algorithm SHA256).Hash
    Write-LogLine "Source: $Source  SHA256: $sourceHash" 'DarkGray'

    try {
        $manifest = Get-Content -Path $List -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        throw "Manifest parse failed (may be corrupted): $List - $($_.Exception.Message)"
    }
    if ($null -eq $manifest -or $null -eq $manifest.files) { throw "Manifest invalid or missing 'files': $List" }

    $records = [System.Collections.ArrayList]::new()
    $kept = 0; $replaced = 0; $skippedSame = 0; $cleaned = 0; $errors = 0
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    foreach ($item in $manifest.files) {
        $full = $item.path
        if ([string]::IsNullOrWhiteSpace($full)) { continue }
        if (-not (Test-Path $full -PathType Leaf)) {
            $doClean = $Force
            if (-not $doClean) {
                Write-LogLine "  stale path (skipped, use Force to clean): $full" 'DarkOrange'
                [void]$records.Add($item)
                continue
            }
            if ($WhatIf) {
                Write-LogLine "  [preview] will clean: $full" 'Yellow'
                $cleaned++
                continue
            }
            Write-LogLine "  cleaned stale path: $full" 'DarkGray'
            $cleaned++
            continue
        }
        $kept++
        $fileHash = (Get-FileHash -Path $full -Algorithm SHA256).Hash
        if ($fileHash -eq $sourceHash) {
            Write-LogLine "  skipped (identical): $full" 'DarkGray'
            $skippedSame++
            [void]$records.Add($item)
            continue
        }
        if ($WhatIf) {
            Write-LogLine "  [preview] will replace: $full" 'Yellow'
            $replaced++
            [void]$records.Add($item)
            continue
        }
        if (-not $Force) {
            Write-LogLine "  skipped (use Force to replace): $full" 'DarkOrange'
            [void]$records.Add($item)
            continue
        }
        try {
            $bak = "$full.bak.$timestamp"
            Copy-Item -Path $full -Destination $bak -Force
            [System.IO.File]::WriteAllBytes($full, $sourceBytes)
            Write-LogLine "  replaced (backup: $bak): $full" 'Green'
            $replaced++
            [void]$records.Add($item)
        } catch {
            Write-LogLine "  failed $full : $($_.Exception.Message)" 'Red'
            $errors++
            [void]$records.Add($item)
        }
    }

    if (-not $WhatIf) {
        if ($BackupList) {
            $listBak = "$List.bak.$timestamp"
            Copy-Item -Path $List -Destination $listBak -Force
            Write-LogLine "Manifest backed up: $listBak" 'DarkGray'
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

    Write-LogLine "Summary: valid=$kept identical=$skippedSame replaced=$replaced cleaned=$cleaned errors=$errors" 'Cyan'
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

# ---------- Event handlers ----------
$btnBrowseRoot.Add_Click({
    $p = Pick-Folder
    if ($p) { $txtRoot.Text = $p }
})

$btnBrowseOut.Add_Click({
    $p = Pick-File -Title 'Manifest output' -Filter 'JSON files (*.json)|*.json|All files (*.*)|*.*'
    if ($p) { $txtOut.Text = $p }
})

$btnOpenManifest.Add_Click({
    $p = $txtOut.Text
    if (Test-Path $p) {
        try { Invoke-Item $p } catch { Add-Log "Cannot open: $_" 'Red' }
    } else {
        Add-Log "Manifest not found: $p" 'DarkOrange'
    }
})

$btnScan.Add_Click({
    Set-Busy $true
    try {
        Add-Log '--- Starting scan ---' 'Blue'
        $out = $txtOut.Text.Trim()
        if (-not $out) { $out = Join-Path $scriptDir 'stignore-paths.json'; $txtOut.Text = $out }
        if ($chkPreview.Checked) {
            Add-Log 'Preview mode ON: no files will be written.' 'Yellow'
        } else {
            Add-Log "Writing manifest to: $out" 'Yellow'
        }
        Start-ScanJob -Root $txtRoot.Text.Trim() -Output $out -WhatIf $chkPreview.Checked
    } catch {
        Add-Log "ERROR: $_" 'Red'
    } finally {
        Set-Busy $false
    }
})

$btnApply.Add_Click({
    Set-Busy $true
    try {
        Add-Log '--- Starting apply ---' 'Blue'
        $list = $txtOut.Text.Trim()
        Start-ApplyJob -List $list -Source $StandardRuleSource -WhatIf $chkPreview.Checked -Force $chkForce.Checked -BackupList $chkBackupList.Checked
        Add-Log 'Apply finished.' 'Green'
    } catch {
        Add-Log "ERROR: $_" 'Red'
    } finally {
        Set-Busy $false
    }
})

# ---------- Run ----------
Add-Log "Tool ready. Scripts dir: $scriptDir" 'Gray'
[System.Windows.Forms.Application]::EnableVisualStyles() | Out-Null
[System.Windows.Forms.Application]::Run($form)
