import '../../../../core/models/local_reminder.dart';

class NotificationState {
  final bool permissionGranted;
  final bool busy;
  final String? fcmToken;
  final List<LocalReminder> reminders;

  const NotificationState({
    this.permissionGranted = false,
    this.busy = false,
    this.fcmToken,
    this.reminders = const [],
  });

  NotificationState copyWith({
    bool? permissionGranted,
    bool? busy,
    String? fcmToken,
    List<LocalReminder>? reminders,
  }) {
    return NotificationState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      busy: busy ?? this.busy,
      fcmToken: fcmToken ?? this.fcmToken,
      reminders: reminders ?? this.reminders,
    );
  }
}