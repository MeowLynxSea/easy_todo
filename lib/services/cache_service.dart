import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/services/timezone_service.dart';

class CacheService {
  static const String _todoCacheBox = 'todo_cache';
  static const String _statsCacheBox = 'stats_cache';
  static const Duration _cacheDuration = Duration(hours: 1);

  // 获取本地时间的辅助方法 (使用增强时区服务)
  static DateTime _getLocalDateTime() {
    try {
      final timezoneService = TimezoneService();
      return timezoneService.getCurrentTime();
    } catch (e) {
      debugPrint('CacheService: Enhanced timezone service failed: $e');
      // Fallback to basic timezone handling
      try {
        tz.initializeTimeZones();
        return tz.TZDateTime.now(tz.UTC);
      } catch (fallbackError) {
        debugPrint(
          'CacheService: Fallback timezone initialization failed: $fallbackError',
        );
        return DateTime.now();
      }
    }
  }

  static Future<void> init() async {
    await Hive.openBox(_todoCacheBox);
    await Hive.openBox(_statsCacheBox);
  }

  // Cache todo items
  static Future<void> cacheTodos(List<TodoModel> todos, String cacheKey) async {
    final box = Hive.box(_todoCacheBox);
    final cacheData = {
      'todos': todos.map((todo) => todo.toJson()).toList(),
      'timestamp': _getLocalDateTime().millisecondsSinceEpoch,
    };

    await box.put(cacheKey, jsonEncode(cacheData));
  }

  // Get cached todo items
  static List<TodoModel>? getCachedTodos(String cacheKey) {
    final box = Hive.box(_todoCacheBox);
    final cachedData = box.get(cacheKey);

    if (cachedData == null) return null;

    try {
      final data = jsonDecode(cachedData);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);

      // Check if cache is expired - use local time
      final now = _getLocalDateTime();
      if (now.difference(timestamp) > _cacheDuration) {
        box.delete(cacheKey);
        return null;
      }

      return (data['todos'] as List)
          .map((todoJson) => TodoModel.fromJson(todoJson))
          .toList();
    } catch (e) {
      // Invalid cache data
      box.delete(cacheKey);
      return null;
    }
  }

  // Cache statistics data
  static Future<void> cacheStats(
    StatisticsDataModel stats,
    String cacheKey,
  ) async {
    final box = Hive.box(_statsCacheBox);
    final cacheData = {
      'stats': stats.toJson(),
      'timestamp': _getLocalDateTime().millisecondsSinceEpoch,
    };

    await box.put(cacheKey, jsonEncode(cacheData));
  }

  // Get cached statistics data
  static StatisticsDataModel? getCachedStats(String cacheKey) {
    final box = Hive.box(_statsCacheBox);
    final cachedData = box.get(cacheKey);

    if (cachedData == null) return null;

    try {
      final data = jsonDecode(cachedData);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);

      // Check if cache is expired - use local time
      final now = _getLocalDateTime();
      if (now.difference(timestamp) > _cacheDuration) {
        box.delete(cacheKey);
        return null;
      }

      return StatisticsDataModel.fromJson(data['stats']);
    } catch (e) {
      // Invalid cache data
      box.delete(cacheKey);
      return null;
    }
  }

  // Clear all cache
  static Future<void> clearCache() async {
    final todoBox = Hive.box(_todoCacheBox);
    final statsBox = Hive.box(_statsCacheBox);

    await todoBox.clear();
    await statsBox.clear();
  }

  // Clear specific cache key
  static Future<void> clearCacheKey(String cacheKey) async {
    final todoBox = Hive.box(_todoCacheBox);
    final statsBox = Hive.box(_statsCacheBox);

    await todoBox.delete(cacheKey);
    await statsBox.delete(cacheKey);
  }

  // Clear cache for specific todo ID (for reminder changes)
  static Future<void> clearTodoCache(String todoId) async {
    final todoBox = Hive.box(_todoCacheBox);

    // Clear all cache keys that might contain this todo
    for (final key in todoBox.keys) {
      try {
        final cachedData = jsonDecode(todoBox.get(key));
        if (cachedData['todos'] != null) {
          final todos = cachedData['todos'] as List;
          // Check if this todo exists in the cached list
          final containsTodo = todos.any(
            (todoJson) => todoJson['id'] == todoId,
          );
          if (containsTodo) {
            await todoBox.delete(key);
          }
        }
      } catch (e) {
        // Invalid cache data, delete it
        await todoBox.delete(key);
      }
    }
  }

  // Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    // 确保时区已初始化
    try {
      tz.initializeTimeZones();
    } catch (e) {
      // 时区初始化失败时继续使用默认时区
    }
    final todoBox = Hive.box(_todoCacheBox);
    final statsBox = Hive.box(_statsCacheBox);
    final now = _getLocalDateTime();

    // Clear expired todo cache
    for (final key in todoBox.keys) {
      try {
        final data = jsonDecode(todoBox.get(key));
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          data['timestamp'],
        );

        if (now.difference(timestamp) > _cacheDuration) {
          todoBox.delete(key);
        }
      } catch (e) {
        todoBox.delete(key);
      }
    }

    // Clear expired stats cache
    for (final key in statsBox.keys) {
      try {
        final data = jsonDecode(statsBox.get(key));
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          data['timestamp'],
        );

        if (now.difference(timestamp) > _cacheDuration) {
          statsBox.delete(key);
        }
      } catch (e) {
        statsBox.delete(key);
      }
    }
  }

  // Image caching utility
  static ImageProvider getCachedImage(String imageUrl) {
    return NetworkImage(imageUrl);
  }

  // Memory cache for frequently accessed data
  static final Map<String, _CacheEntry> _memoryCache = {};

  static T? getFromMemoryCache<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null || entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  static void setMemoryCache<T>(
    String key,
    T data, {
    Duration duration = const Duration(minutes: 30),
  }) {
    // 确保时区已初始化
    try {
      tz.initializeTimeZones();
    } catch (e) {
      // 时区初始化失败时继续使用默认时区
    }
    _memoryCache[key] = _CacheEntry(data, _getLocalDateTime().add(duration));
  }

  static void clearMemoryCache() {
    _memoryCache.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry(this.data, this.expiry);

  bool get isExpired {
    try {
      final timezoneService = TimezoneService();
      final now = timezoneService.getCurrentTime();
      return now.isAfter(expiry);
    } catch (e) {
      debugPrint('CacheEntry: Enhanced timezone service failed: $e');
      // Fallback to system time
      return DateTime.now().isAfter(expiry);
    }
  }
}
