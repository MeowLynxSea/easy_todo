import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/schedule_color_group.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/screens/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockTodoProvider extends Mock implements TodoProvider {}

class _MockAppSettingsProvider extends Mock implements AppSettingsProvider {}

MaterialApp _wrap({
  required TodoProvider todoProvider,
  required AppSettingsProvider appSettingsProvider,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<TodoProvider>.value(value: todoProvider),
        ChangeNotifierProvider<AppSettingsProvider>.value(
          value: appSettingsProvider,
        ),
      ],
      child: const ScheduleScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      TodoModel(
        id: 'fallback',
        title: 'fallback',
        createdAt: DateTime(2025, 1, 1),
      ),
    );
  });

  testWidgets('Repeat-generated unscheduled items are not draggable', (
    tester,
  ) async {
    final provider = _MockTodoProvider();
    final settings = _MockAppSettingsProvider();

    when(() => settings.scheduleDayStartMinutes).thenReturn(0);
    when(() => settings.scheduleDayEndMinutes).thenReturn(24 * 60);
    when(
      () => settings.scheduleVisibleWeekdays,
    ).thenReturn(const <int>[1, 2, 3, 4, 5, 6, 7]);
    when(() => settings.scheduleLabelTextScale).thenReturn(1.0);
    when(() => settings.scheduleVisibleDayCount).thenReturn(5);
    when(() => settings.scheduleEffectiveActiveColorGroup).thenReturn(
      const ScheduleColorGroup(
        id: 'test',
        name: 'test',
        incompleteColorsArgb: <int>[0xFFFFB74D],
        completedColorsArgb: <int>[0xFF4FC3F7],
      ),
    );

    when(
      () => provider.getScheduleTodosInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenReturn([
      TodoModel(
        id: 'r1',
        title: 'repeat',
        createdAt: DateTime.now(),
        isGeneratedFromRepeat: true,
      ),
    ]);

    when(() => provider.updateTodo(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      _wrap(todoProvider: provider, appSettingsProvider: settings),
    );
    await tester.pumpAndSettle();

    expect(find.text('repeat'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('repeat'), matching: find.byType(Draggable)),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('repeat'),
        matching: find.byType(LongPressDraggable),
      ),
      findsNothing,
    );
  });
}
