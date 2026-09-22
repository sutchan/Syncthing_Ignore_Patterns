# Elevate: repair every registered Windows SDK MSI (msiexec /fa) so the
# ghost-registered payloads (Headers/Libs/Tools) get their files rewritten to
# the Kits root (KitsRoot10 = E:\Windows Kits\10).
$log = 'e:\Github\SyncthingIgnorePatterns\app\_elevate.log'
$codes = Get-Content 'e:\Github\SyncthingIgnorePatterns\app\sdk_msi_codes.txt'
$i = 0
$fail = 0
foreach ($line in $codes) {
  $code = ($line -split '\|')[0]
  $i++
  $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/fa $code /qn /norestart" -PassThru -Wait
  if ($p.ExitCode -ne 0) {
    $fail++
    Add-Content -Path $log -Value "msi repair FAIL ($i): $line -> $($p.ExitCode)"
  }
}
Add-Content -Path $log -Value "msi repair done: total=$i fail=$fail at $(Get-Date -Format 'HH:mm:ss')"
