/// Downloads and applies an application update on Windows.
///
/// A running executable cannot overwrite itself, so applying the update is
/// delegated to a small PowerShell script: it waits for this process to exit,
/// expands the downloaded archive over the application directory, relaunches
/// the app and deletes itself. Only [downloadReleaseZip] touches the network.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'http_client.dart';
import 'updater_script.dart';
import 'version_util.dart';

// Re-export the pure helpers so existing importers (e.g. the updater tests)
// keep resolving `releaseAssetUrl` / `buildUpdaterScript` / `looksLikeZip` /
// `psQuote` from this library.
export 'updater_script.dart';

/// Downloads [uri] into [destination], rejecting non-zip payloads.
typedef ReleaseDownloader = Future<void> Function(Uri uri, File destination);

/// Runs the updater [scriptPath] detached from this process.
typedef UpdateLauncher = Future<void> Function(String scriptPath);

/// Default launcher: a hidden, non-blocking PowerShell process.
Future<void> launchUpdater(String scriptPath) async {
  await Process.start(
    'powershell',
    <String>[
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-WindowStyle',
      'Hidden',
      '-File',
      scriptPath,
    ],
    mode: ProcessStartMode.detached,
  );
}

/// Streams [uri] into [destination]; throws on non-200, oversized or non-zip
/// payloads.
Future<void> downloadReleaseZip(
  Uri uri,
  File destination, {
  Duration timeout = const Duration(seconds: 15),
  void Function(int received, int total)? onProgress,
}) async {
  // The shared client stays open so its keep-alive connection pool is reused.
  final client = sharedHttpClient(connectionTimeout: timeout);
  final request = await client.getUrl(uri).timeout(timeout);
  request.headers.set(HttpHeaders.userAgentHeader, 'SyncthingIgnoreGUI');
  final response = await request.close().timeout(timeout);
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('HTTP ${response.statusCode}', uri: uri);
  }
  final total = response.contentLength;
  final head = <int>[];
  var received = 0;
  final sink = destination.openWrite();
  try {
    await for (final chunk in response.timeout(timeout)) {
      received += chunk.length;
      if (received > maxReleaseZipBytes) {
        throw const HttpException('update archive exceeded the size limit');
      }
      if (head.length < zipMagic.length) {
        head.addAll(chunk.take(zipMagic.length - head.length));
      }
      sink.add(chunk);
      onProgress?.call(received, total);
    }
  } finally {
    await sink.close();
  }
  if (!looksLikeZip(head)) {
    try {
      await destination.delete();
    } on Exception {
      // best effort: leaving a stray file behind is harmless
    }
    throw const HttpException('downloaded file is not a zip archive');
  }
}

/// Stages and runs the updater for a downloaded release.
///
/// Injected dependencies keep the flow unit-testable; the defaults download
/// over HTTP, launch PowerShell and exit the process.
class UpdateInstaller {
  UpdateInstaller({
    Directory? stagingDirectory,
    ReleaseDownloader? downloader,
    UpdateLauncher? launcher,
    void Function(int code)? exitApp,
    String? executablePath,
  })  : _staging = stagingDirectory ?? Directory.systemTemp,
        _downloader = downloader ?? _defaultDownload,
        _launcher = launcher ?? launchUpdater,
        _exitApp = exitApp ?? exit,
        _executable = executablePath ?? Platform.resolvedExecutable;

  final Directory _staging;
  final ReleaseDownloader _downloader;
  final UpdateLauncher _launcher;
  final void Function(int) _exitApp;
  final String _executable;

  static Future<void> _defaultDownload(Uri uri, File destination) =>
      downloadReleaseZip(uri, destination);

  /// Directory holding the downloaded archive and the updater script.
  Directory get stagingDirectory => _staging;

  /// Downloads [version], writes the updater script and starts it.
  ///
  /// Throws when the application directory is not writable or the download
  /// fails; on success the process exits, so this normally never returns.
  Future<void> install(String version) async {
    if (!isValidVersion(version)) {
      throw ArgumentError('invalid update version: $version');
    }
    final appDirectory = File(_executable).parent.path;
    _ensureWritable(appDirectory);

    final zip = File(
        p.join(_staging.path, 'SyncthingIgnoreGUI-update-$version.zip'));
    if (await zip.exists()) await zip.delete();
    await _downloader(Uri.parse(releaseAssetUrl(version)), zip);

    final script = File(
        p.join(_staging.path, 'SyncthingIgnoreGUI-update-$version.ps1'));
    await script.writeAsString(
      buildUpdaterScript(
        pid: pid,
        zipPath: zip.path,
        appDirectory: appDirectory,
        exePath: _executable,
      ),
      flush: true,
    );
    await _launcher(script.path);
    _exitApp(0);
  }

  /// Fails fast when [directory] cannot be written (e.g. installed under
  /// `Program Files` without elevation).
  void _ensureWritable(String directory) {
    final probe = File(p.join(directory, '.syncthing_ignore_gui_write_test'));
    try {
      probe.writeAsStringSync('x', flush: true);
      probe.deleteSync();
    } on FileSystemException {
      throw FileSystemException(
          'application directory is not writable', directory);
    }
  }
}
