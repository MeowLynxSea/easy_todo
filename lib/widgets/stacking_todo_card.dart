import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/widgets/ai_loading_indicator.dart';

class StackingTodoCard extends StatefulWidget {
  final TodoModel todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onStartPomodoro;
  final VoidCallback? onEditReminder;
  final bool isActive;
  final int currentIndex;
  final int totalCount;
  final bool showCategoryLoading;
  final bool showPriorityLoading;

  const StackingTodoCard({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.onStartPomodoro,
    this.onEditReminder,
    this.isActive = false,
    this.currentIndex = 1,
    this.showCategoryLoading = false,
    this.showPriorityLoading = false,
    this.totalCount = 1,
  });

  @override
  State<StackingTodoCard> createState() => _StackingTodoCardState();
}

class _StackingTodoCardState extends State<StackingTodoCard> {
  final _valueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isBeingDeleted = false;
  RepeatTodoModel? _repeatTodo;

  @override
  void initState() {
    super.initState();
    _loadRepeatTodo();
    if (widget.todo.dataValue != null) {
      _valueController.text = widget.todo.dataValue.toString();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadRepeatTodo() async {
    if (!widget.todo.isGeneratedFromRepeat) return;

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final repeatTodo = todoProvider.repeatTodos.firstWhere(
      (rt) => rt.id == widget.todo.repeatTodoId,
      orElse: () => RepeatTodoModel.create(title: '', repeatType: RepeatType.daily),
    );

    if (mounted) {
      setState(() {
        _repeatTodo = repeatTodo;
      });
    }
  }

  bool get _needsDataInput {
    return widget.todo.isGeneratedFromRepeat &&
           _repeatTodo?.dataStatisticsEnabled == true &&
           !widget.todo.isCompleted;
  }

  
  Future<void> _handleSubmitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final value = double.parse(_valueController.text.trim());
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      await todoProvider.completeTodoWithData(widget.todo.id, value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.taskCompleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidNumberFormat),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmitWithoutData() async {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    await todoProvider.toggleTodoCompletion(widget.todo.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.taskCompleted),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleWithdraw() async {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    await todoProvider.toggleTodoCompletion(widget.todo.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.taskWithdrawn),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    // 如果是从重复任务生成的待办事项，显示特殊的提示信息
    if (widget.todo.isGeneratedFromRepeat) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.delete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteTodoConfirmation),
              const SizedBox(height: 8),
              Text(
                l10n.repeatTaskWarning,
                style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
      return confirmed ?? false;
    }

    // 普通待办事项的删除确认
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteTodoConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    // Check if todo still exists, if not return empty widget
    final todoExists = todoProvider.todos.any((t) => t.id == widget.todo.id);
    if (!todoExists) {
      return const SizedBox.shrink(); // Todo has been deleted
    }

    return Opacity(
      opacity: widget.isActive ? 1.0 : 0.7,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        elevation: widget.isActive ? 8 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.9)
                    : Theme.of(context).colorScheme.surface,
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.8)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
            ),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main content area
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with fraction indicator
                    Row(
                      children: [
                        if (widget.todo.isGeneratedFromRepeat) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.repeat,
                            size: 16,
                            color: widget.todo.isCompleted
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                        ] else ...[
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            widget.todo.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              decoration: widget.todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: widget.todo.isCompleted
                                  ? Colors.grey
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Fraction indicator
                        if (widget.totalCount > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.2)
                                  : Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.progressFormat(widget.currentIndex, widget.totalCount),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Data input section for tasks that require data
                    if (_needsDataInput) ...[
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _valueController,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.dataValue,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.dataValueRequired;
                            }
                            final number = double.tryParse(value.trim());
                            if (number == null) {
                              return AppLocalizations.of(context)!.invalidNumberFormat;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Description, data value, and AI info
                    if (widget.todo.description != null &&
                        widget.todo.description!.isNotEmpty ||
                        widget.todo.dataValue != null ||
                        _shouldShowAITags(context))
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.todo.description != null &&
                                widget.todo.description!.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight:
                                      72, // Maximum height for description area (approx 3-4 lines)
                                ),
                                child: Text(
                                  widget.todo.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.todo.isCompleted
                                        ? Colors.grey
                                        : Theme.of(context).colorScheme.onSurface
                                              .withValues(alpha: 0.7),
                                    decoration: widget.todo.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (widget.todo.dataValue != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    size: 14,
                                    color: widget.todo.isCompleted
                                        ? Colors.grey
                                        : Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.todo.dataValue}${widget.todo.dataUnit != null ? ' ${widget.todo.dataUnit}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.todo.isCompleted
                                          ? Colors.grey
                                          : Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // AI information
                            if (_shouldShowAITags(context)) ...[
                              const SizedBox(height: 4),
                              _buildAITags(context, widget.todo),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Time info
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.todo.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${widget.todo.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (widget.todo.reminderEnabled &&
                              widget.todo.reminderTime != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.alarm_outlined,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.todo.reminderTime!.hour.toString().padLeft(2, '0')}:${widget.todo.reminderTime!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons for all tasks
              Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2)
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pomodoro button (only for incomplete tasks)
                      if (!widget.todo.isCompleted && widget.onStartPomodoro != null)
                        _buildActionButton(
                          icon: Icons.timer,
                          color: AppTheme.primaryColor,
                          onPressed: widget.onStartPomodoro!,
                          tooltip: l10n.pomodoroTimer,
                        ),

                      // Reminder button
                      if (widget.onEditReminder != null)
                        _buildActionButton(
                          icon: widget.todo.reminderEnabled
                              ? Icons.alarm_off
                              : Icons.alarm,
                          color: widget.todo.reminderEnabled
                              ? Colors.orange
                              : AppTheme.primaryColor,
                          onPressed: widget.onEditReminder!,
                          tooltip: widget.todo.reminderEnabled
                              ? l10n.cancelReminder
                              : l10n.setReminder,
                        ),

                      // Submit/Withdraw button
                      _buildActionButton(
                        icon: widget.todo.isCompleted ? Icons.undo : Icons.check,
                        color: widget.todo.isCompleted ? Colors.orange : Colors.green,
                        onPressed: widget.todo.isCompleted
                            ? _handleWithdraw
                            : _needsDataInput ? _handleSubmitData : _handleSubmitWithoutData,
                        tooltip: widget.todo.isCompleted ? l10n.taskWithdrawn : l10n.taskCompleted,
                      ),

                      // Delete button
                      widget.todo.isGeneratedFromRepeat
                          ? _buildActionButton(
                              icon: Icons.delete,
                              color: Colors.grey,
                              onPressed: () {},
                              tooltip: l10n.cannotDeleteRepeatTodo,
                            )
                          : _buildActionButton(
                              icon: Icons.delete,
                              color: Colors.red,
                              onPressed: () {
                                _showDeleteConfirmation(context).then((
                                  confirmed,
                                ) {
                                  if (confirmed) {
                                    // Mark as being deleted to prevent further AI processing
                                    _isBeingDeleted = true;
                                    widget.onDelete();
                                  }
                                });
                              },
                              tooltip: l10n.delete,
                            ),
                    ],
                  ),
                ),

              ],
          ),
        ),
      ),
    );
  }

  // Check if AI tags should be shown based on settings
  bool _shouldShowAITags(BuildContext context) {
    // If this widget is being deleted, don't trigger any AI processing
    if (_isBeingDeleted) return false;

    final aiProvider = Provider.of<AIProvider?>(context, listen: false);
    if (aiProvider == null) return false;

    final settings = aiProvider.settings;
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    // Check if todo still exists in the provider's list
    final todoExists = todoProvider.todos.any((t) => t.id == widget.todo.id);
    if (!todoExists) {
      return false; // Todo has been deleted, don't show AI tags or trigger processing
    }

    // ALWAYS get the latest todo from provider to ensure we have the most up-to-date AI data
    final latestTodo = todoProvider.todos.firstWhere((t) => t.id == widget.todo.id);

    bool shouldShowCategory = settings.enableAutoCategorization;
    bool shouldShowPriority = settings.enablePrioritySorting;

    // If AI features are enabled but data is missing, trigger background generation
    if (settings.enableAIFeatures && !latestTodo.isCompleted) {
      bool needsCategoryGeneration = settings.enableAutoCategorization && latestTodo.aiCategory == null;
      bool needsPriorityGeneration = settings.enablePrioritySorting && latestTodo.aiPriority == 0;

      if (needsCategoryGeneration || needsPriorityGeneration) {
        // Only trigger if todo was created more than 2 seconds ago to avoid spam during creation
        final now = DateTime.now();
        final timeSinceCreation = now.difference(latestTodo.createdAt);
        if (timeSinceCreation.inMilliseconds > 2000) {
          // Trigger background generation only if we haven't tried recently
          todoProvider.processMissingAIDataForTodo(latestTodo);
        }
      }
    }

    // Return whether to show tags based on available data or loading state
    bool shouldShowCategoryWithData = shouldShowCategory && (latestTodo.aiCategory != null || widget.showCategoryLoading);
    bool shouldShowPriorityWithData = shouldShowPriority && (latestTodo.aiPriority > 0 || widget.showPriorityLoading);

    return shouldShowCategoryWithData || shouldShowPriorityWithData;
  }

  Widget _buildAITags(BuildContext context, TodoModel todo) {
    final aiProvider = Provider.of<AIProvider?>(context, listen: false);
    if (aiProvider == null) return const SizedBox();
    final l10n = AppLocalizations.of(context)!;

    final settings = aiProvider.settings;
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    // ALWAYS get the latest todo from provider to ensure we have the most up-to-date AI data
    final latestTodo = todoProvider.todos.firstWhere((t) => t.id == todo.id, orElse: () => todo);

    bool shouldShowCategory = settings.enableAutoCategorization;
    bool shouldShowPriority = settings.enablePrioritySorting;

    // Check if this is a repeat-generated todo and its template is being processed
    bool isRepeatTodoProcessing = todo.isGeneratedFromRepeat &&
        todo.repeatTodoId != null &&
        todoProvider.isRepeatTodoProcessingAI(todo.repeatTodoId!);

    // Check if we need to show loading states
    bool needsCategoryLoading = (shouldShowCategory && latestTodo.aiCategory == null && !latestTodo.isCompleted) ||
                               (isRepeatTodoProcessing && shouldShowCategory);
    bool needsPriorityLoading = (shouldShowPriority && latestTodo.aiPriority == 0 && !latestTodo.isCompleted) ||
                               (isRepeatTodoProcessing && shouldShowPriority);

    // Check what we should actually display
    bool shouldShowCategoryWithData = shouldShowCategory && latestTodo.aiCategory != null;
    bool shouldShowPriorityWithData = shouldShowPriority && latestTodo.aiPriority > 0;

    // If nothing to show (no data and no loading needed), return empty
    if (!shouldShowCategoryWithData && !shouldShowPriorityWithData &&
        !needsCategoryLoading && !needsPriorityLoading) {
      return const SizedBox();
    }

    // Map English AI categories to localized strings
    String getLocalizedCategory(String? englishCategory) {
      if (englishCategory == null) return '';

      switch (englishCategory.toLowerCase()) {
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
          return englishCategory; // Fallback to original if no mapping found
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show AI processing status for repeat-generated todos
        if (isRepeatTodoProcessing && todo.repeatTodoId != null) ...[
          RepeatTodoAIStatus(
            repeatTodoId: todo.repeatTodoId!,
            isProcessing: todoProvider.isRepeatTodoProcessingAI(todo.repeatTodoId!),
            isLoading: todoProvider.isRepeatTodoAILoading(todo.repeatTodoId!),
            status: todoProvider.getRepeatTodoAIStatus(todo.repeatTodoId!),
          ),
          const SizedBox(height: 4),
        ],
        // AI tags
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            // Category tag or loading
        if (shouldShowCategory)
          if (shouldShowCategoryWithData && latestTodo.aiCategory != null)
            _buildAIChip(
              label: getLocalizedCategory(latestTodo.aiCategory),
              color: latestTodo.isCompleted ? Colors.grey : Theme.of(context).colorScheme.primary,
              icon: Icons.category_outlined,
            )
          else if (needsCategoryLoading)
            _buildLoadingChip(
              label: l10n.autoCategorization,
              color: latestTodo.isCompleted ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),

        // Priority tag or loading
        if (shouldShowPriority)
          if (shouldShowPriorityWithData && latestTodo.aiPriority > 0)
            _buildAIChip(
              label: '${latestTodo.aiPriority}',
              color: latestTodo.isCompleted ? Colors.grey : _getPriorityTagColor(latestTodo.aiPriority),
              icon: Icons.star_outline,
            )
          else if (needsPriorityLoading)
            _buildLoadingChip(
              label: l10n.prioritySorting,
              color: latestTodo.isCompleted ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
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
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.7)),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
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

  Color _getPriorityTagColor(int priority) {
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}