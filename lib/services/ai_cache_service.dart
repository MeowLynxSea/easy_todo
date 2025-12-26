import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:easy_todo/models/todo_model.dart';

class AICacheService {
  static const String _cacheBoxName = 'ai_cache';
  static const Duration _defaultCacheDuration = Duration(hours: 24);
  static const Duration _incentiveCacheDuration = Duration(minutes: 30);

  Box<String>? _cacheBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _cacheBox = await Hive.openBox<String>(_cacheBoxName);
      await _cleanupExpiredCache();
      await clearPreviousDayMotivationalMessages();
      _isInitialized = true;
      // debugPrint('AICacheService: Initialized successfully');
    } catch (e) {
      debugPrint('AICacheService: Failed to initialize cache: $e');
      _isInitialized = false;
    }
  }

  bool get _isBoxReady => _isInitialized && _cacheBox != null;
  bool get isInitialized => _isInitialized;

  Future<void> _cleanupExpiredCache() async {
    if (!_isBoxReady) return;

    try {
      final now = DateTime.now();
      final keysToDelete = <String>[];

      for (final key in _cacheBox!.keys) {
        final cachedData = _getCachedDataWithTimestamp(_cacheBox!.get(key));
        if (cachedData != null) {
          final timestampString = cachedData['timestamp'] as String;
          final timestamp = DateTime.parse(timestampString);
          if (now.difference(timestamp) > _defaultCacheDuration) {
            keysToDelete.add(key);
          }
        }
      }

      if (keysToDelete.isNotEmpty) {
        await _cacheBox!.deleteAll(keysToDelete);
      }
    } catch (e) {
      // debugPrint('AICacheService: Error cleaning up cache: $e');
    }
  }

  Map<String, dynamic>? _getCachedDataWithTimestamp(String? cachedString) {
    if (cachedString == null) return null;

    try {
      return jsonDecode(cachedString) as Map<String, dynamic>;
    } catch (e) {
      // debugPrint('AICacheService: Error parsing cached data: $e');
      return null;
    }
  }

  Future<T?> get<T>(String key) async {
    if (!_isBoxReady) {
      // debugPrint('AICacheService: Cache not initialized, returning null');
      return null;
    }

    try {
      final cachedString = _cacheBox!.get(key);
      final cachedData = _getCachedDataWithTimestamp(cachedString);

      if (cachedData == null) return null;

      final timestampString = cachedData['timestamp'] as String;
      final timestamp = DateTime.parse(timestampString);
      if (DateTime.now().difference(timestamp) > _defaultCacheDuration) {
        await _cacheBox!.delete(key);
        return null;
      }

      return cachedData['data'] as T;
    } catch (e) {
      // debugPrint('AICacheService: Error getting cached data: $e');
      return null;
    }
  }

  Future<void> set<T>(String key, T data) async {
    if (!_isBoxReady) {
      // debugPrint('AICacheService: Cache not initialized, cannot set data');
      return;
    }

    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _cacheBox!.put(key, jsonEncode(cacheData));
    } catch (e) {
      // debugPrint('AICacheService: Error setting cached data: $e');
    }
  }

  Future<void> remove(String key) async {
    if (!_isBoxReady) return;

    try {
      await _cacheBox!.delete(key);
    } catch (e) {
      // debugPrint('AICacheService: Error removing cached data: $e');
    }
  }

  Future<void> clear() async {
    if (!_isBoxReady) return;

    try {
      await _cacheBox!.clear();
    } catch (e) {
      // debugPrint('AICacheService: Error clearing cache: $e');
    }
  }

  Future<void> clearIncentiveMessages() async {
    if (!_isBoxReady) return;

    try {
      final keysToDelete = <String>[];
      for (final key in _cacheBox!.keys) {
        if (key.startsWith('incentive_')) {
          keysToDelete.add(key);
        }
      }
      if (keysToDelete.isNotEmpty) {
        await _cacheBox!.deleteAll(keysToDelete);
      }
    } catch (e) {
      // debugPrint('AICacheService: Error clearing incentive messages: $e');
    }
  }

  Future<void> close() async {
    if (!_isBoxReady) return;

    try {
      await _cacheBox!.close();
      _cacheBox = null;
      _isInitialized = false;
    } catch (e) {
      // debugPrint('AICacheService: Error closing cache: $e');
    }
  }

  // Generate cache keys for different AI operations
  static String getCategorizationKey(
    String title,
    String description,
    String language,
  ) {
    return 'categorization_${title.hashCode}_${description.hashCode}_$language';
  }

  static String getPriorityKey(
    String title,
    String description,
    String language, {
    bool hasDeadline = false,
  }) {
    return 'priority_${title.hashCode}_${description.hashCode}_$language${hasDeadline ? '_deadline' : ''}';
  }

  static String getIncentiveMessageKey(double completionRate, String language) {
    return 'incentive_${completionRate.round()}_$language';
  }

  Future<T?> getIncentiveMessage<T>(String key) async {
    if (!_isBoxReady) {
      return null;
    }

    try {
      final cachedString = _cacheBox!.get(key);
      final cachedData = _getCachedDataWithTimestamp(cachedString);

      if (cachedData == null) return null;

      final timestampString = cachedData['timestamp'] as String;
      final timestamp = DateTime.parse(timestampString);
      if (DateTime.now().difference(timestamp) > _incentiveCacheDuration) {
        await _cacheBox!.delete(key);
        return null;
      }

      return cachedData['data'] as T;
    } catch (e) {
      return null;
    }
  }

  Future<void> setIncentiveMessage<T>(String key, T data) async {
    if (!_isBoxReady) {
      return;
    }

    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _cacheBox!.put(key, jsonEncode(cacheData));
    } catch (e) {
      // debugPrint('AICacheService: Error setting incentive message: $e');
    }
  }

  static String getMotivationKey(
    String name,
    String description,
    dynamic value,
    String language,
  ) {
    final now = DateTime.now();
    final dateString = '${now.year}-${now.month}-${now.day}';
    return 'motivation_${name.hashCode}_${description.hashCode}_${value}_${language}_$dateString';
  }

  static String getNotificationKey(
    String title,
    String category,
    int priority,
    String language, {
    DateTime? reminderTime,
  }) {
    // 添加提醒时间因素到缓存键
    final timeHash = reminderTime != null
        ? '${reminderTime.hour}_${reminderTime.minute.toString().padLeft(2, '0')}'
        : 'no_reminder';
    return 'notification_${title.hashCode}_$category${priority}_${language}_$timeHash';
  }

  // Backward compatibility method (without reminder time parameter)
  static String getNotificationKeyLegacy(
    String title,
    String category,
    int priority,
    String language,
  ) {
    return 'notification_${title.hashCode}_$category${priority}_$language';
  }

  static String getCompletionKey(int completed, int total, String language) {
    return 'completion_${completed}_${total}_$language';
  }

  // Clear AI cache for a specific todo (used when reminder changes)
  Future<void> clearTodoAICache(TodoModel todo, String language) async {
    if (!_isBoxReady) return;

    try {
      final keysToDelete = <String>[];

      // Generate possible cache keys for this todo
      final categorizationKey = getCategorizationKey(
        todo.title,
        todo.description ?? '',
        language,
      );
      final priorityKeyWithDeadline = getPriorityKey(
        todo.title,
        todo.description ?? '',
        language,
        hasDeadline: true,
      );
      final priorityKeyWithoutDeadline = getPriorityKey(
        todo.title,
        todo.description ?? '',
        language,
        hasDeadline: false,
      );

      // Generate all possible notification cache keys (with different reminder times)
      final notificationKeys = <String>[];

      // Current reminder time key
      if (todo.reminderTime != null) {
        final currentNotificationKey = getNotificationKey(
          todo.title,
          todo.aiCategory ?? '',
          todo.aiPriority,
          language,
          reminderTime: todo.reminderTime,
        );
        notificationKeys.add(currentNotificationKey);
      }

      // No reminder time key
      final noReminderKey = getNotificationKey(
        todo.title,
        todo.aiCategory ?? '',
        todo.aiPriority,
        language,
        reminderTime: null,
      );
      notificationKeys.add(noReminderKey);

      // Also clear any old notification cache keys that might exist (without reminder time parameter)
      final oldNotificationKey = getNotificationKey(
        todo.title,
        todo.aiCategory ?? '',
        todo.aiPriority,
        language,
      );
      notificationKeys.add(oldNotificationKey);

      // Add keys to deletion list
      keysToDelete.addAll([
        categorizationKey,
        priorityKeyWithDeadline,
        priorityKeyWithoutDeadline,
        ...notificationKeys,
      ]);

      // Also clear any cache keys that might contain partial matches
      for (final key in _cacheBox!.keys) {
        final keyString = key.toString();
        // Check if this key contains the todo title hash (indicating it's related to this todo)
        if (keyString.contains('${todo.title.hashCode}')) {
          keysToDelete.add(keyString);
        }
      }

      // Delete all related cache entries
      if (keysToDelete.isNotEmpty) {
        await _cacheBox!.deleteAll(keysToDelete);
      }
    } catch (e) {
      debugPrint('AICacheService: Error clearing todo AI cache: $e');
    }
  }

  // Clear motivational message cache (when language changes or settings are toggled)
  Future<void> clearMotivationalMessages() async {
    if (!_isBoxReady) return;

    try {
      final keysToDelete = <String>[];
      for (final key in _cacheBox!.keys) {
        if (key.startsWith('motivation_') ||
            key.startsWith('incentive_') ||
            key.startsWith('completion_')) {
          keysToDelete.add(key);
        }
      }

      if (keysToDelete.isNotEmpty) {
        await _cacheBox!.deleteAll(keysToDelete);
      }
    } catch (e) {
      debugPrint(
        'AICacheService: Error clearing motivational messages cache: $e',
      );
    }
  }

  // Clear motivational message cache for previous days
  Future<void> clearPreviousDayMotivationalMessages() async {
    if (!_isBoxReady) return;

    try {
      final now = DateTime.now();
      final todayString = '${now.year}-${now.month}-${now.day}';
      final keysToDelete = <String>[];

      for (final key in _cacheBox!.keys) {
        if (key.startsWith('motivation_')) {
          final parts = key.split('_');
          if (parts.length >= 6) {
            final dateString = parts.last;
            if (dateString != todayString) {
              keysToDelete.add(key);
            }
          }
        }
      }

      if (keysToDelete.isNotEmpty) {
        await _cacheBox!.deleteAll(keysToDelete);
      }
    } catch (e) {
      debugPrint(
        'AICacheService: Error clearing previous day motivational messages cache: $e',
      );
    }
  }

  // Clear all AI cache (for debugging or when settings change)
  Future<void> clearAllAICache() async {
    if (!_isBoxReady) return;

    try {
      await _cacheBox!.clear();
    } catch (e) {
      debugPrint('AICacheService: Error clearing all AI cache: $e');
    }
  }
}
