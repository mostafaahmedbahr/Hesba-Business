import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/local_reminder.dart';
import '../../../../core/services/notification_service.dart';
import '../repos/notification_repo.dart';

class NotificationRepoImpl implements NotificationRepo {
  final SharedPreferences _prefs;
  final NotificationService _service;

  NotificationRepoImpl(this._prefs, this._service);

  /// Public daily reminders are stored and seeded separately from personal
  /// ones so the two kinds can never corrupt each other.
  static const _kPublicKey = 'public_reminders';
  static const _kPublicSeededKey = 'public_reminders_seeded';
  static const _kPersonalKey = 'personal_reminders';

  // ── Firebase ──────────────────────────────────────────────────────────────
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

  // ── Public daily reminders ────────────────────────────────────────────────
  @override
  Future<List<LocalReminder>> loadPublicReminders({
    required List<LocalReminder> defaults,
  }) async {
    final seeded = _prefs.getBool(_kPublicSeededKey) ?? false;
    final List<LocalReminder> list;

    if (!seeded) {
      list = List.of(defaults);
      await _prefs.setString(
        _kPublicKey,
        jsonEncode(list.map((r) => r.toJson()).toList()),
      );
      await _prefs.setBool(_kPublicSeededKey, true);
    } else {
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

    // Public list is always fully re-synced on launch, independent of personal.
    await _service.syncReminders(list);
    return list;
  }

  // ── Personal reminders ────────────────────────────────────────────────────
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

    // Cancel personal schedules that are no longer in the list (e.g. a
    // reminder removed while the app was closed) then re-schedule the rest.
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