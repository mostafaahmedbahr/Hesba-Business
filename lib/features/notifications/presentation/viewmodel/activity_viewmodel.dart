import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../data/models/activity_model.dart';
import '../../data/repos/activity_repo.dart';
import 'activity_state.dart';

/// فيو موديل سجل النشاطات (شارة الجرس).
class ActivityViewModel extends Cubit<ActivityState> {
  final ActivityRepo _repo;
  StreamSubscription<List<ActivityModel>>? _sub;
  StreamSubscription<AppEvent>? _eventSub;

  ActivityViewModel({required ActivityRepo repo}) : _repo = repo, super(const ActivityState()) {
    _init();
  }

  /// يحمل ويشترك (سجل + أحداث عامة).
  Future<void> _init() async {
    final list = await _repo.getActivities();
    if (!isClosed) {
      emit(ActivityState(activities: list, unreadCount: list.where((e) => !e.isRead).length));
    }

    _sub = _repo.watchActivities().listen((list) {
      if (isClosed) return;
      emit(state.copyWith(activities: list, unreadCount: list.where((e) => !e.isRead).length));
    });

    // أي حدث عام يتسجل تلقائيًا (اللوجيك في الـ repo).
    _eventSub = AppEvents.instance.stream.listen((event) {
      _repo.logAppEvent(event);
    });
  }

  /// يضيف نشاط يدويًا.
  Future<void> add({required ActivityType type, required String title, required String body}) async {
    await _repo.addActivity(type: type, title: title, body: body);
  }

  /// يعلم الكل كمقروء.
  Future<void> markAllRead() async {
    await _repo.markAllRead();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _eventSub?.cancel();
    return super.close();
  }
}
