import '../../../../core/models/local_reminder.dart';

/// Operations for the notifications feature.
///
/// The three kinds of notifications are completely independent:
/// - Firebase (FCM): handled by [NotificationService] itself.
/// - Public daily reminders: read-only, seeded once, always re-synced at
///   startup, never touched by personal CRUD.
/// - Personal reminders: full CRUD, __only__ touching the personal namespace.
abstract class NotificationRepo {
  // ── Firebase ──────────────────────────────────────────────────────────────
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

  // ── Public daily reminders (read-only, for everyone) ──────────────────────
  /// Loads the public daily list. Seeds the provided [defaults] on first run
  /// and always re-syncs public schedules. The client cannot modify these.
  Future<List<LocalReminder>> loadPublicReminders({
    required List<LocalReminder> defaults,
  });

  // ── Personal reminders (full user CRUD) ───────────────────────────────────
  /// Loads the user's personal reminders and re-syncs their schedules.
  Future<List<LocalReminder>> loadPersonalReminders();

  /// Persists the whole personal list and re-syncs schedules. Only personal
  /// notification ids are touched; public/Firebase are never affected.
  Future<void> persistPersonalReminders(List<LocalReminder> reminders);
}