/// Version-string validation shared by the update paths.
library;

/// `true` for a clean version such as `1.28.5` (digits and dots only).
///
/// Release tags arrive from GitHub as arbitrary strings; interpolating an
/// unvalidated tag into a download URL or an on-disk archive path lets a
/// malicious/transient tag containing `..` or `/` escape the intended location
/// (path traversal). Restricting versions to `^[0-9][0-9.]*$` closes that gap.
bool isValidVersion(String version) =>
    RegExp(r'^[0-9][0-9.]*$').hasMatch(version.trim());
