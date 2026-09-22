# Enumerate registered Windows SDK MSIs and emit their ProductCodes.
$base = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products'
function Convert-PackedGuid([string]$packed) {
  if ($packed.Length -ne 32) { return $null }
  $g1 = ($packed.Substring(0, 8).ToCharArray() | Select-Object -Last 1 -First 0) # placeholder
  $r = { param($s) -join $s[$s.Length..0] }
  $g1 = -join $packed.Substring(0, 8).ToCharArray()[7..0]
  $g2 = -join $packed.Substring(8, 4).ToCharArray()[3..0]
  $g3 = -join $packed.Substring(12, 4).ToCharArray()[3..0]
  $p4 = $packed.Substring(16, 4)
  $g4 = ''
  for ($i = 0; $i -lt 4; $i += 2) { $g4 += $p4[$i + 1]; $g4 += $p4[$i] }
  $p5 = $packed.Substring(20, 12)
  $g5 = ''
  for ($i = 0; $i -lt 12; $i += 2) { $g5 += $p5[$i + 1]; $g5 += $p5[$i] }
  return "{$g1-$g2-$g3-$g4-$g5}"
}
$codes = New-Object System.Collections.Generic.List[string]
Get-ChildItem $base -ErrorAction SilentlyContinue | ForEach-Object {
  $ip = Get-ItemProperty (Join-Path $_.PSPath 'InstallProperties') -ErrorAction SilentlyContinue
  if ($ip -and $ip.DisplayName -match 'Windows SDK') {
    $code = Convert-PackedGuid ([string]$_.PSChildName)
    if ($code) { $codes.Add("$code|$($ip.DisplayName)|$($ip.DisplayVersion)") }
  }
}
Set-Content -Path 'e:\Github\SyncthingIgnorePatterns\app\sdk_msi_codes.txt' -Value $codes
"count=$($codes.Count)"
