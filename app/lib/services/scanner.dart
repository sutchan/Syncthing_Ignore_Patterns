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

/// Walks [root] depth-first and returns raw record maps for every `.stignore`.
/// Exposed as a top-level function so it can run inside an isolate.
List<Map<String, dynamic>> findStignoreFilesRaw(
  String root, {
  String? skipDir,
}) {
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

  final stack = <String>[root];
  while (stack.isNotEmpty) {
    final dir = stack.removeLast();
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
        stack.add(e.path);
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
List<StignoreRecord> findStignoreFiles(String root, {String? skipDir}) =>
    findStignoreFilesRaw(root, skipDir: skipDir)
        .map(StignoreRecord.fromJson)
        .toList();

/// Top-level isolate entry: scans a single root and returns raw record maps.
List<Map<String, dynamic>> _scanRoot(Map<String, String?> args) =>
    findStignoreFilesRaw(args['root']!, skipDir: args['skipDir']);

/// Scans all [roots] with at most [maxThreads] isolates running concurrently
/// (roots are processed in batches of [maxThreads]). [skipDir] is the directory
/// of the standard rules source, excluded to avoid re-scanning the tool's own
/// `.stignore`.
Future<List<StignoreRecord>> scanRoots(
  List<String> roots, {
  int maxThreads = 4,
  String? skipDir,
}) async {
  final records = <StignoreRecord>[];
  for (var i = 0; i < roots.length; i += maxThreads) {
    final batch =
        roots.sublist(i, min(i + maxThreads, roots.length));
    final tasks = batch.map(
      (r) => Isolate.run<List<Map<String, dynamic>>>(
        () => _scanRoot({'root': r, 'skipDir': skipDir}),
      ),
    );
    final results = await Future.wait(tasks);
    for (final maps in results) {
      records.addAll(maps.map(StignoreRecord.fromJson));
    }
  }
  return records;
}
