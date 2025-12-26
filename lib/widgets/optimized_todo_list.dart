import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/widgets/todo_card.dart';
import 'package:easy_todo/widgets/skeleton_loading.dart';

class OptimizedTodoList extends StatefulWidget {
  final List<TodoModel> todos;
  final ScrollController? scrollController;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Function(TodoModel) onToggle;
  final Function(TodoModel) onDelete;
  final Function(TodoModel) onEditReminder;
  final Function(TodoModel) onTap;

  const OptimizedTodoList({
    super.key,
    required this.todos,
    this.scrollController,
    this.isLoading = false,
    this.hasMore = false,
    required this.onLoadMore,
    required this.onToggle,
    required this.onDelete,
    required this.onEditReminder,
    required this.onTap,
  });

  @override
  State<OptimizedTodoList> createState() => _OptimizedTodoListState();
}

class _OptimizedTodoListState extends State<OptimizedTodoList>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  static const int _itemsPerPage = 20;
  int _currentlyDisplayed = _itemsPerPage;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _scrollController.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Load more when 200px from bottom

    if (maxScroll - currentScroll <= delta &&
        !widget.isLoading &&
        widget.hasMore) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.todos.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (widget.todos.isEmpty) {
      return _buildEmptyState();
    }

    final displayTodos = widget.todos.take(_currentlyDisplayed).toList();

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                final metrics = notification.metrics;
                if (metrics.maxScrollExtent - metrics.pixels < 200) {
                  setState(() {
                    _currentlyDisplayed = (_currentlyDisplayed + _itemsPerPage)
                        .clamp(0, widget.todos.length);
                  });
                }
              }
              return false;
            },
            child: AnimationLimiter(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: displayTodos.length + (widget.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < displayTodos.length) {
                    final todo = displayTodos[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 80.0,
                        curve: Curves.elasticOut,
                        child: FadeInAnimation(
                          curve: Curves.easeOutCubic,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _animationController..forward(),
                                curve: Curves.elasticOut,
                              ),
                            ),
                            child: TodoCard(
                              todo: todo,
                              onTap: () => widget.onTap(todo),
                              onToggle: () => widget.onToggle(todo),
                              onDelete: () => widget.onDelete(todo),
                              onEditReminder: () => widget.onEditReminder(todo),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else if (widget.hasMore) {
                    return _buildLoadingIndicator();
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const TodoCardSkeleton(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noTodosYet,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addTodoHint,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
