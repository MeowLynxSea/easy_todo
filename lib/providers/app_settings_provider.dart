import 'package:flutter/foundation.dart';
import 'package:easy_todo/models/device_settings_model.dart';
import 'package:easy_todo/models/user_preferences_model.dart';
import 'package:easy_todo/models/schedule_color_group.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/biometric_service.dart';
import 'package:easy_todo/services/repositories/user_preferences_repository.dart';
import 'package:easy_todo/utils/random_id.dart';
import 'package:easy_todo/utils/schedule_color_group_presets.dart';

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}

class AppSettingsProvider extends ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final BiometricService _biometricService = BiometricService.instance;
  final UserPreferencesRepository _preferencesRepository =
      UserPreferencesRepository();

  DeviceSettingsModel _deviceSettings = DeviceSettingsModel.create();
  UserPreferencesModel _preferences = UserPreferencesModel.create();
  bool _isLoading = false;

  AppSettingsProvider() {
    _loadSettings();
  }

  DeviceSettingsModel get deviceSettings => _deviceSettings;
  UserPreferencesModel get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get biometricLockEnabled => _deviceSettings.biometricLockEnabled;
  bool get autoUpdateEnabled => _deviceSettings.autoUpdateEnabled;
  String get viewMode => _preferences.viewMode;
  bool get viewOpenInNewPage => _preferences.viewOpenInNewPage;
  String get historyViewMode => _preferences.historyViewMode;
  int get scheduleDayStartMinutes => _preferences.scheduleDayStartMinutes;
  int get scheduleDayEndMinutes => _preferences.scheduleDayEndMinutes;
  double get scheduleLabelTextScale => _preferences.scheduleLabelTextScale;
  String get scheduleActiveColorGroupId =>
      _preferences.scheduleActiveColorGroupId;
  List<ScheduleColorGroup> get scheduleCustomColorGroups =>
      List<ScheduleColorGroup>.unmodifiable(
        ScheduleColorGroup.decodeListFromString(
          _preferences.scheduleCustomColorGroupsString,
        ),
      );
  List<ScheduleColorGroup> get schedulePresetColorGroups =>
      List<ScheduleColorGroup>.unmodifiable(ScheduleColorGroupPresets.all);

  ScheduleColorGroup get scheduleEffectiveActiveColorGroup {
    final id = _preferences.scheduleActiveColorGroupId;
    final custom =
        scheduleCustomColorGroups.where((e) => e.id == id).firstOrNull;
    return custom ??
        ScheduleColorGroupPresets.byId(id) ??
        ScheduleColorGroupPresets.warmCool;
  }

  List<int> get scheduleVisibleWeekdays =>
      List<int>.unmodifiable(_preferences.scheduleVisibleWeekdays);

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    final deviceBox = _hiveService.deviceSettingsBox;
    try {
      final savedDevice = deviceBox.get('deviceSettings');

      if (savedDevice != null) {
        _deviceSettings = savedDevice;
      }

      var preferencesChanged = false;
      _preferences = await _preferencesRepository.load();

      if (savedDevice == null) {
        // Legacy migration from AppSettingsModel (pre-sync split).
        final legacyBox = _hiveService.appSettingsBox;
        final legacy = legacyBox.get('appSettings');
        if (legacy != null) {
          if (savedDevice == null) {
            _deviceSettings = DeviceSettingsModel(
              biometricLockEnabled: legacy.biometricLockEnabled,
              autoUpdateEnabled: legacy.autoUpdateEnabled,
            );
          }

          final defaultPrefs = UserPreferencesModel.create();
          if (_preferences.viewMode == defaultPrefs.viewMode &&
              _preferences.viewOpenInNewPage ==
                  defaultPrefs.viewOpenInNewPage &&
              _preferences.historyViewMode == defaultPrefs.historyViewMode &&
              _preferences.scheduleDayStartMinutes ==
                  defaultPrefs.scheduleDayStartMinutes &&
              _preferences.scheduleDayEndMinutes ==
                  defaultPrefs.scheduleDayEndMinutes &&
              _preferences.scheduleLabelTextScale ==
                  defaultPrefs.scheduleLabelTextScale &&
              listEquals(
                _preferences.scheduleVisibleWeekdays,
                defaultPrefs.scheduleVisibleWeekdays,
              ) &&
              _preferences.scheduleActiveColorGroupId ==
                  defaultPrefs.scheduleActiveColorGroupId &&
              _preferences.scheduleCustomColorGroupsString ==
                  defaultPrefs.scheduleCustomColorGroupsString) {
            _preferences = UserPreferencesModel(
              languageCode: _preferences.languageCode,
              themeModeIndex: _preferences.themeModeIndex,
              themeColorsString: _preferences.themeColorsString,
              customThemeColorsString: _preferences.customThemeColorsString,
              statusFilterIndex: _preferences.statusFilterIndex,
              timeFilterIndex: _preferences.timeFilterIndex,
              sortOrderIndex: _preferences.sortOrderIndex,
              selectedCategories: _preferences.selectedCategories,
              viewMode: legacy.viewMode,
              viewOpenInNewPage: legacy.viewOpenInNewPage,
              historyViewMode: legacy.historyViewMode,
              scheduleDayStartMinutes: legacy.scheduleDayStartMinutes,
              scheduleDayEndMinutes: legacy.scheduleDayEndMinutes,
              scheduleVisibleWeekdays: legacy.scheduleVisibleWeekdays,
              scheduleLabelTextScale: legacy.scheduleLabelTextScale,
              scheduleActiveColorGroupId:
                  defaultPrefs.scheduleActiveColorGroupId,
              scheduleCustomColorGroupsString:
                  defaultPrefs.scheduleCustomColorGroupsString,
            );
            preferencesChanged = true;
          }
        }
      }

      final isDesktop =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux);

      if (kIsWeb || isDesktop) {
        final needsDisableAutoUpdate = _deviceSettings.autoUpdateEnabled;
        final needsDisableBiometric =
            kIsWeb && _deviceSettings.biometricLockEnabled;
        if (needsDisableAutoUpdate || needsDisableBiometric) {
          _deviceSettings = _deviceSettings.copyWith(
            autoUpdateEnabled: false,
            biometricLockEnabled: kIsWeb ? false : null,
          );
        }
      }

      await deviceBox.put('deviceSettings', _deviceSettings);
      if (preferencesChanged) {
        await _preferencesRepository.save(_preferences);
      }
    } catch (e) {
      debugPrint('Error loading app settings: $e');
      _deviceSettings = DeviceSettingsModel.create();
      _preferences = UserPreferencesModel.create();
      try {
        await deviceBox.put('deviceSettings', _deviceSettings);
        await _preferencesRepository.save(_preferences);
      } catch (saveError) {
        debugPrint('Error saving default app settings: $saveError');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadFromStorage() async {
    await _loadSettings();
  }

  Future<void> reloadFromHiveReadOnly() async {
    final deviceBox = _hiveService.deviceSettingsBox;
    final prefsBox = _hiveService.userPreferencesBox;

    final savedDevice = deviceBox.get('deviceSettings');
    if (savedDevice != null) {
      _deviceSettings = savedDevice;
    } else {
      _deviceSettings = DeviceSettingsModel.create();
    }

    final prefs =
        prefsBox.get(UserPreferencesRepository.hiveKey) ??
        UserPreferencesModel.create();
    _preferences = prefs;

    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    if (kIsWeb || isDesktop) {
      final needsDisableAutoUpdate = _deviceSettings.autoUpdateEnabled;
      final needsDisableBiometric =
          kIsWeb && _deviceSettings.biometricLockEnabled;
      if (needsDisableAutoUpdate || needsDisableBiometric) {
        _deviceSettings = _deviceSettings.copyWith(
          autoUpdateEnabled: false,
          biometricLockEnabled: kIsWeb ? false : null,
        );
      }
    }

    notifyListeners();
  }

  Future<void> _saveDeviceSettings() async {
    try {
      final deviceBox = _hiveService.deviceSettingsBox;
      await deviceBox.put('deviceSettings', _deviceSettings);
    } catch (e) {
      debugPrint('Error saving app settings: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _preferencesRepository.save(_preferences);
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
    }
  }

  /// 设置应用锁（设备认证：PIN/指纹/人脸等）
  Future<bool> setFingerprintLock(
    bool enabled, {
    String? enableReason,
    String? disableReason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (enabled) {
        // 启用应用锁，需要先验证身份
        final isAvailable = await _biometricService.isFingerprintAvailable();
        if (!isAvailable) {
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final authenticated = await _biometricService
            .authenticateWithFingerprint(reason: enableReason ?? '请验证身份以启用应用锁');

        if (!authenticated) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // 禁用应用锁，需要先验证身份
        final isAvailable = await _biometricService.isFingerprintAvailable();
        if (isAvailable) {
          final authenticated = await _biometricService
              .authenticateWithFingerprint(
                reason: disableReason ?? '请验证身份以禁用应用锁',
              );

          if (!authenticated) {
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      }

      // 更新设置
      _deviceSettings = _deviceSettings.copyWith(biometricLockEnabled: enabled);
      await _saveDeviceSettings();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting fingerprint lock: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 验证设备认证（用于应用启动时的验证）
  Future<bool> authenticateForAppAccess({String? reason}) async {
    if (!_deviceSettings.biometricLockEnabled) {
      return true; // 如果未启用应用锁，直接允许访问
    }

    try {
      final isAvailable = await _biometricService.isFingerprintAvailable();
      if (!isAvailable) {
        return true; // 如果设备不支持指纹，允许访问
      }

      return await _biometricService.authenticateWithFingerprint(
        reason: reason ?? '请使用指纹验证以访问应用',
      );
    } catch (e) {
      debugPrint('Error authenticating for app access: $e');
      return false;
    }
  }

  /// 验证指纹（用于敏感操作如删除数据）
  Future<bool> authenticateForSensitiveOperation({
    String reason = '请使用生物识别验证您的身份以继续',
  }) async {
    try {
      final isAvailable = await _biometricService.isFingerprintAvailable();
      if (!isAvailable) {
        return true; // 如果设备不支持生物识别，允许操作
      }

      return await _biometricService.authenticateWithFingerprint(
        reason: reason,
      );
    } catch (e) {
      debugPrint('Error authenticating for sensitive operation: $e');
      return false;
    }
  }

  /// 检查指纹是否可用
  Future<bool> isFingerprintAvailable() async {
    return await _biometricService.isFingerprintAvailable();
  }

  /// 获取可用的生物识别类型
  Future<List<String>> getAvailableBiometricTypes() async {
    final types = await _biometricService.getAvailableBiometrics();
    return types.map((type) => type.toString().split('.').last).toList();
  }

  /// 设置自动更新
  Future<void> setAutoUpdate(bool enabled) async {
    _deviceSettings = _deviceSettings.copyWith(autoUpdateEnabled: enabled);
    await _saveDeviceSettings();
    notifyListeners();
  }

  /// 设置视图模式
  Future<void> setViewMode(String mode) async {
    _preferences = _preferences.copyWith(viewMode: mode);
    await _savePreferences();
    notifyListeners();
  }

  /// 设置视图在新页面打开
  Future<void> setViewOpenInNewPage(bool enabled) async {
    _preferences = _preferences.copyWith(viewOpenInNewPage: enabled);
    await _savePreferences();
    notifyListeners();
  }

  /// 设置历史视图模式
  Future<void> setHistoryViewMode(String mode) async {
    _preferences = _preferences.copyWith(historyViewMode: mode);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setScheduleTimeRange({
    required int startMinutes,
    required int endMinutes,
  }) async {
    final normalized = _normalizeScheduleTimeRange(
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );

    _preferences = _preferences.copyWith(
      scheduleDayStartMinutes: normalized.startMinutes,
      scheduleDayEndMinutes: normalized.endMinutes,
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setScheduleVisibleWeekdays(List<int> weekdays) async {
    final normalized = _normalizeScheduleWeekdays(weekdays);
    if (normalized.isEmpty) return;

    _preferences = _preferences.copyWith(scheduleVisibleWeekdays: normalized);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> resetScheduleLayoutSettings() async {
    _preferences = _preferences.copyWith(
      scheduleDayStartMinutes: 0,
      scheduleDayEndMinutes: 1440,
      scheduleVisibleWeekdays: const <int>[1, 2, 3, 4, 5, 6, 7],
      scheduleLabelTextScale: 1.0,
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setScheduleActiveColorGroupId(String groupId) async {
    final normalized = groupId.trim();
    if (normalized.isEmpty) return;
    _preferences =
        _preferences.copyWith(scheduleActiveColorGroupId: normalized);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> createScheduleColorGroup({
    required String name,
    required List<int> incompleteColorsArgb,
    required List<int> completedColorsArgb,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return;

    final group = ScheduleColorGroup(
      id: 'custom:${generateUrlSafeRandomId(byteLength: 12)}',
      name: normalizedName,
      incompleteColorsArgb: List<int>.from(incompleteColorsArgb),
      completedColorsArgb: List<int>.from(completedColorsArgb),
    );

    final next = [...scheduleCustomColorGroups, group];
    _preferences = _preferences.copyWith(
      scheduleCustomColorGroupsString:
          ScheduleColorGroup.encodeListToString(next),
      scheduleActiveColorGroupId: group.id,
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> updateScheduleColorGroup(ScheduleColorGroup group) async {
    final normalizedName = group.name.trim();
    if (group.id.trim().isEmpty || normalizedName.isEmpty) return;

    final existing = scheduleCustomColorGroups;
    final idx = existing.indexWhere((e) => e.id == group.id);
    if (idx < 0) return;

    final next = [...existing];
    next[idx] = group.copyWith(name: normalizedName);
    _preferences = _preferences.copyWith(
      scheduleCustomColorGroupsString:
          ScheduleColorGroup.encodeListToString(next),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> deleteScheduleColorGroup(String groupId) async {
    final id = groupId.trim();
    if (id.isEmpty) return;

    final existing = scheduleCustomColorGroups;
    final next = existing.where((e) => e.id != id).toList(growable: false);

    var activeId = _preferences.scheduleActiveColorGroupId;
    if (activeId == id) {
      activeId = ScheduleColorGroupPresets.warmCool.id;
    }

    _preferences = _preferences.copyWith(
      scheduleCustomColorGroupsString:
          ScheduleColorGroup.encodeListToString(next),
      scheduleActiveColorGroupId: activeId,
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setScheduleLabelTextScale(double scale) async {
    final normalized = scale.clamp(0.8, 1.4).toDouble();
    _preferences = _preferences.copyWith(scheduleLabelTextScale: normalized);
    await _savePreferences();
    notifyListeners();
  }

  _ScheduleTimeRange _normalizeScheduleTimeRange({
    required int startMinutes,
    required int endMinutes,
  }) {
    final start = startMinutes.clamp(0, 1440);
    final end = endMinutes.clamp(0, 1440);

    const minSpanMinutes = 15;

    if (end - start < minSpanMinutes) {
      if (start + minSpanMinutes <= 1440) {
        return _ScheduleTimeRange(
          startMinutes: start,
          endMinutes: start + minSpanMinutes,
        );
      }
      if (end - minSpanMinutes >= 0) {
        return _ScheduleTimeRange(
          startMinutes: end - minSpanMinutes,
          endMinutes: end,
        );
      }

      return const _ScheduleTimeRange(startMinutes: 0, endMinutes: 1440);
    }
    return _ScheduleTimeRange(startMinutes: start, endMinutes: end);
  }

  List<int> _normalizeScheduleWeekdays(List<int> weekdays) {
    final result =
        weekdays
            .where((e) => e >= DateTime.monday && e <= DateTime.sunday)
            .toSet()
            .toList(growable: false)
          ..sort();
    return result;
  }
}

class _ScheduleTimeRange {
  final int startMinutes;
  final int endMinutes;

  const _ScheduleTimeRange({
    required this.startMinutes,
    required this.endMinutes,
  });
}
