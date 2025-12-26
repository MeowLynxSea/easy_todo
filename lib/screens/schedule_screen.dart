import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/utils/responsive.dart';
import 'package:easy_todo/utils/time_format.dart';
import 'package:easy_todo/widgets/add_todo_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = isWebDesktop(context);

    return Consumer2<TodoProvider, AppSettingsProvider>(
      builder: (context, todoProvider, appSettingsProvider, child) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1));

        final weekDays = List<DateTime>.generate(
          7,
          (i) => weekStart.add(Duration(days: i)),
        );

        final selectedWeekdays = appSettingsProvider.scheduleVisibleWeekdays;
        final filteredDays = selectedWeekdays.isEmpty
            ? weekDays
            : weekDays
                  .where((d) => selectedWeekdays.contains(d.weekday))
                  .toList(growable: false);
        final days = filteredDays.isEmpty ? weekDays : filteredDays;

        final rawStartMinute = appSettingsProvider.scheduleDayStartMinutes;
        final rawEndMinute = appSettingsProvider.scheduleDayEndMinutes;
        final startMinute = rawStartMinute.clamp(0, 1440);
        final endMinute = rawEndMinute.clamp(0, 1440);
        final visibleStartMinute = endMinute > startMinute ? startMinute : 0;
        final visibleEndMinute = endMinute > startMinute ? endMinute : 1440;

        final scheduleTodos = todoProvider.getThisWeekScheduleTodos();
        final labelTextScale = appSettingsProvider.scheduleLabelTextScale.clamp(
          0.8,
          1.4,
        );

        final itemsByDay = <DateTime, List<_PlacedScheduleItem>>{};
        for (final dayStart in days) {
          itemsByDay[dayStart] = _collectItemsForDay(
            scheduleTodos,
            dayStart: dayStart,
          );
        }

        final maxUnscheduled = itemsByDay.values
            .map((items) => items.where((e) => e.type == _ItemType.unscheduled))
            .map((items) => items.length)
            .fold<int>(0, math.max);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.schedule),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    l10n.thisWeek,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final gutterWidth = isDesktop ? 56.0 : 44.0;
              final headerHeight = isDesktop ? 40.0 : 36.0;
              final minHourHeight = isDesktop ? 8.0 : 6.0;
              final bottomPadding = isDesktop ? 16.0 : 12.0;

              final availableForDays = math.max(
                0.0,
                constraints.maxWidth - gutterWidth,
              );
              final dayCount = math.max(1, days.length);
              final dayWidth = availableForDays / dayCount.toDouble();

              final baseUnscheduledItemHeight = isDesktop ? 24.0 : 22.0;
              const baseUnscheduledGap = 6.0;
              const minUnscheduledItemHeight = 14.0;
              const minUnscheduledGap = 2.0;
              const unscheduledPaddingTop = 6.0;
              const unscheduledPaddingBottom = 6.0;
              final availableHeight = math.max(0.0, constraints.maxHeight);
              final heightForLayout = math.max(
                0.0,
                availableHeight - bottomPadding,
              );

              final visibleMinutesSpan = (visibleEndMinute - visibleStartMinute)
                  .toDouble();
              final minMinuteHeight = minHourHeight / 60.0;
              final maxTopAreaHeightForMinHours = math.max(
                headerHeight,
                heightForLayout - minMinuteHeight * visibleMinutesSpan,
              );

              final perDayUnscheduledCount = maxUnscheduled;
              var unscheduledItemHeight = baseUnscheduledItemHeight;
              var unscheduledGap = baseUnscheduledGap;

              if (perDayUnscheduledCount > 0) {
                final availableForUnscheduled =
                    maxTopAreaHeightForMinHours -
                    headerHeight -
                    unscheduledPaddingTop -
                    unscheduledPaddingBottom;

                if (availableForUnscheduled > 0) {
                  final perItem =
                      availableForUnscheduled / perDayUnscheduledCount;
                  unscheduledGap = math.min(
                    baseUnscheduledGap,
                    math.max(minUnscheduledGap, perItem * 0.18),
                  );
                  unscheduledItemHeight = math.min(
                    baseUnscheduledItemHeight,
                    math.max(
                      minUnscheduledItemHeight,
                      perItem - unscheduledGap,
                    ),
                  );
                } else {
                  unscheduledGap = minUnscheduledGap;
                  unscheduledItemHeight = minUnscheduledItemHeight;
                }
              }

              final topAreaHeight =
                  headerHeight +
                  (perDayUnscheduledCount == 0
                      ? 0
                      : unscheduledPaddingTop +
                            perDayUnscheduledCount *
                                (unscheduledItemHeight + unscheduledGap) +
                            unscheduledPaddingBottom);

              final hourHeight = heightForLayout <= topAreaHeight
                  ? 0.0
                  : (heightForLayout - topAreaHeight) /
                        visibleMinutesSpan *
                        60.0;

              final minuteHeight = hourHeight / 60.0;
              const markedMinutes = <int>[
                0,
                3 * 60,
                6 * 60,
                9 * 60,
                12 * 60,
                15 * 60,
                18 * 60,
                21 * 60,
              ];

              final contentHeight = availableHeight;

              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TimeGutter(
                      width: gutterWidth,
                      height: contentHeight,
                      topAreaHeight: topAreaHeight,
                      startMinute: visibleStartMinute,
                      endMinute: visibleEndMinute,
                      minuteHeight: minuteHeight,
                      markedMinutes: markedMinutes,
                      bottomPadding: bottomPadding,
                      dense: !isDesktop,
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: days
                            .map(
                              (dayStart) => _DayColumn(
                                dayStart: dayStart,
                                items: itemsByDay[dayStart] ?? const [],
                                width: dayWidth,
                                height: contentHeight,
                                headerHeight: headerHeight,
                                topAreaHeight: topAreaHeight,
                                startMinute: visibleStartMinute,
                                endMinute: visibleEndMinute,
                                unscheduledItemHeight: unscheduledItemHeight,
                                unscheduledGap: unscheduledGap,
                                minuteHeight: minuteHeight,
                                markedMinutes: markedMinutes,
                                bottomPadding: bottomPadding,
                                dense: !isDesktop,
                                labelTextScale: labelTextScale,
                                isWebDesktop: isDesktop,
                                onEdit: _showEditDialog,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<_PlacedScheduleItem> _collectItemsForDay(
    List<TodoModel> todos, {
    required DateTime dayStart,
  }) {
    final dayEnd = dayStart.add(const Duration(days: 1));
    final items = <_PlacedScheduleItem>[];

    for (final todo in todos) {
      final start = todo.startTime;
      final end = todo.endTime;

      if (start != null && end != null && end.isAfter(start)) {
        if (!start.isBefore(dayEnd) || !end.isAfter(dayStart)) continue;

        final clampedStart = start.isBefore(dayStart) ? dayStart : start;
        final clampedEnd = end.isAfter(dayEnd) ? dayEnd : end;
        items.add(
          _PlacedScheduleItem.ranged(
            todo: todo,
            start: clampedStart,
            end: clampedEnd,
          ),
        );
        continue;
      }

      final point = start ?? end;
      if (point != null) {
        if (point.isBefore(dayStart) || !point.isBefore(dayEnd)) continue;
        items.add(
          _PlacedScheduleItem.point(
            todo: todo,
            at: point,
            type: start != null ? _ItemType.startOnly : _ItemType.endOnly,
          ),
        );
        continue;
      }

      final anchor = (todo.reminderEnabled && todo.reminderTime != null)
          ? todo.reminderTime!
          : todo.createdAt;
      if (anchor.isBefore(dayStart) || !anchor.isBefore(dayEnd)) continue;
      items.add(_PlacedScheduleItem.unscheduled(todo: todo));
    }

    items.sort((a, b) {
      final aKey = a.type == _ItemType.unscheduled ? -1 : a.minutesFromMidnight;
      final bKey = b.type == _ItemType.unscheduled ? -1 : b.minutesFromMidnight;
      final cmp = aKey.compareTo(bKey);
      if (cmp != 0) return cmp;
      return a.todo.title.compareTo(b.todo.title);
    });

    return items;
  }

  void _showEditDialog(TodoModel todo) {
    final provider = Provider.of<TodoProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        todo: todo,
        onAdd:
            (
              title,
              description, {
              reminderTime,
              reminderEnabled = false,
              startTime,
              endTime,
            }) async {
              final updatedTodo = todo.copyWith(
                title: title,
                description: description,
                reminderTime: reminderTime,
                reminderEnabled: reminderEnabled,
                startTime: startTime,
                endTime: endTime,
              );
              await provider.updateTodo(updatedTodo);
            },
      ),
    );
  }
}

enum _ItemType { unscheduled, startOnly, endOnly, ranged }

class _PlacedScheduleItem {
  final TodoModel todo;
  final _ItemType type;
  final DateTime? start;
  final DateTime? end;

  const _PlacedScheduleItem._({
    required this.todo,
    required this.type,
    this.start,
    this.end,
  });

  factory _PlacedScheduleItem.unscheduled({required TodoModel todo}) {
    return _PlacedScheduleItem._(todo: todo, type: _ItemType.unscheduled);
  }

  factory _PlacedScheduleItem.point({
    required TodoModel todo,
    required DateTime at,
    required _ItemType type,
  }) {
    return _PlacedScheduleItem._(todo: todo, type: type, start: at);
  }

  factory _PlacedScheduleItem.ranged({
    required TodoModel todo,
    required DateTime start,
    required DateTime end,
  }) {
    return _PlacedScheduleItem._(
      todo: todo,
      type: _ItemType.ranged,
      start: start,
      end: end,
    );
  }

  int get minutesFromMidnight {
    final at = start ?? end;
    if (at == null) return 0;
    return at.hour * 60 + at.minute;
  }

  int get durationMinutes {
    if (type != _ItemType.ranged || start == null || end == null) return 0;
    return end!.difference(start!).inMinutes;
  }
}

class _TimeGutter extends StatelessWidget {
  final double width;
  final double height;
  final double topAreaHeight;
  final int startMinute;
  final int endMinute;
  final double minuteHeight;
  final List<int> markedMinutes;
  final double bottomPadding;
  final bool dense;

  const _TimeGutter({
    required this.width,
    required this.height,
    required this.topAreaHeight,
    required this.startMinute,
    required this.endMinute,
    required this.minuteHeight,
    required this.markedMinutes,
    required this.bottomPadding,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.7);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            top: topAreaHeight,
            left: 0,
            right: 0,
            child: Container(height: 1, color: lineColor),
          ),
          for (final minute in markedMinutes)
            if (minute >= startMinute && minute <= endMinute)
              Positioned(
                top: topAreaHeight + (minute - startMinute) * minuteHeight - 8,
                left: 0,
                right: 6,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    (minute == 0 && startMinute == 0)
                        ? ''
                        : (minute ~/ 60).toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DateTime dayStart;
  final List<_PlacedScheduleItem> items;
  final double width;
  final double height;
  final double headerHeight;
  final double topAreaHeight;
  final int startMinute;
  final int endMinute;
  final double unscheduledItemHeight;
  final double unscheduledGap;
  final double minuteHeight;
  final List<int> markedMinutes;
  final double bottomPadding;
  final bool dense;
  final double labelTextScale;
  final bool isWebDesktop;
  final ValueChanged<TodoModel> onEdit;

  const _DayColumn({
    required this.dayStart,
    required this.items,
    required this.width,
    required this.height,
    required this.headerHeight,
    required this.topAreaHeight,
    required this.startMinute,
    required this.endMinute,
    required this.unscheduledItemHeight,
    required this.unscheduledGap,
    required this.minuteHeight,
    required this.markedMinutes,
    required this.bottomPadding,
    required this.dense,
    required this.labelTextScale,
    required this.isWebDesktop,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabel = _weekdayLabel(l10n, dayStart.weekday);
    final dateLabel =
        '${dayStart.month.toString().padLeft(2, '0')}/${dayStart.day.toString().padLeft(2, '0')}';

    final lineColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.55);

    final unscheduled = items.where((e) => e.type == _ItemType.unscheduled);
    final timed = items.where((e) => e.type != _ItemType.unscheduled);
    final compact = width < (dense ? 64 : 84);
    final compactDayLabel = _compactWeekdayLabel(context, dayStart.weekday);

    final warmPalette = <Color>[
      Colors.orange.shade300,
      Colors.deepOrange.shade200,
      Colors.amber.shade300,
      Colors.redAccent.shade100,
      Colors.pink.shade200,
    ];
    final coolPalette = <Color>[
      Colors.lightBlue.shade300,
      Colors.blue.shade200,
      Colors.cyan.shade200,
      Colors.teal.shade200,
      Colors.indigo.shade200,
    ];

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              compact ? compactDayLabel : dayLabel,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(width: 6),
                            Text(
                              dateLabel,
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: topAreaHeight,
              left: 0,
              right: 0,
              child: Container(height: 1, color: lineColor),
            ),
            for (final minute in markedMinutes)
              if (minute >= startMinute && minute <= endMinute)
                Positioned(
                  top: topAreaHeight + (minute - startMinute) * minuteHeight,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: lineColor.withValues(alpha: 0.4),
                  ),
                ),
            ..._buildUnscheduledItems(
              context,
              unscheduled.toList(growable: false),
              compact: compact,
              warmPalette: warmPalette,
              coolPalette: coolPalette,
            ),
            ..._buildTimedItems(
              context,
              timed.toList(growable: false),
              compact: compact,
              warmPalette: warmPalette,
              coolPalette: coolPalette,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUnscheduledItems(
    BuildContext context,
    List<_PlacedScheduleItem> items, {
    required bool compact,
    required List<Color> warmPalette,
    required List<Color> coolPalette,
  }) {
    if (items.isEmpty) return const [];

    final visibleItems = items;

    return [
      for (int i = 0; i < visibleItems.length; i++)
        Positioned(
          top: headerHeight + 6 + i * (unscheduledItemHeight + unscheduledGap),
          left: 6,
          right: 6,
          height: unscheduledItemHeight,
          child: _ScheduleChip(
            todo: visibleItems[i].todo,
            color: _colorFor(
              visibleItems[i].todo,
              warmPalette: warmPalette,
              coolPalette: coolPalette,
            ),
            dense: dense,
            showText: true,
            textScale: labelTextScale,
            isWebDesktop: isWebDesktop,
            onEdit: () => onEdit(visibleItems[i].todo),
          ),
        ),
    ];
  }

  List<Widget> _buildTimedItems(
    BuildContext context,
    List<_PlacedScheduleItem> items, {
    required bool compact,
    required List<Color> warmPalette,
    required List<Color> coolPalette,
  }) {
    if (items.isEmpty) return const [];

    final minBlockHeight = dense ? 18.0 : 22.0;

    return [
      for (final item in items)
        if (item.type == _ItemType.ranged &&
            item.start != null &&
            item.end != null)
          _buildRangeBlock(
            context,
            item,
            minBlockHeight: minBlockHeight,
            warmPalette: warmPalette,
            coolPalette: coolPalette,
            compact: compact,
          )
        else if ((item.type == _ItemType.startOnly ||
                item.type == _ItemType.endOnly) &&
            item.start != null)
          _buildPointMark(
            context,
            item,
            warmPalette: warmPalette,
            coolPalette: coolPalette,
          ),
    ];
  }

  Widget _buildRangeBlock(
    BuildContext context,
    _PlacedScheduleItem item, {
    required double minBlockHeight,
    required List<Color> warmPalette,
    required List<Color> coolPalette,
    required bool compact,
  }) {
    final start = item.start!;
    final end = item.end!;

    final startMinutes = start.difference(dayStart).inMinutes;
    final endMinutes = end.difference(dayStart).inMinutes;

    if (endMinutes <= startMinute || startMinutes >= endMinute) {
      return const SizedBox.shrink();
    }

    final clampedStart = math.max(startMinutes, startMinute);
    final clampedEnd = math.min(endMinutes, endMinute);
    final minutesSpan = math.max(1, clampedEnd - clampedStart);

    final top = topAreaHeight + (clampedStart - startMinute) * minuteHeight;
    final height = math.max(minBlockHeight, minutesSpan * minuteHeight);

    final color = _colorFor(
      item.todo,
      warmPalette: warmPalette,
      coolPalette: coolPalette,
    );

    return Positioned(
      top: top + 1,
      left: 6,
      right: 6,
      height: height - 2,
      child: _ScheduleBlock(
        todo: item.todo,
        color: color,
        dense: dense,
        showText: true,
        textScale: labelTextScale,
        isWebDesktop: isWebDesktop,
        onEdit: () => onEdit(item.todo),
      ),
    );
  }

  Widget _buildPointMark(
    BuildContext context,
    _PlacedScheduleItem item, {
    required List<Color> warmPalette,
    required List<Color> coolPalette,
  }) {
    final at = item.start!;
    final minutes = at.difference(dayStart).inMinutes;
    if (minutes < startMinute || minutes >= endMinute) {
      return const SizedBox.shrink();
    }

    final tickTop = topAreaHeight + (minutes - startMinute) * minuteHeight;

    final color = _colorFor(
      item.todo,
      warmPalette: warmPalette,
      coolPalette: coolPalette,
    );

    final chipHeight = dense ? 20.0 : 22.0;
    final top = tickTop - chipHeight / 2;

    return Positioned(
      top: top,
      left: 6,
      right: 6,
      height: chipHeight,
      child: _ScheduleChip(
        todo: item.todo,
        color: color,
        dense: dense,
        showText: true,
        textScale: labelTextScale,
        isWebDesktop: isWebDesktop,
        onEdit: () => onEdit(item.todo),
      ),
    );
  }

  String _weekdayLabel(AppLocalizations l10n, int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.monday;
      case DateTime.tuesday:
        return l10n.tuesday;
      case DateTime.wednesday:
        return l10n.wednesday;
      case DateTime.thursday:
        return l10n.thursday;
      case DateTime.friday:
        return l10n.friday;
      case DateTime.saturday:
        return l10n.saturday;
      case DateTime.sunday:
        return l10n.sunday;
    }
    return l10n.monday;
  }

  String _compactWeekdayLabel(BuildContext context, int weekday) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'zh') {
      switch (weekday) {
        case DateTime.monday:
          return '一';
        case DateTime.tuesday:
          return '二';
        case DateTime.wednesday:
          return '三';
        case DateTime.thursday:
          return '四';
        case DateTime.friday:
          return '五';
        case DateTime.saturday:
          return '六';
        case DateTime.sunday:
          return '日';
      }
      return '一';
    }

    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
    }
    return 'M';
  }

  Color _colorFor(
    TodoModel todo, {
    required List<Color> warmPalette,
    required List<Color> coolPalette,
  }) {
    final palette = todo.isCompleted ? coolPalette : warmPalette;
    final idx = _stableHash(todo.id) % palette.length;
    return palette[idx];
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = 0x7fffffff & (hash * 31 + unit);
    }
    return hash;
  }
}

class _ScheduleChip extends StatelessWidget {
  final TodoModel todo;
  final Color color;
  final bool dense;
  final bool showText;
  final double textScale;
  final bool isWebDesktop;
  final VoidCallback onEdit;

  const _ScheduleChip({
    required this.todo,
    required this.color,
    required this.dense,
    required this.showText,
    required this.textScale,
    required this.isWebDesktop,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    final baseStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final textStyle = _scaleTextStyle(baseStyle, textScale);

    return _ScheduleItemPreviewWrapper(
      todo: todo,
      isWebDesktop: isWebDesktop,
      onEdit: onEdit,
      builder: (context, onTap, onLongPress) {
        return Material(
          color: color.withValues(alpha: 0.25),
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10),
              child: showText
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        todo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleBlock extends StatelessWidget {
  final TodoModel todo;
  final Color color;
  final bool dense;
  final bool showText;
  final double textScale;
  final bool isWebDesktop;
  final VoidCallback onEdit;

  const _ScheduleBlock({
    required this.todo,
    required this.color,
    required this.dense,
    required this.showText,
    required this.textScale,
    required this.isWebDesktop,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    final baseStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: foreground.withValues(alpha: 0.9),
      fontWeight: FontWeight.w700,
    );
    final textStyle = _scaleTextStyle(baseStyle, textScale);

    final borderRadius = BorderRadius.circular(10);

    return _ScheduleItemPreviewWrapper(
      todo: todo,
      isWebDesktop: isWebDesktop,
      onEdit: onEdit,
      builder: (context, onTap, onLongPress) {
        return Material(
          color: color.withValues(alpha: 0.85),
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: EdgeInsets.all(dense ? 6 : 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: showText
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final direction = Directionality.of(context);
                          final lineHeight = _lineHeightForStyle(
                            todo.title,
                            textStyle,
                            direction,
                          );
                          final availableHeight = constraints.maxHeight;
                          final maxLines = _maxLinesForHeight(
                            availableHeight,
                            lineHeight,
                          );

                          return Text(
                            todo.title,
                            maxLines: maxLines,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: textStyle,
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }

  double _lineHeightForStyle(
    String sample,
    TextStyle? style,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: sample.isEmpty ? 'A' : sample[0], style: style),
      textDirection: direction,
      maxLines: 1,
    )..layout();
    return painter.preferredLineHeight;
  }

  int _maxLinesForHeight(double height, double lineHeight) {
    if (!height.isFinite || height <= 0 || lineHeight <= 0) return 1;
    return math.max(1, (height / lineHeight).floor());
  }
}

TextStyle? _scaleTextStyle(TextStyle? style, double scale) {
  if (style == null) return null;
  final baseSize = style.fontSize ?? 14.0;
  return style.copyWith(fontSize: baseSize * scale);
}

class _ScheduleItemPreviewWrapper extends StatefulWidget {
  final TodoModel todo;
  final bool isWebDesktop;
  final VoidCallback onEdit;
  final Widget Function(
    BuildContext context,
    VoidCallback onTap,
    VoidCallback? onLongPress,
  )
  builder;

  const _ScheduleItemPreviewWrapper({
    required this.todo,
    required this.isWebDesktop,
    required this.onEdit,
    required this.builder,
  });

  @override
  State<_ScheduleItemPreviewWrapper> createState() =>
      _ScheduleItemPreviewWrapperState();
}

class _ScheduleItemPreviewWrapperState
    extends State<_ScheduleItemPreviewWrapper> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _hidePreview();
    super.dispose();
  }

  @override
  void deactivate() {
    _hidePreview();
    super.deactivate();
  }

  void _togglePreview() {
    if (_entry == null) {
      _showPreview(dismissOnTapOutside: true);
    } else {
      _hidePreview();
    }
  }

  void _showPreview({required bool dismissOnTapOutside}) {
    if (_entry != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            if (dismissOnTapOutside)
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    _hidePreview();
                  },
                ),
              ),
            IgnorePointer(
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topCenter,
                followerAnchor: Alignment.bottomCenter,
                offset: const Offset(0, -8),
                child: _ScheduleItemPreviewBubble(todo: widget.todo),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
  }

  void _hidePreview() {
    _entry?.remove();
    _entry = null;
  }

  void _openEdit() {
    _hidePreview();
    widget.onEdit();
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.isWebDesktop ? _openEdit : _togglePreview;
    final onLongPress = widget.isWebDesktop ? null : _openEdit;

    Widget child = CompositedTransformTarget(
      link: _layerLink,
      child: widget.builder(context, onTap, onLongPress),
    );

    if (widget.isWebDesktop) {
      child = MouseRegion(
        onEnter: (_) => _showPreview(dismissOnTapOutside: false),
        onExit: (_) => _hidePreview(),
        child: child,
      );
    }

    return child;
  }
}

class _ScheduleItemPreviewBubble extends StatelessWidget {
  final TodoModel todo;

  const _ScheduleItemPreviewBubble({required this.todo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = todo.title.trim();
    final description = (todo.description ?? '').trim();
    final timeLabel = _schedulePreviewTime(todo);

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
    final descriptionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );
    final timeStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );

    final children = <Widget>[
      Text(title, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
      if (description.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          description,
          style: descriptionStyle,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      if (timeLabel != null) ...[
        const SizedBox(height: 6),
        Text(timeLabel, style: timeStyle),
      ],
    ];

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

String? _schedulePreviewTime(TodoModel todo) {
  final start = todo.startTime;
  final end = todo.endTime;

  if (start != null && end != null && end.isAfter(start)) {
    if (_isSameDate(start, end)) {
      return '${_formatTime(start)} - ${_formatTime(end)}';
    }
    return '${_formatMonthDayTime(start)} - ${_formatMonthDayTime(end)}';
  }

  final point = start ?? end;
  if (point != null) return _formatTime(point);

  final reminder = todo.reminderEnabled ? todo.reminderTime : null;
  if (reminder != null) return _formatTime(reminder);

  return null;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatTime(DateTime dt) {
  return formatMinutesAsHHmm(dt.hour * 60 + dt.minute);
}

String _formatMonthDayTime(DateTime dt) {
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '$month/$day ${_formatTime(dt)}';
}
