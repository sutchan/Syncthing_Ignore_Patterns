# temp verification of the CI version-consistency check (three-track model)
$ver = (Get-Content VERSION | Out-String).Trim()
Write-Host "VERSION = $ver"

$flutter = @(
  @{ file = 'app/pubspec.yaml';             pat = 'version:\s*([0-9.]+)' }
  @{ file = 'README.md';                    pat = 'version-v([0-9.]+)' }
  @{ file = 'README_EN.md';                 pat = 'version-v([0-9.]+)' }
  @{ file = 'app/lib/state/app_state.dart'; pat = "this\.version = '([0-9.]+)'" }
  @{ file = 'app/lib/models/manifest.dart'; pat = '"version":\s*"([0-9.]+)"' }
)
$fv = @($ver)
foreach ($s in $flutter) {
  $c = Get-Content $s.file -Raw
  if ($c -match $s.pat) { $fv += $Matches[1] }
  else { Write-Error "No version found in $($s.file)"; exit 1 }
}
$fu = $fv | Sort-Object -Unique
if ($fu.Count -ne 1) { Write-Error "Flutter mismatch: $($fv -join ' | ')"; exit 1 }
Write-Host "Flutter track consistent: $ver"

$ps1 = Get-Content SyncthingIgnoreGUI.ps1 -Raw
$head = if ($ps1 -match '//Version:\s*([0-9.]+)') { $Matches[1] } else { $null }
$scriptv = if ($ps1 -match '[$]ScriptVersion = ''([0-9.]+)''') { $Matches[1] } else { $null }
if ($head -ne $scriptv) { Write-Error "PowerShell mismatch: //Version=$head `$ScriptVersion=$scriptv"; exit 1 }
Write-Host "PowerShell legacy consistent: $head"

$rv  = if ((Get-Content .stignore -Raw) -match '//Version:\s*([0-9.]+)') { $Matches[1] } else { $null }
$rav = if ((Get-Content app/assets/.stignore -Raw) -match '//Version:\s*([0-9.]+)') { $Matches[1] } else { $null }
if ($rv -ne $rav) { Write-Error "Ruleset mismatch: .stignore=$rv assets=$rav"; exit 1 }
Write-Host "Ruleset consistent: $rv"

Write-Host "ALL CHECKS PASSED"
