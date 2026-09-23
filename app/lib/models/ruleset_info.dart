/// Ruleset metadata parsed from the `.stignore` header.
///
/// The ruleset carries its own version so the app can tell whether the copy in
/// the repository is newer than the one in use:
///
/// ```
/// //Syncthing Ignore Patterns Lists
/// //Version: 1.18.5
/// //Updated: 2026-09-22
/// ```
library;

class RulesetInfo {
  const RulesetInfo({required this.version, this.updated});

  /// Version declared by `//Version:`.
  final String version;

  /// Revision date declared by `//Updated:`, when present.
  final String? updated;

  static final RegExp _versionLine =
      RegExp(r'^\s*//\s*Version\s*:\s*([0-9][0-9.]*)\s*$', caseSensitive: false);
  static final RegExp _updatedLine =
      RegExp(r'^\s*//\s*Updated\s*:\s*(\S+)\s*$', caseSensitive: false);

  /// How many leading lines are searched for the header.
  static const int _headerLines = 20;

  /// Parses the header of [content], or returns `null` when it declares no
  /// version (e.g. a truncated or unrelated file).
  static RulesetInfo? parse(String content) {
    String? version;
    String? updated;
    var scanned = 0;
    for (final raw in content.split('\n')) {
      if (scanned++ >= _headerLines) break;
      final line = raw.replaceFirst('\uFEFF', '').trimRight();
      version ??= _versionLine.firstMatch(line)?.group(1);
      updated ??= _updatedLine.firstMatch(line)?.group(1);
      if (version != null && updated != null) break;
    }
    if (version == null) return null;
    return RulesetInfo(version: version, updated: updated);
  }

  @override
  String toString() => updated == null ? 'v$version' : 'v$version ($updated)';
}

/// Compares two dotted numeric versions: negative when [a] is older than [b],
/// `0` when equal, positive when newer.
///
/// Missing parts count as zero (`1.19` == `1.19.0`) and non-numeric parts
/// compare as zero, so a malformed header can never look "newer" by accident.
int compareRulesetVersions(String a, String b) {
  final left = a.split('.');
  final right = b.split('.');
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final l = i < left.length ? int.tryParse(left[i]) ?? 0 : 0;
    final r = i < right.length ? int.tryParse(right[i]) ?? 0 : 0;
    if (l != r) return l < r ? -1 : 1;
  }
  return 0;
}
