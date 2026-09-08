import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/local_reminder.dart';
import '../../../../core/services/notification_service.dart';
import '../repos/notification_repo.dart';

class NotificationRepoImpl implements NotificationRepo {
  final SharedPreferences _prefs;
  final NotificationService _service;

  NotificationRepoImpl(this._prefs, this._service);

  static const _kRemindersKey = 'local_reminders';
  static const _kSeededKey = 'local_reminders_seeded';

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
  Future<List<LocalReminder>> loadReminders({
    required List<LocalReminder> defaults,
  }) async {
    final seeded = _prefs.getBool(_kSeededKey) ?? false;
    if (!seeded) {
      await persistReminders(defaults);
      await _prefs.setBool(_kSeededKey, true);
      return List.of(defaults);
    }

    final raw = _prefs.getString(_kRemindersKey);
    final list = <LocalReminder>[];
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      list.addAll(
        decoded.map(
          (e) => LocalReminder.fromJson(e as Map<String, dynamic>),
        ),
      );
    }

    // Re-sync schedules at startup so they survive reboots/restores.
    await _service.syncReminders(list);
    return list;
  }

  @override
  Future<void> persistReminders(List<LocalReminder> reminders) async {
    final json = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await _prefs.setString(_kRemindersKey, json);
    await _service.syncReminders(reminders);
  }

  @override
  Future<void> sendTestNotification({
    required String title,
    required String body,
  }) {
    return _service.showReminder(title: title, body: body);
  }
}