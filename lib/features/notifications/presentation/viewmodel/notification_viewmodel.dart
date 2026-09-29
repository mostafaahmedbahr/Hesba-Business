import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/default_reminders.dart';
import '../../data/models/local_reminder.dart';
import '../../data/repos/activity_repo.dart';
import '../../data/repos/notification_repo.dart';
import 'notification_state.dart';

/// فيو موديل التذكيرات (كل لوجيك الشاشة هنا).
class NotificationViewModel extends Cubit<NotificationState> {
  final NotificationRepo _repo;
  final ActivityRepo _activityRepo;

  NotificationViewModel({required NotificationRepo repo, required ActivityRepo activityRepo})
      : _repo = repo,
        _activityRepo = activityRepo,
        super(const NotificationState());

  /// يجهز الإذن والتوكن.
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

  /// يحمل القائمتين ويجدولهما.
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

  /// يصفر شارة الجرس بعد فتح الشاشة.
  Future<void> markSeenAfterOpen() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (isClosed) return;
    try {
      await _activityRepo.markAllRead();
    } catch (_) {}
  }

  /// يتأكد إن الإذن مفتوح (يطلبه لو مقفول).
  Future<bool> ensurePermission() async {
    if (state.permissionGranted) return true;
    final granted = await _repo.requestPermissions();
    emit(state.copyWith(permissionGranted: granted));
    if (granted) await _repo.setupFcm();
    return granted;
  }

  /// يبعت تذكير فورًا (تجربة).
  Future<bool> testReminder(LocalReminder r) async {
    try {
      await _repo.sendTestNotification(
        title: r.title,
        body: r.body.isEmpty ? 'تذكير حسبة' : r.body,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// يضيف تذكير شخصي.
  Future<void> addReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    ReminderRepeat repeat = ReminderRepeat.daily,
    int? weekday,
  }) async {
    final list = [...state.personalReminders];
    final reminder = LocalReminder(
      id: _nextId(list),
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

  /// يعدل تذكير.
  Future<void> updateReminder(LocalReminder reminder) async {
    final updated = [
      for (final r in state.personalReminders)
        if (r.id == reminder.id) reminder else r,
    ];
    emit(state.copyWith(personalReminders: updated));
    await _repo.persistPersonalReminders(updated);
  }

  /// يحذف تذكير.
  Future<void> deleteReminder(int id) async {
    final updated =
        state.personalReminders.where((r) => r.id != id).toList();
    emit(state.copyWith(personalReminders: updated));
    await _repo.persistPersonalReminders(updated);
  }

  /// يشغل / يطفي تذكير.
  Future<void> toggleReminderEnabled(LocalReminder reminder) async {
    final updated = [
      for (final r in state.personalReminders)
        if (r.id == reminder.id) r.copyWith(enabled: !r.enabled) else r,
    ];
    emit(state.copyWith(personalReminders: updated));
    await _repo.persistPersonalReminders(updated);
  }

  /// يطلب الإذن يدويًا (بانر التفعيل).
  Future<void> enablePermissions() async {
    final granted = await _repo.requestPermissions();
    emit(state.copyWith(permissionGranted: granted));
    if (granted) {
      await _repo.setupFcm();
      final freshToken = await _repo.getFcmToken();
      emit(state.copyWith(fcmToken: freshToken));
    }
  }

  /// id جديد (نطاق الشخصية 2000+).
  int _nextId(List<LocalReminder> current) {
    var max = 1999;
    for (final r in current) {
      if (r.id > max) max = r.id;
    }
    return max + 1;
  }
}
