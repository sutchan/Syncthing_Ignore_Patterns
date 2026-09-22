# Force flutter tool rebuild: delete stale flutter_tools.stamp
$stamp = 'E:\Program Files\Flutter\bin\cache\flutter_tools.stamp'
if (Test-Path $stamp) {
  Remove-Item $stamp -Force
}
"stamp_exists=$(Test-Path $stamp)"
