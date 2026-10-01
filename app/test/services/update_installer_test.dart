import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncthing_ignore_gui/services/update_installer.dart';

void main() {
  test('releaseAssetUrl points at the versioned archive', () {
    final url = releaseAssetUrl('1.25.0');
    expect(url, contains('/download/v1.25.0/'));
    expect(url, endsWith('SyncthingIgnoreGUI-v1.25.0-windows-x64.zip'));
  });

  test('looksLikeZip recognises the local-file-header magic', () {
    expect(looksLikeZip([0x50, 0x4B, 0x03, 0x04, 0x00]), isTrue);
    expect(looksLikeZip([1, 2, 3, 4]), isFalse);
    expect(looksLikeZip([0x50, 0x4B]), isFalse);
  });

  test('psQuote wraps and escapes single quotes', () {
    expect(psQuote(r'C:\a b'), "'C:\\a b'");
    expect(psQuote("it's"), "'it''s'");
  });

  test('buildUpdaterScript waits, expands, relaunches and self-deletes', () {
    final script = buildUpdaterScript(
      pid: 4321,
      zipPath: r'C:\tmp\u.zip',
      appDirectory: r'C:\app',
      exePath: r'C:\app\SyncthingIgnoreGUI.exe',
    );
    expect(script, contains(r'$targetPid = 4321'));
    expect(script, contains("'C:\\tmp\\u.zip'"));
    expect(script, contains('Expand-Archive'));
    expect(script, contains('Start-Process'));
    expect(script, contains('MyInvocation.MyCommand.Path'));
  });

  Future<HttpServer> serve(List<int> payload, {int status = 200}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      req.response
        ..statusCode = status
        ..add(payload);
      req.response.close();
    });
    return server;
  }

  test('downloadReleaseZip saves a valid archive and reports progress',
      () async {
    final dir = Directory.systemTemp.createTempSync('upd_dl');
    final payload = [0x50, 0x4B, 0x03, 0x04, 1, 2, 3, 4];
    final server = await serve(payload);
    try {
      final dest = File(p.join(dir.path, 'u.zip'));
      var seen = 0;
      await downloadReleaseZip(
        Uri.parse('http://${server.address.address}:${server.port}/u.zip'),
        dest,
        onProgress: (received, total) => seen = received,
      );
      expect(dest.readAsBytesSync(), payload);
      expect(seen, payload.length);
    } finally {
      await server.close(force: true);
      dir.deleteSync(recursive: true);
    }
  });

  test('downloadReleaseZip rejects a non-zip payload', () async {
    final dir = Directory.systemTemp.createTempSync('upd_bad');
    final server = await serve('not a zip'.codeUnits);
    try {
      await expectLater(
        downloadReleaseZip(
          Uri.parse('http://${server.address.address}:${server.port}/u.zip'),
          File(p.join(dir.path, 'u.zip')),
        ),
        throwsA(isA<HttpException>()),
      );
    } finally {
      await server.close(force: true);
      dir.deleteSync(recursive: true);
    }
  });

  test('UpdateInstaller stages the archive, launches and exits', () async {
    final staging = Directory.systemTemp.createTempSync('upd_stage');
    final appDir = Directory.systemTemp.createTempSync('upd_app');
    try {
      final exe = File(p.join(appDir.path, 'SyncthingIgnoreGUI.exe'))
        ..writeAsStringSync('fake');
      var launched = '';
      var exitCode = -1;
      final installer = UpdateInstaller(
        stagingDirectory: staging,
        downloader: (uri, destination) =>
            destination.writeAsBytes(zipMagic, flush: true),
        launcher: (scriptPath) async => launched = scriptPath,
        exitApp: (code) => exitCode = code,
        executablePath: exe.path,
      );

      await installer.install('1.25.0');

      expect(exitCode, 0);
      expect(launched, endsWith('SyncthingIgnoreGUI-update-1.25.0.ps1'));
      expect(File(launched).readAsStringSync(), contains(appDir.path));
      expect(
        File(p.join(staging.path, 'SyncthingIgnoreGUI-update-1.25.0.zip'))
            .existsSync(),
        isTrue,
      );
    } finally {
      staging.deleteSync(recursive: true);
      appDir.deleteSync(recursive: true);
    }
  });

  test('UpdateInstaller refuses a non-writable application directory',
      () async {
    final staging = Directory.systemTemp.createTempSync('upd_ro');
    try {
      final installer = UpdateInstaller(
        stagingDirectory: staging,
        downloader: (uri, destination) => destination.writeAsBytes(zipMagic),
        launcher: (_) async {},
        exitApp: (_) {},
        // Points into a directory that does not exist, so the write probe fails.
        executablePath:
            p.join(staging.path, 'missing-dir', 'SyncthingIgnoreGUI.exe'),
      );
      await expectLater(
        installer.install('1.25.0'),
        throwsA(isA<FileSystemException>()),
      );
    } finally {
      staging.deleteSync(recursive: true);
    }
  });
}
