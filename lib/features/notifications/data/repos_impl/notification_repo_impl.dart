import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/notification_service.dart';
import '../models/local_reminder.dart';
import '../repos/notification_repo.dart';

/// تنفيذ التخزين (SharedPreferences + جدولة).
class NotificationRepoImpl implements NotificationRepo {
  final SharedPreferences _prefs;
  final NotificationService _service;

  NotificationRepoImpl(this._prefs, this._service);

  /// مفاتيح التخزين (عامة وشخصية منفصلة).
  static const _kPublicKey = 'public_reminders';
  static const _kPublicSeededKey = 'public_reminders_seeded';
  static const _kPersonalKey = 'personal_reminders';

  @override
  Future<bool> requestPermissions() {
    return _service.requestPermissions();
  }

  @override
  Future<bool> setupFcm() async {
    try {
      await _service.setupFcm();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getFcmToken() => _service.getToken();

  @override
  Future<void> sendTestNotification({
    required String title,
    required String body,
  }) {
    return _service.showReminder(title: title, body: body);
  }

  @override
  Future<List<LocalReminder>> loadPublicReminders({
    required List<LocalReminder> defaults,
  }) async {
    final seeded = _prefs.getBool(_kPublicSeededKey) ?? false;
    final List<LocalReminder> list;

    if (!seeded) {
      // أول مرة: يزرع الافتراضي.
      list = List.of(defaults);
      await _prefs.setString(
        _kPublicKey,
        jsonEncode(list.map((r) => r.toJson()).toList()),
      );
      await _prefs.setBool(_kPublicSeededKey, true);
    } else {
      // بعد كده: يقرأ المخزن.
      final raw = _prefs.getString(_kPublicKey);
      list = <LocalReminder>[];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list.addAll(
          decoded.map(
            (e) => LocalReminder.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
    }

    await _service.syncReminders(list);
    return list;
  }

  @override
  Future<List<LocalReminder>> loadPersonalReminders() async {
    final raw = _prefs.getString(_kPersonalKey);
    final list = <LocalReminder>[];
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      list.addAll(
        decoded.map(
          (e) => LocalReminder.fromJson(e as Map<String, dynamic>),
        ),
      );
    }

    await _service.syncReminders(list);
    return list;
  }

  @override
  Future<void> persistPersonalReminders(
    List<LocalReminder> reminders,
  ) async {
    await _prefs.setString(
      _kPersonalKey,
      jsonEncode(reminders.map((r) => r.toJson()).toList()),
    );
    await _service.syncReminders(reminders);
  }
}
