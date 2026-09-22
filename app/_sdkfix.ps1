# Elevate: the Windows SDK MSIs are ghost-registered (bundle says Present but
# Include/Lib files are missing everywhere). Force a clean remove + re-add of
# the SDK component through the VS Installer so it reinstalls for real.
$log = 'e:\Github\SyncthingIgnorePatterns\app\_elevate.log'
$setup = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe'
$ip = '"E:\Program Files\Microsoft Visual Studio\18\Community"'

Add-Content -Path $log -Value "sdk-remove start $(Get-Date -Format 'HH:mm:ss')"
$argRemove = "modify --installPath $ip --remove Microsoft.VisualStudio.Component.Windows11SDK.26100 --remove Microsoft.VisualStudio.Component.Windows11SDK.22621 --quiet --norestart"
$p1 = Start-Process -FilePath $setup -ArgumentList $argRemove -PassThru -Wait
Add-Content -Path $log -Value "sdk-remove exit: $($p1.ExitCode) at $(Get-Date -Format 'HH:mm:ss')"

Add-Content -Path $log -Value "sdk-add start $(Get-Date -Format 'HH:mm:ss')"
$argAdd = "modify --installPath $ip --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --quiet --norestart"
$p2 = Start-Process -FilePath $setup -ArgumentList $argAdd -PassThru -Wait
Add-Content -Path $log -Value "sdk-add exit: $($p2.ExitCode) at $(Get-Date -Format 'HH:mm:ss')"
