import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/providers/filter_provider.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/widgets/stacking_todo_list.dart';
import 'package:easy_todo/widgets/optimized_todo_list.dart';
import 'package:easy_todo/widgets/add_todo_dialog.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/screens/pomodoro_screen.dart';
import 'package:easy_todo/screens/repeat_tasks_screen.dart';
import 'package:easy_todo/utils/responsive.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addTodoController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Initialize filters after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final filterProvider = Provider.of<FilterProvider>(
          context,
          listen: false,
        );
        final todoProvider = Provider.of<TodoProvider>(context, listen: false);

        // Sync TodoProvider with FilterProvider defaults
        todoProvider.syncWithFilterProvider(filterProvider);
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _addTodoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = Provider.of<TodoProvider>(context, listen: false);
    provider.setSearchQuery(_searchController.text);
  }

  Future<void> _addTodo() async {
    if (_addTodoController.text.trim().isEmpty) return;

    final provider = Provider.of<TodoProvider>(context, listen: false);
    await provider.addTodo(_addTodoController.text.trim(), description: null);

    if (!mounted) return;
    _addTodoController.clear();
    FocusScope.of(context).unfocus();
  }

  void _showAddTodoDialog() {
    final provider = Provider.of<TodoProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        onAdd:
            (
              title,
              description, {
              reminderTime,
              reminderEnabled = false,
              startTime,
              endTime,
            }) async {
              await provider.addTodo(
                title,
                description: description,
                reminderTime: reminderTime,
                reminderEnabled: reminderEnabled,
                startTime: startTime,
                endTime: endTime,
              );
            },
        onAddRepeat: (repeatTodo) async {
          await provider.addRepeatTodo(repeatTodo);
        },
      ),
    );
  }

  void _showEditReminderDialog(TodoModel todo) {
    final provider = Provider.of<TodoProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        todo: todo,
        onAdd:
            (
              title,
              description, {
              reminderTime,
              reminderEnabled = false,
              startTime,
              endTime,
            }) async {
              final updatedTodo = todo.copyWith(
                reminderTime: reminderTime,
                reminderEnabled: reminderEnabled,
                startTime: startTime,
                endTime: endTime,
              );
              await provider.updateTodo(updatedTodo);
            },
      ),
    );
  }

  void _showFilterDialog() {
    final l10n = AppLocalizations.of(context)!;
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    final aiProvider = Provider.of<AIProvider>(context, listen: false);

    final showCategoryFilter =
        aiProvider.settings.enableAIFeatures &&
        aiProvider.settings.enableAutoCategorization;
    final showImportanceSort =
        aiProvider.settings.enableAIFeatures &&
        aiProvider.settings.enablePrioritySorting;

    final tabCount = 3 + (showCategoryFilter ? 1 : 0);

    Widget buildFilterPanel(StateSetter setState, {required bool asDialog}) {
      final borderRadius = asDialog
          ? BorderRadius.circular(16)
          : const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            );

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filterByStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Filter Presets
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterPresetChip(
                    l10n.filterAll,
                    filterProvider.statusFilter == TodoFilter.all &&
                        filterProvider.timeFilter == TimeFilter.all,
                    () {
                      setState(() {
                        filterProvider.setStatusFilter(TodoFilter.all);
                        filterProvider.setTimeFilter(TimeFilter.all);
                        todoProvider.setFilter(TodoFilter.all);
                        todoProvider.setTimeFilter(TimeFilter.all);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPresetChip(
                    l10n.filterTodayTodos,
                    filterProvider.statusFilter == TodoFilter.active &&
                        filterProvider.timeFilter == TimeFilter.today,
                    () {
                      setState(() {
                        filterProvider.setStatusFilter(TodoFilter.active);
                        filterProvider.setTimeFilter(TimeFilter.today);
                        todoProvider.setFilter(TodoFilter.active);
                        todoProvider.setTimeFilter(TimeFilter.today);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPresetChip(
                    l10n.filterCompleted,
                    filterProvider.statusFilter == TodoFilter.completed,
                    () {
                      setState(() {
                        filterProvider.setStatusFilter(TodoFilter.completed);
                        todoProvider.setFilter(TodoFilter.completed);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPresetChip(
                    l10n.filterThisWeek,
                    filterProvider.timeFilter == TimeFilter.week,
                    () {
                      setState(() {
                        filterProvider.setTimeFilter(TimeFilter.week);
                        todoProvider.setTimeFilter(TimeFilter.week);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab Bar
            DefaultTabController(
              length: tabCount,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBar(
                    isScrollable: true,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: AppTheme.primaryColor,
                    overlayColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.pressed)) {
                        return AppTheme.primaryColor.withValues(alpha: 0.1);
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return AppTheme.primaryColor.withValues(alpha: 0.05);
                      }
                      return null;
                    }),
                    tabs: [
                      Tab(text: l10n.filterByStatus),
                      Tab(text: l10n.filterByTime),
                      if (showCategoryFilter) Tab(text: l10n.filterByCategory),
                      Tab(text: l10n.sortBy),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      children: [
                        // Status Filter
                        _buildStatusFilterTab(
                          filterProvider,
                          todoProvider,
                          setState,
                        ),
                        // Time Filter
                        _buildTimeFilterTab(
                          filterProvider,
                          todoProvider,
                          setState,
                        ),
                        // Category Filter
                        if (showCategoryFilter)
                          _buildCategoryFilterTab(
                            filterProvider,
                            todoProvider,
                            setState,
                          ),
                        // Sort Order
                        _buildSortOrderTab(
                          filterProvider,
                          todoProvider,
                          setState,
                          showImportanceSort: showImportanceSort,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // Reset all filters
                      setState(() {
                        filterProvider.setStatusFilter(TodoFilter.all);
                        filterProvider.setTimeFilter(TimeFilter.all);
                        filterProvider.setSortOrder(SortOrder.timeDescending);
                        filterProvider.clearCategoryFilter();
                        // Sync TodoProvider with FilterProvider after reset
                        todoProvider.syncWithFilterProvider(filterProvider);
                      });
                    },
                    child: Text(l10n.resetButton),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.applyButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isWebDesktop(context)) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                child: buildFilterPanel(setState, asDialog: true),
              ),
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) =>
            buildFilterPanel(setState, asDialog: false),
      ),
    );
  }

  Widget _buildFilterPresetChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700]),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
        width: 1,
      ),
    );
  }

  Widget _buildStatusFilterTab(
    FilterProvider filterProvider,
    TodoProvider todoProvider,
    StateSetter setState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: TodoFilter.values.map((filter) {
        String title;
        switch (filter) {
          case TodoFilter.all:
            title = l10n.allTodos;
            break;
          case TodoFilter.active:
            title = l10n.activeTodos;
            break;
          case TodoFilter.completed:
            title = l10n.completedTodos;
            break;
        }

        return RadioListTile<TodoFilter>(
          title: Text(
            title,
            style: TextStyle(
              color: filter == filterProvider.statusFilter
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(
                            0xFF818CF8,
                          ) // Lighter theme color for dark mode
                        : Theme.of(context).colorScheme.primary)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: filter == filterProvider.statusFilter
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          value: filter,
          groupValue: filterProvider.statusFilter,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                filterProvider.setStatusFilter(value);
                todoProvider.setFilter(value);
              });
            }
          },
          contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF818CF8) // Lighter theme color for dark mode
              : Theme.of(context).colorScheme.primary,
          fillColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF818CF8) // Lighter theme color for dark mode
                  : Theme.of(context).colorScheme.primary;
            }
            return null;
          }),
        );
      }).toList(),
    );
  }

  Widget _buildTimeFilterTab(
    FilterProvider filterProvider,
    TodoProvider todoProvider,
    StateSetter setState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: TimeFilter.values.map((filter) {
        String title;
        switch (filter) {
          case TimeFilter.all:
            title = l10n.allTodos;
            break;
          case TimeFilter.today:
            title = l10n.today;
            break;
          case TimeFilter.yesterday:
            title = l10n.yesterday;
            break;
          case TimeFilter.threeDays:
            title = l10n.threeDays;
            break;
          case TimeFilter.week:
            title = l10n.thisWeek;
            break;
          case TimeFilter.month:
            title = l10n.thisMonth;
            break;
        }

        return RadioListTile<TimeFilter>(
          title: Text(
            title,
            style: TextStyle(
              color: filter == filterProvider.timeFilter
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(
                            0xFF818CF8,
                          ) // Lighter theme color for dark mode
                        : Theme.of(context).colorScheme.primary)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: filter == filterProvider.timeFilter
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          value: filter,
          groupValue: filterProvider.timeFilter,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                filterProvider.setTimeFilter(value);
                todoProvider.setTimeFilter(value);
              });
            }
          },
          contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF818CF8) // Lighter theme color for dark mode
              : Theme.of(context).colorScheme.primary,
          fillColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF818CF8)
                  : Theme.of(context).colorScheme.primary;
            }
            return null;
          }),
        );
      }).toList(),
    );
  }

  Widget _buildSortOrderTab(
    FilterProvider filterProvider,
    TodoProvider todoProvider,
    StateSetter setState, {
    bool showImportanceSort = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: SortOrder.values
          .where((order) {
            // Filter out importance sorting options if not enabled
            if (!showImportanceSort &&
                (order == SortOrder.importanceAscending ||
                    order == SortOrder.importanceDescending)) {
              return false;
            }
            return true;
          })
          .map((order) {
            String title;
            switch (order) {
              case SortOrder.timeAscending:
                title = '${l10n.sortByTime} (${l10n.ascending})';
                break;
              case SortOrder.timeDescending:
                title = '${l10n.sortByTime} (${l10n.descending})';
                break;
              case SortOrder.alphabetical:
                title = l10n.alphabetical;
                break;
              case SortOrder.importanceAscending:
                title = '${l10n.importance} (${l10n.ascending})';
                break;
              case SortOrder.importanceDescending:
                title = '${l10n.importance} (${l10n.descending})';
                break;
            }

            return RadioListTile<SortOrder>(
              title: Text(
                title,
                style: TextStyle(
                  color: order == filterProvider.sortOrder
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF818CF8)
                            : Theme.of(context).colorScheme.primary)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: order == filterProvider.sortOrder
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              value: order,
              groupValue: filterProvider.sortOrder,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    filterProvider.setSortOrder(value);
                    todoProvider.setSortOrder(value);
                  });
                }
              },
              contentPadding: EdgeInsets.zero,
              activeColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF818CF8) // Lighter theme color for dark mode
                  : Theme.of(context).colorScheme.primary,
              fillColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).brightness == Brightness.dark
                      ? const Color(
                          0xFF818CF8,
                        ) // Lighter theme color for dark mode
                      : Theme.of(context).colorScheme.primary;
                }
                return null;
              }),
            );
          })
          .toList(),
    );
  }

  // Helper function to get localized category name
  String _getLocalizedCategory(String category, AppLocalizations l10n) {
    switch (category.toLowerCase()) {
      case 'work':
        return l10n.aiCategoryWork;
      case 'personal':
        return l10n.aiCategoryPersonal;
      case 'study':
        return l10n.aiCategoryStudy;
      case 'health':
        return l10n.aiCategoryHealth;
      case 'fitness':
        return l10n.aiCategoryFitness;
      case 'finance':
        return l10n.aiCategoryFinance;
      case 'shopping':
        return l10n.aiCategoryShopping;
      case 'family':
        return l10n.aiCategoryFamily;
      case 'social':
        return l10n.aiCategorySocial;
      case 'hobby':
        return l10n.aiCategoryHobby;
      case 'travel':
        return l10n.aiCategoryTravel;
      case 'other':
        return l10n.aiCategoryOther;
      default:
        return category; // Fallback to original category if not found
    }
  }

  Widget _buildCategoryFilterTab(
    FilterProvider filterProvider,
    TodoProvider todoProvider,
    StateSetter setState,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // Get all available categories from todos
    final allCategories =
        todoProvider.allTodos
            .where(
              (todo) => todo.aiCategory != null && todo.aiCategory!.isNotEmpty,
            )
            .map((todo) => todo.aiCategory!)
            .toSet()
            .toList()
          ..sort();

    if (allCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noCategoriesAvailable,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aiWillCategorizeTasks,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.selectCategories,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: filterProvider.selectedCategories.isNotEmpty
                    ? () {
                        setState(() {
                          filterProvider.clearCategoryFilter();
                          // Sync TodoProvider with FilterProvider after clearing categories
                          todoProvider.syncWithFilterProvider(filterProvider);
                        });
                      }
                    : null,
                child: Text(
                  l10n.clear,
                  style: TextStyle(
                    color: filterProvider.selectedCategories.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: allCategories.map((category) {
              return Consumer<FilterProvider>(
                builder: (context, provider, child) {
                  final isSelected = provider.selectedCategories.contains(
                    category,
                  );
                  return CheckboxListTile(
                    title: Text(
                      _getLocalizedCategory(category, l10n),
                      style: TextStyle(
                        color: isSelected
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF818CF8)
                                  : Theme.of(context).colorScheme.primary)
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        filterProvider.toggleCategory(category);
                        // Sync TodoProvider with FilterProvider after category change
                        todoProvider.syncWithFilterProvider(filterProvider);
                      });
                    },
                    activeColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF818CF8)
                        : Theme.of(context).colorScheme.primary,
                    checkColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer3<TodoProvider, AppSettingsProvider, AIProvider>(
      builder: (context, provider, appSettingsProvider, aiProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.easyTodo),
            actions: [
              Consumer<TodoProvider>(
                builder: (context, provider, child) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterDialog,
                        tooltip: l10n.filterByStatus,
                      ),
                      if (provider.dateRange != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.repeat),
                onPressed: _showRepeatTasksScreen,
                tooltip: l10n.manageRepeatTasks,
              ),
            ],
          ),
          floatingActionButton: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            child: AnimatedRotation(
              turns: 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_addTodoController.text.trim().isNotEmpty) {
                    _addTodo();
                  } else {
                    _showAddTodoDialog();
                  }
                },
                elevation: 6,
                highlightElevation: 12,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
          body: WebDesktopContent(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildStatsSummary(provider, l10n),
                _buildSearchBar(l10n),
                const Divider(height: 1),
                Expanded(child: _buildTodoList(provider, appSettingsProvider)),
                _buildAddTodoInput(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSummary(TodoProvider provider, AppLocalizations l10n) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: l10n.totalTodos,
                  value: provider.allTodos.length.toString(),
                  color: AppTheme.primaryColor,
                  filter: TodoFilter.all,
                  provider: provider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: l10n.activeTodosCount,
                  value: provider.activeTodosCount.toString(),
                  color: Colors.orange,
                  filter: TodoFilter.active,
                  provider: provider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: l10n.completedTodosCount,
                  value: provider.completedTodosCount.toString(),
                  color: AppTheme.secondaryColor,
                  filter: TodoFilter.completed,
                  provider: provider,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required TodoFilter filter,
    required TodoProvider provider,
  }) {
    final isSelected = provider.currentFilter == filter;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          final filterProvider = Provider.of<FilterProvider>(
            context,
            listen: false,
          );
          filterProvider.setStatusFilter(filter);
          provider.setFilter(filter);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.3),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Text(
                  value,
                  key: ValueKey('${filter}_$value'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: l10n.searchTodos,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTodoList(
    TodoProvider provider,
    AppSettingsProvider appSettingsProvider,
  ) {
    if (provider.isLoading && provider.todos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.todos.isEmpty) {
      return _buildEmptyState();
    }

    if (appSettingsProvider.viewMode == 'stacking') {
      return StackingTodoList(
        todos: provider.todos,
        onToggle: (todo) => _toggleTodoCompletion(todo.id),
        onDelete: (todo) => _deleteTodo(todo.id),
        onStartPomodoro: (todo) => _startPomodoro(todo),
        onEditReminder: (todo) => _showEditReminderDialog(todo),
        onTap: (todo) => _showTodoDetails(todo),
        isProcessingCategories: provider.isProcessingCategories,
        isProcessingPriorities: provider.isProcessingPriorities,
      );
    } else {
      return OptimizedTodoList(
        todos: provider.todos,
        scrollController: _scrollController,
        isLoading: provider.isLoading,
        hasMore: false,
        onLoadMore: () {},
        onToggle: (todo) => _toggleTodoCompletion(todo.id),
        onDelete: (todo) => _deleteTodo(todo.id),
        onEditReminder: (todo) => _showEditReminderDialog(todo),
        onTap: (todo) => _showTodoDetails(todo),
      );
    }
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty
                    ? l10n.noTodosMatchSearch
                    : provider.currentFilter == TodoFilter.completed
                    ? l10n.noCompletedTodos
                    : provider.currentFilter == TodoFilter.active
                    ? l10n.noActiveTodos
                    : l10n.noTodosYet,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty
                    ? l10n.noTodosMatchSearch
                    : provider.currentFilter == TodoFilter.completed
                    ? l10n.noCompletedTodos
                    : provider.currentFilter == TodoFilter.active
                    ? l10n.noActiveTodos
                    : l10n.addTodoHint,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTodoDetails(TodoModel todo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(todo.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description != null && todo.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(todo.description!),
              const SizedBox(height: 16),
            ],
            Text(
              '${l10n.createdLabel}${_formatDate(todo.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (todo.completedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.completedLabel}${_formatDate(todo.completedAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTodoCompletion(String id) async {
    if (!mounted) return;
    final provider = Provider.of<TodoProvider>(context, listen: false);
    await provider.toggleTodoCompletion(id);
  }

  void _startPomodoro(TodoModel todo) {
    if (!todo.isCompleted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PomodoroScreen(todo: todo)),
      );
    }
  }

  Future<void> _deleteTodo(String id) async {
    if (!mounted) return;
    final provider = Provider.of<TodoProvider>(context, listen: false);
    await provider.deleteTodo(id);
  }

  Widget _buildAddTodoInput() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addTodoController,
                  decoration: InputDecoration(
                    hintText: l10n.addTodoHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _addTodo(),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _addTodo,
                  tooltip: l10n.addTodo,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRepeatTasksScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RepeatTasksScreen()));
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year} ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }
}
