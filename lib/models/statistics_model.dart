import 'package:hive/hive.dart';

part 'statistics_model.g.dart';

@HiveType(typeId: 1)
class StatisticsModel extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int tasksCreated;

  @HiveField(2)
  int tasksCompleted;

  @HiveField(3)
  double completionRate;

  StatisticsModel({
    required this.date,
    this.tasksCreated = 0,
    this.tasksCompleted = 0,
    this.completionRate = 0.0,
  });

  factory StatisticsModel.create({
    required DateTime date,
    int tasksCreated = 0,
    int tasksCompleted = 0,
  }) {
    final completionRate = tasksCreated > 0
        ? (tasksCompleted / tasksCreated) * 100
        : 0.0;

    return StatisticsModel(
      date: date,
      tasksCreated: tasksCreated,
      tasksCompleted: tasksCompleted,
      completionRate: completionRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'tasksCreated': tasksCreated,
      'tasksCompleted': tasksCompleted,
      'completionRate': completionRate,
    };
  }

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      date: DateTime.parse(json['date']),
      tasksCreated: json['tasksCreated'],
      tasksCompleted: json['tasksCompleted'],
      completionRate: json['completionRate'].toDouble(),
    );
  }
}
