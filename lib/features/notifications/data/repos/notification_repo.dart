import '../models/local_reminder.dart';

/// عقد تخزين وجدولة التذكيرات.
abstract class NotificationRepo {
  /// يطلب إذن الإشعارات.
  Future<bool> requestPermissions();

  /// يجهز FCM (إذن + توكن).
  Future<bool> setupFcm();

  /// توكن الجهاز الحالي.
  Future<String?> getFcmToken();

  /// يبعت إشعار فوري (تجربة).
  Future<void> sendTestNotification({
    required String title,
    required String body,
  });

  /// يحمل اليومية الثابتة (ويجدولها).
  Future<List<LocalReminder>> loadPublicReminders({
    required List<LocalReminder> defaults,
  });

  /// يحمل الشخصية (ويجدولها).
  Future<List<LocalReminder>> loadPersonalReminders();

  /// يحفظ الشخصية كلها (ويعيد جدولتها).
  Future<void> persistPersonalReminders(List<LocalReminder> reminders);
}
