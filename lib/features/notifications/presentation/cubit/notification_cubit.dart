import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/local_reminder.dart';
import '../../data/repos/notification_repo.dart';
import '../states/notification_state.dart';
import '../utils/default_reminders.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo _repo;

  NotificationCubit({required NotificationRepo repo})
      : _repo = repo,
        super(const NotificationState());

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

  /// Called at app startup: seeds (first run) and schedules all local
  /// reminders. Idempotent.
  Future<void> ensureAllRemindersScheduled() async {
    await loadReminders();
  }

  Future<void> loadReminders() async {
    final list = await _repo.loadReminders(defaults: buildDefaultReminders());
    emit(state.copyWith(reminders: list));
  }

  Future<void> addReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final list = [...state.reminders];
    final maxId =
        list.fold<int>(1007, (max, r) => r.id > max ? r.id : max) + 1;
    final reminder = LocalReminder(
      id: maxId,
      title: title.trim(),
      body: body.trim(),
      hour: hour,
      minute: minute,
    );
    final updated = [...list, reminder];
    emit(state.copyWith(reminders: updated));
    await _repo.persistReminders(updated);
  }

  Future<void> updateReminder(LocalReminder reminder) async {
    final updated = [
      for (final r in state.reminders)
        if (r.id == reminder.id) reminder else r,
    ];
    emit(state.copyWith(reminders: updated));
    await _repo.persistReminders(updated);
  }

  Future<void> deleteReminder(int id) async {
    final updated = state.reminders.where((r) => r.id != id).toList();
    emit(state.copyWith(reminders: updated));
    await _repo.persistReminders(updated);
  }

  Future<void> toggleReminderEnabled(LocalReminder reminder) async {
    final updated = [
      for (final r in state.reminders)
        if (r.id == reminder.id) r.copyWith(enabled: !r.enabled) else r,
    ];
    emit(state.copyWith(reminders: updated));
    await _repo.persistReminders(updated);
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
}