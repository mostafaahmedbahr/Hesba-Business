/// How a local reminder repeats.
enum ReminderRepeat {
  /// Fires daily at the same time.
  daily,

  /// Fires weekly on a chosen [LocalReminder.weekday].
  weekly;

  static ReminderRepeat fromString(String? value) => value == 'weekly'
      ? ReminderRepeat.weekly
      : ReminderRepeat.daily;

  String get wire => name;
}

/// The kind of notification. Every kind lives in its own independent
/// namespace/slot so the three systems never interfere with each other.
enum NotificationKind {
  /// Remote push messages sent from Firebase Console / backend.
  firebase,

  /// Fixed daily reminders that every user always receives.
  publicDaily,

  /// User-created personal reminders (editable, deletable, toggleable).
  personal,
}

/// A single user-defined local reminder shown at a fixed time.
///
/// Reminder [id]s are globally unique and namespaced by kind so cancelling or
/// editing one kind can never affect another:
/// - 1001..1099: app/system notifications (test, FCM display)
/// - 1004..1007: reserved public daily reminders
/// - >= 2000: personal reminders
class LocalReminder {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool enabled;
  final bool isBuiltIn;
  final ReminderRepeat repeat;

  /// Target weekday for [ReminderRepeat.weekly] (1 = Monday .. 7 = Sunday,
  /// matching [DateTime.weekday]).
  final int? weekday;

  const LocalReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.isBuiltIn = false,
    this.repeat = ReminderRepeat.daily,
    this.weekday,
  });

  LocalReminder copyWith({
    String? title,
    String? body,
    int? hour,
    int? minute,
    bool? enabled,
    ReminderRepeat? repeat,
    int? weekday,
  }) {
    return LocalReminder(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      isBuiltIn: isBuiltIn,
      repeat: repeat ?? this.repeat,
      weekday: weekday ?? this.weekday,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
      'isBuiltIn': isBuiltIn,
      'repeat': repeat.wire,
      'weekday': weekday,
    };
  }

  factory LocalReminder.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    return LocalReminder(
      id: id,
      title: json['title'] as String,
      body: (json['body'] as String?) ?? '',
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      enabled: (json['enabled'] as bool?) ?? true,
      // Migrates reminders persisted before the flag existed: the reserved
      // default ids (1004..1007) are always locked built-ins.
      isBuiltIn: (json['isBuiltIn'] as bool?) ?? (id >= 1004 && id <= 1007),
      repeat: ReminderRepeat.fromString(json['repeat'] as String?),
      weekday: (json['weekday'] as num?)?.toInt(),
    );
  }
}