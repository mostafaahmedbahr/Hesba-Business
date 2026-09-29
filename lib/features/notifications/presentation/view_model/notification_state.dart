import '../../data/models/local_reminder.dart';

/// حالة التذكيرات.
class NotificationState {
  final bool permissionGranted;
  final bool busy;
  final String? fcmToken;

  /// true أثناء أول تحميل (الشاشة تعرض لودر).
  final bool isLoading;

  /// الثابتة (عرض فقط).
  final List<LocalReminder> publicReminders;

  /// الشخصية (تتعدل).
  final List<LocalReminder> personalReminders;

  const NotificationState({
    this.permissionGranted = false,
    this.busy = false,
    this.fcmToken,
    this.isLoading = true,
    this.publicReminders = const [],
    this.personalReminders = const [],
  });

  /// نسخ مع تعديل.
  NotificationState copyWith({
    bool? permissionGranted,
    bool? busy,
    String? fcmToken,
    bool? isLoading,
    List<LocalReminder>? publicReminders,
    List<LocalReminder>? personalReminders,
  }) {
    return NotificationState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      busy: busy ?? this.busy,
      fcmToken: fcmToken ?? this.fcmToken,
      isLoading: isLoading ?? this.isLoading,
      publicReminders: publicReminders ?? this.publicReminders,
      personalReminders: personalReminders ?? this.personalReminders,
    );
  }
}
