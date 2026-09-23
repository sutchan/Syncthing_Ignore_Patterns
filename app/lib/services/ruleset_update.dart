/// Downloads the canonical ruleset from the project repository.
library;

import 'dart:convert';
import 'dart:io';

/// Raw URL of the ruleset maintained in the project repository.
const String rulesetRepoUrl =
    'https://raw.githubusercontent.com/sutchan/Syncthing_Ignore_Patterns/main/.stignore';

/// Repository page shown to users when a manual download is needed.
const String rulesetRepoPage =
    'https://github.com/sutchan/Syncthing_Ignore_Patterns';

/// Largest response accepted; guards against a runaway download.
const int maxRulesetBytes = 5 * 1024 * 1024;

/// How long a single network step may take.
const Duration rulesetTimeout = Duration(seconds: 15);

/// Fetches a ruleset; injectable so tests never touch the network.
typedef RulesetFetcher = Future<String> Function(Uri uri);

/// Fetches [uri] (defaults to [rulesetRepoUrl]) and decodes it as UTF-8.
///
/// Throws on transport errors, non-200 responses and oversized payloads.
Future<String> fetchRulesetFromRepo({
  Uri? uri,
  Duration timeout = rulesetTimeout,
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(uri ?? Uri.parse(rulesetRepoUrl)).timeout(timeout);
    request.headers.set(HttpHeaders.userAgentHeader, 'SyncthingIgnoreGUI');
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri ?? Uri.parse(rulesetRepoUrl));
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > maxRulesetBytes) {
        throw const HttpException('ruleset exceeded the size limit');
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  } finally {
    client.close(force: true);
  }
}
