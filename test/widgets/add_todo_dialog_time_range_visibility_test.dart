import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/widgets/add_todo_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

MaterialApp _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'AddTodoDialog hides start/end time editors for repeat-generated todos',
    (tester) async {
      final todo = TodoModel(
        id: 't1',
        title: 'todo',
        createdAt: DateTime(2025, 1, 1),
        isGeneratedFromRepeat: true,
      );

      await tester.pumpWidget(
        _wrap(
          AddTodoDialog(
            todo: todo,
            onAdd: (
              title,
              description, {
              reminderTime,
              reminderEnabled = false,
              startTime,
              endTime,
            }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.event), findsNothing);
      expect(find.byIcon(Icons.event_available), findsNothing);

      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields, hasLength(2));
      expect(fields[0].readOnly, isTrue); // title
      expect(fields[1].readOnly, isTrue); // description
    },
  );

  testWidgets(
    'AddTodoDialog shows start/end time editors for normal todos',
    (tester) async {
      final todo = TodoModel(
        id: 't1',
        title: 'todo',
        createdAt: DateTime(2025, 1, 1),
        isGeneratedFromRepeat: false,
      );

      await tester.pumpWidget(
        _wrap(
          AddTodoDialog(
            todo: todo,
            onAdd: (
              title,
              description, {
              reminderTime,
              reminderEnabled = false,
              startTime,
              endTime,
            }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.event), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);

      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields, hasLength(2));
      expect(fields[0].readOnly, isFalse); // title
      expect(fields[1].readOnly, isFalse); // description
    },
  );
}
