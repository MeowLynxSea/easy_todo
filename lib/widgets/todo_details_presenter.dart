import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/utils/responsive.dart';
import 'package:easy_todo/widgets/todo_attachments_section.dart';
import 'package:flutter/material.dart';

Future<void> showTodoDetails(BuildContext context, TodoModel todo) async {
  final useDialog = _shouldUseDialog(context);
  if (useDialog) {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(todo.title),
        content: SizedBox(
          width: 560,
          height: 560,
          child: TodoDetailsPanel(todo: todo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) => TodoDetailsPanel(
        todo: todo,
        scrollController: scrollController,
        showTitle: true,
      ),
    ),
  );
}

bool _shouldUseDialog(BuildContext context) {
  return isWebDesktop(context);
}

class TodoDetailsPanel extends StatelessWidget {
  final TodoModel todo;
  final ScrollController? scrollController;
  final bool showTitle;

  const TodoDetailsPanel({
    super.key,
    required this.todo,
    this.scrollController,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final backgroundColor =
        theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface;

    return Material(
      color: backgroundColor,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          if (showTitle) ...[
            Text(
              todo.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (todo.description != null && todo.description!.isNotEmpty) ...[
            Text(todo.description!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          _InfoRow(
            label: l10n.createdLabel,
            value: _formatDate(todo.createdAt),
          ),
          if (todo.completedAt != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: l10n.completedLabel,
              value: _formatDate(todo.completedAt!),
            ),
          ],
          if (todo.timeSpent != null && todo.timeSpent! > 0) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: '${l10n.timeSpent}: ',
              value: todo.formattedTimeSpent,
            ),
          ],
          const SizedBox(height: 12),
          _StatusPill(isCompleted: todo.isCompleted),
          const SizedBox(height: 16),
          TodoAttachmentsSection(todoId: todo.id),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        Expanded(child: Text(value, style: valueStyle)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isCompleted;

  const _StatusPill({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = isCompleted
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isCompleted ? l10n.complete : l10n.incomplete,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
