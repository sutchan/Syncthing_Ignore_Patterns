/// Backup management: lists, restores and deletes `.stignore` backups.
///
/// Mixed into `AppState`; the backup list is derived from the current scan
/// results (the `.stignore` paths Apply would target).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/backup_manager.dart';
import 'log_state.dart';
import 'preferences_state.dart';

mixin BackupState on ChangeNotifier, LogState, PreferencesState {
  List<BackupEntry> _backups = const [];
  bool _loadingBackups = false;

  /// Currently listed backups (newest first).
  List<BackupEntry> get backups => _backups;

  /// `true` while the backup list is being read.
  bool get loadingBackups => _loadingBackups;

  /// Refreshes the backup list for the given target paths.
  Future<void> loadBackups(List<String> targets) async {
    _loadingBackups = true;
    notifyListeners();
    try {
      _backups = BackupManager.listForTargets(targets);
    } on Exception catch (e) {
      log('backup list failed: $e', 'error');
      _backups = const [];
    } finally {
      _loadingBackups = false;
      notifyListeners();
    }
  }

  /// Restores a backup by its path, then refreshes the list.
  Future<void> restoreBackup(String bakPath) async {
    final entry = _find(bakPath);
    if (entry == null) return;
    try {
      await BackupManager.restore(entry);
      log(loc.t('backupRestored', [entry.targetName]), 'info');
    } on Exception catch (e) {
      log('${loc.t('backupRestoreFailed')}: $e', 'error');
    }
    await loadBackups(_backups.map((b) => b.target).toList());
  }

  /// Deletes a backup by its path, then refreshes the list.
  Future<void> deleteBackup(String bakPath) async {
    final entry = _find(bakPath);
    if (entry == null) return;
    try {
      await BackupManager.deleteEntry(entry);
      log(loc.t('backupDeleted', [entry.targetName]), 'info');
    } on Exception catch (e) {
      log('${loc.t('backupDeleteFailed')}: $e', 'error');
    }
    await loadBackups(_backups.map((b) => b.target).toList());
  }

  BackupEntry? _find(String bakPath) {
    for (final b in _backups) {
      if (b.bakPath == bakPath) return b;
    }
    return null;
  }
}
