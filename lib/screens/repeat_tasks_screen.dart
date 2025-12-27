import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:provider/provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/utils/date_utils.dart';
import 'package:easy_todo/widgets/repeat_todo_dialog.dart';
import 'package:easy_todo/widgets/ai_loading_indicator.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class RepeatTasksScreen extends StatefulWidget {
  const RepeatTasksScreen({super.key});

  @override
  State<RepeatTasksScreen> createState() => _RepeatTasksScreenState();
}

class _RepeatTasksScreenState extends State<RepeatTasksScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // 延迟加载以避免在构建期间调用 notifyListeners()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRepeatTodos();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retry loading if we're in an error state and not loading
    if (_hasError && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRepeatTodos();
      });
    }
  }

  Future<void> _loadRepeatTodos() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      await todoProvider.loadRepeatTodos();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error loading repeat todos in screen: $e');
    }
  }

  Future<void> _forceRefreshRepeatTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final todoProvider = Provider.of<TodoProvider>(context, listen: false);

      // First, clean up any existing tasks for repeat templates
      await _cleanupExistingRepeatTasks(todoProvider);

      // 重新加载以确保数据一致性
      await todoProvider.loadTodos();

      final beforeGeneratedTodoIds = todoProvider.allTodos
          .where((todo) => todo.isGeneratedFromRepeat)
          .map((todo) => todo.id)
          .toSet();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 直接调用强制刷新方法，而不是refreshTodayRepeatTasks
      await todoProvider.forceRefreshAllRepeatTasks(
        onBackfillStartConflict: (repeatTodo, startDate, backfillStartDate) {
          return _showBackfillStartConflictDialog(
            repeatTodo: repeatTodo,
            startDate: startDate,
            backfillStartDate: backfillStartDate,
          );
        },
      );

      // 再次加载以显示新生成的任务
      await todoProvider.loadTodos();

      final createdGeneratedTodos = todoProvider.allTodos
          .where(
            (todo) =>
                todo.isGeneratedFromRepeat &&
                !beforeGeneratedTodoIds.contains(todo.id),
          )
          .toList(growable: false);

      final createdCount = createdGeneratedTodos.length;
      final createdTodayCount = createdGeneratedTodos
          .where((todo) => _isSameDay(todo.createdAt, today))
          .length;
      final createdBackfillCount = createdCount - createdTodayCount;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.repeatTasksRefreshedSuccessfully} '
              '(+$createdCount, ${l10n.today}: $createdTodayCount, ${l10n.backfillMode}: $createdBackfillCount)',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error force refreshing repeat tasks: $e');

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorRefreshingRepeatTasks}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _cleanupExistingRepeatTasks(TodoProvider todoProvider) async {
    // 确保时区已初始化
    try {
      tz.initializeTimeZones();
    } catch (e) {
      // 时区初始化失败时继续使用默认时区
    }

    // 使用本地时间而不是时区时间，避免时区混乱
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all active repeat todos
    final activeRepeatTodos = todoProvider.repeatTodos
        .where((rt) => rt.isActive)
        .toList();

    for (final repeatTodo in activeRepeatTodos) {
      // Find all todos generated from this repeat template that were created TODAY
      // 删除所有今天生成的任务，无论其完成状态如何
      final generatedTodos = todoProvider.allTodos
          .where(
            (todo) =>
                todo.repeatTodoId == repeatTodo.id &&
                todo.isGeneratedFromRepeat &&
                _isSameDay(todo.createdAt, today),
          )
          .toList();

      // Delete all today's generated tasks (both completed and uncompleted)
      for (final todo in generatedTodos) {
        await todoProvider.deleteTodo(todo.id);
      }
    }
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return isSameLocalDay(date1, date2);
  }

  Future<BackfillStartBasis?> _showBackfillStartConflictDialog({
    required RepeatTodoModel repeatTodo,
    required DateTime startDate,
    required DateTime backfillStartDate,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final startDateText = startDate.toLocal().toString().split(' ')[0];
    final backfillStartDateText = backfillStartDate.toLocal().toString().split(
      ' ',
    )[0];

    return showDialog<BackfillStartBasis>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.backfillConflictTitle),
          content: Text(
            l10n.backfillConflictMessage(
              repeatTodo.title,
              startDateText,
              backfillStartDateText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(BackfillStartBasis.startDate);
              },
              child: Text(l10n.useStartDate),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(BackfillStartBasis.backfillDays);
              },
              child: Text(l10n.useBackfillDays),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageRepeatTasks),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceRefreshRepeatTasks,
            tooltip: l10n.forceRefresh,
          ),
        ],
      ),
      body: WebDesktopContent(
        padding: EdgeInsets.zero,
        child: Consumer<TodoProvider>(
          builder: (context, todoProvider, child) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.errorLoadingRepeatTasks,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.pleaseCheckStoragePermissions,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadRepeatTodos,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }

            final repeatTodos = todoProvider.repeatTodos;

            if (repeatTodos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.repeat, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noRepeatTasks,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.createYourFirstRepeatTask,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            // Sort repeat tasks: active first, then paused
            final sortedRepeatTodos = List<RepeatTodoModel>.from(repeatTodos)
              ..sort((a, b) {
                if (a.isActive == b.isActive) return 0;
                return a.isActive ? -1 : 1;
              });

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: sortedRepeatTodos.length,
              itemBuilder: (context, index) {
                final repeatTodo = sortedRepeatTodos[index];
                return _buildRepeatTaskCard(repeatTodo, todoProvider, l10n);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRepeatTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRepeatTaskCard(
    RepeatTodoModel repeatTodo,
    TodoProvider todoProvider,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: repeatTodo.isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.repeat,
            color: repeatTodo.isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
        title: Text(
          repeatTodo.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: repeatTodo.isActive
                ? Theme.of(context).colorScheme.onSurface
                : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _getRepeatDescription(repeatTodo, l10n),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // Show AI processing status
            if (todoProvider.isRepeatTodoProcessingAI(repeatTodo.id) ||
                todoProvider.getRepeatTodoAIStatus(repeatTodo.id) != null) ...[
              const SizedBox(height: 4),
              RepeatTodoAIStatus(
                repeatTodoId: repeatTodo.id,
                isProcessing: todoProvider.isRepeatTodoProcessingAI(
                  repeatTodo.id,
                ),
                isLoading: todoProvider.isRepeatTodoAILoading(repeatTodo.id),
                status: todoProvider.getRepeatTodoAIStatus(repeatTodo.id),
              ),
            ],
            if (!repeatTodo.isActive) ...[
              const SizedBox(height: 2),
              Text(
                l10n.pause,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (repeatTodo.endDate != null) ...[
              const SizedBox(height: 2),
              Text(
                'Until ${repeatTodo.endDate!.toLocal().toString().split(' ')[0]}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) =>
              _handleMenuAction(value, repeatTodo, todoProvider, l10n),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    repeatTodo.isActive ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    repeatTodo.isActive ? l10n.pauseRepeat : l10n.resumeRepeat,
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.editRepeat),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    l10n.deleteRepeat,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRepeatDescription(
    RepeatTodoModel repeatTodo,
    AppLocalizations l10n,
  ) {
    switch (repeatTodo.repeatType) {
      case RepeatType.daily:
        return l10n.everyDay;
      case RepeatType.weekly:
        if (repeatTodo.weekDays != null && repeatTodo.weekDays!.isNotEmpty) {
          final days = repeatTodo.weekDays!
              .map((day) => _getWeekdayName(day, l10n))
              .join(', ');
          return '${l10n.everyWeek} ($days)';
        }
        return l10n.everyWeek;
      case RepeatType.monthly:
        if (repeatTodo.dayOfMonth != null) {
          return '${l10n.everyMonth} (${repeatTodo.dayOfMonth}${l10n.selectDate})';
        }
        return l10n.everyMonth;
      case RepeatType.weekdays:
        return l10n.weekdays;
    }
  }

  String _getWeekdayName(int day, AppLocalizations l10n) {
    switch (day) {
      case 1:
        return l10n.monday;
      case 2:
        return l10n.tuesday;
      case 3:
        return l10n.wednesday;
      case 4:
        return l10n.thursday;
      case 5:
        return l10n.friday;
      case 6:
        return l10n.saturday;
      case 7:
        return l10n.sunday;
      default:
        return '';
    }
  }

  void _handleMenuAction(
    String action,
    RepeatTodoModel repeatTodo,
    TodoProvider todoProvider,
    AppLocalizations l10n,
  ) {
    switch (action) {
      case 'toggle':
        todoProvider.toggleRepeatTodoActive(repeatTodo.id);
        break;
      case 'edit':
        _showEditRepeatTodoDialog(repeatTodo, todoProvider);
        break;
      case 'delete':
        _showDeleteConfirmDialog(repeatTodo, todoProvider, l10n);
        break;
    }
  }

  void _showAddRepeatTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => RepeatTodoDialog(
        onAdd: (repeatTodo) async {
          final todoProvider = Provider.of<TodoProvider>(
            context,
            listen: false,
          );
          await todoProvider.addRepeatTodo(repeatTodo);
        },
      ),
    );
  }

  void _showEditRepeatTodoDialog(
    RepeatTodoModel repeatTodo,
    TodoProvider todoProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => RepeatTodoDialog(
        repeatTodo: repeatTodo,
        onAdd: (updatedRepeatTodo) async {
          await todoProvider.updateRepeatTodo(updatedRepeatTodo);
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(
    RepeatTodoModel repeatTodo,
    TodoProvider todoProvider,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.repeatTaskConfirm),
        content: Text(l10n.repeatTaskDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await todoProvider.deleteRepeatTodo(repeatTodo.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteRepeat),
          ),
        ],
      ),
    );
  }
}
