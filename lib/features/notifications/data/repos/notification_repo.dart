/// Operations for the notifications feature.
abstract class NotificationRepo {
  /// Whether the hourly reminder is enabled.
  Future<bool> getRemindersEnabled();

  /// Persists the hourly reminder toggle.
  Future<void> setRemindersEnabled(bool enabled);

  /// Requests notification permission from the OS.
  Future<bool> requestPermissions();

  /// Requests permission + fetches & stores the FCM token.
  Future<bool> setupFcm();

  /// Returns the current FCM registration token for this device.
  Future<String?> getFcmToken();

  /// Schedules the repeating hourly reminder.
  Future<void> scheduleReminder({
    required String title,
    required String body,
  });

  /// Cancels the scheduled hourly reminder.
  Future<void> cancelReminder();

  /// Shows one immediate local notification.
  Future<void> sendTestNotification({
    required String title,
    required String body,
  });
}