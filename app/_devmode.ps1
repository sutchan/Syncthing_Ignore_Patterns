# Elevate: enable Windows Developer Mode (symlink support) required by
# `flutter build windows` when the app uses plugins (file_picker).
$log = 'e:\Github\SyncthingIgnorePatterns\app\_elevate.log'
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v AllowDevelopmentWithoutDevLicense /d 1 | Out-Null
Add-Content -Path $log -Value "devmode exit: $LASTEXITCODE"
