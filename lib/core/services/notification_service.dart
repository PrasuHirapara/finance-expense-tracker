import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_settings_repository.dart';

class NotificationService {
  NotificationService(this._reminderSettingsRepository);

  static const int _expenseReminderId = 8001;
  static const int _taskReminderId = 8002;

  final ReminderSettingsRepository _reminderSettingsRepository;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notifications.initialize(settings: initializationSettings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> scheduleDailyReminders() async {
    await initialize();

    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final reminderSettings = await _reminderSettingsRepository.getSettings();

    await _notifications.cancel(id: _expenseReminderId);
    await _notifications.cancel(id: _taskReminderId);

    final androidScheduleMode = await _resolveAndroidScheduleMode();

    await _notifications.zonedSchedule(
      id: _expenseReminderId,
      title: 'Write today\'s expenses',
      body:
          'Add today\'s spending before the day ends. Update income, lent, or borrowed entries if needed.',
      scheduledDate: _nextInstanceOf(reminderSettings.expenseReminder),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_use_expense_reminders',
          'Expense reminders',
          channelDescription: 'Daily reminders to record expenses.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          threadIdentifier: 'daily_use_expense_reminders',
        ),
      ),
      androidScheduleMode: androidScheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _notifications.zonedSchedule(
      id: _taskReminderId,
      title: 'Review today\'s tasks',
      body:
          'Plan your day, review priorities, and mark finished work in Daily Use.',
      scheduledDate: _nextInstanceOf(reminderSettings.taskReminder),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_use_task_reminders',
          'Task reminders',
          channelDescription: 'Daily reminders to review tasks.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          threadIdentifier: 'daily_use_task_reminders',
        ),
      ),
      androidScheduleMode: androidScheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminders() async {
    await initialize();

    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    await _notifications.cancel(id: _expenseReminderId);
    await _notifications.cancel(id: _taskReminderId);
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }

    if (Platform.isAndroid) {
      final androidNotifications = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidNotifications?.requestNotificationsPermission();
      final canScheduleExact =
          await androidNotifications?.canScheduleExactNotifications() ?? false;
      if (!canScheduleExact) {
        await androidNotifications?.requestExactAlarmsPermission();
      }
    }
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final androidNotifications = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    var canScheduleExact =
        await androidNotifications?.canScheduleExactNotifications() ?? false;
    if (!canScheduleExact) {
      canScheduleExact =
          await androidNotifications?.requestExactAlarmsPermission() ?? false;
    }

    if (canScheduleExact) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  tz.TZDateTime _nextInstanceOf(ReminderTime reminderTime) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
