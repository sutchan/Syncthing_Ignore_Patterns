import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncthing_ignore_gui/services/ruleset_update.dart';

void main() {
  test('fetchRulesetFromRepo decodes a 200 response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      req.response
        ..statusCode = HttpStatus.ok
        ..write('//Version: 1.0.0\nRULE\n');
      req.response.close();
    });
    try {
      final content = await fetchRulesetFromRepo(
        uri: Uri.parse('http://${server.address.address}:${server.port}/.stignore'),
      );
      expect(content, contains('RULE'));
    } finally {
      await server.close(force: true);
    }
  });

  test('fetchRulesetFromRepo throws on a non-200 response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      req.response.statusCode = HttpStatus.notFound;
      req.response.close();
    });
    try {
      await expectLater(
        fetchRulesetFromRepo(
          uri: Uri.parse('http://${server.address.address}:${server.port}/x'),
        ),
        throwsA(isA<HttpException>()),
      );
    } finally {
      await server.close(force: true);
    }
  });
}
