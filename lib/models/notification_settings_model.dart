import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'notification_settings_model.g.dart';

@HiveType(typeId: 2)
class NotificationSettingsModel extends HiveObject {
  @HiveField(0)
  bool notificationsEnabled;

  @HiveField(1)
  bool dailySummaryEnabled;

  @HiveField(2)
  TimeOfDay dailySummaryTime;

  @HiveField(3)
  bool defaultReminderEnabled;

  @HiveField(4)
  int defaultReminderMinutesBefore;

  NotificationSettingsModel({
    this.notificationsEnabled = true,
    this.dailySummaryEnabled = true,
    TimeOfDay? dailySummaryTime,
    this.defaultReminderEnabled = false,
    this.defaultReminderMinutesBefore = 30,
  }) : dailySummaryTime =
           dailySummaryTime ?? const TimeOfDay(hour: 9, minute: 0);

  factory NotificationSettingsModel.create({
    bool notificationsEnabled = true,
    bool dailySummaryEnabled = true,
    TimeOfDay? dailySummaryTime,
    bool defaultReminderEnabled = false,
    int defaultReminderMinutesBefore = 30,
  }) {
    return NotificationSettingsModel(
      notificationsEnabled: notificationsEnabled,
      dailySummaryEnabled: dailySummaryEnabled,
      dailySummaryTime: dailySummaryTime ?? const TimeOfDay(hour: 9, minute: 0),
      defaultReminderEnabled: defaultReminderEnabled,
      defaultReminderMinutesBefore: defaultReminderMinutesBefore,
    );
  }

  NotificationSettingsModel copyWith({
    bool? notificationsEnabled,
    bool? dailySummaryEnabled,
    TimeOfDay? dailySummaryTime,
    bool? defaultReminderEnabled,
    int? defaultReminderMinutesBefore,
  }) {
    return NotificationSettingsModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      dailySummaryTime: dailySummaryTime ?? this.dailySummaryTime,
      defaultReminderEnabled:
          defaultReminderEnabled ?? this.defaultReminderEnabled,
      defaultReminderMinutesBefore:
          defaultReminderMinutesBefore ?? this.defaultReminderMinutesBefore,
    );
  }
}
