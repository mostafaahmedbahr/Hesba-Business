/// A single user-defined local reminder shown daily at a fixed time.
class LocalReminder {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool enabled;
  final bool isBuiltIn;

  const LocalReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.isBuiltIn = false,
  });

  LocalReminder copyWith({
    String? title,
    String? body,
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return LocalReminder(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      isBuiltIn: isBuiltIn,
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
    );
  }
}