import 'package:hive/hive.dart';

part 'app_settings_model.g.dart';

@HiveType(typeId: 3)
class AppSettingsModel extends HiveObject {
  @HiveField(0, defaultValue: false)
  bool biometricLockEnabled;

  @HiveField(1, defaultValue: true)
  bool autoUpdateEnabled;

  @HiveField(2, defaultValue: 'list')
  String viewMode; // 'list' or 'stacking'

  @HiveField(3, defaultValue: false)
  bool viewOpenInNewPage;

  @HiveField(4, defaultValue: 'list')
  String historyViewMode; // 'list' or 'calendar'

  /// Schedule: visible range within a day (minutes since midnight).
  /// End is allowed to be 1440, representing 24:00.
  @HiveField(5, defaultValue: 0)
  int scheduleDayStartMinutes;

  @HiveField(6, defaultValue: 1440)
  int scheduleDayEndMinutes;

  /// Schedule: which weekdays are shown (DateTime.weekday: 1=Mon..7=Sun).
  @HiveField(7, defaultValue: <int>[1, 2, 3, 4, 5, 6, 7])
  List<int> scheduleVisibleWeekdays;

  /// Schedule: text scale factor for labels (chips/blocks).
  @HiveField(8, defaultValue: 1.0)
  double scheduleLabelTextScale;

  AppSettingsModel({
    this.biometricLockEnabled = false,
    this.autoUpdateEnabled = true,
    this.viewMode = 'list',
    this.viewOpenInNewPage = false,
    this.historyViewMode = 'list',
    this.scheduleDayStartMinutes = 0,
    this.scheduleDayEndMinutes = 1440,
    this.scheduleVisibleWeekdays = const <int>[1, 2, 3, 4, 5, 6, 7],
    this.scheduleLabelTextScale = 1.0,
  });

  AppSettingsModel copyWith({
    bool? biometricLockEnabled,
    bool? autoUpdateEnabled,
    String? viewMode,
    bool? viewOpenInNewPage,
    String? historyViewMode,
    int? scheduleDayStartMinutes,
    int? scheduleDayEndMinutes,
    List<int>? scheduleVisibleWeekdays,
    double? scheduleLabelTextScale,
  }) {
    return AppSettingsModel(
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      viewMode: viewMode ?? this.viewMode,
      viewOpenInNewPage: viewOpenInNewPage ?? this.viewOpenInNewPage,
      historyViewMode: historyViewMode ?? this.historyViewMode,
      scheduleDayStartMinutes:
          scheduleDayStartMinutes ?? this.scheduleDayStartMinutes,
      scheduleDayEndMinutes:
          scheduleDayEndMinutes ?? this.scheduleDayEndMinutes,
      scheduleVisibleWeekdays:
          scheduleVisibleWeekdays ?? this.scheduleVisibleWeekdays,
      scheduleLabelTextScale:
          scheduleLabelTextScale ?? this.scheduleLabelTextScale,
    );
  }

  factory AppSettingsModel.create() {
    return AppSettingsModel();
  }
}
