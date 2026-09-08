import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/local_reminder.dart';
import '../../data/repos/notification_repo.dart';
import '../states/notification_state.dart';
import '../utils/default_reminders.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo _repo;

  NotificationCubit({required this._repo}) : super(const NotificationState());

  /// Initializes FCM (permission + token). Personal/public reminders are
  /// loaded separately via [loadReminders].
  Future<void> init() async {
    final granted = await _repo.requestPermissions();
    emit(state.copyWith(permissionGranted: granted));

    final token = await _repo.getFcmToken();
    emit(state.copyWith(fcmToken: token));
    if (granted) {
      await _repo.setupFcm();
      final freshToken = await _repo.getFcmToken();
      emit(state.copyWith(fcmToken: freshToken));
    }
  }

  /// Called at app startup: seeds + schedules the public daily reminders
  /// (idempotent) and re-syncs personal ones. That's it.
  Future<void> ensureAllRemindersScheduled() => loadReminders();

  /// Loads BOTH lists: public (read-only) and personal. Each list is synced
  /// to the OS scheduler independently.
  Future<void> loadReminders() async {
    final public = await _repo.loadPublicReminders(
      defaults: buildDefaultReminders(),
    );
    final personal = await _repo.loadPersonalReminders();
    emit(
      state.copyWith(
        publicReminders: public,
        personalReminders: personal,
      ),
    );
  }

  // ── Public (client has no control here) ──────────────────────────────────
  // Intentionally no mutating methods: public reminders are fixed for
  // everyone and never affected by personal CRUD.

  // ── Personal reminders (independent per-reminder) ─────────────────────────
  Future<void> addReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    ReminderRepeat repeat = ReminderRepeat.daily,
    int? weekday,
  }) async {
    final list = [...state.personalReminders];
    final id = _nextId(list);
    final reminder = LocalReminder(
      id: id,
      title: title.trim(),
      body: body.trim(),
      hour: hour,
      minute: minute,
      repeat: repeat,
      weekday: weekday,
    );
    final updated = [...list, reminder];
    emit(state.copyWith(personalReminders: updated));
    await _repo.persistPersonalReminders(updated);
  }

  Future<void> updateReminder(LocalReminder reminder) async {
    final updated = [
      for (final r in state.personalReminders)
        if (r.id == reminder.id) reminder else r,
    ];
    emit(state.copyWith(personalReminders: updated));
    await _repo.persistPersonalReminders(updated);
  }

  Future<void> deleteReminder(int id) async {
    final updated =
        state.personalReminders.where((r) => r.id != id).toList();
    emit(state.copyWith(personalReminders: updated));
    await _repo.persistPersonalReminders(updated);
  }

  Future<void> toggleReminderEnabled(LocalReminder reminder) async {
    final updated = [
      for (final r in state.personalReminders)
        if (r.id == reminder.id) r.copyWith(enabled: !r.enabled) else r,
    ];
    emit(state.copyWith(personalReminders: updated));
    await _repo.persistPersonalReminders(updated);
  }

  Future<void> enablePermissions() async {
    final granted = await _repo.requestPermissions();
    emit(state.copyWith(permissionGranted: granted));
    if (granted) {
      await _repo.setupFcm();
      final freshToken = await _repo.getFcmToken();
      emit(state.copyWith(fcmToken: freshToken));
    }
  }

  Future<bool> sendTest({
    required String title,
    required String body,
  }) async {
    try {
      await _repo.sendTestNotification(title: title, body: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  int _nextId(List<LocalReminder> current) {
    var max = 1999;
    for (final r in current) {
      if (r.id > max) max = r.id;
    }
    return max + 1;
  }
}