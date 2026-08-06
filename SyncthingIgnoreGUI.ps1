<#
//File: SyncthingIgnoreGUI.ps1
//Version: 1.2.0
//Updated: 2026-08-06
.SYNOPSIS
    Graphical interface for scanning and applying Syncthing .stignore rules.

.DESCRIPTION
    A WinForms-based GUI that wraps scan-stignore.ps1 and apply-stignore.ps1.
    Provides scan root / output path selection, a live log panel, and
    preview/force options. No external dependencies beyond .NET WinForms.

.EXAMPLE
    .\SyncthingIgnoreGUI.ps1
    Launch the graphical tool.
#>

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = $PSScriptRoot
$scanScript  = Join-Path $scriptDir 'scan-stignore.ps1'
$applyScript = Join-Path $scriptDir 'apply-stignore.ps1'

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
$chkPreview.Checked = $true
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
        if (-not (Test-Path $scanScript)) { throw "Scan script missing: $scanScript" }
        $out = $txtOut.Text.Trim()
        if (-not $out) { $out = Join-Path $scriptDir 'stignore-paths.json'; $txtOut.Text = $out }
        $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scanScript, '-Output', $out)
        $root = $txtRoot.Text.Trim()
        if ($root) {
            if (-not (Test-Path $root)) { throw "Scan root does not exist: $root" }
            $argsList += '-Path'; $argsList += $root
        }
        if ($chkPreview.Checked) { $argsList += '-WhatIf' }
        Add-Log "Command: powershell $($argsList -join ' ')"
        & powershell.exe @argsList
        if ($chkPreview.Checked) {
            Add-Log 'Preview finished (no manifest written).' 'Blue'
        } else {
            Add-Log "Scan complete. Manifest: $out" 'Green'
        }
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
        if (-not (Test-Path $applyScript)) { throw "Apply script missing: $applyScript" }
        $list = $txtOut.Text.Trim()
        if (-not (Test-Path $list)) { throw "Manifest not found: $list (run Scan first)" }
        $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $applyScript, '-List', $list)
        if ($chkPreview.Checked) { $argsList += '-WhatIf' }
        if ($chkForce.Checked) { $argsList += '-Force' }
        if ($chkBackupList.Checked -and -not $chkPreview.Checked) { $argsList += '-BackupList' }
        Add-Log "Command: powershell $($argsList -join ' ')"
        & powershell.exe @argsList
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
