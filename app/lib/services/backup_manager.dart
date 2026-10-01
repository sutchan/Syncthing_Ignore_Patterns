/// Lists, restores and deletes the `.stignore.bak.*` backups created by Apply.
///
/// Apply writes `<path>.bak.<timestamp>` before overwriting each target and
/// rotates them to keep at most three. This helper surfaces those backups so
/// the UI can let the user restore or remove them.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'applier.dart' show limitBackups;

/// One discovered backup file and the target it would restore into.
class BackupEntry {
  const BackupEntry({
    required this.target,
    required this.bakPath,
    required this.modified,
  });

  /// The `.stignore` path the backup was made from.
  final String target;

  /// Absolute path of the `.bak.<timestamp>` file.
  final String bakPath;

  /// Last-modified time of the backup file.
  final DateTime modified;

  /// Display name of the target (its file name).
  String get targetName => p.basename(target);
}

/// Finds backups that sit next to the given target paths.
List<BackupEntry> listForTargets(List<String> targets) {
  final entries = <BackupEntry>[];
  for (final target in targets) {
    final dir = File(target).parent;
    if (!dir.existsSync()) continue;
    final base = p.basename(target);
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.uri.pathSegments.last.startsWith('$base.bak.')) continue;
      entries.add(BackupEntry(
        target: target,
        bakPath: f.path,
        modified: f.lastModifiedSync(),
      ));
    }
  }
  entries.sort((a, b) => b.modified.compareTo(a.modified));
  return entries;
}

/// Restores [entry]: backs up the current target first (so the restore is
/// reversible), then copies the backup over the live file and rotates.
Future<void> restore(BackupEntry entry) async {
  final target = File(entry.target);
  final ts = DateTime.now()
      .toIso8601String()
      .replaceAll(RegExp(r'[:.-]'), '')
      .substring(0, 14);
  if (target.existsSync()) {
    await target.copy('${entry.target}.bak.$ts');
    limitBackups(entry.target);
  }
  await File(entry.bakPath).copy(entry.target);
  limitBackups(entry.target);
}

/// Deletes the backup file referenced by [entry].
Future<void> deleteEntry(BackupEntry entry) async {
  try {
    await File(entry.bakPath).delete();
  } on FileSystemException {
    // best-effort
  }
}
