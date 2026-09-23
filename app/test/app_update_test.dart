import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/services/app_update.dart';

void main() {
  test('stripVersionPrefix drops a leading v', () {
    expect(stripVersionPrefix('v1.24.0'), '1.24.0');
    expect(stripVersionPrefix('1.24.0'), '1.24.0');
  });

  test('latestTagFromReleaseJson reads tag_name and tolerates bad input', () {
    expect(latestTagFromReleaseJson('{"tag_name":"v1.24.0"}'), '1.24.0');
    expect(latestTagFromReleaseJson('{"tag_name":"1.24.0"}'), '1.24.0');
    expect(latestTagFromReleaseJson('{"other":1}'), isNull);
    expect(latestTagFromReleaseJson('not json'), isNull);
    expect(latestTagFromReleaseJson('[]'), isNull);
  });

  Future<HttpServer> startServer(String body, int status) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      req.response
        ..statusCode = status
        ..write(body);
      req.response.close();
    });
    return server;
  }

  Uri urlOf(HttpServer server) =>
      Uri.parse('http://${server.address.address}:${server.port}/latest');

  test('fetchLatestReleaseTag decodes a 200 response', () async {
    final server = await startServer('{"tag_name":"v9.9.9"}', HttpStatus.ok);
    try {
      expect(await fetchLatestReleaseTag(uri: urlOf(server)), '9.9.9');
    } finally {
      await server.close(force: true);
    }
  });

  test('fetchLatestReleaseTag throws on a non-200 response', () async {
    final server = await startServer('{}', HttpStatus.notFound);
    try {
      await expectLater(
        fetchLatestReleaseTag(uri: urlOf(server)),
        throwsA(isA<HttpException>()),
      );
    } finally {
      await server.close(force: true);
    }
  });

  test('fetchLatestReleaseTag throws when tag_name is missing', () async {
    final server = await startServer('{"message":"no tag"}', HttpStatus.ok);
    try {
      await expectLater(
        fetchLatestReleaseTag(uri: urlOf(server)),
        throwsA(isA<HttpException>()),
      );
    } finally {
      await server.close(force: true);
    }
  });
}
