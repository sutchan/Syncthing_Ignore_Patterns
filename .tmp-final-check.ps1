$root = 'e:\Github\SyncthingIgnorePatterns'
$gui  = Join-Path $root 'SyncthingIgnoreGUI.ps1'

$errs = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($gui, [ref]$null, [ref]$errs)
if ($errs -and $errs.Count -gt 0) {
    Write-Output "PARSE_ERRORS: $($errs.Count)"
    foreach ($e in $errs) { Write-Output ("L{0}: {1}" -f $e.Extent.StartLineNumber, $e.Message) }
} else {
    Write-Output 'PARSE_OK'
}

$lines = [System.IO.File]::ReadAllLines($gui)
$bad = New-Object System.Collections.ArrayList
for ($i = 0; $i -lt $lines.Count; $i++) {
    $ln = $lines[$i]
    for ($j = 0; $j -lt $ln.Length; $j++) {
        if ([int][char]$ln[$j] -gt 127) { [void]$bad.Add($i + 1); break }
    }
}
Write-Output ('NON_ASCII_LINES: ' + ($bad -join ','))

# Version consistency across the repo
$hdr = (Select-String -Path $gui -Pattern '^//Version: ').Line
Write-Output ('GUI_HEADER: ' + $hdr)
$sv = (Select-String -Path $gui -Pattern '^\$ScriptVersion = ').Line
Write-Output ('SCRIPT_VAR: ' + $sv)
Write-Output ('STIGNORE:   ' + (Get-Content (Join-Path $root '.stignore') -TotalCount 2)[1])
Write-Output ('README:     ' + ((Select-String -Path (Join-Path $root 'README.md') -Pattern 'version-v').Line))
Write-Output ('README_EN:  ' + ((Select-String -Path (Join-Path $root 'README_EN.md') -Pattern 'version-v').Line))
Write-Output ('OPENSPEC:   ' + ((Select-String -Path (Join-Path $root 'openspec\project.md') -Pattern 'v1\.17\.\d`\)|\(\u7248\u672c v|v1\.17').Line -join ' | '))
