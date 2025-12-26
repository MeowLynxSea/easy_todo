import 'package:flutter/material.dart';
import 'package:easy_todo/services/notification_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // 简化的初始化，只重新安排通知
      await rescheduleAllNotifications();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing simplified background service: $e');
    }
  }

  Future<void> rescheduleAllNotifications() async {
    try {
      // Only reschedule if needed to avoid unnecessary operations
      if (_notificationService.settings?.notificationsEnabled == true) {
        await _notificationService.rescheduleAllReminders();
      } else {}
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
    }
  }

  void reset() {
    _isInitialized = false;
  }
}
