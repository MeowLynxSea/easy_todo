import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/utils/date_utils.dart';

part 'repeat_todo_model.g.dart';

@HiveType(typeId: 5)
class RepeatTodoModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  RepeatType repeatType;

  @HiveField(4)
  List<int>? weekDays; // For weekly: 1-7 (Monday-Sunday)

  @HiveField(5)
  int? dayOfMonth; // For monthly: 1-31

  @HiveField(6)
  DateTime? startDate;

  @HiveField(7)
  DateTime? endDate;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  DateTime? lastGeneratedDate;

  @HiveField(11)
  int order;

  @HiveField(12)
  bool dataStatisticsEnabled;

  @HiveField(13)
  List<StatisticsMode>? statisticsModes;

  @HiveField(14)
  String? dataUnit;

  @HiveField(15)
  String? aiCategory; // AI-generated category

  @HiveField(16, defaultValue: 0)
  int aiPriority; // AI-generated priority (0-100)

  @HiveField(17, defaultValue: false)
  bool aiProcessed; // Whether this todo has been processed by AI

  // Optional time range for generated todos (minutes from midnight).
  // For repeat todos we store time only (no date).
  @HiveField(18)
  int? startTimeMinutes;

  @HiveField(19)
  int? endTimeMinutes;

  // Backfill (catch-up) options.
  @HiveField(20, defaultValue: false)
  bool backfillEnabled;

  /// Max days to look back when backfilling (not including today).
  @HiveField(21, defaultValue: 7)
  int backfillDays;

  /// If enabled, backfilled todos are created as completed.
  @HiveField(22, defaultValue: false)
  bool backfillAutoComplete;

  RepeatTodoModel({
    required this.id,
    required this.title,
    this.description,
    required this.repeatType,
    this.weekDays,
    this.dayOfMonth,
    this.startDate,
    this.endDate,
    required this.createdAt,
    this.isActive = true,
    this.lastGeneratedDate,
    this.order = 0,
    this.dataStatisticsEnabled = false,
    this.statisticsModes,
    this.dataUnit,
    this.aiCategory,
    this.aiPriority = 0,
    this.aiProcessed = false,
    this.startTimeMinutes,
    this.endTimeMinutes,
    this.backfillEnabled = false,
    this.backfillDays = 7,
    this.backfillAutoComplete = false,
  });

  factory RepeatTodoModel.create({
    required String title,
    String? description,
    required RepeatType repeatType,
    List<int>? weekDays,
    int? dayOfMonth,
    DateTime? startDate,
    DateTime? endDate,
    bool dataStatisticsEnabled = false,
    List<StatisticsMode>? statisticsModes,
    String? dataUnit,
    String? aiCategory,
    int aiPriority = 0,
    bool aiProcessed = false,
    int? startTimeMinutes,
    int? endTimeMinutes,
    bool backfillEnabled = false,
    int backfillDays = 7,
    bool backfillAutoComplete = false,
  }) {
    // 使用与每日任务相同的系统时间
    final now = DateTime.now();
    debugPrint(
      'Creating RepeatTodoModel at system time: $now (timezone offset: ${now.timeZoneOffset})',
    );

    return RepeatTodoModel(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      repeatType: repeatType,
      weekDays: weekDays,
      dayOfMonth: dayOfMonth,
      startDate: startDate ?? now,
      endDate: endDate,
      createdAt: now,
      isActive: true,
      dataStatisticsEnabled: dataStatisticsEnabled,
      statisticsModes: statisticsModes,
      dataUnit: dataUnit,
      aiCategory: aiCategory,
      aiPriority: aiPriority,
      aiProcessed: aiProcessed,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      backfillEnabled: backfillEnabled,
      backfillDays: backfillDays,
      backfillAutoComplete: backfillAutoComplete,
    );
  }

  RepeatTodoModel copyWith({
    String? id,
    String? title,
    String? description,
    RepeatType? repeatType,
    List<int>? weekDays,
    int? dayOfMonth,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    bool? isActive,
    DateTime? lastGeneratedDate,
    int? order,
    bool? dataStatisticsEnabled,
    List<StatisticsMode>? statisticsModes,
    String? dataUnit,
    String? aiCategory,
    int? aiPriority,
    bool? aiProcessed,
    int? startTimeMinutes,
    int? endTimeMinutes,
    bool? backfillEnabled,
    int? backfillDays,
    bool? backfillAutoComplete,
  }) {
    return RepeatTodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      repeatType: repeatType ?? this.repeatType,
      weekDays: weekDays ?? this.weekDays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      order: order ?? this.order,
      dataStatisticsEnabled:
          dataStatisticsEnabled ?? this.dataStatisticsEnabled,
      statisticsModes: statisticsModes ?? this.statisticsModes,
      dataUnit: dataUnit ?? this.dataUnit,
      aiCategory: aiCategory ?? this.aiCategory,
      aiPriority: aiPriority ?? this.aiPriority,
      aiProcessed: aiProcessed ?? this.aiProcessed,
      startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
      endTimeMinutes: endTimeMinutes ?? this.endTimeMinutes,
      backfillEnabled: backfillEnabled ?? this.backfillEnabled,
      backfillDays: backfillDays ?? this.backfillDays,
      backfillAutoComplete: backfillAutoComplete ?? this.backfillAutoComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'repeatType': repeatType.name,
      'weekDays': weekDays,
      'dayOfMonth': dayOfMonth,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'order': order,
      'dataStatisticsEnabled': dataStatisticsEnabled,
      'statisticsModes': statisticsModes?.map((e) => e.name).toList(),
      'dataUnit': dataUnit,
      'aiCategory': aiCategory,
      'aiPriority': aiPriority,
      'aiProcessed': aiProcessed,
      'startTimeMinutes': startTimeMinutes,
      'endTimeMinutes': endTimeMinutes,
      'backfillEnabled': backfillEnabled,
      'backfillDays': backfillDays,
      'backfillAutoComplete': backfillAutoComplete,
    };
  }

  factory RepeatTodoModel.fromJson(Map<String, dynamic> json) {
    return RepeatTodoModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      repeatType: RepeatType.values.firstWhere(
        (type) => type.name == json['repeatType'],
        orElse: () => RepeatType.daily,
      ),
      weekDays: json['weekDays'] != null
          ? List<int>.from(json['weekDays'])
          : null,
      dayOfMonth: json['dayOfMonth'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
      lastGeneratedDate: json['lastGeneratedDate'] != null
          ? DateTime.parse(json['lastGeneratedDate'])
          : null,
      order: json['order'] ?? 0,
      dataStatisticsEnabled: json['dataStatisticsEnabled'] ?? false,
      statisticsModes: json['statisticsModes'] != null
          ? (json['statisticsModes'] as List)
                .map(
                  (e) => StatisticsMode.values.firstWhere(
                    (mode) => mode.name == e,
                    orElse: () => StatisticsMode.average,
                  ),
                )
                .toList()
          : null,
      dataUnit: json['dataUnit'],
      aiCategory: json['aiCategory'],
      aiPriority: json['aiPriority'] ?? 0,
      aiProcessed: json['aiProcessed'] ?? false,
      startTimeMinutes: json['startTimeMinutes'],
      endTimeMinutes: json['endTimeMinutes'],
      backfillEnabled: json['backfillEnabled'] ?? false,
      backfillDays: json['backfillDays'] ?? 7,
      backfillAutoComplete: json['backfillAutoComplete'] ?? false,
    );
  }

  /// Whether this repeat template should generate a todo on the given date.
  ///
  /// This checks:
  /// - `isActive`
  /// - `startDate` / `endDate` bounds (date-only)
  /// - The repeat rule (daily/weekly/monthly/weekdays)
  bool shouldGenerateForDate(
    DateTime dateTime, {
    bool ignoreStartDate = false,
  }) {
    if (!isActive) return false;

    final date = _normalizeDay(dateTime);

    if (!ignoreStartDate &&
        startDate != null &&
        date.isBefore(_normalizeDay(startDate!))) {
      return false;
    }

    if (endDate != null && date.isAfter(_normalizeDay(endDate!))) {
      return false;
    }

    switch (repeatType) {
      case RepeatType.daily:
        return true;

      case RepeatType.weekly:
        if (weekDays == null || weekDays!.isEmpty) return false;
        return weekDays!.contains(date.weekday); // 1=Mon ... 7=Sun

      case RepeatType.monthly:
        if (dayOfMonth == null) return false;
        final maxDay = _maxDayOfMonth(date.year, date.month);
        final scheduledDay = dayOfMonth! > maxDay ? maxDay : dayOfMonth!;
        return date.day == scheduledDay;

      case RepeatType.weekdays:
        return date.weekday <= DateTime.friday;
    }
  }

  DateTime? getNextGenerateDate(DateTime fromDate) {
    if (!isActive ||
        (endDate != null &&
            _normalizeDay(fromDate).isAfter(_normalizeDay(endDate!)))) {
      return null;
    }

    DateTime date = fromDate;

    switch (repeatType) {
      case RepeatType.daily:
        // 对于每日任务，返回明天的同一时间，但使用日期规范化
        final tomorrow = date.add(const Duration(days: 1));
        return DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          date.hour,
          date.minute,
          date.second,
        );

      case RepeatType.weekly:
        if (weekDays == null || weekDays!.isEmpty) return null;

        // Find next weekday, starting from tomorrow (not including today)
        for (int i = 1; i <= 7; i++) {
          final nextDate = date.add(Duration(days: i));
          final weekday = nextDate.weekday; // 1=Monday, 7=Sunday
          if (weekDays!.contains(weekday)) {
            return nextDate;
          }
        }
        return null;

      case RepeatType.monthly:
        if (dayOfMonth == null) return null;

        // Move to next month
        final nextMonth = date.month == 12 ? 1 : date.month + 1;
        final nextYear = date.month == 12 ? date.year + 1 : date.year;

        // Adjust day if it's invalid for the month
        final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
        final adjustedDay = dayOfMonth! > maxDay ? maxDay : dayOfMonth!;

        return DateTime(nextYear, nextMonth, adjustedDay);

      case RepeatType.weekdays:
        // Monday to Friday
        if (date.weekday >= 5) {
          // If it's Friday or weekend, next is Monday
          return date.add(Duration(days: 8 - date.weekday));
        } else {
          return date.add(const Duration(days: 1));
        }
    }
  }

  bool shouldGenerateTodo(DateTime currentDate) {
    if (!isActive) return false;

    // Check if we have an end date and if we've passed it
    if (endDate != null &&
        _normalizeDay(currentDate).isAfter(_normalizeDay(endDate!))) {
      return false;
    }

    // If we've never generated, check if we should start now
    if (lastGeneratedDate == null) {
      return startDate == null ||
          currentDate.isAfter(startDate!) ||
          _isSameDay(currentDate, startDate!);
    }

    // Special case: if last generated date is in the future, we should generate
    if (lastGeneratedDate!.isAfter(currentDate)) {
      return true;
    }

    // Get the next generate date
    final nextDate = getNextGenerateDate(lastGeneratedDate!);
    if (nextDate == null) return false;

    // Check if the current date is at or past the next generate date
    // 使用日期比较而不是时间比较，避免时区问题
    final currentDay = localDay(currentDate);
    final nextDay = localDay(nextDate);
    return !currentDay.isBefore(nextDay);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return isSameLocalDay(date1, date2);
  }

  DateTime _normalizeDay(DateTime dateTime) => localDay(dateTime);

  int _maxDayOfMonth(int year, int month) => DateTime(year, month + 1, 0).day;
}

enum RepeatType { daily, weekly, monthly, weekdays }

enum BackfillStartBasis { startDate, backfillDays }

extension RepeatTypeExtension on RepeatType {
  String get displayName {
    switch (this) {
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        return 'Weekly';
      case RepeatType.monthly:
        return 'Monthly';
      case RepeatType.weekdays:
        return 'Weekdays';
    }
  }
}
