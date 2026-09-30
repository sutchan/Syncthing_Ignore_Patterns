// ignore_for_file: avoid_print

/// Pure-Dart micro-benchmarks backing `docs/performance.md`.
///
/// Measures the two non-widget v1.28.0 optimizations:
///   1. log/result buffer caps (old growing-copy policy vs. the ring cap)
///   2. shared keep-alive HttpClient vs. one client per request
///
/// The widget-side layout benchmark lives in
/// `test/perf_layout_bench_test.dart` (it needs the Flutter engine).
///
/// Run from `app/`:
///   dart run tool/perf_benchmark.dart
library;

import 'dart:io';

import 'package:syncthing_ignore_gui/services/http_client.dart';

/// Number of log emits in the append benchmark (one per touched file).
const int logEmits = 50000;

/// Mirrors `maxLogEntries` in `lib/state/log_state.dart`.
const int logCap = 1000;

/// Number of scan paths fed to a single result replacement.
const int resultRows = 200000;

/// Mirrors `maxResultEntries` in `lib/state/progress_state.dart`.
const int resultCap = 5000;

/// Sequential HTTP requests per timed round.
const int httpRounds = 5;
const int httpRequestsPerRound = 100;

Future<void> main() async {
  print('== v1.28.0 performance benchmarks ==');
  print('Dart ${Platform.version}');
  print('');

  _benchmarkLogAppend();
  print('');
  _benchmarkResultReplacement();
  print('');
  await _benchmarkHttpReuse();
}

/// Builds realistic ~80-char log/result payloads (paths + digests).
List<String> _messages(int count) => [
      for (var i = 0; i < count; i++)
        'applied::C:\\sync-data\\share-${i % 50}\\folder-$i\\.stignore  '
            "sha256=${'a' * (40 + i % 5)}",
    ];

int _charCount(List<String> entries) {
  var total = 0;
  for (final e in entries) {
    total += e.length;
  }
  return total;
}

/// Old log policy: every append replaced the whole list with a growing copy
/// (`_logs = [..._logs, entry]`) so select() saw a new identity. Cumulative
/// copying is quadratic; retained memory is unbounded.
void _benchmarkLogAppend() {
  print('-- log append: $logEmits emits (one line per touched file) --');
  final messages = _messages(logEmits);

  // Old policy (pre-v1.28.0): unbounded growing copy per append.
  var oldBuffer = <String>[];
  var sw = Stopwatch()..start();
  for (final m in messages) {
    oldBuffer = [...oldBuffer, m];
  }
  sw.stop();
  final oldMs = sw.elapsedMilliseconds;
  final oldChars = _charCount(oldBuffer);
  oldBuffer = <String>[]; // release before the next run

  // New policy (v1.28.0): copy then trim to the newest [logCap] entries.
  var newBuffer = <String>[];
  sw = Stopwatch()..start();
  for (final m in messages) {
    final next = [...newBuffer, m];
    if (next.length > logCap) {
      next.removeRange(0, next.length - logCap);
    }
    newBuffer = next;
  }
  sw.stop();
  final newMs = sw.elapsedMilliseconds;
  final newChars = _charCount(newBuffer);

  print('old (unbounded): ${oldMs}ms, retained ${messages.length} entries '
      '($oldChars chars)');
  print('new (cap=$logCap): ${newMs}ms, retained $logCap entries '
      '($newChars chars)');
  print('speedup: ${(oldMs / newMs).toStringAsFixed(1)}x, '
      'payload retained: ${(oldChars / newChars).toStringAsFixed(0)}x less');
}

/// Results are replaced once at the end of a scan; the cap is a memory guard,
/// so the comparison is retained size (the manifest on disk keeps all rows).
void _benchmarkResultReplacement() {
  print('-- scan results: one replacement with $resultRows paths --');
  final paths = _messages(resultRows);

  var sw = Stopwatch()..start();
  final oldList = paths.toList();
  sw.stop();
  final oldMs = sw.elapsedMilliseconds;
  final oldChars = _charCount(oldList);

  sw = Stopwatch()..start();
  final newList = paths.toList();
  if (newList.length > resultCap) {
    newList.removeRange(0, newList.length - resultCap);
  }
  sw.stop();
  final newMs = sw.elapsedMilliseconds;
  final newChars = _charCount(newList);

  print('old (unbounded): ${oldMs}ms, retained $resultRows entries '
      '($oldChars chars)');
  print('new (cap=$resultCap): ${newMs}ms, retained $resultCap entries '
      '($newChars chars; newest kept: '
      '${newList.last == paths.last})');
  print('payload retained: '
      '${(oldChars / newChars).toStringAsFixed(0)}x less');
}

/// Times sequential loopback GETs and counts distinct TCP connections.
///
/// The shared client reuses one keep-alive socket; the old path constructed
/// an HttpClient per request and closed it immediately, paying a fresh TCP
/// handshake every time (and a TLS handshake for https hosts such as GitHub).
Future<void> _benchmarkHttpReuse() async {
  print('-- http: $httpRequestsPerRound sequential requests x $httpRounds '
      'rounds (loopback, ~1 KiB JSON) --');
  final body = '{"tag_name":"v9.9.9","data":"${'x' * 980}"}';
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) {
    _activePorts.add(req.connectionInfo!.remotePort);
    req.response
      ..headers.contentType = ContentType.json
      ..write(body)
      ..close();
  });
  final uri =
      Uri.parse('http://${server.address.host}:${server.port}/release.json');

  Future<void> getOnce(HttpClient? reusable) async {
    final client = reusable ?? HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      await response.drain<void>();
    } finally {
      // Old code closed its per-request client in a finally block.
      if (reusable == null) {
        client.close();
      }
    }
  }

  // Warm up both paths (and the server) outside the timed rounds.
  for (var i = 0; i < 20; i++) {
    await getOnce(sharedHttpClient());
  }
  for (var i = 0; i < 20; i++) {
    await getOnce(null);
  }

  final perRequestMs = <int>[];
  final perRequestSockets = <int>[];
  final sharedMs = <int>[];
  final sharedSockets = <int>[];

  for (var round = 0; round < httpRounds; round++) {
    // Per-request client (old behaviour).
    _activePorts.clear();
    var sw = Stopwatch()..start();
    for (var i = 0; i < httpRequestsPerRound; i++) {
      await getOnce(null);
    }
    perRequestMs.add(sw.elapsedMilliseconds);
    perRequestSockets.add(_activePorts.length);

    // Shared process-wide client (new behaviour).
    _activePorts.clear();
    sw = Stopwatch()..start();
    for (var i = 0; i < httpRequestsPerRound; i++) {
      await getOnce(sharedHttpClient());
    }
    sharedMs.add(sw.elapsedMilliseconds);
    sharedSockets.add(_activePorts.length);
  }

  final oldMedian = _median(perRequestMs);
  final newMedian = _median(sharedMs);
  print('old (new client/request): ${oldMedian}ms/round '
      '(${(oldMedian / httpRequestsPerRound).toStringAsFixed(2)} '
      'ms/request), connections/round: '
      '${_summarize(perRequestSockets)}');
  print('new (shared keep-alive): ${newMedian}ms/round '
      '(${(newMedian / httpRequestsPerRound).toStringAsFixed(2)} '
      'ms/request), connections/round: ${_summarize(sharedSockets)}');
  print('speedup: ${(oldMedian / newMedian).toStringAsFixed(2)}x per round');

  await server.close(force: true);
}

final Set<int> _activePorts = <int>{};

int _median(List<int> values) {
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

String _summarize(List<int> values) =>
    values.toSet().length == 1 ? '${values.first}' : values.toString();
