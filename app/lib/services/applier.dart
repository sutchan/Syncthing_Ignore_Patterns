/// Applies the standard `.stignore` rules to every path recorded in a manifest.
///
/// Mirrors the PowerShell `Start-ApplyJob` / `Limit-Backups` logic:
///  - skip files whose content already equals the source (SHA-256 compare),
///  - never back up the source file itself,
///  - back up with `<path>.bak.<timestamp>` before writing when backup is on,
///  - rotate `<path>.bak.*` to keep at most 3 newest,
///  - clean stale (source-deleted) paths only when [force] is set.
library;

import 'dart:io';

import '../models/manifest.dart';
import 'rules_source.dart';

/// Outcome counters for one Apply run.
class ApplyResult {
  const ApplyResult({
    this.replaced = 0,
    this.identicalCount = 0,
    this.cleaned = 0,
    this.errors = 0,
  });

  final int replaced;
  final int identicalCount;
  final int cleaned;
  final int errors;

  @override
  String toString() =>
      'replaced=$replaced identical=$identicalCount cleaned=$cleaned errors=$errors';
}

/// Keeps at most [keep] newest `<base>.bak.*` files, deleting older extras.
/// Returns the number of files removed.
int limitBackups(String base, {int keep = 3}) {
  final file = File(base);
  final parent = file.parent;
  if (!parent.existsSync()) return 0;
  final lastName = base.split(Platform.pathSeparator).last;
  final backups = parent
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('$lastName.bak.'))
      .toList()
    ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

  var removed = 0;
  while (backups.length > keep) {
    final oldest = backups.removeAt(0);
    try {
      oldest.deleteSync();
      removed++;
    } on FileSystemException {
      // best-effort cleanup; ignore individual failures
    }
  }
  return removed;
}

/// Applies [sourceContent] (with [sourceHash]) to every record in [manifest].
///
/// [whatIf] = preview only; [force] = also clean stale paths; [backup] = back up
/// before writing. [log] receives a message and a level string ('info'/'warn'/
/// 'error'/'muted'). Returns the outcome counters.
Future<ApplyResult> applyRules({
  required Manifest manifest,
  required String sourceContent,
  required String sourceHash,
  required String sourcePath,
  required bool whatIf,
  required bool force,
  required bool backup,
  required void Function(String message, String level) log,
}) async {
  var replaced = 0;
  var identicalCount = 0;
  var cleaned = 0;
  var errors = 0;

  final timestamp =
      DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.-]'), '').substring(0, 14);
  final sourceCanonical =
      File(sourcePath).absolute.resolveSymbolicLinksSyncSafe();

  for (final rec in manifest.files) {
    final target = File(rec.path);
    if (!target.existsSync()) {
      // Stale path: only cleaned when force is requested.
      if (force) {
        log('cleanedStale::${rec.path}', 'warn');
        cleaned++;
      }
      continue;
    }

    final targetHash = sha256OfString(await target.readAsString());
    if (targetHash == sourceHash) {
      log('skippedSame::${rec.path}', 'muted');
      identicalCount++;
      continue;
    }

    final isSourceItself =
        sourceCanonical == target.absolute.resolveSymbolicLinksSyncSafe();
    if (whatIf) continue;

    try {
      if (backup && !isSourceItself) {
        final bak = '${rec.path}.bak.$timestamp';
        await target.copy(bak);
        log('wroteBackup::$bak', 'info');
        final removed = limitBackups(rec.path);
        if (removed > 0) {
          log('backupRemoved::$removed::${rec.path}', 'muted');
        }
      }
      await target.writeAsString(sourceContent);
      log('wroteTarget::${rec.path}', 'info');
      replaced++;
    } on FileSystemException catch (e) {
      log('errorWriting::${rec.path}::$e', 'error');
      errors++;
    }
  }

  return ApplyResult(
    replaced: replaced,
    identicalCount: identicalCount,
    cleaned: cleaned,
    errors: errors,
  );
}

extension on File {
  /// Like [resolveSymbolicLinksSync] but returns the path unchanged on failure.
  String resolveSymbolicLinksSyncSafe() {
    try {
      return resolveSymbolicLinksSync();
    } on FileSystemException {
      return absolute.path;
    }
  }
}
