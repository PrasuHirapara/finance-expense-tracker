import '../models/app_preferences.dart';
import 'notification_service.dart';

class AppPreferencesEffectsService {
  AppPreferencesEffectsService({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  final NotificationService _notificationService;

  Future<void> apply(AppPreferences preferences) async {
    if (preferences.notificationsEnabled) {
      await _notificationService.scheduleDailyReminders();
    } else {
      await _notificationService.cancelDailyReminders();
    }
  }
}
