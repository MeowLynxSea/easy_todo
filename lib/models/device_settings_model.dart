class DeviceSettingsModel {
  final bool biometricLockEnabled;
  final bool autoUpdateEnabled;

  const DeviceSettingsModel({
    required this.biometricLockEnabled,
    required this.autoUpdateEnabled,
  });

  DeviceSettingsModel copyWith({
    bool? biometricLockEnabled,
    bool? autoUpdateEnabled,
  }) {
    return DeviceSettingsModel(
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
    );
  }

  static DeviceSettingsModel create() {
    return const DeviceSettingsModel(
      biometricLockEnabled: false,
      autoUpdateEnabled: true,
    );
  }
}
