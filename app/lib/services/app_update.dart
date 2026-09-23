/// Checks GitHub releases for a newer application version.
library;

import 'dart:convert';
import 'dart:io';

/// GitHub API endpoint that returns the latest published release.
const String appReleasesApiUrl =
    'https://api.github.com/repos/sutchan/Syncthing_Ignore_Patterns/releases/latest';

/// Releases page opened when a newer version is available.
const String appReleasesPageUrl =
    'https://github.com/sutchan/Syncthing_Ignore_Patterns/releases';

/// Largest response accepted from the releases API; guards against a runaway
/// download (the real payload is a few KB).
const int maxReleaseJsonBytes = 1 * 1024 * 1024;

/// Drops a leading `v` from a release tag (`v1.24.0` -> `1.24.0`).
String stripVersionPrefix(String tag) =>
    tag.startsWith('v') ? tag.substring(1) : tag;

/// Extracts the release tag (without the `v` prefix) from a GitHub releases
/// JSON payload, or `null` when it is missing or unparseable.
String? latestTagFromReleaseJson(String body) {
  Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final tag = decoded['tag_name'];
  if (tag is! String || tag.trim().isEmpty) return null;
  return stripVersionPrefix(tag.trim());
}

/// Fetches the latest release tag; injectable so tests never touch the network.
typedef ReleaseFetcher = Future<String> Function(Uri uri);

/// Downloads the latest release tag from the GitHub API.
///
/// Throws on transport errors, non-200 responses, oversized payloads and
/// payloads without a `tag_name`.
Future<String> fetchLatestReleaseTag({
  Uri? uri,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final target = uri ?? Uri.parse(appReleasesApiUrl);
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(target).timeout(timeout);
    request.headers
      ..set(HttpHeaders.userAgentHeader, 'SyncthingIgnoreGUI')
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: target);
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > maxReleaseJsonBytes) {
        throw const HttpException('release payload exceeded the size limit');
      }
    }
    final tag =
        latestTagFromReleaseJson(utf8.decode(bytes, allowMalformed: true));
    if (tag == null) {
      throw const HttpException('release payload has no tag_name');
    }
    return tag;
  } finally {
    client.close(force: true);
  }
}
