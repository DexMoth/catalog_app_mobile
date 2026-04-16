import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationTimeService {
  static const String _key = 'notification_time_hour';
  static const String _keyMinute = 'notification_time_minute';

  static const int defaultHour = 9;
  static const int defaultMinute = 0;

  /// Получить сохраненное время
  static Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_key) ?? defaultHour;
    final minute = prefs.getInt(_keyMinute) ?? defaultMinute;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Сохранить время
  static Future<void> setNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, time.hour);
    await prefs.setInt(_keyMinute, time.minute);
  }
}