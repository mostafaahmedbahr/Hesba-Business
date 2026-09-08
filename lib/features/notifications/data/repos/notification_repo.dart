import '../../../../core/models/local_reminder.dart';

/// Operations for the notifications feature.
abstract class NotificationRepo {
  /// Requests notification permission from the OS.
  Future<bool> requestPermissions();

  /// Requests permission + fetches & stores the FCM token.
  Future<bool> setupFcm();

  /// Returns the current FCM registration token for this device.
  Future<String?> getFcmToken();

  /// Shows one immediate local notification.
  Future<void> sendTestNotification({
    required String title,
    required String body,
  });

  /// Loads the local reminders list from storage. On first run it seeds the
  /// provided [defaults] (the built-in reminders for everyone) and schedules
  /// them. Always re-syncs schedules so they stay correct after reboots.
  Future<List<LocalReminder>> loadReminders({
    required List<LocalReminder> defaults,
  });

  /// Persists the whole reminders list and re-schedules the enabled ones.
  Future<void> persistReminders(List<LocalReminder> reminders);
}