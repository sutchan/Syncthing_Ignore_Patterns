/// PowerShell updater script construction and release-archive URL helpers.
///
/// Kept separate from [UpdateInstaller] (the staging/launch flow) so the pure
/// string builders stay small and easy to unit-test in isolation.
library;

import 'package:path/path.dart' as p;

/// Direct download URL of the release archive published for [version].
///
/// [version] is assumed already validated by `isValidVersion`; only clean
/// digit-and-dot versions are interpolated, so the URL cannot embed a path
/// separator or `..` segment (path traversal).
String releaseAssetUrl(String version) =>
    'https://github.com/sutchan/Syncthing_Ignore_Patterns/releases/download/'
    'v$version/SyncthingIgnoreGUI-v$version-windows-x64.zip';

/// Largest update archive accepted; guards against a runaway download.
const int maxReleaseZipBytes = 200 * 1024 * 1024;

/// The zip local-file-header magic (`PK\x03\x04`).
const List<int> zipMagic = [0x50, 0x4B, 0x03, 0x04];

/// `true` when [bytes] start with the zip local-file-header magic.
bool looksLikeZip(List<int> bytes) {
  if (bytes.length < zipMagic.length) return false;
  for (var i = 0; i < zipMagic.length; i++) {
    if (bytes[i] != zipMagic[i]) return false;
  }
  return true;
}

/// Quotes [value] as a single-quoted PowerShell literal.
String psQuote(String value) => "'${value.replaceAll("'", "''")}'";

/// Builds the PowerShell updater script for [pid].
///
/// It waits for the process to exit (at most 120 s), expands [zipPath] over
/// [appDirectory], relaunches [exePath] and removes the archive and itself.
String buildUpdaterScript({
  required int pid,
  required String zipPath,
  required String appDirectory,
  required String exePath,
}) {
  final log = p.join(appDirectory, 'update.log');
  return <String>[
    "\$ErrorActionPreference = 'Stop'",
    '\$targetPid = $pid',
    '\$zip = ${psQuote(zipPath)}',
    '\$dest = ${psQuote(appDirectory)}',
    '\$exe = ${psQuote(exePath)}',
    '\$log = ${psQuote(log)}',
    'function Write-UpdateLog([string]\$message) {',
    '  "\$(Get-Date -Format o) \$message" |'
        ' Out-File -LiteralPath \$log -Append -Encoding utf8',
    '}',
    'try {',
    '  Write-UpdateLog "waiting for process \$targetPid to exit"',
    '  \$deadline = (Get-Date).AddSeconds(120)',
    '  while ((Get-Process -Id \$targetPid -ErrorAction SilentlyContinue) -and'
        ' ((Get-Date) -lt \$deadline)) {',
    '    Start-Sleep -Milliseconds 300',
    '  }',
    '  Start-Sleep -Milliseconds 500',
    '  Write-UpdateLog "expanding \$zip into \$dest"',
    '  Expand-Archive -LiteralPath \$zip -DestinationPath \$dest -Force',
    '  Write-UpdateLog "relaunching \$exe"',
    '  Start-Process -FilePath \$exe -WorkingDirectory \$dest',
    '  Remove-Item -LiteralPath \$zip -Force -ErrorAction SilentlyContinue',
    '  Write-UpdateLog "update finished"',
    '} catch {',
    '  Write-UpdateLog "update failed: \$_"',
    '} finally {',
    '  Remove-Item -LiteralPath \$MyInvocation.MyCommand.Path -Force'
        ' -ErrorAction SilentlyContinue',
    '}',
    '',
  ].join('\r\n');
}
