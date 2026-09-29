/// شكل تكرار التذكير.
enum ReminderRepeat {
  /// كل يوم نفس الوقت.
  daily,

  /// كل أسبوع في يوم معين.
  weekly;

  static ReminderRepeat fromString(String? value) => value == 'weekly'
      ? ReminderRepeat.weekly
      : ReminderRepeat.daily;

  String get wire => name;
}

/// نوع الإشعار (كل نوع في نطاق ids مستقل).
enum NotificationKind {
  /// push من Firebase.
  firebase,

  /// اليومية الثابتة للكل.
  publicDaily,

  /// الشخصية (تتعدل وتتمسح).
  personal,
}

/// تذكير واحد بوقت ثابت.
class LocalReminder {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool enabled;
  final bool isBuiltIn;
  final ReminderRepeat repeat;

  /// يوم الأسبوع للأسبوعي (1 = اثنين .. 7 = أحد).
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

  /// نسخ مع تعديل.
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

  /// للتحويل لـ Map (تخزين).
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

  /// من Map مخزنة.
  factory LocalReminder.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    return LocalReminder(
      id: id,
      title: json['title'] as String,
      body: (json['body'] as String?) ?? '',
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      enabled: (json['enabled'] as bool?) ?? true,
      isBuiltIn: (json['isBuiltIn'] as bool?) ?? (id >= 1004 && id <= 1007),
      repeat: ReminderRepeat.fromString(json['repeat'] as String?),
      weekday: (json['weekday'] as num?)?.toInt(),
    );
  }
}
