import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/utils/repeat_backfill_utils.dart';
import 'package:flutter_test/flutter_test.dart';

RepeatTodoModel _repeat({
  DateTime? startDate,
  DateTime? endDate,
  bool backfillEnabled = false,
  int backfillDays = 7,
}) {
  return RepeatTodoModel(
    id: 'rt_1',
    title: 't',
    repeatType: RepeatType.daily,
    startDate: startDate,
    endDate: endDate,
    createdAt: DateTime(2025, 1, 1),
    backfillEnabled: backfillEnabled,
    backfillDays: backfillDays,
  );
}

void main() {
  group('repeat_backfill_utils', () {
    test('isLikelyBackfilledRepeatTodoInstance: false when same day', () {
      final createdAt = DateTime(2025, 1, 10, 8, 0);
      final todoId = '${createdAt.millisecondsSinceEpoch}_123';

      expect(
        isLikelyBackfilledRepeatTodoInstance(
          todoId: todoId,
          todoCreatedAt: createdAt,
        ),
        isFalse,
      );
    });

    test('isLikelyBackfilledRepeatTodoInstance: true when day differs', () {
      final createdAtById = DateTime(2025, 1, 10, 8, 0);
      final createdAt = DateTime(2025, 1, 9, 8, 0);
      final todoId = '${createdAtById.millisecondsSinceEpoch}_123';

      expect(
        isLikelyBackfilledRepeatTodoInstance(
          todoId: todoId,
          todoCreatedAt: createdAt,
        ),
        isTrue,
      );
    });

    test('computeBackfillWindow: respects startDate and backfillDays', () {
      final repeatTodo = _repeat(
        startDate: DateTime(2025, 1, 5),
        backfillEnabled: true,
        backfillDays: 7,
      );

      final window = computeBackfillWindow(
        repeatTodo: repeatTodo,
        now: DateTime(2025, 1, 10, 12),
      );

      expect(window.start, DateTime(2025, 1, 5));
      expect(window.end, DateTime(2025, 1, 9));
    });

    test(
      'computeBackfillWindow: can ignore startDate under backfillDays basis',
      () {
        final repeatTodo = _repeat(
          startDate: DateTime(2025, 1, 5),
          backfillEnabled: true,
          backfillDays: 7,
        );

        final window = computeBackfillWindow(
          repeatTodo: repeatTodo,
          now: DateTime(2025, 1, 10, 12),
          startBasis: BackfillStartBasis.backfillDays,
        );

        expect(window.start, DateTime(2025, 1, 3));
        expect(window.end, DateTime(2025, 1, 9));
      },
    );

    test('computeBackfillWindow: end is min(yesterday, endDate)', () {
      final repeatTodo = _repeat(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 8),
        backfillEnabled: true,
        backfillDays: 30,
      );

      final window = computeBackfillWindow(
        repeatTodo: repeatTodo,
        now: DateTime(2025, 1, 10, 12),
      );

      expect(window.start, DateTime(2025, 1, 1));
      expect(window.end, DateTime(2025, 1, 8));
    });

    test(
      'computeBackfillWindow: backfill disabled keeps startDate bound only',
      () {
        final repeatTodo = _repeat(
          startDate: DateTime(2025, 1, 5),
          backfillEnabled: false,
          backfillDays: 7,
        );

        final window = computeBackfillWindow(
          repeatTodo: repeatTodo,
          now: DateTime(2025, 1, 10, 12),
        );

        expect(window.start, DateTime(2025, 1, 5));
        expect(window.end, DateTime(2025, 1, 9));
      },
    );
  });
}
