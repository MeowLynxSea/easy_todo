import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:flutter_test/flutter_test.dart';

RepeatTodoModel _repeat({
  required RepeatType type,
  List<int>? weekDays,
  int? dayOfMonth,
  DateTime? startDate,
  DateTime? endDate,
  bool isActive = true,
}) {
  return RepeatTodoModel(
    id: 'rt_1',
    title: 't',
    repeatType: type,
    weekDays: weekDays,
    dayOfMonth: dayOfMonth,
    startDate: startDate,
    endDate: endDate,
    createdAt: DateTime(2025, 1, 1),
    isActive: isActive,
  );
}

void main() {
  group('RepeatTodoModel.shouldGenerateForDate', () {
    test('weekly: only generates on selected weekdays', () {
      final repeatTodo = _repeat(
        type: RepeatType.weekly,
        weekDays: <int>[DateTime.monday],
        startDate: DateTime(2025, 1, 1),
      );

      expect(repeatTodo.shouldGenerateForDate(DateTime(2025, 1, 6)), isTrue);
      expect(repeatTodo.shouldGenerateForDate(DateTime(2025, 1, 7)), isFalse);
      expect(
        repeatTodo.shouldGenerateForDate(
          DateTime(2025, 1, 7),
          ignoreStartDate: true,
        ),
        isFalse,
      );
    });

    test('monthly: generates on dayOfMonth or last day fallback', () {
      final repeatTodo = _repeat(
        type: RepeatType.monthly,
        dayOfMonth: 31,
        startDate: DateTime(2020, 1, 1),
      );

      // April has 30 days, should fallback to April 30.
      expect(repeatTodo.shouldGenerateForDate(DateTime(2025, 4, 30)), isTrue);
      expect(repeatTodo.shouldGenerateForDate(DateTime(2025, 4, 29)), isFalse);

      // Leap year February fallback to Feb 29.
      expect(repeatTodo.shouldGenerateForDate(DateTime(2024, 2, 29)), isTrue);
      expect(repeatTodo.shouldGenerateForDate(DateTime(2024, 2, 28)), isFalse);
    });

    test('respects startDate/endDate bounds (date-only)', () {
      final repeatTodo = _repeat(
        type: RepeatType.daily,
        startDate: DateTime(2025, 1, 10, 23, 59),
        endDate: DateTime(2025, 1, 12, 0, 1),
      );

      expect(repeatTodo.shouldGenerateForDate(DateTime(2025, 1, 9)), isFalse);
      expect(repeatTodo.shouldGenerateForDate(DateTime(2025, 1, 10)), isTrue);
      expect(repeatTodo.shouldGenerateForDate(DateTime(2025, 1, 12)), isTrue);
      expect(repeatTodo.shouldGenerateForDate(DateTime(2025, 1, 13)), isFalse);
    });

    test('weekdays: Monday-Friday only', () {
      final repeatTodo = _repeat(
        type: RepeatType.weekdays,
        startDate: DateTime(2025, 1, 1),
      );

      expect(
        repeatTodo.shouldGenerateForDate(DateTime(2025, 1, 3)),
        isTrue,
      ); // Fri
      expect(
        repeatTodo.shouldGenerateForDate(DateTime(2025, 1, 4)),
        isFalse,
      ); // Sat
    });

    test('inactive repeat todo never generates', () {
      final repeatTodo = _repeat(
        type: RepeatType.daily,
        isActive: false,
        startDate: DateTime(2025, 1, 1),
      );

      expect(repeatTodo.shouldGenerateForDate(DateTime(2025, 1, 1)), isFalse);
    });
  });
}
