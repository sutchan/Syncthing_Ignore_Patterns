<#
//File: SyncthingIgnoreGUI.ps1
//Version: 1.18.0
//Updated: 2026-08-31
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

# WinForms requires an STA thread. When launched via "powershell -Command",
# the default apartment is MTA and the form silently fails to open. Restart
# the script in STA mode if needed.
# 预先加载程序集，便于在重启失败时用 MessageBox 给出清晰提示而非静默退出。
try { Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop } catch {}
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    try {
        $exe = (Get-Process -Id $PID).Path
        if (-not $exe) { $exe = 'powershell.exe' }
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $exe
        $psi.Arguments = "-STA -NoProfile -File `"$PSCommandPath`""
        $psi.WorkingDirectory = $PWD.ProviderPath
        $proc = [System.Diagnostics.Process]::Start($psi)
        $proc.WaitForExit()
        exit $proc.ExitCode
    } catch {
        if (('System.Windows.Forms.MessageBox' -as [type])) {
            [System.Windows.Forms.MessageBox]::Show(
                "无法以 STA 模式启动 GUI，请使用以下命令运行：`n`npowershell -STA -NoProfile -File `"$PSCommandPath`"`n`n错误：$_",
                '启动失败', 'OK', 'Error') | Out-Null
        } else {
            Write-Error "无法以 STA 模式启动 GUI：$_"
        }
        exit 1
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# Must be called before any control is created so visual styles apply.
[System.Windows.Forms.Application]::EnableVisualStyles() | Out-Null

$scriptDir = $PSScriptRoot
$ScriptVersion = '1.18.0'
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
        zhItem      = 'Chinese'
        folderTitle = 'Select scan root folder'
        fileTitle   = 'Manifest output'
        jsonFilter  = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
        ready       = 'Tool ready. Scripts dir: '
        repo        = 'Project: '
        summary     = 'Found {0} .stignore file(s).'
        clear       = 'Clear log'
        stop        = 'Stop'
        results     = 'Results:'
        dragTip     = 'Tip: drag a folder or .stignore here'
        theme       = 'Theme:'
        themeLight  = 'Light'
        themeDark   = 'Dark'
        confirmTitle= 'Confirm action'
        about       = 'About'
        aboutText   = "Syncthing .stignore Manager`nVersion {0}`nProject: {1}"
        replaced    = 'Replaced'
        identical   = 'Identical'
        cleaned     = 'Cleaned'
        failed      = 'Failed'
        scanDone    = 'Scan finished.'
        applyDone   = 'Apply finished.'
        stopped     = 'Operation stopped by user.'
        openFile    = 'Open file'
        applyTitle  = 'Apply standard rules'
        applyConfirm= 'About to write the standard .stignore rules into {0} path(s). Continue?'
        manifestLoaded = 'Existing manifest loaded: {0} file(s).'
        noManifest  = 'No manifest found. Run Scan first.'
        statusIdle  = 'Ready.'
        statusPrep  = 'Preparing...'
        statusScan  = 'Scanning {0}/{1} roots | found: {2} | now: {3} | {4}'
        statusScanOne = 'Scanning | found: {0} | now: {1} | {2}'
        statusApply = 'Applying {0}/{1}  |  {2}'
        scanning    = 'Scanning... found {0} so far'
        statusScanDone  = 'Scan done: {0} file(s) in {1}'
        statusApplyDone = 'Apply done: {0} path(s) in {1}'
        statusStopped   = 'Stopped by user.'
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
        repo        = '\u9879\u76ee\u5730\u5740\uff1a'
        summary     = '\u5df2\u627e\u5230 {0} \u4e2a .stignore \u6587\u4ef6\u3002'
        clear       = '\u6e05\u7a7a\u65e5\u5fd7'
        applyTitle  = '\u5e94\u7528\u6807\u51c6\u89c4\u5219'
        applyConfirm= '\u5373\u5c06\u628a\u6807\u51c6 .stignore \u89c4\u5219\u5199\u5165 {0} \u4e2a\u8def\u5f84\uff0c\u662f\u5426\u7ee7\u7eed\uff1f'
        manifestLoaded = '\u5df2\u52a0\u8f7d\u73b0\u6709\u6e05\u5355\uff1a{0} \u4e2a\u6587\u4ef6\u3002'
        noManifest  = '\u672a\u627e\u5230\u6e05\u5355\uff0c\u8bf7\u5148\u626b\u63cf\u3002'
        stop        = '\u505c\u6b62'
        results     = '\u7ed3\u679c\uff1a'
        dragTip     = '\u63d0\u793a\uff1a\u53ef\u5c06\u6587\u4ef6\u5939\u6216 .stignore \u62d6\u5165\u6b64\u5904'
        theme       = '\u4e3b\u9898\uff1a'
        themeLight  = '\u6d45\u8272'
        themeDark   = '\u6df1\u8272'
        confirmTitle= '\u786e\u8ba4\u64cd\u4f5c'
        about       = '\u5173\u4e8e'
        aboutText   = 'Syncthing .stignore \u7ba1\u7406\u5668`n\u7248\u672c {0}`n\u9879\u76ee\uff1a{1}'
        replaced    = '\u5df2\u66ff\u6362'
        identical   = '\u4e00\u81f4'
        cleaned     = '\u5df2\u6e05\u7406'
        failed      = '\u5931\u8d25'
        scanDone    = '\u626b\u63cf\u5b8c\u6210\u3002'
        applyDone   = '\u5e94\u7528\u5b8c\u6210\u3002'
        stopped     = '\u7528\u6237\u5df2\u505c\u6b62\u64cd\u4f5c\u3002'
        openFile    = '\u6253\u5f00\u6587\u4ef6'
        statusIdle  = '\u5c31\u7eea\u3002'
        statusPrep  = '\u6b63\u5728\u51c6\u5907...'
        statusScan  = '\u6b63\u5728\u626b\u63cf {0}/{1} \u4e2a\u6839\u76ee\u5f55  |  \u5df2\u627e\u5230\uff1a{2}  |  \u5f53\u524d\uff1a{3}  |  {4}'
        statusScanOne = '\u6b63\u5728\u626b\u63cf  |  \u5df2\u627e\u5230\uff1a{0}  |  \u5f53\u524d\uff1a{1}  |  {2}'
        statusApply = '\u6b63\u5728\u5e94\u7528 {0}/{1}  |  {2}'
        scanning    = '\u6b63\u5728\u626b\u63cf... \u76ee\u524d\u5df2\u627e\u5230 {0} \u4e2a'
        statusScanDone  = '\u626b\u63cf\u5b8c\u6210\uff1a{0} \u4e2a\u6587\u4ef6\uff0c\u7528\u65f6 {1}'
        statusApplyDone = '\u5e94\u7528\u5b8c\u6210\uff1a{0} \u4e2a\u8def\u5f84\uff0c\u7528\u65f6 {1}'
        statusStopped   = '\u7528\u6237\u5df2\u505c\u6b62\u3002'
    }
}

# Default language from system UI culture
try { $uiCulture = (Get-Culture).Name } catch { $uiCulture = 'en-US' }
$lang = if ($uiCulture -like 'zh*') { 'zh' } else { 'en' }

# ---------- Form ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = $T[$lang].title
$form.Size = New-Object System.Drawing.Size(720, 640)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(640, 560)
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
$form.AutoScroll = $false

# ---------- Language selector ----------
$lblLang = New-Object System.Windows.Forms.Label
$lblLang.Location = New-Object System.Drawing.Point(16, 14)
$lblLang.AutoSize = $true
$form.Controls.Add($lblLang)

$cmbLang = New-Object System.Windows.Forms.ComboBox
$cmbLang.Location = New-Object System.Drawing.Point(78, 10)
$cmbLang.Size = New-Object System.Drawing.Size(116, 24)
$cmbLang.DropDownStyle = 'DropDownList'
$cmbLang.Items.Add($T.en.enItem) | Out-Null
$cmbLang.Items.Add($T.en.zhItem) | Out-Null
$form.Controls.Add($cmbLang)

# ---------- Theme selector ----------
$lblTheme = New-Object System.Windows.Forms.Label
$lblTheme.Location = New-Object System.Drawing.Point(210, 14)
$lblTheme.AutoSize = $true
$form.Controls.Add($lblTheme)

$cmbTheme = New-Object System.Windows.Forms.ComboBox
$cmbTheme.Location = New-Object System.Drawing.Point(280, 10)
$cmbTheme.Size = New-Object System.Drawing.Size(92, 24)
$cmbTheme.DropDownStyle = 'DropDownList'
$cmbTheme.Items.Add($T.en.themeLight) | Out-Null
$cmbTheme.Items.Add($T.en.themeDark) | Out-Null
$cmbTheme.SelectedIndex = 0
$form.Controls.Add($cmbTheme)

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
$txtOut.Text = Join-Path $scriptDir 'config\stignore-paths.json'
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
$btnScan.Location = New-Object System.Drawing.Point(16, 212)
$btnScan.Size = New-Object System.Drawing.Size(180, 32)
$btnScan.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnScan.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnScan)

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Location = New-Object System.Drawing.Point(200, 212)
$btnApply.Size = New-Object System.Drawing.Size(180, 32)
$btnApply.BackColor = [System.Drawing.Color]::FromArgb(46, 138, 87)
$btnApply.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnApply)

$btnOpenManifest = New-Object System.Windows.Forms.Button
$btnOpenManifest.Location = New-Object System.Drawing.Point(384, 212)
$btnOpenManifest.Size = New-Object System.Drawing.Size(96, 32)
$form.Controls.Add($btnOpenManifest)

$btnClearLog = New-Object System.Windows.Forms.Button
$btnClearLog.Location = New-Object System.Drawing.Point(484, 212)
$btnClearLog.Size = New-Object System.Drawing.Size(88, 32)
$form.Controls.Add($btnClearLog)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Location = New-Object System.Drawing.Point(576, 212)
$btnStop.Size = New-Object System.Drawing.Size(60, 32)
$btnStop.BackColor = [System.Drawing.Color]::FromArgb(192, 80, 77)
$btnStop.ForeColor = [System.Drawing.Color]::White
$btnStop.Enabled = $false
$form.Controls.Add($btnStop)

$btnAbout = New-Object System.Windows.Forms.Button
$btnAbout.Location = New-Object System.Drawing.Point(644, 212)
$btnAbout.Size = New-Object System.Drawing.Size(48, 32)
$form.Controls.Add($btnAbout)

# ---------- Scan summary ----------
$lblSummary = New-Object System.Windows.Forms.Label
$lblSummary.Location = New-Object System.Drawing.Point(16, 252)
$lblSummary.AutoSize = $true
$lblSummary.ForeColor = [System.Drawing.Color]::FromArgb(46, 138, 87)
$lblSummary.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblSummary)

# ---------- Results list ----------
$lblResults = New-Object System.Windows.Forms.Label
$lblResults.Location = New-Object System.Drawing.Point(16, 276)
$lblResults.AutoSize = $true
$form.Controls.Add($lblResults)

$lstResults = New-Object System.Windows.Forms.ListBox
$lstResults.Location = New-Object System.Drawing.Point(16, 298)
$lstResults.Size = New-Object System.Drawing.Size(672, 126)
$lstResults.Anchor = 'Top,Left,Right'
$lstResults.HorizontalScrollbar = $true
$lstResults.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($lstResults)

# ---------- Log ----------
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Location = New-Object System.Drawing.Point(16, 430)
$lblLog.AutoSize = $true
$form.Controls.Add($lblLog)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(16, 452)
$txtLog.Size = New-Object System.Drawing.Size(672, 88)
$txtLog.Multiline = $true
$txtLog.ScrollBars = 'Vertical'
$txtLog.ReadOnly = $true
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$txtLog.Anchor = 'Top,Left,Right'
$txtLog.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($txtLog)

# ---------- Real-time status line ----------
# Single-line live status: current root / found count / latest hit / elapsed.
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Name = 'lblStatus'
$lblStatus.Location = New-Object System.Drawing.Point(16, 546)
$lblStatus.Size = New-Object System.Drawing.Size(672, 16)
$lblStatus.AutoSize = $false
$lblStatus.AutoEllipsis = $true
$lblStatus.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
$form.Controls.Add($lblStatus)

# ---------- Custom dark-mode borders (avoid bright system 3D edges) ----------
# Input controls get BorderStyle=None and a custom-drawn 1px border via the
# form's Paint event, so the edge color is fully controlled (dark gray in
# dark mode instead of the bright default system border).
$script:borderedControls = @($txtRoot, $txtOut, $cmbLang, $cmbTheme, $lstResults, $txtLog)
$script:borderColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
foreach ($bc in $script:borderedControls) {
    if ($bc.PSObject.Properties.Name -contains 'BorderStyle') { $bc.BorderStyle = 'None' }
}
$form.Add_Paint({
    param($sender, $e)
    foreach ($c in $script:borderedControls) {
        if ($c -and $c.IsHandleCreated) {
            # 恢复路径框（txtOut）使用更醒目的中灰色边框，区别于其它控件
            $edge = if ($c -eq $script:txtOut) { [System.Drawing.Color]::FromArgb(140, 140, 140) } else { $script:borderColor }
            [System.Windows.Forms.ControlPaint]::DrawBorder(
                $e.Graphics, $c.Bounds,
                $edge,
                1, [System.Windows.Forms.ButtonBorderStyle]::Solid,
                $edge,
                1, [System.Windows.Forms.ButtonBorderStyle]::Solid,
                $edge,
                1, [System.Windows.Forms.ButtonBorderStyle]::Solid,
                $edge,
                1, [System.Windows.Forms.ButtonBorderStyle]::Solid)
        }
    }
})

# Real percentage progress bar (Blocks style for accurate feedback).
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Name = 'progress'
$progress.Location = New-Object System.Drawing.Point(16, 566)
$progress.Size = New-Object System.Drawing.Size(560, 14)
$progress.Style = 'Blocks'
$progress.Minimum = 0
$progress.Maximum = 100
$progress.Value = 0
$progress.Visible = $false
$form.Controls.Add($progress)

# Percentage text next to the progress bar.
$lblPct = New-Object System.Windows.Forms.Label
$lblPct.Name = 'lblPct'
$lblPct.Location = New-Object System.Drawing.Point(584, 564)
$lblPct.AutoSize = $true
$lblPct.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
$lblPct.Visible = $false
$form.Controls.Add($lblPct)

# ---------- Version + project link (status bar) ----------
$RepoUrl = 'https://github.com/sutchan/Syncthing_Ignore_Patterns'

$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Location = New-Object System.Drawing.Point(16, 600)
$lblVersion.AutoSize = $true
$lblVersion.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
$lblVersion.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
$form.Controls.Add($lblVersion)

$lblRepo = New-Object System.Windows.Forms.LinkLabel
$lblRepo.Location = New-Object System.Drawing.Point(300, 600)
$lblRepo.AutoSize = $true
$lblRepo.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
$lblRepo.LinkColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$lblRepo.Add_LinkClicked({
    try { Start-Process $RepoUrl } catch { Add-Log (Lmsg "Cannot open link: $_" "\u65e0\u6cd5\u6253\u5f00\u94fe\u63a5\uff1a$_") 'Red' }
})
$form.Controls.Add($lblRepo)

# ---------- Config persistence (language + theme) ----------
$ConfigPath = Join-Path $scriptDir 'config.json'
function Get-Config {
    if (Test-Path $ConfigPath) {
        try { return (Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json) } catch {}
    }
    return $null
}
function Save-Config {
    param([string]$Language, [string]$Theme)
    try {
        $obj = [pscustomobject]@{ language = $Language; theme = $Theme; version = $ScriptVersion }
        Set-Content -Path $ConfigPath -Value ($obj | ConvertTo-Json -Compress) -Encoding UTF8
    } catch {}
}

# Theme application: switch light/dark palettes across all controls.
function Apply-Theme {
    param([string]$Theme)
    $dark = ($Theme -eq 'dark')
    if ($dark) {
        $bg = [System.Drawing.Color]::FromArgb(40, 40, 40)
        $fg = [System.Drawing.Color]::FromArgb(228, 228, 228)
        $ctrlBg = [System.Drawing.Color]::FromArgb(55, 55, 55)
        $logBg = [System.Drawing.Color]::FromArgb(30, 30, 30)
    } else {
        $bg = [System.Drawing.Color]::FromArgb(240, 240, 240)
        $fg = [System.Drawing.Color]::FromArgb(0, 0, 0)
        $ctrlBg = [System.Drawing.Color]::White
        $logBg = [System.Drawing.Color]::FromArgb(245, 245, 245)
    }
    $form.BackColor = $bg
    $form.ForeColor = $fg
    # Custom border color: dark gray in dark mode (no bright system edge),
    # medium gray in light mode. Applied via form.Paint on bordered controls.
    $script:borderColor = if ($dark) { [System.Drawing.Color]::FromArgb(85, 85, 85) } else { [System.Drawing.Color]::FromArgb(120, 120, 120) }
    $allControls = New-Object System.Collections.ArrayList
    $stack = New-Object System.Collections.Stack
    $stack.Push($form)
    while ($stack.Count -gt 0) {
        $cur = $stack.Pop()
        foreach ($child in $cur.Controls) {
            $allControls.Add($child) | Out-Null
            if ($child.Controls.Count -gt 0) { $stack.Push($child) }
        }
    }
    # Button border color: dark gray in dark mode so the edge doesn't glare,
    # medium gray in light mode. Applied via FlatStyle instead of the default
    # bright 3D bevel.
    $btnBorder = if ($dark) { [System.Drawing.Color]::FromArgb(70, 70, 70) } else { [System.Drawing.Color]::FromArgb(150, 150, 150) }
    foreach ($c in $allControls) {
        if ($c -is [System.Windows.Forms.Button]) {
            # Replace the bright default 3D bevel with a flat, controlled edge.
            $c.FlatStyle = 'Flat'
            $c.FlatAppearance.BorderColor = $btnBorder
            $c.FlatAppearance.BorderSize = 1
            $isAccent = ($c.BackColor -eq [System.Drawing.Color]::FromArgb(0,120,215)) -or ($c.BackColor -eq [System.Drawing.Color]::FromArgb(46,138,87)) -or ($c.BackColor -eq [System.Drawing.Color]::FromArgb(192,80,77))
            if (-not $isAccent) {
                $c.BackColor = $ctrlBg
                $c.ForeColor = $fg
            }
        } elseif ($c -is [System.Windows.Forms.ComboBox] -or $c -is [System.Windows.Forms.TextBox] -or $c -is [System.Windows.Forms.ListBox] -or $c -is [System.Windows.Forms.Label] -or $c -is [System.Windows.Forms.CheckBox] -or $c -is [System.Windows.Forms.LinkLabel]) {
            $c.BackColor = $bg
            $c.ForeColor = $fg
        }
    }
    $txtLog.BackColor = $logBg
    $lstResults.BackColor = $ctrlBg
    $lstResults.ForeColor = $fg
    $form.PerformLayout()
    $form.Refresh()
    $form.Invalidate()
    [System.Windows.Forms.Application]::DoEvents()
}

# ---------- Apply language to all controls ----------
function Apply-Language {
    $script:applyingLang = $true
    try {
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
    $btnClearLog.Text     = if ($lang -eq 'zh') { Decode-Uni $d.clear } else { $d.clear }
    $btnStop.Text         = if ($lang -eq 'zh') { Decode-Uni $d.stop } else { $d.stop }
    $btnAbout.Text        = if ($lang -eq 'zh') { Decode-Uni $d.about } else { $d.about }
    $lblResults.Text      = if ($lang -eq 'zh') { Decode-Uni $d.results } else { $d.results }
    $lblTheme.Text        = if ($lang -eq 'zh') { Decode-Uni $d.theme } else { $d.theme }
    $lblLog.Text          = if ($lang -eq 'zh') { Decode-Uni $d.log } else { $d.log }
    # Ensure the theme combo language follows the selected UI language.
    if ($cmbTheme.Items.Count -ge 2) {
        $cmbTheme.Items[0] = if ($lang -eq 'zh') { Decode-Uni $d.themeLight } else { $d.themeLight }
        $cmbTheme.Items[1] = if ($lang -eq 'zh') { Decode-Uni $d.themeDark } else { $d.themeDark }
    }
    if ($lang -eq 'zh') {
        $lblVersion.Text = "v$ScriptVersion  |  SyncthingIgnorePatterns"
        $lblRepo.Text    = "$(Decode-Uni $d.repo)$RepoUrl"
    } else {
        $lblVersion.Text = "v$ScriptVersion  |  SyncthingIgnorePatterns"
        $lblRepo.Text    = "$($d.repo)$RepoUrl"
    }
    # Idle status text; a running job overwrites it on the next timer tick.
    $lblStatus.Text = (Lmsg $d.statusIdle (Decode-Uni $d.statusIdle))
    $cmbLang.SelectedIndex = if ($lang -eq 'zh') { 1 } else { 0 }
    } finally {
        $script:applyingLang = $false
    }
}

# ---------- Helpers ----------
# Unified logging entry used by both Scan and Apply jobs.
function Write-LogLine {
    param([string]$Message, [string]$Color = 'Black')
    $ts = (Get-Date).ToString('HH:mm:ss')
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.AppendText("[$ts] $Message`r`n")
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# Backwards-compatible alias for older call sites.
function Add-Log {
    param([string]$Message, [string]$Color = 'Black')
    Write-LogLine -Message $Message -Color $Color
}

# ---------- Real-time status helpers ----------
# Thread-safe shared state for the parallel scanner. The scanner runspaces
# write into it; the UI thread reads it every timer tick (no cross-thread
# marshalling needed, so the UI never blocks).
function New-ScanState {
    $st = [hashtable]::Synchronized(([hashtable]@{}))
    $st.Lock    = New-Object object
    $st.Files   = 0
    $st.Done    = 0
    $st.Total   = 0
    $st.Current = ''
    $st.CurrentDir = ''
    $st.Last    = ''
    $st.ErrDirs = 0
    $st.Started = $null
    $st.Records = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    return $st
}

# Elapsed time as mm:ss (h:mm:ss past one hour).
function Format-Elapsed {
    param($Start)
    if ($null -eq $Start) { return '00:00' }
    $ts = (Get-Date) - ([datetime]$Start)
    if ($ts.TotalHours -ge 1) { return $ts.ToString('h\:mm\:ss') }
    return $ts.ToString('mm\:ss')
}

# Keep long paths on one status line: head + '...' + tail.
function Shorten-Path {
    param([string]$Path, [int]$Max = 52)
    if ([string]::IsNullOrEmpty($Path)) { return '' }
    if ($Path.Length -le $Max) { return $Path }
    $tailLen = 22
    $headLen = [Math]::Max(1, $Max - $tailLen - 3)
    return ($Path.Substring(0, $headLen) + '...' + $Path.Substring($Path.Length - $tailLen))
}

# Pull the live counters from the shared state onto the status line.
function Update-ScanStatus {
    param($State)
    if ($null -eq $State) { return }
    $files = [int]$State.Files
    $done  = [int]$State.Done
    $total = [int]$State.Total
    # Prefer the directory being traversed; fall back to the latest hit.
    $last  = [string]$State.CurrentDir
    if (-not $last) { $last = [string]$State.Last }
    $el = Format-Elapsed $State.Started
    if ($total -gt 1 -and $progress.Style -ne 'Marquee') {
        $pct = [int](($done / [Math]::Max(1, $total)) * 100)
        $pct = [Math]::Max(0, [Math]::Min(100, $pct))
        $progress.Value = $pct
        $lblPct.Text = "$pct%"
    } else {
        $lblPct.Text = "$files"
    }
    $lblPct.Visible = $true
    $cur = Shorten-Path $last 72
    if ($total -gt 1) {
        $tpl = $T[$lang].statusScan
        $lblStatus.Text = (Lmsg ($tpl -f $done, $total, $files, $cur, $el) (Decode-Uni $tpl -f $done, $total, $files, $cur, $el))
    } else {
        $tpl = $T[$lang].statusScanOne
        $lblStatus.Text = (Lmsg ($tpl -f $files, $cur, $el) (Decode-Uni $tpl -f $files, $cur, $el))
    }
    $scanTpl = $T[$lang].scanning
    $lblSummary.Text = (Lmsg ($scanTpl -f $files) (Decode-Uni $scanTpl -f $files))
    # Stream newly found paths into the results list as they are discovered.
    $recs = $State.Records
    if ($null -ne $recs -and $recs.Count -gt $script:scanRendered) {
        for ($i = $script:scanRendered; $i -lt $recs.Count; $i++) {
            [void]$lstResults.Items.Add([string]$recs[$i].path)
        }
        $script:scanRendered = $recs.Count
    }
}

# Keep at most $Keep newest backups matching "<Base>.bak.*" (by last-write time).
# Any older extras are deleted. Returns count of removed files.
function Limit-Backups {
    param([string]$Base, [int]$Keep = 3)
    try {
        $backups = @(Get-ChildItem -Path "$Base.bak.*" -File -Force -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc)
        if ($backups.Count -le $Keep) { return 0 }
        $remove = $backups[0..($backups.Count - $Keep - 1)]
        $n = 0
        foreach ($b in $remove) {
            Remove-Item -Path $b.FullName -Force -ErrorAction SilentlyContinue
            $n++
        }
        return $n
    } catch {
        return 0
    }
}

# Parallel multi-root scanner using a runspace pool.
# The scanner logic is passed as an inline script block so that the runspace
# (which has no access to the caller's function definitions) can execute it.
# Returns an ArrayList of file records (errors surfaced as __error entries).
function Start-ParallelScan {
    param([string[]]$Roots, [string]$ScriptDir, [int]$MaxThreads = 4, $State)

    $scanScript = {
        param([string]$Root, [string]$ScriptDir, $State)
        # Bump a shared counter safely: several runspaces hit it concurrently.
        function Add-StateCount {
            param($State, [string]$Key, [int]$Delta = 1)
            if ($null -eq $State) { return }
            try {
                [System.Threading.Monitor]::Enter($State.Lock)
                $State[$Key] = ([int]$State[$Key]) + $Delta
            } finally {
                [System.Threading.Monitor]::Exit($State.Lock)
            }
        }
        # Explicit depth-first walk instead of Get-ChildItem -Recurse: the
        # pipeline cannot report where it currently is, while this loop
        # publishes every directory it enters to the shared state, so the GUI
        # can show the live scan path. One enumeration per directory yields
        # both files and sub-directories (no extra IO per entry).
        function Find-StignoreFiles {
            param([string]$Root, [string]$ScriptDir, $State)
            $local = [System.Collections.ArrayList]::new()
            if (-not [System.IO.Directory]::Exists($Root)) {
                [void]$local.Add([pscustomobject]@{ __error = "$Root : directory not found" })
                return $local
            }
            $skipDir = if ($ScriptDir) { $ScriptDir.TrimEnd('\', '/').ToLowerInvariant() } else { '' }
            $stack = [System.Collections.Stack]::new()
            $stack.Push($Root)
            while ($stack.Count -gt 0) {
                $dir = [string]$stack.Pop()
                # Live feedback: the directory being traversed right now.
                if ($null -ne $State) { $State.CurrentDir = $dir }
                try {
                    $di = [System.IO.DirectoryInfo]::new($dir)
                    foreach ($e in $di.EnumerateFileSystemInfos('*')) {
                        if ($e -is [System.IO.DirectoryInfo]) {
                            # Skip .git and the tool's own directory subtree.
                            if ($e.Name -eq '.git') { continue }
                            if ($skipDir -and $e.FullName.ToLowerInvariant() -eq $skipDir) { continue }
                            $stack.Push($e.FullName)
                            continue
                        }
                        if ($e.Name -ne '.stignore') { continue }
                        $rec = [pscustomobject]@{
                            path         = $e.FullName
                            size         = $e.Length
                            lastWriteUtc = $e.LastWriteTimeUtc.ToString('o')
                            foundAtUtc   = (Get-Date).ToUniversalTime().ToString('o')
                        }
                        [void]$local.Add($rec)
                        # Live feedback: count + latest hit shared with the GUI.
                        if ($null -ne $State) {
                            Add-StateCount $State 'Files' 1
                            $State.Last = $e.FullName
                            [void]$State.Records.Add($rec)
                        }
                    }
                } catch {
                    # Unreadable directory (access denied / too long path):
                    # count it and keep walking the rest of the tree.
                    if ($null -ne $State) { Add-StateCount $State 'ErrDirs' 1 }
                }
            }
            return $local
        }
        return (Find-StignoreFiles -Root $Root -ScriptDir $ScriptDir -State $State)
    }

    $pool = [runspacefactory]::CreateRunspacePool(1, [Math]::Max(1, $MaxThreads))
    $pool.Open()
    $jobs = @()
    foreach ($r in $Roots) {
        $ps = [powershell]::Create().AddScript($scanScript).AddArgument($r).AddArgument($ScriptDir).AddArgument($State)
        $ps.RunspacePool = $pool
        $jobs += [pscustomobject]@{ Root = $r; Handle = $ps.BeginInvoke(); PS = $ps }
    }
    $all = [System.Collections.ArrayList]::new()
    $done = 0
    $total = $jobs.Count
    foreach ($j in $jobs) {
        $res = $j.PS.EndInvoke($j.Handle)
        foreach ($rec in $res) { [void]$all.Add($rec) }
        $j.PS.Dispose()
        $done++
        # Only the orchestrating thread writes Done, so no lock is needed here.
        # The GUI timer pulls these counters every tick instead of marshalling
        # a callback here (also avoids touching Value while Style=Marquee).
        if ($null -ne $State) { $State.Done = $done }
    }
    $pool.Close()
    $pool.Dispose()
    return $all
}

function Set-Busy {
    param([bool]$Busy, [string]$Mode = 'scan', [int]$Total = 0)
    $btnScan.Enabled = -not $Busy
    $btnApply.Enabled = -not $Busy
    $btnOpenManifest.Enabled = -not $Busy
    $btnClearLog.Enabled = -not $Busy
    # Stop button is only active while a background job is running.
    $btnStop.Enabled = $Busy
    $progress.Visible = $Busy
    $lblPct.Visible = $Busy
    if ($Busy) {
        # Total is unknown (or a single root) for scans: use a marquee and let
        # the live status line carry the real feedback instead of a fake %.
        if ($Mode -eq 'scan' -and $Total -le 1) {
            $progress.Style = 'Marquee'
            $progress.MarqueeAnimationSpeed = 30
            $lblPct.Text = '0'
        } else {
            $progress.Style = 'Blocks'
            $progress.Value = 0
            $lblPct.Text = '0%'
        }
    } else {
        $progress.Style = 'Blocks'
        $progress.MarqueeAnimationSpeed = 0
        $progress.Value = 100
        $lblPct.Text = '100%'
    }
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

# Pure data core: compute roots and run the parallel scan off the UI thread.
# Returns a hashtable { roots, raw, error }. No UI access here.
function Invoke-ScanCore {
    param(
        [string]$Root,
        [string]$ScriptDir,
        $State
    )
    $roots = @()
    if ([string]::IsNullOrWhiteSpace($Root)) {
        $roots = @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
            Where-Object { $_.Free -ne $null } | Select-Object -ExpandProperty Root)
        if ($roots.Count -eq 0) { throw 'No filesystem drives found.' }
    } else {
        if (-not (Test-Path $Root)) { throw "Scan root does not exist: $Root" }
        $roots = @($Root)
    }
    if ($null -ne $State) {
        $State.Total = $roots.Count
        $State.Started = Get-Date
    }
    $raw = Start-ParallelScan -Roots $roots -ScriptDir $ScriptDir -MaxThreads 4 -State $State
    return [pscustomobject]@{ roots = $roots; raw = $raw }
}

function Start-ApplyJob {
    param(
        [string]$List,
        [string]$Source,
        [bool]$WhatIf,
        [bool]$Force,
        [bool]$BackupList,
        $FormObj
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
    $total = $manifest.files.Count
    $done = 0

    foreach ($item in $manifest.files) {
        $full = $item.path
        if ([string]::IsNullOrWhiteSpace($full)) { continue }
        $done++
        if ($null -ne $FormObj) {
            $pct = [int](($done / [Math]::Max(1, $total)) * 100)
            $applyTpl = $T[$lang].statusApply
            $curText = (Lmsg ($applyTpl -f $done, $total, (Shorten-Path $full)) (Decode-Uni $applyTpl -f $done, $total, (Shorten-Path $full)))
            $FormObj.Invoke([Action[int,string]] {
                param([int]$p, [string]$c)
                $pb = $FormObj.Controls.Find('progress', $true)
                if ($pb.Count -gt 0 -and $pb[0].Style -ne 'Marquee') { $pb[0].Value = [Math]::Max(0, [Math]::Min(100, $p)) }
                $pc = $FormObj.Controls.Find('lblPct', $true)
                if ($pc.Count -gt 0) { $pc[0].Text = "$p%" }
                $st = $FormObj.Controls.Find('lblStatus', $true)
                if ($st.Count -gt 0) { $st[0].Text = $c }
                [System.Windows.Forms.Application]::DoEvents()
            }, @($pct, $curText))
        }
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
            # Do not back up the target when it IS the standard .stignore source
            # itself (e.g. applying rules into the project's own .stignore dir).
            $isSourceFile = ($full -eq $Source)
            if (-not $isSourceFile) {
                $bak = "$full.bak.$timestamp"
                Copy-Item -Path $full -Destination $bak -Force
                $removed = Limit-Backups -Base $full -Keep 3
                if ($removed -gt 0) {
                    Write-LogLine (Lmsg "  cleaned $removed old backup(s) for: $full" "  \u5df2\u6e05\u7406 $removed \u4e2a\u65e7\u5907\u4efd\uff1a$full") 'DarkGray'
                }
                Write-LogLine (Lmsg "  replaced (backup: $bak): $full" "  \u5df2\u66ff\u6362\uff08\u5907\u4efd\uff1a$bak\uff09\uff1a$full") 'Green'
            } else {
                Write-LogLine (Lmsg "  replaced (no backup, source .stignore): $full" "  \u5df2\u66ff\u6362\uff08\u4e0d\u5907\u4efd\uff0c\u6e90 .stignore\uff09\uff1a$full") 'Green'
            }
            [System.IO.File]::WriteAllBytes($full, $sourceBytes)
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
            $removed = Limit-Backups -Base $List -Keep 3
            if ($removed -gt 0) {
                Write-LogLine (Lmsg "Cleaned $removed old manifest backup(s)" "\u5df2\u6e05\u7406 $removed \u4e2a\u65e7\u6e05\u5355\u5907\u4efd") 'DarkGray'
            }
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

    # Surface a short status for the GUI summary label via a cross-thread-safe call.
    if ($null -ne $FormObj) {
        $summaryMsg = (Lmsg ($T[$lang].summary -f $total) (Decode-Uni $T[$lang].summary -f $total))
        $FormObj.Invoke([Action[string]] {
            param([string]$m)
            $script:lblSummary.Text = $m
        }, $summaryMsg)
    }
}

# ---------- Event handlers ----------
$cmbLang.Add_SelectedIndexChanged({
    if ($script:applyingLang) { return }
    $lang = if ($cmbLang.SelectedIndex -eq 1) { 'zh' } else { 'en' }
    Apply-Language
    Save-Config -Language $lang -Theme $script:currentTheme
})

$cmbTheme.Add_SelectedIndexChanged({
    if ($script:applyingLang) { return }
    $script:currentTheme = if ($cmbTheme.SelectedIndex -eq 1) { 'dark' } else { 'light' }
    Apply-Theme -Theme $script:currentTheme
    Save-Config -Language $lang -Theme $script:currentTheme
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
    Add-Log (Lmsg '--- Starting scan ---' '--- \u5f00\u59cb\u626b\u63cf ---') 'Blue'
    $lstResults.Items.Clear()
    $out = $txtOut.Text.Trim()
    if (-not $out) { $out = Join-Path $scriptDir 'config\stignore-paths.json'; $txtOut.Text = $out }
    # 确保清单输出目录存在（首次运行 config/ 可能尚未创建）
    try { $dir = Split-Path -Path $out -Parent; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null } } catch {}
    $rootArg = $txtRoot.Text.Trim()
    $whatif = $chkPreview.Checked
    if ($whatif) {
        Add-Log (Lmsg 'Preview mode: listing results only, no manifest written.' '\u9884\u89c8\u6a21\u5f0f\uff1a\u4ec5\u5217\u51fa\u7ed3\u679c\uff0c\u4e0d\u5199\u5165\u6e05\u5355\u3002') 'Yellow'
    } else {
        Add-Log (Lmsg "Writing manifest to: $out" "\u6b63\u5728\u5199\u5165\u6e05\u5355\uff1a$out") 'Yellow'
    }

    # Pre-compute how many roots the scan will walk: with a single root the
    # total is unknown, so the bar becomes a marquee and the status line shows
    # the real feedback (found count / latest hit / elapsed).
    $rootTotal = if ([string]::IsNullOrWhiteSpace($rootArg)) {
        @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Where-Object { $_.Free -ne $null }).Count
    } else { 1 }
    Set-Busy $true -Mode 'scan' -Total $rootTotal
    $script:scanState = New-ScanState
    $script:scanRendered = 0
    $lblStatus.Text = (Lmsg $T[$lang].statusPrep (Decode-Uni $T[$lang].statusPrep))

    # Run the scan off the UI thread so the GUI stays responsive. The shared
    # $script:scanState carries live counters back to the UI thread.
    $bg = [powershell]::Create().AddCommand('Invoke-ScanCore').AddArgument($rootArg).AddArgument($scriptDir).AddArgument($script:scanState)
    $bgHandle = $bg.BeginInvoke()
    $script:cancelFlag = $false

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 100
    $timer.Add_Tick({
        [System.Windows.Forms.Application]::DoEvents()
        Update-ScanStatus -State $script:scanState
        if ($script:cancelFlag) {
            $timer.Stop()
            # Hard-abort the background job so it cannot write the manifest.
            try { $bg.Stop() } catch {}
            try { $bg.Dispose() } catch {}
            Add-Log (Lmsg 'Scan stopped by user. Background job aborted; manifest NOT written.' '\u7528\u6237\u5df2\u505c\u6b62\u626b\u63cf\u3002\u540e\u53f0\u4efb\u52a1\u5df2\u4e2d\u65ad\uff1b\u672a\u5199\u5165\u6e05\u5355\u3002') 'DarkOrange'
            $lblStatus.Text = (Lmsg $T[$lang].statusStopped (Decode-Uni $T[$lang].statusStopped))
            $progress.Visible = $false; $lblPct.Visible = $false
            Set-Busy $false
            return
        }
        if ($bgHandle.IsCompleted) {
            $timer.Stop()
            try {
                $core = $bg.EndInvoke($bgHandle)
                $bg.Dispose()
                $raw = $core.raw
                $roots = $core.roots
                $records = [System.Collections.ArrayList]::new()
                $errCount = 0
                foreach ($rec in $raw) {
                    if ($null -ne $rec.__error) {
                        Add-Log (Lmsg "Cannot access $($rec.__error)" "\u65e0\u6cd5\u8bbf\u95ee $($rec.__error)") 'DarkOrange'
                        $errCount++
                        continue
                    }
                    [void]$records.Add($rec)
                }
                # Paths were streamed into the list while scanning; only rebuild
                # if nothing was rendered (e.g. live state unavailable).
                if ($script:lstResults.Items.Count -eq 0) {
                    foreach ($rec in $records) { [void]$script:lstResults.Items.Add($rec.path) }
                }
                # Unreadable directories were skipped individually; report the
                # total once so the count is visible but does not flood the log.
                $skipDirs = [int]$script:scanState.ErrDirs
                if ($skipDirs -gt 0) {
                    Add-Log (Lmsg "Skipped $skipDirs inaccessible directories." "\u5df2\u8df3\u8fc7 $skipDirs \u4e2a\u65e0\u6743\u8bbf\u95ee\u7684\u76ee\u5f55\u3002") 'DarkGray'
                }
                # Marquee mode rejects Value assignments, so switch back first.
                $progress.Style = 'Blocks'
                $progress.Value = 100; $lblPct.Text = '100%'
                if ($whatif) {
                    Add-Log (Lmsg "Preview complete. Files: $($records.Count) (errors: $errCount). Manifest NOT written." "\u9884\u89c8\u5b8c\u6210\u3002\u6587\u4ef6\u6570\uff1a$($records.Count)\uff08\u9519\u8bef\uff1a$errCount\uff09\u3002\u672a\u5199\u5165\u6e05\u5355\u3002") 'Green'
                } else {
                    $manifest = [pscustomobject]@{
                        version   = $ScriptVersion
                        scannedAt = (Get-Date).ToUniversalTime().ToString('o')
                        count     = $records.Count
                        roots     = $roots
                        files     = $records
                    }
                    $json = $manifest | ConvertTo-Json -Depth 4 -Compress:$false
                    Set-Content -Path $out -Value $json -Encoding UTF8
                    Add-Log (Lmsg "Scan complete. Files: $($records.Count) (errors: $errCount). Manifest: $out" "\u626b\u63cf\u5b8c\u6210\u3002\u6587\u4ef6\u6570\uff1a$($records.Count)\uff08\u9519\u8bef\uff1a$errCount\uff09\u3002\u6e05\u5355\uff1a$out") 'Green'
                    [System.Windows.Forms.MessageBox]::Show((Lmsg $T[$lang].scanDone (Decode-Uni $T[$lang].scanDone)), (Lmsg $T[$lang].confirmTitle (Decode-Uni $T[$lang].confirmTitle)), 'OK', 'Information') | Out-Null
                }
                $script:lblSummary.Text = (Lmsg ($T[$lang].summary -f $records.Count) (Decode-Uni $T[$lang].summary -f $records.Count))
                $scanTpl = $T[$lang].statusScanDone
                $el = Format-Elapsed $script:scanState.Started
                $lblStatus.Text = (Lmsg ($scanTpl -f $records.Count, $el) (Decode-Uni $scanTpl -f $records.Count, $el))
            } catch {
                Add-Log (Lmsg "ERROR: $_" "\u9519\u8bef\uff1a$_") 'Red'
            } finally {
                $progress.Visible = $false; $lblPct.Visible = $false
                Set-Busy $false
                $script:cancelFlag = $false
            }
        }
    })
    $timer.Start()
})

$btnApply.Add_Click({
    $list = $txtOut.Text.Trim()
    if (-not (Test-Path $list -PathType Leaf)) {
        Add-Log (Lmsg "Manifest not found: $list (run Scan first)" "\u672a\u627e\u5230\u6e05\u5355\uff1a$list\uff08\u8bf7\u5148\u626b\u63cf\uff09") 'DarkOrange'
        return
    }
    # Safety confirmation before writing standard rules into target paths.
    if (-not $chkPreview.Checked -and -not $chkForce.Checked) {
        $count = 0
        try { $count = @((Get-Content -Path $list -Raw -Encoding UTF8 | ConvertFrom-Json).files).Count } catch {}
        $msg = (Lmsg ($T[$lang].applyConfirm -f $count) (Decode-Uni $T[$lang].applyConfirm -f $count))
        $ans = [System.Windows.Forms.MessageBox]::Show($msg, (Lmsg $T[$lang].applyTitle (Decode-Uni $T[$lang].applyTitle)), 'YesNo', 'Warning')
        if ($ans -ne 'Yes') {
            Add-Log (Lmsg 'Apply cancelled by user.' '\u5e94\u7528\u5df2\u88ab\u7528\u6237\u53d6\u6d88\u3002') 'Gray'
            return
        }
    }

    Set-Busy $true -Mode 'apply' -Total 1
    $script:cancelFlag = $false
    $script:applyStarted = Get-Date
    $lblStatus.Text = (Lmsg $T[$lang].statusPrep (Decode-Uni $T[$lang].statusPrep))
    Add-Log (Lmsg '--- Starting apply ---' '--- \u5f00\u59cb\u5e94\u7528 ---') 'Blue'
    # Run apply off the UI thread; progress is pushed via form.Invoke.
    $bg = [powershell]::Create().AddCommand('Start-ApplyJob').AddArgument($list).AddArgument($StandardRuleSource).AddArgument($chkPreview.Checked).AddArgument($chkForce.Checked).AddArgument($chkBackupList.Checked).AddArgument($form)
    $bgHandle = $bg.BeginInvoke()
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 100
    $timer.Add_Tick({
        [System.Windows.Forms.Application]::DoEvents()
        # Mirror the live progress (driven by form.Invoke inside the job).
        $lblPct.Visible = $true
        $lblPct.Text = "$($progress.Value)%"
        if ($script:cancelFlag) {
            $timer.Stop()
            # Hard-abort the background job so no further files are written.
            try { $bg.Stop() } catch {}
            try { $bg.Dispose() } catch {}
            Add-Log (Lmsg 'Apply stopped by user. Background job aborted; no further files written.' '\u7528\u6237\u5df2\u505c\u6b62\u5e94\u7528\u3002\u540e\u53f0\u4efb\u52a1\u5df2\u4e2d\u65ad\uff1c\u4e0d\u518d\u5199\u5165\u6587\u4ef6\u3002') 'DarkOrange'
            $lblStatus.Text = (Lmsg $T[$lang].statusStopped (Decode-Uni $T[$lang].statusStopped))
            $progress.Visible = $false; $lblPct.Visible = $false
            Set-Busy $false
            return
        }
        if ($bgHandle.IsCompleted) {
            $timer.Stop()
            try {
                $bg.EndInvoke($bgHandle)
                $bg.Dispose()
                $progress.Value = 100; $lblPct.Text = '100%'
            } catch {
                Add-Log (Lmsg "ERROR: $_" "\u9519\u8bef\uff1a$_") 'Red'
            } finally {
                Set-Busy $false
                $script:cancelFlag = $false
                Add-Log (Lmsg 'Apply finished.' '\u5e94\u7528\u5b8c\u6210\u3002') 'Green'
                [System.Windows.Forms.MessageBox]::Show((Lmsg $T[$lang].applyDone (Decode-Uni $T[$lang].applyDone)), (Lmsg $T[$lang].confirmTitle (Decode-Uni $T[$lang].confirmTitle)), 'OK', 'Information') | Out-Null
                # Refresh the manifest summary in the GUI from the updated list.
                if (Test-Path $list) {
                    try {
                        $m = Get-Content -Path $list -Raw -Encoding UTF8 | ConvertFrom-Json
                        $cnt = @($m.files).Count
                        $script:lblSummary.Text = (Lmsg ($T[$lang].summary -f $cnt) (Decode-Uni $T[$lang].summary -f $cnt))
                        # Populate the results list with manifest paths.
                        $script:lstResults.Items.Clear()
                        foreach ($f in $m.files) { [void]$script:lstResults.Items.Add($f.path) }
                        $applyTpl = $T[$lang].statusApplyDone
                        $el = Format-Elapsed $script:applyStarted
                        $lblStatus.Text = (Lmsg ($applyTpl -f $cnt, $el) (Decode-Uni $applyTpl -f $cnt, $el))
                    } catch {}
                }
            }
        }
    })
    $timer.Start()
})

$btnClearLog.Add_Click({
    $txtLog.Clear()
    Add-Log (Lmsg 'Log cleared.' '\u65e5\u5fd7\u5df2\u6e05\u7a7a\u3002') 'Gray'
})

$btnStop.Add_Click({
    $script:cancelFlag = $true
    Add-Log (Lmsg 'Stop requested...' '\u5df2\u8bf7\u6c42\u505c\u6b62...') 'DarkOrange'
})

$btnAbout.Add_Click({
    $msg = (Lmsg ($T[$lang].aboutText -f $ScriptVersion, $RepoUrl) (Decode-Uni $T[$lang].aboutText -f $ScriptVersion, $RepoUrl))
    [System.Windows.Forms.MessageBox]::Show($msg, (Lmsg $T[$lang].about (Decode-Uni $T[$lang].about)), 'OK', 'Information') | Out-Null
})

# Double-click a result item to open its containing folder / file.
$lstResults.Add_DoubleClick({
    if ($lstResults.SelectedItem) {
        $path = ($lstResults.SelectedItem -split '\t')[0].Trim()
        if (Test-Path $path) {
            try { Invoke-Item $path } catch {}
        }
    }
})

# Drag-and-drop: folder -> scan root, .stignore/file -> out/manifest path.
$form.AllowDrop = $true
$form.Add_DragEnter({
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})
$form.Add_DragDrop({
    $paths = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    if ($paths -and $paths.Count -gt 0) {
        $p = $paths[0]
        if (Test-Path $p -PathType Container) {
            $txtRoot.Text = $p
        } elseif ($p -like '*.stignore') {
            $txtOut.Text = $p
        } elseif ($p -like '*.json') {
            $txtOut.Text = $p
        }
    }
})

# ---------- Run ----------
# Restore persisted language/theme from config.json if present.
$script:currentTheme = 'light'
$script:scanState = $null
$script:scanRendered = 0
$script:applyStarted = $null
$cfg = Get-Config
if ($cfg -and $cfg.language -and ($cfg.language -eq 'zh' -or $cfg.language -eq 'en')) {
    $lang = $cfg.language
}
if ($cfg -and $cfg.theme -and ($cfg.theme -eq 'dark' -or $cfg.theme -eq 'light')) {
    $script:currentTheme = $cfg.theme
}
$cmbTheme.SelectedIndex = if ($script:currentTheme -eq 'dark') { 1 } else { 0 }
Apply-Language
Apply-Theme -Theme $script:currentTheme
Add-Log (Lmsg "Tool ready. Scripts dir: $scriptDir" "\u5de5\u5177\u5df2\u5c31\u7eea\u3002\u811a\u672c\u76ee\u5f55\uff1a$scriptDir") 'Gray'
# Auto-load an existing manifest on startup and reflect it in the summary.
$initList = $txtOut.Text.Trim()
if (Test-Path $initList -PathType Leaf) {
    try {
        $m = Get-Content -Path $initList -Raw -Encoding UTF8 | ConvertFrom-Json
        $cnt = @($m.files).Count
        $lblSummary.Text = (Lmsg ($T[$lang].manifestLoaded -f $cnt) (Decode-Uni $T[$lang].manifestLoaded -f $cnt))
    } catch {
        $lblSummary.Text = (Lmsg $T[$lang].noManifest (Decode-Uni $T[$lang].noManifest))
    }
} else {
    $lblSummary.Text = (Lmsg $T[$lang].noManifest (Decode-Uni $T[$lang].noManifest))
}
try {
    [System.Windows.Forms.Application]::Run($form)
} catch {
    # 全局兜底：事件处理或消息循环中未捕获的异常不再静默终止（闪退），
    # 而是弹出错误明细，便于定位问题。
    $detail = $_.Exception.ToString()
    try {
        [System.Windows.Forms.MessageBox]::Show(
            "GUI 运行时发生未捕获异常，已退出：`n`n$detail",
            '运行错误', 'OK', 'Error') | Out-Null
    } catch {}
    throw
}
