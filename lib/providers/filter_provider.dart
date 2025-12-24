import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_todo/providers/todo_provider.dart';

class FilterProvider extends ChangeNotifier {
  static const String _statusFilterKey = 'todo_status_filter';
  static const String _timeFilterKey = 'todo_time_filter';
  static const String _sortOrderKey = 'todo_sort_order';
  static const String _selectedCategoriesKey = 'todo_selected_categories';

  TodoFilter _statusFilter = TodoFilter.active;
  TimeFilter _timeFilter = TimeFilter.all;
  SortOrder _sortOrder = SortOrder.timeAscending;
  Set<String> _selectedCategories = {};

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
    final prefs = await SharedPreferences.getInstance();

    _statusFilter = TodoFilter
        .values[prefs.getInt(_statusFilterKey) ?? TodoFilter.active.index];
    _timeFilter =
        TimeFilter.values[prefs.getInt(_timeFilterKey) ?? TimeFilter.all.index];
    _sortOrder = SortOrder
        .values[prefs.getInt(_sortOrderKey) ?? SortOrder.timeAscending.index];

    final categoriesString = prefs.getString(_selectedCategoriesKey);
    if (categoriesString != null && categoriesString.isNotEmpty) {
      _selectedCategories = Set<String>.from(categoriesString.split(','));
    }

    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_statusFilterKey, _statusFilter.index);
    await prefs.setInt(_timeFilterKey, _timeFilter.index);
    await prefs.setInt(_sortOrderKey, _sortOrder.index);
    await prefs.setString(_selectedCategoriesKey, _selectedCategories.join(','));
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
