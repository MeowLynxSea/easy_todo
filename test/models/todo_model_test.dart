import 'package:easy_todo/models/todo_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoModel.copyWith', () {
    test('clears startTime/endTime when set to null', () {
      final todo = TodoModel(
        id: 't1',
        title: 'todo',
        createdAt: DateTime(2025, 1, 1),
        startTime: DateTime(2025, 1, 1, 9),
        endTime: DateTime(2025, 1, 1, 10),
      );

      final updated = todo.copyWith(startTime: null, endTime: null);

      expect(updated.startTime, isNull);
      expect(updated.endTime, isNull);
    });

    test('keeps startTime/endTime when omitted', () {
      final start = DateTime(2025, 1, 1, 9);
      final end = DateTime(2025, 1, 1, 10);
      final todo = TodoModel(
        id: 't1',
        title: 'todo',
        createdAt: DateTime(2025, 1, 1),
        startTime: start,
        endTime: end,
      );

      final updated = todo.copyWith(title: 'updated');

      expect(updated.startTime, start);
      expect(updated.endTime, end);
    });

    test('clears description when set to null', () {
      final todo = TodoModel(
        id: 't1',
        title: 'todo',
        description: 'desc',
        createdAt: DateTime(2025, 1, 1),
      );

      final updated = todo.copyWith(description: null);

      expect(updated.description, isNull);
    });

    test('clears reminderTime when set to null', () {
      final todo = TodoModel(
        id: 't1',
        title: 'todo',
        createdAt: DateTime(2025, 1, 1),
        reminderEnabled: true,
        reminderTime: DateTime(2025, 1, 1, 9),
      );

      final updated = todo.copyWith(reminderTime: null, reminderEnabled: false);

      expect(updated.reminderEnabled, isFalse);
      expect(updated.reminderTime, isNull);
    });
  });
}
