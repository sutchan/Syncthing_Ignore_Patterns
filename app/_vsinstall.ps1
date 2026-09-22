# Elevate: add the "Desktop development with C++" workload (incl. Windows SDK
# + CMake tools) to the existing VS 2026 Community install so that
# `flutter build windows` can run. Non-destructive: modify, not repair.
# NOTE: this installer build (4.9.50) rejects `--wait` (exit 87), so we fire
# the quiet modify and let the caller poll for completion instead.
$log = 'e:\Github\SyncthingIgnorePatterns\app\_elevate.log'
Add-Content -Path $log -Value "vs-install start(no-wait) $(Get-Date -Format 'HH:mm:ss')"
$setup = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe'
$argStr = 'modify --installPath "E:\Program Files\Microsoft Visual Studio\18\Community" --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --quiet --norestart'
$p = Start-Process -FilePath $setup -ArgumentList $argStr -PassThru -Wait
Add-Content -Path $log -Value "vs-install bootstrapper exit: $($p.ExitCode) at $(Get-Date -Format 'HH:mm:ss')"
