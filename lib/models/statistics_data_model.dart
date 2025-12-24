import 'package:hive/hive.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

part 'statistics_data_model.g.dart';

@HiveType(typeId: 6)
class StatisticsDataModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String repeatTodoId;

  @HiveField(2)
  String todoId;

  @HiveField(3)
  double value;

  @HiveField(4)
  String unit;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime todoCreatedAt; // Store the actual todo creation date for statistics filtering

  StatisticsDataModel({
    required this.id,
    required this.repeatTodoId,
    required this.todoId,
    required this.value,
    required this.unit,
    required this.date,
    required this.createdAt,
    required this.todoCreatedAt,
  });

  factory StatisticsDataModel.create({
    required String repeatTodoId,
    required String todoId,
    required double value,
    required String unit,
    DateTime? date,
    required DateTime todoCreatedAt,
  }) {
    // 确保时区已初始化
    try {
      tz.initializeTimeZones();
    } catch (e) {
      // 时区初始化失败时继续使用默认时区
    }
    final now = tz.TZDateTime.now(tz.local);
    return StatisticsDataModel(
      id: now.millisecondsSinceEpoch.toString(),
      repeatTodoId: repeatTodoId,
      todoId: todoId,
      value: value,
      unit: unit,
      date: date ?? now,
      createdAt: now,
      todoCreatedAt: todoCreatedAt,
    );
  }

  StatisticsDataModel copyWith({
    String? id,
    String? repeatTodoId,
    String? todoId,
    double? value,
    String? unit,
    DateTime? date,
    DateTime? createdAt,
    DateTime? todoCreatedAt,
  }) {
    return StatisticsDataModel(
      id: id ?? this.id,
      repeatTodoId: repeatTodoId ?? this.repeatTodoId,
      todoId: todoId ?? this.todoId,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      todoCreatedAt: todoCreatedAt ?? this.todoCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repeatTodoId': repeatTodoId,
      'todoId': todoId,
      'value': value,
      'unit': unit,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'todoCreatedAt': todoCreatedAt.toIso8601String(),
    };
  }

  factory StatisticsDataModel.fromJson(Map<String, dynamic> json) {
    return StatisticsDataModel(
      id: json['id'],
      repeatTodoId: json['repeatTodoId'],
      todoId: json['todoId'],
      value: json['value'].toDouble(),
      unit: json['unit'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      todoCreatedAt: DateTime.parse(json['todoCreatedAt']),
    );
  }
}

enum StatisticsMode {
  average,
  growth,
  extremum,
  trend,
  sum,
}

extension StatisticsModeExtension on StatisticsMode {
  String get displayName {
    switch (this) {
      case StatisticsMode.average:
        return 'Average';
      case StatisticsMode.growth:
        return 'Growth';
      case StatisticsMode.extremum:
        return 'Extremum';
      case StatisticsMode.trend:
        return 'Trend';
      case StatisticsMode.sum:
        return 'Sum';
    }
  }
}