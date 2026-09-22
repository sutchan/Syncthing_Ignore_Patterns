/// Loads the standard `.stignore` rule set (the "source" applied by Apply).
///
/// By default the bundled asset `assets/.stignore` is used. A custom file path
/// can be supplied to keep the GUI in sync with an external rules file.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads the standard rules content. When [path] is provided it is read from
/// disk; otherwise the bundled asset is used.
Future<String> loadStandardRules({String? path}) async {
  if (path != null && path.isNotEmpty) {
    return File(path).readAsString();
  }
  return (await rootBundle.loadString('assets/.stignore')).replaceAll('\r\n', '\n');
}

/// SHA-256 hex digest of [content] (UTF-8 bytes).
String sha256OfString(String content) {
  final bytes = utf8.encode(content);
  return sha256.convert(bytes).toString();
}
