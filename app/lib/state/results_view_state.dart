/// Result-list view state: search query, compliance / type filters and
/// multi-select, mixed into `AppState`.
///
/// Kept separate so `ui/results_list.dart` and `ui/results_filter.dart` stay
/// small and focused on rendering. The state is session-scoped (not persisted).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'progress_state.dart';
import 'scan_flow.dart';

/// Applies the search query, compliance filter and type filter to [results].
///
/// Pure helper (no `AppState` access) so both the list and its header recompute
/// the visible rows from the same inputs without relying on list identity.
List<String> filterResults(
  List<String> results,
  Map<String, bool> compliance,
  String query,
  String complianceFilter,
  String typeFilter,
) {
  var list = results;
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list.where((p) => p.toLowerCase().contains(q)).toList();
  }
  if (complianceFilter != 'all') {
    final want = complianceFilter == 'ok';
    list = list.where((p) => (compliance[p] ?? false) == want).toList();
  }
  if (typeFilter != 'all') {
    final wantDir = typeFilter == 'dir';
    list =
        list.where((p) => FileSystemEntity.isDirectorySync(p) == wantDir).toList();
  }
  return list;
}

mixin ResultsViewState on ChangeNotifier, ProgressState, ScanFlow {
  String _resultQuery = '';

  /// Substring filter applied to result paths (case-insensitive).
  String get resultQuery => _resultQuery;
  void setResultQuery(String value) {
    if (_resultQuery == value) return;
    _resultQuery = value;
    notifyListeners();
  }

  /// Compliance filter: `all` | `need` (would change) | `ok` (already matches).
  String _complianceFilter = 'all';
  String get complianceFilter => _complianceFilter;
  void setComplianceFilter(String value) {
    if (_complianceFilter == value) return;
    _complianceFilter = value;
    notifyListeners();
  }

  /// Type filter: `all` | `file` | `dir`.
  String _typeFilter = 'all';
  String get typeFilter => _typeFilter;
  void setTypeFilter(String value) {
    if (_typeFilter == value) return;
    _typeFilter = value;
    notifyListeners();
  }

  final Set<String> _selected = {};

  /// Paths currently selected for bulk actions.
  Set<String> get selected => _selected;
  bool isSelected(String path) => _selected.contains(path);
  void toggleSelected(String path) {
    if (_selected.contains(path)) {
      _selected.remove(path);
    } else {
      _selected.add(path);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }

  /// Results after the search query, compliance filter and type filter.
  List<String> get filteredResults => filterResults(
        results,
        compliance,
        _resultQuery,
        _complianceFilter,
        _typeFilter,
      );

  /// Writes the selected paths (one per line) to [file].
  Future<void> exportSelected(String file) async {
    final sink = File(file).openWrite();
    for (final p in _selected) {
      sink.writeln(p);
    }
    await sink.flush();
    await sink.close();
  }
}
