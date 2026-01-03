import 'package:hive/hive.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 0)
class TodoModel extends HiveObject {
  static const Object _unset = Object();

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? completedAt;

  @HiveField(6)
  int order;

  @HiveField(7)
  DateTime? reminderTime;

  @HiveField(8)
  bool reminderEnabled;

  @HiveField(9)
  int? timeSpent; // in seconds

  @HiveField(10)
  String? repeatTodoId; // ID of the repeat template that generated this todo

  @HiveField(11, defaultValue: false)
  bool isGeneratedFromRepeat; // Whether this todo was generated from a repeat template

  @HiveField(12)
  double? dataValue; // User input data value for statistics

  @HiveField(13)
  String? dataUnit; // Data unit (inherited from repeat todo)

  @HiveField(14)
  String? aiCategory; // AI-generated category

  @HiveField(15, defaultValue: 0)
  int aiPriority; // AI-generated priority (0-100)

  @HiveField(16, defaultValue: false)
  bool aiProcessed; // Whether this todo has been processed by AI

  @HiveField(17)
  DateTime? startTime;

  @HiveField(18)
  DateTime? endTime;

  /// Stable de-dup key for todos generated from repeat templates.
  /// Format: "{repeatTodoId}:{yyyyMMdd}".
  @HiveField(19)
  String? generatedKey;

  /// Schedule color seed.
  /// When present, Schedule view uses this stable seed to pick a random color
  /// from the active color group.
  @HiveField(20)
  String? scheduleColorSeed;

  @HiveField(21, defaultValue: 0)
  int aiImportance; // AI-generated importance (0-100)

  TodoModel({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.order = 0,
    this.reminderTime,
    this.reminderEnabled = false,
    this.timeSpent,
    this.repeatTodoId,
    this.isGeneratedFromRepeat = false,
    this.dataValue,
    this.dataUnit,
    this.aiCategory,
    this.aiPriority = 0,
    this.aiProcessed = false,
    this.startTime,
    this.endTime,
    this.generatedKey,
    this.scheduleColorSeed,
    this.aiImportance = 0,
  });

  factory TodoModel.create({
    required String title,
    String? description,
    int order = 0,
    DateTime? reminderTime,
    bool reminderEnabled = false,
    String? repeatTodoId,
    bool isGeneratedFromRepeat = false,
    String? generatedKey,
    double? dataValue,
    String? dataUnit,
    String? aiCategory,
    int aiPriority = 0,
    bool aiProcessed = false,
    DateTime? startTime,
    DateTime? endTime,
    String? scheduleColorSeed,
    int aiImportance = 0,
  }) {
    // 使用系统时间，避免时区混乱
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = now.microsecond; // Add microsecond for uniqueness
    final id = '${timestamp}_$random';

    // debugPrint('TodoModel.create - System time: $now');
    // debugPrint('TodoModel.create - Timezone offset: ${now.timeZoneOffset}');
    // debugPrint('TodoModel.create - Reminder time: $reminderTime');

    return TodoModel(
      id: id,
      title: title,
      description: description,
      isCompleted: false,
      createdAt: now,
      order: order,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      repeatTodoId: repeatTodoId,
      isGeneratedFromRepeat: isGeneratedFromRepeat,
      generatedKey: generatedKey,
      dataValue: dataValue,
      dataUnit: dataUnit,
      aiCategory: aiCategory,
      aiPriority: aiPriority,
      aiProcessed: aiProcessed,
      startTime: startTime,
      endTime: endTime,
      scheduleColorSeed: scheduleColorSeed,
      aiImportance: aiImportance,
    );
  }

  TodoModel copyWith({
    String? id,
    String? title,
    Object? description = _unset,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    int? order,
    Object? reminderTime = _unset,
    bool? reminderEnabled,
    int? timeSpent,
    String? repeatTodoId,
    bool? isGeneratedFromRepeat,
    double? dataValue,
    String? dataUnit,
    String? aiCategory,
    int? aiPriority,
    bool? aiProcessed,
    Object? startTime = _unset,
    Object? endTime = _unset,
    Object? generatedKey = _unset,
    Object? scheduleColorSeed = _unset,
    int? aiImportance,
  }) {
    final resolvedDescription = identical(description, _unset)
        ? this.description
        : description as String?;
    final resolvedReminderTime = identical(reminderTime, _unset)
        ? this.reminderTime
        : reminderTime as DateTime?;
    final resolvedStartTime = identical(startTime, _unset)
        ? this.startTime
        : startTime as DateTime?;
    final resolvedEndTime = identical(endTime, _unset)
        ? this.endTime
        : endTime as DateTime?;
    final resolvedGeneratedKey = identical(generatedKey, _unset)
        ? this.generatedKey
        : generatedKey as String?;
    final resolvedScheduleColorSeed = identical(scheduleColorSeed, _unset)
        ? this.scheduleColorSeed
        : scheduleColorSeed as String?;

    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: resolvedDescription,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
      reminderTime: resolvedReminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      timeSpent: timeSpent ?? this.timeSpent,
      repeatTodoId: repeatTodoId ?? this.repeatTodoId,
      isGeneratedFromRepeat:
          isGeneratedFromRepeat ?? this.isGeneratedFromRepeat,
      dataValue: dataValue ?? this.dataValue,
      dataUnit: dataUnit ?? this.dataUnit,
      aiCategory: aiCategory ?? this.aiCategory,
      aiPriority: aiPriority ?? this.aiPriority,
      aiProcessed: aiProcessed ?? this.aiProcessed,
      startTime: resolvedStartTime,
      endTime: resolvedEndTime,
      generatedKey: resolvedGeneratedKey,
      scheduleColorSeed: resolvedScheduleColorSeed,
      aiImportance: aiImportance ?? this.aiImportance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'order': order,
      'reminderTime': reminderTime?.toIso8601String(),
      'reminderEnabled': reminderEnabled,
      'timeSpent': timeSpent,
      'repeatTodoId': repeatTodoId,
      'isGeneratedFromRepeat': isGeneratedFromRepeat,
      'dataValue': dataValue,
      'dataUnit': dataUnit,
      'aiCategory': aiCategory,
      'aiPriority': aiPriority,
      'aiProcessed': aiProcessed,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'generatedKey': generatedKey,
      'scheduleColorSeed': scheduleColorSeed,
      'aiImportance': aiImportance,
    };
  }

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      order: json['order'],
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'])
          : null,
      reminderEnabled: json['reminderEnabled'] ?? false,
      timeSpent: json['timeSpent'],
      repeatTodoId: json['repeatTodoId'],
      isGeneratedFromRepeat: json['isGeneratedFromRepeat'] ?? false,
      dataValue: json['dataValue']?.toDouble(),
      dataUnit: json['dataUnit'],
      aiCategory: json['aiCategory'],
      aiPriority: json['aiPriority'] ?? 0,
      aiProcessed: json['aiProcessed'] ?? false,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      generatedKey: json['generatedKey'],
      scheduleColorSeed: json['scheduleColorSeed'],
      aiImportance: json['aiImportance'] ?? 0,
    );
  }

  String get formattedTimeSpent {
    if (timeSpent == null) return '--:--';
    final minutes = (timeSpent! ~/ 60).toString().padLeft(2, '0');
    final seconds = (timeSpent! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
