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

  AppSettingsModel({
    this.biometricLockEnabled = false,
    this.autoUpdateEnabled = true,
    this.viewMode = 'list',
    this.viewOpenInNewPage = false,
    this.historyViewMode = 'list',
  });

  AppSettingsModel copyWith({
    bool? biometricLockEnabled,
    bool? autoUpdateEnabled,
    String? viewMode,
    bool? viewOpenInNewPage,
    String? historyViewMode,
  }) {
    return AppSettingsModel(
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      viewMode: viewMode ?? this.viewMode,
      viewOpenInNewPage: viewOpenInNewPage ?? this.viewOpenInNewPage,
      historyViewMode: historyViewMode ?? this.historyViewMode,
    );
  }

  factory AppSettingsModel.create() {
    return AppSettingsModel();
  }
}
