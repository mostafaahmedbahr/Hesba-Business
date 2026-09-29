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

  /// أيام الأسبوع للأسبوعي (1 = اثنين .. 7 = أحد) — يوم أو أكتر.
  final List<int> weekdays;

  const LocalReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.isBuiltIn = false,
    this.repeat = ReminderRepeat.daily,
    this.weekdays = const [],
  });

  /// نسخ مع تعديل.
  LocalReminder copyWith({
    String? title,
    String? body,
    int? hour,
    int? minute,
    bool? enabled,
    ReminderRepeat? repeat,
    List<int>? weekdays,
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
      weekdays: weekdays ?? this.weekdays,
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
      'weekdays': weekdays,
    };
  }

  /// من Map مخزنة (يدعم الشكل القديم `weekday` المفرد).
  factory LocalReminder.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    // ترحيل: القديم كان يوم واحد `weekday` — يتحول لقائمة.
    var days = (json['weekdays'] as List<dynamic>?)
        ?.map((e) => (e as num).toInt())
        .where((d) => d >= 1 && d <= 7)
        .toList();
    days ??= switch ((json['weekday'] as num?)?.toInt()) {
      final d? when d >= 1 && d <= 7 => [d],
      _ => <int>[],
    };
    return LocalReminder(
      id: id,
      title: json['title'] as String,
      body: (json['body'] as String?) ?? '',
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      enabled: (json['enabled'] as bool?) ?? true,
      isBuiltIn: (json['isBuiltIn'] as bool?) ?? (id >= 1004 && id <= 1007),
      repeat: ReminderRepeat.fromString(json['repeat'] as String?),
      weekdays: days,
    );
  }
}
