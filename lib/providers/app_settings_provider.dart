import 'package:flutter/foundation.dart';
import 'package:easy_todo/models/app_settings_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/biometric_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final BiometricService _biometricService = BiometricService.instance;

  AppSettingsModel _settings = AppSettingsModel.create();
  bool _isLoading = false;

  AppSettingsProvider() {
    _loadSettings();
  }

  AppSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  bool get biometricLockEnabled => _settings.biometricLockEnabled;
  bool get autoUpdateEnabled => _settings.autoUpdateEnabled;
  String get viewMode => _settings.viewMode;
  bool get viewOpenInNewPage => _settings.viewOpenInNewPage;
  String get historyViewMode => _settings.historyViewMode;
  int get scheduleDayStartMinutes => _settings.scheduleDayStartMinutes;
  int get scheduleDayEndMinutes => _settings.scheduleDayEndMinutes;
  double get scheduleLabelTextScale => _settings.scheduleLabelTextScale;
  List<int> get scheduleVisibleWeekdays =>
      List<int>.unmodifiable(_settings.scheduleVisibleWeekdays);

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    final settingsBox = _hiveService.appSettingsBox;
    try {
      final savedSettings = settingsBox.get('appSettings');

      if (savedSettings != null) {
        _settings = savedSettings;
      } else {
        // 如果没有保存的设置，创建默认设置
        _settings = AppSettingsModel.create();
        await settingsBox.put('appSettings', _settings);
      }

      if (kIsWeb) {
        final needsDisable =
            _settings.autoUpdateEnabled || _settings.biometricLockEnabled;
        if (needsDisable) {
          _settings = _settings.copyWith(
            autoUpdateEnabled: false,
            biometricLockEnabled: false,
          );
          await settingsBox.put('appSettings', _settings);
        }
      }
    } catch (e) {
      debugPrint('Error loading app settings: $e');
      // If there's an error loading settings (e.g., format mismatch), create default settings
      _settings = AppSettingsModel.create();
      try {
        await settingsBox.put('appSettings', _settings);
      } catch (saveError) {
        debugPrint('Error saving default app settings: $saveError');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settingsBox = _hiveService.appSettingsBox;
      await settingsBox.put('appSettings', _settings);
    } catch (e) {
      debugPrint('Error saving app settings: $e');
    }
  }

  /// 设置指纹锁
  Future<bool> setFingerprintLock(
    bool enabled, {
    String? enableReason,
    String? disableReason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (enabled) {
        // 启用指纹锁，需要先验证身份
        final isAvailable = await _biometricService.isFingerprintAvailable();
        if (!isAvailable) {
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final authenticated = await _biometricService
            .authenticateWithFingerprint(reason: enableReason ?? '请验证身份以启用指纹锁');

        if (!authenticated) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // 禁用指纹锁，需要先验证身份
        final isAvailable = await _biometricService.isFingerprintAvailable();
        if (isAvailable) {
          final authenticated = await _biometricService
              .authenticateWithFingerprint(
                reason: disableReason ?? '请验证身份以禁用指纹锁',
              );

          if (!authenticated) {
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      }

      // 更新设置
      _settings = _settings.copyWith(biometricLockEnabled: enabled);
      await _saveSettings();

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

  /// 验证指纹（用于应用启动时的验证）
  Future<bool> authenticateForAppAccess({String? reason}) async {
    if (!_settings.biometricLockEnabled) {
      return true; // 如果未启用指纹锁，直接允许访问
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
    _settings = _settings.copyWith(autoUpdateEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }

  /// 设置视图模式
  Future<void> setViewMode(String mode) async {
    _settings = _settings.copyWith(viewMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  /// 设置视图在新页面打开
  Future<void> setViewOpenInNewPage(bool enabled) async {
    _settings = _settings.copyWith(viewOpenInNewPage: enabled);
    await _saveSettings();
    notifyListeners();
  }

  /// 设置历史视图模式
  Future<void> setHistoryViewMode(String mode) async {
    _settings = _settings.copyWith(historyViewMode: mode);
    await _saveSettings();
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

    _settings = _settings.copyWith(
      scheduleDayStartMinutes: normalized.startMinutes,
      scheduleDayEndMinutes: normalized.endMinutes,
    );
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setScheduleVisibleWeekdays(List<int> weekdays) async {
    final normalized = _normalizeScheduleWeekdays(weekdays);
    if (normalized.isEmpty) return;

    _settings = _settings.copyWith(scheduleVisibleWeekdays: normalized);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> resetScheduleLayoutSettings() async {
    _settings = _settings.copyWith(
      scheduleDayStartMinutes: 0,
      scheduleDayEndMinutes: 1440,
      scheduleVisibleWeekdays: const <int>[1, 2, 3, 4, 5, 6, 7],
      scheduleLabelTextScale: 1.0,
    );
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setScheduleLabelTextScale(double scale) async {
    final normalized = scale.clamp(0.8, 1.4).toDouble();
    _settings = _settings.copyWith(scheduleLabelTextScale: normalized);
    await _saveSettings();
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
