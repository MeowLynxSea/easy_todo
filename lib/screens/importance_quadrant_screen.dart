import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/widgets/todo_details_presenter.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImportanceQuadrantScreen extends StatelessWidget {
  const ImportanceQuadrantScreen({super.key});

  static int _quantileThreshold(
    List<int> values, {
    int fallback = 60,
    double quantile = 0.5,
  }) {
    final candidates = values.where((v) => v > 0).toList(growable: false);
    if (candidates.length < 6) return fallback;

    final sorted = [...candidates]..sort();
    final clampedQuantile = quantile.clamp(0.0, 1.0);
    final index = (sorted.length - 1) * clampedQuantile;
    final lower = sorted[index.floor()];
    final upper = sorted[index.ceil()];
    final interpolated =
        lower + ((upper - lower) * (index - index.floor())).round();
    return interpolated.clamp(1, 99);
  }

  static ({int urgency, int importance}) _robustThresholds(
    List<TodoModel> todos,
  ) {
    // Use only fully scored items to avoid missing (0) values collapsing the
    // distribution.
    final scored = todos
        .where((t) => t.aiPriority > 0 && t.aiImportance > 0)
        .toList(growable: false);

    if (scored.length < 8) {
      return (urgency: 60, importance: 60);
    }

    final urgencies = scored
        .map((t) => t.aiPriority)
        .toList(growable: false);
    final importances = scored
        .map((t) => t.aiImportance)
        .toList(growable: false);

    const candidateQuantiles = <double>[0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65];
    final urgencyCandidates = candidateQuantiles
        .map(
          (q) => _quantileThreshold(
            urgencies,
            fallback: 60,
            quantile: q,
          ),
        )
        .toSet()
        .toList(growable: false)
      ..sort();
    final importanceCandidates = candidateQuantiles
        .map(
          (q) => _quantileThreshold(
            importances,
            fallback: 60,
            quantile: q,
          ),
        )
        .toSet()
        .toList(growable: false)
      ..sort();

    final n = scored.length;
    final expected = n / 4.0;

    int bestMinCount = -1;
    double bestBalanceScore = double.infinity;
    int bestUrgency = 60;
    int bestImportance = 60;

    for (final u in urgencyCandidates) {
      for (final i in importanceCandidates) {
        int iu = 0;
        int inu = 0;
        int niu = 0;
        int ninu = 0;

        for (final t in scored) {
          final isImportant = t.aiImportance >= i;
          final isUrgent = t.aiPriority >= u;
          if (isImportant && isUrgent) {
            iu++;
          } else if (isImportant && !isUrgent) {
            inu++;
          } else if (!isImportant && isUrgent) {
            niu++;
          } else {
            ninu++;
          }
        }

        final minCount = [iu, inu, niu, ninu].reduce(
          (a, b) => a < b ? a : b,
        );

        // Prefer thresholds that avoid empty quadrants.
        // Tie-break using a simple balance score (sum of squared deviations).
        final balanceScore =
            (iu - expected) * (iu - expected) +
            (inu - expected) * (inu - expected) +
            (niu - expected) * (niu - expected) +
            (ninu - expected) * (ninu - expected);

        final isBetter =
            (minCount > bestMinCount) ||
            (minCount == bestMinCount && balanceScore < bestBalanceScore);
        if (!isBetter) continue;

        bestMinCount = minCount;
        bestBalanceScore = balanceScore;
        bestUrgency = u;
        bestImportance = i;
      }
    }

    // If everything is highly correlated, we may still end up with empty
    // quadrants. In that case, at least remain centered around the medians.
    if (bestMinCount <= 0) {
      return (
        urgency: _quantileThreshold(urgencies, fallback: 60, quantile: 0.5),
        importance:
            _quantileThreshold(importances, fallback: 60, quantile: 0.5),
      );
    }

    return (urgency: bestUrgency, importance: bestImportance);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importanceQuadrant), centerTitle: true),
      body: WebDesktopContent(
        padding: EdgeInsets.zero,
        child: Consumer<TodoProvider>(
          builder: (context, provider, child) {
            final todos = provider.allTodos
                .where((t) => !t.isCompleted)
                .toList(growable: false);

            final thresholds = _robustThresholds(todos);
            final urgencyThreshold = thresholds.urgency;
            final importanceThreshold = thresholds.importance;

            final importantUrgent = todos
                .where(
                  (t) =>
                      t.aiImportance >= importanceThreshold &&
                      t.aiPriority >= urgencyThreshold,
                )
                .toList();
            final importantNotUrgent = todos
                .where(
                  (t) =>
                      t.aiImportance >= importanceThreshold &&
                      t.aiPriority < urgencyThreshold,
                )
                .toList();
            final notImportantUrgent = todos
                .where(
                  (t) =>
                      t.aiImportance < importanceThreshold &&
                      t.aiPriority >= urgencyThreshold,
                )
                .toList();
            final notImportantNotUrgent = todos
                .where(
                  (t) =>
                      t.aiImportance < importanceThreshold &&
                      t.aiPriority < urgencyThreshold,
                )
                .toList();

            importantUrgent.sort(
              (a, b) => b.aiPriority.compareTo(a.aiPriority),
            );
            importantNotUrgent.sort(
              (a, b) => b.aiImportance.compareTo(a.aiImportance),
            );
            notImportantUrgent.sort(
              (a, b) => b.aiPriority.compareTo(a.aiPriority),
            );
            notImportantNotUrgent.sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
            );

            return Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final thresholdHint =
                      '${l10n.urgent}: ≥$urgencyThreshold  ·  ${l10n.importance}: ≥$importanceThreshold';
                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          thresholdHint,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _QuadrantPanel(
                                      title:
                                          '${l10n.important} · ${l10n.urgent}',
                                      color: Colors.red,
                                      todos: importantUrgent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: _QuadrantPanel(
                                      title:
                                          '${l10n.notImportant} · ${l10n.urgent}',
                                      color: Colors.blue,
                                      todos: notImportantUrgent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _QuadrantPanel(
                                      title:
                                          '${l10n.important} · ${l10n.notUrgent}',
                                      color: Colors.yellow.shade700,
                                      todos: importantNotUrgent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: _QuadrantPanel(
                                      title:
                                          '${l10n.notImportant} · ${l10n.notUrgent}',
                                      color: Colors.green,
                                      todos: notImportantNotUrgent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuadrantPanel extends StatelessWidget {
  final String title;
  final Color color;
  final List<TodoModel> todos;

  const _QuadrantPanel({
    required this.title,
    required this.color,
    required this.todos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: titleStyle)),
                Text(
                  '${todos.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (todos.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.noTodosYet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _QuadrantTodoTile(todo: todo, accent: color),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuadrantTodoTile extends StatelessWidget {
  final TodoModel todo;
  final Color accent;

  const _QuadrantTodoTile({required this.todo, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showTodoDetails(context, todo),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  todo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'I${todo.aiImportance} · U${todo.aiPriority}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Checkbox(
                value: todo.isCompleted,
                onChanged: (_) {
                  context.read<TodoProvider>().toggleTodoCompletion(todo.id);
                },
                visualDensity: VisualDensity.compact,
                activeColor: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
