import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/widgets/todo_details_presenter.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class DayDetailScreen extends StatelessWidget {
  final DateTime date;
  final List<TodoModel> todos;

  const DayDetailScreen({super.key, required this.date, required this.todos});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.dayDetails}: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
        centerTitle: true,
      ),
      body: WebDesktopContent(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildStatsSummary(l10n),
            const Divider(height: 1),
            Expanded(child: _buildTodosList(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(AppLocalizations? l10n) {
    final completedCount = todos.where((todo) => todo.isCompleted).length;
    final totalCount = todos.length;
    final completionRate = totalCount > 0
        ? (completedCount / totalCount * 100).toStringAsFixed(1)
        : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: l10n?.totalCount ?? 'Total',
                  value: totalCount.toString(),
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: l10n?.completedCount ?? 'Completed',
                  value: completedCount.toString(),
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: l10n?.completionRate ?? 'Rate',
                  value: '$completionRate%',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodosList(AppLocalizations? l10n) {
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_outlined, size: 64, color: Colors.grey[400]),
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

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildDayTodoCard(context, todo, l10n),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayTodoCard(
    BuildContext context,
    TodoModel todo,
    AppLocalizations? l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
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
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${todo.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${todo.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (todo.completedAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${todo.completedAt!.toLocal().hour.toString().padLeft(2, '0')}:${todo.completedAt!.toLocal().minute.toString().padLeft(2, '0')}',
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
                    '${l10n?.timeSpent ?? 'Time spent'}: ${todo.formattedTimeSpent}',
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
        onTap: () => _showTodoDetails(context, todo),
      ),
    );
  }

  void _showTodoDetails(BuildContext context, TodoModel todo) {
    unawaited(showTodoDetails(context, todo));
  }
}
