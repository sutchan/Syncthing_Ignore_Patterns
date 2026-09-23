/// Filesystem scanner: finds every `.stignore` file under a set of roots.
///
/// Mirrors the PowerShell `Find-StignoreFiles` / `Start-ParallelScan` behavior:
/// explicit depth-first walk via `listSync` (publishable current directory),
/// skipping `.git` and the tool's own script directory, tolerating access-denied
/// folders, and running one isolate per root for parallelism (default 4).
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../models/manifest.dart';

/// Directory that holds the running executable. `.stignore` files under it
/// (e.g. the bundled standard rules extracted next to the exe) must never be
/// scanned or rewritten by the tool itself.
String get _appDirectory => p.dirname(Platform.resolvedExecutable);

/// `true` when [child] is [parent] or lives somewhere underneath it.
/// Comparison is case-insensitive (Windows paths).
bool _isWithinOrEquals(String parent, String child) {
  final np = parent.trim().toLowerCase();
  final nc = child.trim().toLowerCase();
  return nc == np ||
      nc.startsWith('$np${p.separator}') ||
      nc.startsWith('$np/');
}

/// Cheaply counts the entries directly inside [dir], stopping early once the
/// count exceeds [threshold]. Returns a value > [threshold] for large /
/// unreadable directories so the caller can skip them without materializing a
/// huge listing (e.g. `node_modules`).
Future<int> _countEntries(String dir, int threshold) async {
  try {
    return await Directory(dir).list().take(threshold + 1).length;
  } on FileSystemException {
    return threshold + 1; // unreadable => treat as large and skip
  }
}

/// Walks [root] depth-first (up to [maxDepth] levels, root = level 1) and
/// returns raw record maps for every `.stignore`. Exposed as a top-level
/// function so it can run inside an isolate.
///
/// [skipDir] (the standard rules source) and the tool's own executable
/// directory are skipped as whole subtrees. When [skipLargeDirs] is set, any
/// subdirectory whose direct entry count exceeds [maxFilesPerDir] is skipped
/// entirely (not descended, and its own `.stignore` is excluded).
Future<List<Map<String, dynamic>>> findStignoreFilesRaw(
  String root, {
  String? skipDir,
  int maxDepth = 3,
  int maxFilesPerDir = 100,
  bool skipLargeDirs = false,
}) async {
  final records = <Map<String, dynamic>>[];
  if (!Directory(root).existsSync()) return records;

  // Always skip the tool's own directory so it never scans or rewrites its own
  // bundled rules; an explicit [skipDir] (the standard rules source) is also
  // skipped when supplied. Both are matched as subtrees (the directory and
  // everything beneath it).
  final skip = <String>{
    _appDirectory,
    if (skipDir != null && skipDir.trim().isNotEmpty) skipDir.trim(),
  };

  // (directory path, 1-based level from root)
  final stack = <(String, int)>[(root, 1)];
  while (stack.isNotEmpty) {
    final (dir, level) = stack.removeLast();
    final List<FileSystemEntity> entries;
    try {
      entries = Directory(dir).listSync();
    } on FileSystemException {
      continue; // unreadable directory: skip and keep walking
    }

    for (final e in entries) {
      if (e is Directory) {
        if (p.basename(e.path) == '.git') continue;
        if (skip.any((s) => _isWithinOrEquals(s, e.path))) continue;

        // Honor the depth limit and the large-directory filter before descending.
        if (level < maxDepth) {
          if (skipLargeDirs &&
              await _countEntries(e.path, maxFilesPerDir) > maxFilesPerDir) {
            continue; // too many files: skip this whole subtree
          }
          stack.add((e.path, level + 1));
        }
      } else if (e is File) {
        if (p.basename(e.path) == '.stignore') {
          final stat = e.statSync();
          records.add({
            'path': e.path,
            'size': stat.size,
            'lastWriteUtc': stat.modified.toUtc().toIso8601String(),
            'foundAtUtc': DateTime.now().toUtc().toIso8601String(),
          });
        }
      }
    }
  }
  return records;
}

/// Typed wrapper around [findStignoreFilesRaw] for direct (non-isolate) use.
Future<List<StignoreRecord>> findStignoreFiles(
  String root, {
  String? skipDir,
  int maxDepth = 3,
  int maxFilesPerDir = 100,
  bool skipLargeDirs = false,
}) =>
    findStignoreFilesRaw(
      root,
      skipDir: skipDir,
      maxDepth: maxDepth,
      maxFilesPerDir: maxFilesPerDir,
      skipLargeDirs: skipLargeDirs,
    ).then((m) => m.map(StignoreRecord.fromJson).toList());

/// Top-level isolate entry: scans a single root and returns raw record maps.
Future<List<Map<String, dynamic>>> _scanRoot(Map<String, dynamic> args) =>
    findStignoreFilesRaw(
      args['root']!,
      skipDir: args['skipDir'],
      maxDepth: args['maxDepth'] ?? 3,
      maxFilesPerDir: args['maxFilesPerDir'] ?? 100,
      skipLargeDirs: args['skipLargeDirs'] ?? false,
    );

/// Scans a single root inside its own isolate and returns [StignoreRecord]s.
///
/// Defined at top level (not inside [scanRoots]) so the closure handed to
/// [Isolate.run] captures only plain arguments. If it lived inside [scanRoots]
/// it would share that function's closure context with the `onProgress` callback
/// (which closes over app state and is not sendable), and [Isolate.run] would
/// fail with "object is unsendable".
Future<List<StignoreRecord>> _scanOneRoot(
  String root, {
  required String? skipDir,
  required int maxDepth,
  required int maxFilesPerDir,
  required bool skipLargeDirs,
}) =>
    Isolate.run<List<Map<String, dynamic>>>(
      () => _scanRoot({
        'root': root,
        'skipDir': skipDir,
        'maxDepth': maxDepth,
        'maxFilesPerDir': maxFilesPerDir,
        'skipLargeDirs': skipLargeDirs,
      }),
    ).then((maps) => maps.map(StignoreRecord.fromJson).toList());

/// Scans all [roots] with at most [maxThreads] isolates running concurrently
/// (roots are processed in batches of [maxThreads]). [skipDir] is the directory
/// of the standard rules source, excluded to avoid re-scanning the tool's own
/// `.stignore`.
///
/// [onProgress] is invoked at the start of each batch and after each root
/// finishes, with the number of roots already completed, the total root count,
/// the records found so far and a root currently being scanned. It lets the UI
/// show a live status line; the callback always runs on the main isolate.
Future<List<StignoreRecord>> scanRoots(
  List<String> roots, {
  int maxThreads = 4,
  String? skipDir,
  int maxDepth = 3,
  int maxFilesPerDir = 100,
  bool skipLargeDirs = false,
  void Function(int done, int total, int found, String current)? onProgress,
}) async {
  final records = <StignoreRecord>[];
  for (var i = 0; i < roots.length; i += maxThreads) {
    final batch = roots.sublist(i, min(i + maxThreads, roots.length));
    onProgress?.call(i, roots.length, records.length, batch.first);
    var completed = 0;
    await Future.wait(batch.map(
      (root) => _scanOneRoot(
        root,
        skipDir: skipDir,
        maxDepth: maxDepth,
        maxFilesPerDir: maxFilesPerDir,
        skipLargeDirs: skipLargeDirs,
      ).then((recs) {
        records.addAll(recs);
        completed++;
        onProgress?.call(i + completed, roots.length, records.length, root);
      }),
    ));
  }
  return records;
}
