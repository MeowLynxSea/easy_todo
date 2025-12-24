import 'package:hive/hive.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

part 'pomodoro_model.g.dart';

@HiveType(typeId: 4)
class PomodoroModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String todoId;

  @HiveField(2)
  int duration; // in seconds

  @HiveField(3)
  int? actualDuration; // in seconds (actual time spent)

  @HiveField(4)
  DateTime startTime;

  @HiveField(5)
  DateTime? endTime;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  bool isBreak;

  @HiveField(8)
  int workDuration; // in seconds

  @HiveField(9)
  int breakDuration; // in seconds

  PomodoroModel({
    required this.id,
    required this.todoId,
    required this.duration,
    this.actualDuration,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.isBreak = false,
    required this.workDuration,
    required this.breakDuration,
  });

  factory PomodoroModel.create({
    required String todoId,
    required int duration,
    required int workDuration,
    required int breakDuration,
    bool isBreak = false,
  }) {
    // 确保时区已初始化
    try {
      tz.initializeTimeZones();
    } catch (e) {
      // 时区初始化失败时继续使用默认时区
    }
    final now = tz.TZDateTime.now(tz.local);
    return PomodoroModel(
      id: now.millisecondsSinceEpoch.toString(),
      todoId: todoId,
      duration: duration,
      startTime: now,
      workDuration: workDuration,
      breakDuration: breakDuration,
      isBreak: isBreak,
    );
  }

  PomodoroModel copyWith({
    String? id,
    String? todoId,
    int? duration,
    int? actualDuration,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    bool? isBreak,
    int? workDuration,
    int? breakDuration,
  }) {
    return PomodoroModel(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      duration: duration ?? this.duration,
      actualDuration: actualDuration ?? this.actualDuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isBreak: isBreak ?? this.isBreak,
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todoId': todoId,
      'duration': duration,
      'actualDuration': actualDuration,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'isBreak': isBreak,
      'workDuration': workDuration,
      'breakDuration': breakDuration,
    };
  }

  factory PomodoroModel.fromJson(Map<String, dynamic> json) {
    return PomodoroModel(
      id: json['id'],
      todoId: json['todoId'],
      duration: json['duration'],
      actualDuration: json['actualDuration'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isCompleted: json['isCompleted'],
      isBreak: json['isBreak'],
      workDuration: json['workDuration'],
      breakDuration: json['breakDuration'],
    );
  }

  String get formattedDuration {
    final minutes = (duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get formattedActualDuration {
    if (actualDuration == null) return '--:--';
    final minutes = (actualDuration! ~/ 60).toString().padLeft(2, '0');
    final seconds = (actualDuration! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
