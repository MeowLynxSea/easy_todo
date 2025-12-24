import 'package:hive/hive.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 0)
class TodoModel extends HiveObject {
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
  });

  factory TodoModel.create({
    required String title,
    String? description,
    int order = 0,
    DateTime? reminderTime,
    bool reminderEnabled = false,
    String? repeatTodoId,
    bool isGeneratedFromRepeat = false,
    double? dataValue,
    String? dataUnit,
    String? aiCategory,
    int aiPriority = 0,
    bool aiProcessed = false,
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
      dataValue: dataValue,
      dataUnit: dataUnit,
      aiCategory: aiCategory,
      aiPriority: aiPriority,
      aiProcessed: aiProcessed,
    );
  }

  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    int? order,
    DateTime? reminderTime,
    bool? reminderEnabled,
    int? timeSpent,
    String? repeatTodoId,
    bool? isGeneratedFromRepeat,
    double? dataValue,
    String? dataUnit,
    String? aiCategory,
    int? aiPriority,
    bool? aiProcessed,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
      reminderTime: reminderTime ?? this.reminderTime,
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
    );
  }

  String get formattedTimeSpent {
    if (timeSpent == null) return '--:--';
    final minutes = (timeSpent! ~/ 60).toString().padLeft(2, '0');
    final seconds = (timeSpent! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
