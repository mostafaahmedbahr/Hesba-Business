import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/notification_service.dart';
import '../repos/notification_repo.dart';

class NotificationRepoImpl implements NotificationRepo {
  final SharedPreferences _prefs;
  final NotificationService _service;

  NotificationRepoImpl(this._prefs, this._service);

  static const _kRemindersEnabled = 'reminders_enabled';

  @override
  Future<bool> getRemindersEnabled() async {
    return _prefs.getBool(_kRemindersEnabled) ?? true;
  }

  @override
  Future<void> setRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_kRemindersEnabled, enabled);
  }

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
  Future<void> scheduleReminder({
    required String title,
    required String body,
  }) {
    return _service.scheduleHourlyReminder(title: title, body: body);
  }

  @override
  Future<void> cancelReminder() {
    return _service.cancelReminders();
  }

  @override
  Future<void> sendTestNotification({
    required String title,
    required String body,
  }) {
    return _service.showReminder(title: title, body: body);
  }
}