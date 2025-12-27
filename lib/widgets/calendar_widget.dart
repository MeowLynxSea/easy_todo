import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/services/timezone_service.dart';
import 'package:easy_todo/utils/date_utils.dart';

class CalendarWidget extends StatefulWidget {
  final List<TodoModel> todos;
  final Function(DateTime) onDaySelected;
  final DateTime? selectedDay;

  const CalendarWidget({
    super.key,
    required this.todos,
    required this.onDaySelected,
    this.selectedDay,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late final TimezoneService _timezoneService;

  // 获取本地当前日期的辅助方法
  DateTime _getLocalNow() {
    return _timezoneService.getCurrentTime();
  }

  @override
  void initState() {
    super.initState();
    _timezoneService = TimezoneService();
    final now = _getLocalNow();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = now;
    _selectedDay = widget.selectedDay ?? now;
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDay != null && widget.selectedDay != _selectedDay) {
      _selectedDay = widget.selectedDay!;
    }
  }

  Map<DateTime, List<TodoModel>> _getEventsForDay() {
    final events = <DateTime, List<TodoModel>>{};

    for (final todo in widget.todos) {
      final date = localDay(todo.createdAt);
      if (!events.containsKey(date)) {
        events[date] = [];
      }
      events[date]!.add(todo);
    }

    return events;
  }

  Map<DateTime, dynamic> _getEventMarkers(
    Map<DateTime, List<TodoModel>> events,
  ) {
    final markers = <DateTime, dynamic>{};

    events.forEach((date, todos) {
      final completedCount = todos.where((todo) => todo.isCompleted).length;
      final totalCount = todos.length;
      markers[date] = {'completed': completedCount, 'total': totalCount};
    });

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final events = _getEventsForDay();
    final markers = _getEventMarkers(events);
    final localNow = _getLocalNow();

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            locale: languageProvider.locale.languageCode,
            eventLoader: (day) {
              final date = localDay(day);
              return events[date] ?? [];
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              weekendTextStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              holidayTextStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
              weekendStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDaySelected(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;

                final markerData = markers[date];
                if (markerData == null) return null;

                final completed = markerData['completed'] as int;
                final total = markerData['total'] as int;

                return Positioned(
                  bottom: 1,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: completed == total
                          ? AppTheme.secondaryColor.withValues(alpha: 0.8)
                          : AppTheme.primaryColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FittedBox(
                      child: Text(
                        '$completed/$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final markerData = markers[localDay(day)];
                final hasTodos = markerData != null;
                final isToday = isSameDay(day, localNow);

                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasTodos
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : null,
                    border: hasTodos
                        ? Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isToday
                            ? AppTheme.primaryColor
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${l10n.dayDetails}: ${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDayStats(_selectedDay, l10n, events),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayStats(
    DateTime day,
    AppLocalizations l10n,
    Map<DateTime, List<TodoModel>> events,
  ) {
    final dayEvents = events[localDay(day)] ?? [];

    if (dayEvents.isEmpty) {
      return Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[400], size: 16),
          const SizedBox(width: 8),
          Text(
            l10n.noTodosYet,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      );
    }

    final completedCount = dayEvents.where((todo) => todo.isCompleted).length;
    final totalCount = dayEvents.length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.task_alt, color: AppTheme.primaryColor, size: 14),
              const SizedBox(width: 4),
              Text(
                '$totalCount ${l10n.totalCount}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.secondaryColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '$completedCount ${l10n.completedCount}',
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
