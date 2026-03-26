import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/reminder.dart';
import '../models/recurrence_rule.dart';
import 'api_service.dart';
import 'notification_time_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  /// время уведомлений
  TimeOfDay _globalTime = const TimeOfDay(hour: 9, minute: 0);

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    _globalTime = await NotificationTimeService.getNotificationTime();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);

    // Создаем канал для Android 8+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel',
      'Напоминания',
      description: 'Канал для напоминаний о вещах',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// обновить глобальное время уведомлений
  Future<void> updateGlobalTime(TimeOfDay newTime) async {
    _globalTime = newTime;
    await NotificationTimeService.setNotificationTime(newTime);

    // перепланировать все напоминания
    final reminders = await ApiService().getReminders();
    await rescheduleAll(reminders);
  }

  /// получить текущее глобальное время
  TimeOfDay getGlobalTime() => _globalTime;

  /// метод для планирования напоминания
  Future<bool> scheduleReminder(Reminder reminder) async {
    try {
      if (!reminder.isActive) {
        print('Напоминание ${reminder.id} ${reminder.title} неактивно, пропускаем');
        return false;
      }
      if (reminder.reminderDate == null  && reminder.recurrenceRule == null) {
        print('Напоминание ${reminder.id} ${reminder.title} не имеет даты и правила повторения, пропускаем');
        return false;
      }

      // если есть правило повторения - планируем с повторением
      if (reminder.recurrenceRule != null) {
        return await _scheduleRecurring(reminder);
      }

      // иначе разовое напоминание
      if (reminder.reminderDate == null) {
        print('Разовое напоминание ${reminder.id} не имеет даты, пропускаем');
        return false;
      }

      // проверяем, что дата в будущем
      final now = DateTime.now();
      if (reminder.reminderDate!.isBefore(now)) {
        print('Дата напоминания ${reminder.id} уже прошла, пропускаем');
        await _deactivateReminder(reminder.id);
        return false;
      }

      return await _scheduleOneTime(reminder);
    } catch (e) {
      print('Ошибка планирования напоминания ${reminder.id}: $e');
      return false;
    }
  }

  /// разовое напоминание
  Future<bool> _scheduleOneTime(Reminder reminder) async {
    try {
      final scheduledDate = tz.TZDateTime.from(
        reminder.reminderDate!,
        tz.local,
      );

      // проверяем, что дата в будущем
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Дата уже прошла, пропускаем');
        await _deactivateReminder(reminder.id);
        return false;
      }

      await _plugin.zonedSchedule(
        reminder.id,
        reminder.title,
        reminder.message ?? 'Напоминание',
        scheduledDate,
        _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('Запланировано разовое напоминание ${reminder.id} на $scheduledDate');
      return true;
    } catch (e) {
      print('Ошибка планирования разового напоминания: $e');
      return false;
    }
  }

  /// периодическое напоминание по правилу
  Future<bool> _scheduleRecurring(Reminder reminder) async {
    try {
      final nextDate = _calculateNextDate(reminder);
      if (nextDate == null) {
        print('Не удалось рассчитать следующую дату для напоминания ${reminder.id}');
        return false;
      }

      final scheduledDate = tz.TZDateTime.from(nextDate, tz.local);

      // Проверяем, что дата в будущем
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Рассчитанная дата уже прошла для напоминания ${reminder.id}');
        return false;
      }

      await _plugin.zonedSchedule(
        reminder.id,
        reminder.title,
        reminder.message ?? 'Напоминание',
        scheduledDate,
        _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('Запланировано повторяющееся напоминание ${reminder.id} на $scheduledDate');
      return true;
    } catch (e) {
      print('Ошибка планирования повторяющегося напоминания: $e');
      return false;
    }
  }

  /// рассчитывает следующую дату для повторяющегося напоминания
  DateTime? _calculateNextDate(Reminder reminder) {
    final now = DateTime.now();
    final rule = reminder.recurrenceRule!;

    final reminderHour = _globalTime.hour;
    final reminderMinute = _globalTime.minute;

    switch (rule.frequency) {
    // ЕЖЕДНЕВНО
      case Frequency.daily:
        var nextDate = DateTime(
          now.year,
          now.month,
          now.day,
          reminderHour,
          reminderMinute,
        );
        if (nextDate.isBefore(now)) {
          nextDate = nextDate.add(Duration(days: rule.intervalValue));
        }
        return nextDate;

    // ЕЖЕНЕДЕЛЬНО
      case Frequency.weekly:
        var nextDate = DateTime(
          now.year,
          now.month,
          now.day,
          reminderHour,
          reminderMinute,
        );

        final activeDays = rule.activeWeekDays;
        if (activeDays.isEmpty) {
          print('Нет активных дней недели');
          return null;
        }

        // ищем следующий подходящий день недели
        while (!activeDays.contains(nextDate.weekday)) {
          nextDate = nextDate.add(const Duration(days: 1));
        }

        if (nextDate.isBefore(now)) {
          nextDate = nextDate.add(Duration(days: 7 * rule.intervalValue));
        }
        return nextDate;

    // ЕЖЕМЕСЯЧНО
      case Frequency.monthly:
        if (rule.monthDay == null) {
          print('Не указан день');
          return null;
        }

        var nextDate = DateTime(
          now.year,
          now.month,
          rule.monthDay!,
          reminderHour,
          reminderMinute,
        );

        if (nextDate.isBefore(now)) {
          nextDate = DateTime(
            now.year,
            now.month + rule.intervalValue,
            rule.monthDay!,
            reminderHour,
            reminderMinute,
          );
        }
        return nextDate;

      //   СЕЗОННО
      case Frequency.seasonally:
        var nextDate = DateTime(
          now.year,
          now.month,
          1,
          reminderHour,
          reminderMinute,
        );

        // Если дата уже прошла, добавляем 3 месяца
        if (nextDate.isBefore(now)) {
          nextDate = DateTime(
            now.year,
            now.month + 3,
            1,
            reminderHour,
            reminderMinute,
          );
        }

        // Если после добавления 3 месяцев вышли за границы года
        if (nextDate.month > 12) {
          nextDate = DateTime(
            now.year + 1,
            nextDate.month - 12,
            1,
            reminderHour,
            reminderMinute,
          );
        }
        return nextDate;

    // ЕЖЕГОДНО
      case Frequency.yearly:
        if (rule.yearMonth == null || rule.yearDay == null) {
          print('Не указаны месяц и день года');
          return null;
        }

          var nextDate = DateTime(
            now.year,
            rule.yearMonth!,
            rule.yearDay!,
            reminderHour,
            reminderMinute,
          );

          if (nextDate.isBefore(now)) {
            nextDate = DateTime(
              now.year + rule.intervalValue,
              rule.yearMonth!,
              rule.yearDay!,
              reminderHour,
              reminderMinute,
            );
          }
          return nextDate;
    }
  }

  /// настройки уведомления
  NotificationDetails _buildNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel',
        'Напоминания',
        channelDescription: 'Канал для напоминаний',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }

  // вспомогательные методы

  Future<void> checkPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    print('============Запланировано уведомлений: ${pending.length}');
    for (var p in pending) {
      print('  ID: ${p.id}, Title: ${p.title}');
    }
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> rescheduleAll(List<Reminder> reminders) async {
    await cancelAll();
    for (var reminder in reminders) {
      await scheduleReminder(reminder);
    }
  }

  Future<bool> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final result = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return result ?? false;
  }

  Future<bool> areNotificationsEnabled() async {
    final enabled = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return enabled ?? false;
  }

  Future<void> _deactivateReminder(int id) async {
    try {
      // получаем напоминание из бд
      final reminders = await ApiService().getReminders();
      final reminder = reminders.firstWhere((r) => r.id == id);

      if (reminder.isActive) {
        // Деактивируем на сервере
        await ApiService().updateReminderActive(id, false);
        print('Напоминание $id деактивировано (просрочено)');
      }
    } catch (e) {
      print('Ошибка деактивации напоминания $id: $e');
    }
  }
}