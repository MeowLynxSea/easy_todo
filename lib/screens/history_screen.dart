import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/widgets/calendar_widget.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/screens/day_detail_screen.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<TodoProvider, AppSettingsProvider>(
      builder: (context, provider, appSettingsProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.history),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.today),
                Tab(text: l10n.thisWeek),
                Tab(text: l10n.thisMonth),
                Tab(text: l10n.allTodos),
              ],
            ),
          ),
          body: WebDesktopContent(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    return _buildSearchBar(l10n, queryText: value.text);
                  },
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Builder(
                        builder: (context) {
                          final todos = provider.getTodayTodos();
                          return ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, _) {
                              return _buildTodosList(
                                todos,
                                l10n,
                                queryText: value.text,
                              );
                            },
                          );
                        },
                      ),
                      Builder(
                        builder: (context) {
                          final todos = provider.getWeekTodos();
                          return ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, _) {
                              return _buildTodosList(
                                todos,
                                l10n,
                                queryText: value.text,
                              );
                            },
                          );
                        },
                      ),
                      Builder(
                        builder: (context) {
                          final todos = provider.getMonthTodos();
                          return ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, _) {
                              return _buildTodosList(
                                todos,
                                l10n,
                                queryText: value.text,
                              );
                            },
                          );
                        },
                      ),
                      Builder(
                        builder: (context) {
                          return _buildAllTodosTab(
                            provider,
                            appSettingsProvider,
                            l10n,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(AppLocalizations? l10n, {required String queryText}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: l10n?.searchTodos ?? 'Search todos',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: queryText.isNotEmpty
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

  Widget _buildTodosList(
    List<TodoModel> todos,
    AppLocalizations? l10n, {
    required String queryText,
  }) {
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n?.noTodosYet ?? 'No todos yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final filteredTodos = todos
        .where((todo) {
          final query = queryText.toLowerCase();
          return query.isEmpty ||
              todo.title.toLowerCase().contains(query) ||
              (todo.description?.toLowerCase().contains(query) ?? false);
        })
        .cast<TodoModel>()
        .toList();

    if (filteredTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n?.noTodosMatchSearch ?? 'No todos match search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTodos.length,
        itemBuilder: (context, index) {
          final todo = filteredTodos[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: _buildHistoryCard(todo)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(TodoModel todo) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _showTodoDetails(todo),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: todo.isCompleted
                ? AppTheme.secondaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
          child: todo.isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Icon(
                  Icons.radio_button_unchecked,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: todo.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: todo.isCompleted
                ? Colors.grey
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description != null && todo.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                todo.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: todo.isCompleted
                      ? Colors.grey
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(todo.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (todo.completedAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(todo.completedAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ],
            ),
            if (todo.timeSpent != null && todo.timeSpent! > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.timeSpent}: ${todo.formattedTimeSpent}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
            _buildDetailRow(l10n.createdLabel, todo.createdAt),
            if (todo.completedAt != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                l10n.completedLabel,
                todo.completedAt!,
                isCompleted: true,
              ),
            ],
            if (todo.timeSpent != null && todo.timeSpent! > 0) ...[
              const SizedBox(height: 8),
              _buildTimeSpentRow(l10n.timeSpent, todo.timeSpent!),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: todo.isCompleted
                    ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    todo.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: todo.isCompleted
                        ? AppTheme.secondaryColor
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    todo.isCompleted ? l10n.complete : l10n.incomplete,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: todo.isCompleted
                          ? AppTheme.secondaryColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildDetailRow(
    String label,
    DateTime date, {
    bool isCompleted = false,
  }) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isCompleted ? AppTheme.secondaryColor : Colors.grey[600],
          ),
        ),
        Text(
          _formatDate(date),
          style: TextStyle(
            fontSize: 12,
            color: isCompleted ? AppTheme.secondaryColor : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSpentRow(String label, int timeSpent) {
    final minutes = (timeSpent ~/ 60).toString().padLeft(2, '0');
    final seconds = (timeSpent % 60).toString().padLeft(2, '0');
    final formattedTime = '$minutes:$seconds';

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          formattedTime,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year} ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAllTodosTab(
    TodoProvider provider,
    AppSettingsProvider appSettingsProvider,
    AppLocalizations? l10n,
  ) {
    if (appSettingsProvider.historyViewMode == 'calendar') {
      return _buildCalendarView(provider, l10n);
    } else {
      final todos = provider.getAllTodos();
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (context, value, _) {
          return _buildTodosList(todos, l10n, queryText: value.text);
        },
      );
    }
  }

  Widget _buildCalendarView(TodoProvider provider, AppLocalizations? l10n) {
    final allTodos = provider.getAllTodos();

    return CalendarWidget(
      todos: allTodos,
      selectedDay: _selectedDate,
      onDaySelected: (selectedDate) {
        setState(() {
          _selectedDate = selectedDate;
        });
        _navigateToDayDetail(selectedDate, allTodos);
      },
    );
  }

  void _navigateToDayDetail(DateTime date, List<TodoModel> allTodos) {
    final dayTodos = allTodos.where((todo) {
      return todo.createdAt.year == date.year &&
          todo.createdAt.month == date.month &&
          todo.createdAt.day == date.day;
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailScreen(date: date, todos: dayTodos),
      ),
    );
  }
}
