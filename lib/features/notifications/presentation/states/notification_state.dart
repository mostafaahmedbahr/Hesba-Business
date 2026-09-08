import '../../../../core/models/local_reminder.dart';

class NotificationState {
  final bool permissionGranted;
  final bool busy;
  final String? fcmToken;

  /// Read-only public daily reminders (always shown, never editable).
  final List<LocalReminder> publicReminders;

  /// User-created personal reminders (full CRUD).
  final List<LocalReminder> personalReminders;

  const NotificationState({
    this.permissionGranted = false,
    this.busy = false,
    this.fcmToken,
    this.publicReminders = const [],
    this.personalReminders = const [],
  });

  NotificationState copyWith({
    bool? permissionGranted,
    bool? busy,
    String? fcmToken,
    List<LocalReminder>? publicReminders,
    List<LocalReminder>? personalReminders,
  }) {
    return NotificationState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      busy: busy ?? this.busy,
      fcmToken: fcmToken ?? this.fcmToken,
      publicReminders: publicReminders ?? this.publicReminders,
      personalReminders: personalReminders ?? this.personalReminders,
    );
  }
}