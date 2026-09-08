import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/notification_repo.dart';
import '../states/notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo _repo;

  NotificationCubit({required NotificationRepo repo})
      : _repo = repo,
        super(const NotificationState());

  Future<void> init() async {
    final enabled = await _repo.getRemindersEnabled();
    emit(state.copyWith(remindersEnabled: enabled));

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

  /// Called at app startup: schedules the hourly reminder if the user
  /// previously enabled it. Idempotent (same notification id).
  Future<void> ensureReminderScheduled({
    required String title,
    required String body,
  }) async {
    final enabled = await _repo.getRemindersEnabled();
    if (!enabled) return;
    await _repo.scheduleReminder(title: title, body: body);
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

  Future<void> toggleReminder({
    required bool enable,
    required String title,
    required String body,
  }) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));

    try {
      if (enable) {
        await _repo.scheduleReminder(title: title, body: body);
      } else {
        await _repo.cancelReminder();
      }
      await _repo.setRemindersEnabled(enable);
      emit(state.copyWith(remindersEnabled: enable));
    } finally {
      emit(state.copyWith(busy: false));
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