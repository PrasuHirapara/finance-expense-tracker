import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/credentials/data/repositories/credential_repository.dart';
import '../../features/credentials/domain/models/credential_models.dart';
import 'app_settings_repository.dart';
import 'cancellable_task.dart';
import 'credential_crypto_service.dart';
import 'credential_security_service.dart';
import 'reminder_settings_repository.dart';

class NotificationService {
  NotificationService({
    required ReminderSettingsRepository reminderSettingsRepository,
    required AppSettingsRepository appSettingsRepository,
    required CredentialRepository credentialRepository,
    required CredentialCryptoService credentialCryptoService,
    required CredentialSecurityService credentialSecurityService,
  }) : _reminderSettingsRepository = reminderSettingsRepository,
       _appSettingsRepository = appSettingsRepository,
       _credentialRepository = credentialRepository,
       _credentialCryptoService = credentialCryptoService,
       _credentialSecurityService = credentialSecurityService;

  static const int _expenseReminderId = 8001;
  static const int _taskReminderId = 8002;
  static const int _syncReminderId = 8003;
  static const int _credentialExpiryNotificationIdBase = 50000;
  static const int _credentialExpiryHour = 9;
  static const int _credentialExpiryMinute = 0;
  static const String _credentialExpiryPayloadPrefix = 'credential_expiry:';

  final ReminderSettingsRepository _reminderSettingsRepository;
  final AppSettingsRepository _appSettingsRepository;
  final CredentialRepository _credentialRepository;
  final CredentialCryptoService _credentialCryptoService;
  final CredentialSecurityService _credentialSecurityService;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _isCredentialSyncWorkerRunning = false;
  bool _credentialSyncQueued = false;

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
    final appSettings = await _appSettingsRepository.getSettings();

    await _notifications.cancel(id: _expenseReminderId);
    await _notifications.cancel(id: _taskReminderId);
    await _notifications.cancel(id: _syncReminderId);

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

    if (appSettings.cloudSync.enabled) {
      await _notifications.zonedSchedule(
        id: _syncReminderId,
        title: 'Sync your data',
        body: 'Open Daily Use and manually upload a fresh cloud backup today.',
        scheduledDate: _nextInstanceOf(reminderSettings.syncReminder),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_use_sync_reminders',
            'Sync reminders',
            channelDescription:
                'Daily reminders to manually sync your cloud backup.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            threadIdentifier: 'daily_use_sync_reminders',
          ),
        ),
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    requestCredentialExpiryNotificationSync();
  }

  Future<void> cancelDailyReminders() async {
    await initialize();

    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    await _notifications.cancel(id: _expenseReminderId);
    await _notifications.cancel(id: _taskReminderId);
    await _notifications.cancel(id: _syncReminderId);
    await cancelCredentialExpiryNotifications();
  }

  Future<void> syncCredentialExpiryNotifications({
    AppCancellationToken? cancellationToken,
  }) async {
    await initialize();
    cancellationToken?.throwIfCancelled();

    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    await cancelCredentialExpiryNotifications(
      cancellationToken: cancellationToken,
    );

    final appSettings = await _appSettingsRepository.getSettings();
    if (!appSettings.notificationsEnabled ||
        !appSettings.credentialExpiryNotificationEnabled) {
      return;
    }

    final encryptionKey = await _credentialSecurityService.readEncryptionKey();
    if (encryptionKey == null || encryptionKey.trim().isEmpty) {
      return;
    }

    final credentials = await _credentialRepository.loadCredentials();
    if (credentials.isEmpty) {
      return;
    }

    cancellationToken?.throwIfCancelled();
    final androidScheduleMode = await _resolveAndroidScheduleMode();
    final credentialExpiries =
        <({CredentialRecord credential, DateTime? expiryDate})>[];

    for (var index = 0; index < credentials.length; index++) {
      if (index % 8 == 0) {
        await cancellableUiYield(cancellationToken);
      } else {
        cancellationToken?.throwIfCancelled();
      }
      final credential = credentials[index];
      final expiryDate = await _extractExpiryDate(
        credential,
        encryptionKey: encryptionKey,
      );
      credentialExpiries.add((credential: credential, expiryDate: expiryDate));
    }

    for (final entry in credentialExpiries) {
      cancellationToken?.throwIfCancelled();
      final credential = entry.credential;
      final expiryDate = entry.expiryDate;
      if (expiryDate == null) {
        continue;
      }

      final scheduledDate = _credentialExpiryScheduleFor(expiryDate);
      if (scheduledDate == null) {
        continue;
      }

      await _notifications.zonedSchedule(
        id: _credentialExpiryNotificationIdBase + credential.id,
        title: 'Credential Expiry Reminder',
        body: '${credential.title} is expiring tomorrow.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_use_credential_expiry',
            'Credential expiry reminders',
            channelDescription:
                'Notifications for credentials that expire tomorrow.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            threadIdentifier: 'daily_use_credential_expiry',
          ),
        ),
        androidScheduleMode: androidScheduleMode,
        payload: '$_credentialExpiryPayloadPrefix${credential.id}',
      );
    }
  }

  void requestCredentialExpiryNotificationSync() {
    _credentialSyncQueued = true;
    if (_isCredentialSyncWorkerRunning) {
      return;
    }

    _isCredentialSyncWorkerRunning = true;
    unawaited(_drainCredentialSyncQueue());
  }

  Future<void> cancelCredentialExpiryNotifications({
    AppCancellationToken? cancellationToken,
  }) async {
    await initialize();
    cancellationToken?.throwIfCancelled();

    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final pending = await _notifications.pendingNotificationRequests();
    for (final request in pending) {
      cancellationToken?.throwIfCancelled();
      if (request.payload?.startsWith(_credentialExpiryPayloadPrefix) == true) {
        await _notifications.cancel(id: request.id);
      }
    }
  }

  Future<void> _drainCredentialSyncQueue() async {
    try {
      while (_credentialSyncQueued) {
        _credentialSyncQueued = false;
        try {
          await syncCredentialExpiryNotifications();
        } catch (_) {}
      }
    } finally {
      _isCredentialSyncWorkerRunning = false;
    }
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

  Future<DateTime?> _extractExpiryDate(
    CredentialRecord credential, {
    required String encryptionKey,
  }) async {
    try {
      final fields = await _credentialCryptoService.decryptFields(
        record: credential,
        encryptionKey: encryptionKey,
      );
      return extractCredentialExpiryDate(fields);
    } catch (_) {
      return null;
    }
  }

  tz.TZDateTime? _credentialExpiryScheduleFor(DateTime expiryDate) {
    final now = tz.TZDateTime.now(tz.local);
    final expiryLocal = tz.TZDateTime(
      tz.local,
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    if (!expiryLocal.isAfter(now)) {
      return null;
    }

    final dayBeforeExpiry = expiryLocal.subtract(const Duration(days: 1));
    var scheduled = tz.TZDateTime(
      tz.local,
      dayBeforeExpiry.year,
      dayBeforeExpiry.month,
      dayBeforeExpiry.day,
      _credentialExpiryHour,
      _credentialExpiryMinute,
    );

    final tomorrow = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1);
    final isExpiringTomorrow =
        expiryLocal.year == tomorrow.year &&
        expiryLocal.month == tomorrow.month &&
        expiryLocal.day == tomorrow.day;

    if (scheduled.isBefore(now) && isExpiringTomorrow) {
      scheduled = now.add(const Duration(minutes: 1));
    }

    if (!scheduled.isAfter(now)) {
      return null;
    }

    return scheduled;
  }
}
