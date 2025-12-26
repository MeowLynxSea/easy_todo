import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/widgets/data_input_dialog.dart';
import 'package:easy_todo/screens/pomodoro_screen.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';

class TodoCard extends StatefulWidget {
  final TodoModel todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEditReminder;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.onEditReminder,
  });

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  void _handleToggle() {
    // For completed todos being uncompleted, or regular todos, just toggle
    if (widget.todo.isCompleted || !widget.todo.isGeneratedFromRepeat) {
      widget.onToggle();
      return;
    }

    // For incomplete repeat-generated todos, check if data input is required
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    // Find the repeat todo to check if data statistics is enabled
    RepeatTodoModel? repeatTodo;
    try {
      repeatTodo = todoProvider.repeatTodos.firstWhere(
        (rt) => rt.id == widget.todo.repeatTodoId,
      );
    } catch (e) {
      // Repeat todo not found, just toggle normally
      widget.onToggle();
      return;
    }

    // If data statistics is enabled, show data input dialog
    if (repeatTodo.dataStatisticsEnabled) {
      showDialog(
        context: context,
        builder: (context) => DataInputDialog(
          todo: widget.todo,
          repeatTodo: repeatTodo!,
          onSubmit: (double value) async {
            await todoProvider.completeTodoWithData(widget.todo.id, value);
          },
        ),
      );
    } else {
      // No data input required, just toggle normally
      widget.onToggle();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    // Check if todo still exists, if not return empty widget
    final todoExists = todoProvider.todos.any((t) => t.id == widget.todo.id);
    if (!todoExists) {
      return const SizedBox.shrink(); // Todo has been deleted
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        onTap: widget.onTap,
        leading: Checkbox(
          value: widget.todo.isCompleted,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            _handleToggle();
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Row(
          children: [
            if (widget.todo.isGeneratedFromRepeat) ...[
              Icon(
                Icons.repeat,
                size: 16,
                color: widget.todo.isCompleted
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.todo.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: widget.todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: widget.todo.isCompleted
                          ? Colors.grey
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (widget.todo.dataValue != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${widget.todo.dataValue}${widget.todo.dataUnit != null ? ' ${widget.todo.dataUnit}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.todo.isCompleted
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        subtitle:
            (widget.todo.description != null &&
                    widget.todo.description!.isNotEmpty) ||
                (widget.todo.reminderEnabled &&
                    widget.todo.reminderTime != null) ||
                _shouldShowAITags()
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.todo.description != null &&
                      widget.todo.description!.isNotEmpty)
                    Text(
                      widget.todo.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.todo.isCompleted
                            ? Colors.grey
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                        decoration: widget.todo.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  if (widget.todo.reminderEnabled &&
                      widget.todo.reminderTime != null) ...[
                    const SizedBox(height: 4),
                    _buildReminderChip(),
                  ],
                  if (_shouldShowAITags()) ...[
                    const SizedBox(height: 4),
                    _buildAITags(),
                  ],
                ],
              )
            : null, // Don't show subtitle if nothing to display
        trailing: _buildTrailing(),
      ),
    );
  }

  bool _shouldShowAITags() {
    final aiProvider = Provider.of<AIProvider?>(context, listen: false);
    if (aiProvider == null) return false;

    final settings = aiProvider.settings;
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    // Check if todo still exists
    final todoExists = todoProvider.todos.any((t) => t.id == widget.todo.id);
    if (!todoExists) return false;

    // Check if AI features are enabled
    if (!settings.enableAIFeatures) return false;

    // Check if any AI features are enabled
    if (!settings.enableAutoCategorization && !settings.enablePrioritySorting) {
      return false;
    }

    // Get the latest todo data
    final latestTodo = todoProvider.todos.firstWhere(
      (t) => t.id == widget.todo.id,
    );

    // Don't show for completed todos - they should retain their existing AI data
    if (latestTodo.isCompleted) {
      // Even for completed todos, show AI tags if they have valid data
      bool hasCategoryData =
          settings.enableAutoCategorization && latestTodo.aiCategory != null;
      bool hasPriorityData =
          settings.enablePrioritySorting && latestTodo.aiPriority > 0;
      return hasCategoryData || hasPriorityData;
    }

    // Show if data exists or if it's being generated
    bool hasCategoryData =
        settings.enableAutoCategorization && latestTodo.aiCategory != null;
    bool hasPriorityData =
        settings.enablePrioritySorting && latestTodo.aiPriority > 0;
    bool needsGeneration =
        (settings.enableAutoCategorization && latestTodo.aiCategory == null) ||
        (settings.enablePrioritySorting && latestTodo.aiPriority == 0);

    return hasCategoryData || hasPriorityData || needsGeneration;
  }

  Widget _buildReminderChip() {
    final now = DateTime.now();
    final reminderTime = widget.todo.reminderTime!;
    final isOverdue = reminderTime.isBefore(now) && !widget.todo.isCompleted;
    final isToday =
        reminderTime.day == now.day &&
        reminderTime.month == now.month &&
        reminderTime.year == now.year;
    final isTomorrow =
        reminderTime.day == now.day + 1 &&
        reminderTime.month == now.month &&
        reminderTime.year == now.year;

    String timeText;
    final l10n = AppLocalizations.of(context)!;
    if (isToday) {
      timeText = l10n.todayTimeFormat(
        TimeOfDay.fromDateTime(reminderTime).format(context),
      );
    } else if (isTomorrow) {
      timeText = l10n.tomorrowTimeFormat(
        TimeOfDay.fromDateTime(reminderTime).format(context),
      );
    } else {
      timeText =
          '${reminderTime.day}/${reminderTime.month} ${TimeOfDay.fromDateTime(reminderTime).format(context)}';
    }

    return Row(
      children: [
        Icon(
          Icons.alarm_outlined,
          size: 14,
          color: widget.todo.isCompleted
              ? Colors.grey
              : (isOverdue
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: TextStyle(
            fontSize: 12,
            color: widget.todo.isCompleted
                ? Colors.grey
                : (isOverdue
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAITags() {
    final aiProvider = Provider.of<AIProvider?>(context, listen: false);
    if (aiProvider == null) return const SizedBox();

    final settings = aiProvider.settings;
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // Check if todo still exists in the provider's list
    final todoExists = todoProvider.todos.any((t) => t.id == widget.todo.id);
    if (!todoExists) {
      return const SizedBox(); // Todo has been deleted, don't show AI tags or trigger processing
    }

    // ALWAYS get the latest todo from provider to ensure we have the most up-to-date AI data
    final latestTodo = todoProvider.todos.firstWhere(
      (t) => t.id == widget.todo.id,
    );

    bool shouldShowCategory = settings.enableAutoCategorization;
    bool shouldShowPriority = settings.enablePrioritySorting;

    // Check if we need to show loading states
    bool needsCategoryLoading =
        settings.enableAutoCategorization && latestTodo.aiCategory == null;
    bool needsPriorityLoading =
        settings.enablePrioritySorting && latestTodo.aiPriority == 0;

    // If AI features are enabled but data is missing, trigger background generation only for active todos
    if (settings.enableAIFeatures && !latestTodo.isCompleted) {
      if (needsCategoryLoading || needsPriorityLoading) {
        // Only trigger if todo was created more than 2 seconds ago to avoid spam during creation
        final now = DateTime.now();
        final timeSinceCreation = now.difference(latestTodo.createdAt);
        if (timeSinceCreation.inMilliseconds > 2000) {
          // Trigger background generation only if we haven't tried recently
          Future.delayed(const Duration(milliseconds: 500), () {
            // Additional check to ensure widget is still in a valid state
            if (mounted) {
              // Double-check if todo still exists before processing
              final stillExists = todoProvider.todos.any(
                (t) => t.id == widget.todo.id,
              );
              if (stillExists) {
                todoProvider.processMissingAIDataForTodo(latestTodo);
              }
            }
          });
        }
      }
    }

    // Check what we should actually display
    bool shouldShowCategoryWithData =
        shouldShowCategory && latestTodo.aiCategory != null;
    bool shouldShowPriorityWithData =
        shouldShowPriority && latestTodo.aiPriority > 0;

    // If nothing to show (no data and no loading needed), return empty
    if (!shouldShowCategoryWithData &&
        !shouldShowPriorityWithData &&
        !needsCategoryLoading &&
        !needsPriorityLoading) {
      return const SizedBox();
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        // Category tag or loading
        if (shouldShowCategory)
          if (shouldShowCategoryWithData && latestTodo.aiCategory != null)
            _buildAIChip(
              label: _getLocalizedCategory(latestTodo.aiCategory!, l10n),
              color: Colors.blue,
              icon: Icons.category,
            )
          else if (needsCategoryLoading && !latestTodo.isCompleted)
            _buildLoadingChip(
              label: l10n.autoCategorization,
              color: Colors.blue,
            ),

        // Priority tag or loading
        if (shouldShowPriority)
          if (shouldShowPriorityWithData && latestTodo.aiPriority > 0)
            _buildAIChip(
              label: '${latestTodo.aiPriority}',
              color: _getPriorityColor(latestTodo.aiPriority),
              icon: Icons.star,
            )
          else if (needsPriorityLoading && !latestTodo.isCompleted)
            _buildLoadingChip(
              label: l10n.prioritySorting,
              color: Colors.orange,
            ),
      ],
    );
  }

  Widget _buildLoadingChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                color.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 80) {
      return Colors.red;
    } else if (priority >= 60) {
      return Colors.orange;
    } else if (priority >= 40) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
  }

  Widget _buildTrailing() {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'delete') {
          final confirmed = await _showDeleteConfirmation(context);
          if (confirmed) {
            widget.onDelete();
          }
        } else if (value == 'edit' && widget.onEditReminder != null) {
          widget.onEditReminder!();
        } else if (value == 'pomodoro') {
          _startPomodoro(context);
        }
      },
      itemBuilder: (context) => [
        if (!widget.todo.isCompleted && widget.onEditReminder != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.edit,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        if (!widget.todo.isCompleted) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'pomodoro',
            child: Row(
              children: [
                Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.startPomodoro,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Only show delete button for todos not generated from repeat tasks
        if (!widget.todo.isGeneratedFromRepeat) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.delete,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _startPomodoro(BuildContext context) async {
    // 只有未完成的待办事项才能启动番茄钟
    if (!widget.todo.isCompleted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PomodoroScreen(todo: widget.todo),
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTodoDialogTitle),
        content: Text(l10n.deleteTodoDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.deleteTodoDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteTodoDialogDelete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
