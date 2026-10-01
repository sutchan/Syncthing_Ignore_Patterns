/// Data models for the scan manifest, mirroring the PowerShell manifest schema.
///
/// Manifest JSON shape (UTF-8):
/// {
///   "version": "1.30.0",
///   "scannedAt": "2026-09-22T00:00:00.000Z",
///   "count": 2,
///   "roots": ["C:\\", "D:\\"],
///   "files": [
///     { "path": "...", "size": 123, "lastWriteUtc": "..", "foundAtUtc": ".." }
///   ]
/// }
class StignoreRecord {
  const StignoreRecord({
    required this.path,
    required this.size,
    required this.lastWriteUtc,
    required this.foundAtUtc,
  });

  factory StignoreRecord.fromJson(Map<String, dynamic> json) => StignoreRecord(
        // `as String? ?? ''` instead of `as String` so a missing or
        // wrong-typed field degrades to an empty string rather than throwing a
        // TypeError (which `on Exception` handlers cannot catch).
        path: json['path'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        lastWriteUtc: json['lastWriteUtc'] as String? ?? '',
        foundAtUtc: json['foundAtUtc'] as String? ?? '',
      );

  final String path;
  final int size;
  final String lastWriteUtc;
  final String foundAtUtc;

  Map<String, dynamic> toJson() => {
        'path': path,
        'size': size,
        'lastWriteUtc': lastWriteUtc,
        'foundAtUtc': foundAtUtc,
      };
}

class Manifest {
  Manifest({
    required this.version,
    required this.scannedAt,
    required this.roots,
    required this.files,
  }) : count = files.length;

  factory Manifest.fromJson(Map<String, dynamic> json) => Manifest(
        version: json['version'] as String? ?? '0.0.0',
        scannedAt: json['scannedAt'] as String? ?? '',
        // Guard with `is List` before casting so a non-list or null `roots`/
        // `files` field (hand-edited or corrupt manifest) cannot throw a
        // TypeError. Malformed entries are skipped rather than crashing Scan/Apply.
        roots: json['roots'] is List
            ? (json['roots'] as List)
                .map((e) => e as String? ?? '')
                .where((s) => s.isNotEmpty)
                .toList()
            : const <String>[],
        files: json['files'] is List
            ? (json['files'] as List)
                .whereType<Map<String, dynamic>>()
                .map(StignoreRecord.fromJson)
                .toList()
            : const <StignoreRecord>[],
      );

  final String version;
  final String scannedAt;
  final List<String> roots;
  final List<StignoreRecord> files;
  final int count;

  Map<String, dynamic> toJson() => {
        'version': version,
        'scannedAt': scannedAt,
        'count': count,
        'roots': roots,
        'files': files.map((f) => f.toJson()).toList(),
      };
}
