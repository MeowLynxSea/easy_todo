import 'package:flutter/material.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/services/repositories/user_preferences_repository.dart';

class FilterProvider extends ChangeNotifier {
  TodoFilter _statusFilter = TodoFilter.active;
  TimeFilter _timeFilter = TimeFilter.all;
  SortOrder _sortOrder = SortOrder.timeAscending;
  Set<String> _selectedCategories = {};
  final UserPreferencesRepository _preferencesRepository =
      UserPreferencesRepository();

  FilterProvider() {
    _loadPreferences();
  }

  TodoFilter get statusFilter => _statusFilter;
  TimeFilter get timeFilter => _timeFilter;
  SortOrder get sortOrder => _sortOrder;
  Set<String> get selectedCategories => _selectedCategories;

  void setStatusFilter(TodoFilter filter) {
    _statusFilter = filter;
    _savePreferences();
    notifyListeners();
  }

  void setTimeFilter(TimeFilter filter) {
    _timeFilter = filter;
    _savePreferences();
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    _savePreferences();
    notifyListeners();
  }

  void setSelectedCategories(Set<String> categories) {
    _selectedCategories = categories;
    _savePreferences();
    notifyListeners();
  }

  void toggleCategory(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    _savePreferences();
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategories.clear();
    _savePreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final userPrefs = await _preferencesRepository.load();
    _statusFilter = TodoFilter.values[userPrefs.statusFilterIndex];
    _timeFilter = TimeFilter.values[userPrefs.timeFilterIndex];
    _sortOrder = SortOrder.values[userPrefs.sortOrderIndex];
    _selectedCategories = userPrefs.selectedCategories.toSet();

    notifyListeners();
  }

  Future<void> _savePreferences() async {
    await _preferencesRepository.update(
      (current) => current.copyWith(
        statusFilterIndex: _statusFilter.index,
        timeFilterIndex: _timeFilter.index,
        sortOrderIndex: _sortOrder.index,
        selectedCategories: _selectedCategories.toList(growable: false),
      ),
    );
  }

  Future<void> reloadFromPreferences() async {
    await _loadPreferences();
  }

  void resetToDefaults() {
    _statusFilter = TodoFilter.active;
    _timeFilter = TimeFilter.all;
    _sortOrder = SortOrder.timeAscending;
    _selectedCategories.clear();
    _savePreferences();
    notifyListeners();
  }
}
