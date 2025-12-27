import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/utils/date_utils.dart';

DateTime normalizeDay(DateTime dateTime) => localDay(dateTime);

/// Heuristic: a repeat-generated todo is considered "backfilled" when the day
/// encoded in its `id` (creation timestamp) differs from its `createdAt` day.
///
/// - Normal generation: `id` time and `createdAt` are on the same day.
/// - Backfill generation: `createdAt` is set to a past day, while `id` is "now".
bool isLikelyBackfilledRepeatTodoInstance({
  required String todoId,
  required DateTime todoCreatedAt,
}) {
  final millisString = todoId.split('_').first;
  final millis = int.tryParse(millisString);
  if (millis == null) return false;

  final createdAtById = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
  return !normalizeDay(
    createdAtById,
  ).isAtSameMomentAs(normalizeDay(todoCreatedAt));
}

/// If the user chooses to use the backfill window as the baseline, align the
/// repeat todo's `startDate` to that backfill baseline to keep future checks and
/// pruning consistent.
DateTime? computeAlignedStartDateForBackfillChoice({
  required RepeatTodoModel repeatTodo,
  required DateTime now,
  required BackfillStartBasis startBasis,
}) {
  if (startBasis != BackfillStartBasis.backfillDays) return null;
  if (!repeatTodo.backfillEnabled || repeatTodo.backfillDays < 1) return null;
  if (repeatTodo.startDate == null) return null;

  final backfillStart = normalizeDay(
    now,
  ).subtract(Duration(days: repeatTodo.backfillDays));
  final normalizedStartDate = normalizeDay(repeatTodo.startDate!);

  if (!normalizedStartDate.isAfter(backfillStart)) return null;
  return backfillStart;
}

/// Compute the valid backfill window (date-only) for a repeat todo.
///
/// The window is capped at `yesterday` because backfill never generates for today.
/// When `startBasis` is `backfillDays`, startDate is ignored only for the purpose
/// of choosing the earliest backfillable date (same behavior as force refresh).
({DateTime? start, DateTime end}) computeBackfillWindow({
  required RepeatTodoModel repeatTodo,
  required DateTime now,
  BackfillStartBasis startBasis = BackfillStartBasis.startDate,
}) {
  final today = normalizeDay(now);
  final yesterday = today.subtract(const Duration(days: 1));

  var end = yesterday;
  if (repeatTodo.endDate != null) {
    final normalizedEndDate = normalizeDay(repeatTodo.endDate!);
    if (normalizedEndDate.isBefore(end)) {
      end = normalizedEndDate;
    }
  }

  DateTime? start = repeatTodo.startDate != null
      ? normalizeDay(repeatTodo.startDate!)
      : null;

  if (repeatTodo.backfillEnabled && repeatTodo.backfillDays > 0) {
    final earliestBySetting = today.subtract(
      Duration(days: repeatTodo.backfillDays),
    );

    if (startBasis == BackfillStartBasis.backfillDays) {
      start = earliestBySetting;
    } else {
      start = start == null || earliestBySetting.isAfter(start)
          ? earliestBySetting
          : start;
    }
  }

  return (start: start, end: end);
}
