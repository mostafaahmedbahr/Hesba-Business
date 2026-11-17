import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/activity_message.dart';
import '../../data/models/activity_model.dart';
import '../../data/repos/activity_repo.dart';
import 'activity_state.dart';
import 'package:hesba/core/services/app_logger.dart';

/// فيو موديل سجل النشاطات (شارة الجرس).
class ActivityCubit extends Cubit<ActivityState> {
  final ActivityRepo _repo;
  StreamSubscription<List<ActivityModel>>? _sub;
  StreamSubscription<AppEvent>? _eventSub;

  ActivityCubit({required ActivityRepo repo}) : _repo = repo, super(const ActivityState()) {
    _init();
  }

  /// يحمل ويشترك (سجل + أحداث عامة).
  Future<void> _init() async {
    try {
      final list = await _repo.getActivities();
      if (!isClosed) {
        emit(ActivityState(activities: list, unreadCount: list.where((e) => !e.isRead).length));
      }
    } catch (logErr, logSt) {
      AppLogger.nonFatal(
        'features/notifications/presentation/view_model/activity_cubit.dart',
        logErr,
        logSt,
        severity: LoggingSeverity.warning,
      );
    }

    // لو اتقفلت الـ cubit أثناء الـ await — لا تُنشئ اشتراكات بلا مالك.
    if (isClosed) return;

    _sub = _repo.watchActivities().listen((list) {
      if (isClosed) return;
      emit(state.copyWith(activities: list, unreadCount: list.where((e) => !e.isRead).length));
    });

    // أي حدث عام يتسجل تلقائيًا (اللوجيك في الـ repo) + إشعار نظام بنفس النص.
    _eventSub = AppEvents.instance.stream.listen((event) async {
      ActivityMessage? msg;
      try {
        msg = await _repo.logAppEvent(event);
      } catch (logErr, logSt) {
        AppLogger.nonFatal(
          'features/notifications/presentation/view_model/activity_cubit.dart',
          logErr,
          logSt,
          severity: LoggingSeverity.warning,
        );
        return;
      }
      if (msg == null || isClosed) return;
      try {
        await NotificationService().showActivity(
          title: msg.title,
          body: msg.body,
          payload: msg.payload,
        );
      } catch (e, logSt) {
        AppLogger.nonFatal('features/notifications/presentation/view_model/activity_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
        // إشعار فاشل ما يكسرش تسجيل العملية.
      }
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
