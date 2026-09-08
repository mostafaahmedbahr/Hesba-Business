class NotificationState {
  final bool remindersEnabled;
  final bool permissionGranted;
  final bool busy;
  final String? fcmToken;

  const NotificationState({
    this.remindersEnabled = true,
    this.permissionGranted = false,
    this.busy = false,
    this.fcmToken,
  });

  NotificationState copyWith({
    bool? remindersEnabled,
    bool? permissionGranted,
    bool? busy,
    String? fcmToken,
  }) {
    return NotificationState(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      busy: busy ?? this.busy,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}