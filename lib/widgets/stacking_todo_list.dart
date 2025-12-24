import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/widgets/stacking_todo_card.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';

class StackingTodoList extends StatefulWidget {
  final List<TodoModel> todos;
  final Function(TodoModel) onToggle;
  final Function(TodoModel) onDelete;
  final Function(TodoModel)? onStartPomodoro;
  final Function(TodoModel)? onEditReminder;
  final Function(TodoModel)? onTap;
  final bool isProcessingCategories;
  final bool isProcessingPriorities;

  const StackingTodoList({
    super.key,
    required this.todos,
    required this.onToggle,
    required this.onDelete,
    this.onStartPomodoro,
    this.onEditReminder,
    this.onTap,
    this.isProcessingCategories = false,
    this.isProcessingPriorities = false,
  });

  @override
  State<StackingTodoList> createState() => _StackingTodoListState();
}

class _StackingTodoListState extends State<StackingTodoList> {
  int _currentIndex = 0;

  void _nextCard() {
    if (widget.todos.isEmpty) return;
    if (_currentIndex < widget.todos.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousCard() {
    if (widget.todos.isEmpty) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _validateIndex() {
    if (widget.todos.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= widget.todos.length) {
      _currentIndex = widget.todos.length - 1;
    }
  }

  @override
  void didUpdateWidget(StackingTodoList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateIndex();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.todos.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Main card stack
        Expanded(
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // Swipe down - go to previous card
                _previousCard();
              } else if (details.primaryVelocity! < 0) {
                // Swipe up - go to next card
                _nextCard();
              }
            },
            child: Stack(
              children: [
                // Background cards (stacked behind)
                ...List.generate(widget.todos.length, (index) {
                  if (index == _currentIndex) {
                    return const SizedBox(); // Skip current card
                  }

                  final distance = (index - _currentIndex).abs();
                  if (distance > 2) {
                    return const SizedBox(); // Only show cards within 2 positions
                  }

                  final isBefore = index < _currentIndex;
                  final stackOffset = distance * 25.0;
                  final stackScale = 1.0 - distance * 0.08;
                  final opacity = 0.4;

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: isBefore ? -stackOffset : null,
                    bottom: isBefore ? null : stackOffset,
                    left: 16.0 * distance,
                    right: 16.0 * distance,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: opacity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        transform:
                            Matrix4.translationValues(
                                0,
                                isBefore ? -distance * 4 : distance * 4,
                                0,
                              )
                              ..scale(stackScale.clamp(0.75, 1.0))
                              ..rotateZ((isBefore ? 0.02 : -0.02) * distance),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 4.0,
                            sigmaY: 4.0,
                          ),
                          child: StackingTodoCard(
                            key: ValueKey('todo_${widget.todos[index].id}_${widget.todos[index].createdAt.millisecondsSinceEpoch}_bg'),
                            todo: widget.todos[index],
                            currentIndex: index + 1,
                            totalCount: widget.todos.length,
                            onTap: () {
                              setState(() {
                                _currentIndex = index;
                              });
                              widget.onTap?.call(widget.todos[index]);
                            },
                            onToggle: () =>
                                widget.onToggle(widget.todos[index]),
                            onDelete: () =>
                                widget.onDelete(widget.todos[index]),
                            onStartPomodoro: widget.onStartPomodoro != null
                                ? () => widget.onStartPomodoro!(
                                    widget.todos[index],
                                  )
                                : null,
                            onEditReminder: widget.onEditReminder != null
                                ? () => widget.onEditReminder!(
                                    widget.todos[index],
                                  )
                                : null,
                            isActive: false,
                            showCategoryLoading: widget.isProcessingCategories && (widget.todos[index].aiCategory == null || !widget.todos[index].aiProcessed),
                            showPriorityLoading: widget.isProcessingPriorities && (widget.todos[index].aiPriority == 0 || !widget.todos[index].aiProcessed),
                          ),
                        ),
                      ),
                    ),
                  );
                }).where((widget) => widget is! SizedBox),

                // Current active card (on top)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: StackingTodoCard(
                      key: ValueKey('todo_${widget.todos[_currentIndex].id}_${widget.todos[_currentIndex].createdAt.millisecondsSinceEpoch}'),
                      todo: widget.todos[_currentIndex],
                      currentIndex: _currentIndex + 1,
                      totalCount: widget.todos.length,
                      onTap: () =>
                          widget.onTap?.call(widget.todos[_currentIndex]),
                      onToggle: () =>
                          widget.onToggle(widget.todos[_currentIndex]),
                      onDelete: () =>
                          widget.onDelete(widget.todos[_currentIndex]),
                      onStartPomodoro: widget.onStartPomodoro != null
                          ? () => widget.onStartPomodoro!(
                              widget.todos[_currentIndex],
                            )
                          : null,
                      onEditReminder: widget.onEditReminder != null
                          ? () => widget.onEditReminder!(
                              widget.todos[_currentIndex],
                            )
                          : null,
                      isActive: true,
                      showCategoryLoading: widget.isProcessingCategories && (widget.todos[_currentIndex].aiCategory == null || !widget.todos[_currentIndex].aiProcessed),
                      showPriorityLoading: widget.isProcessingPriorities && (widget.todos[_currentIndex].aiPriority == 0 || !widget.todos[_currentIndex].aiProcessed),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noTodosYet,
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
}
