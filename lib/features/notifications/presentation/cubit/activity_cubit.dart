import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../data/models/activity_model.dart';
import '../../data/repos/activity_repo.dart';
import 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  final ActivityRepo _repo;
  StreamSubscription<List<ActivityModel>>? _sub;
  StreamSubscription<AppEvent>? _eventSub;

  ActivityCubit({required ActivityRepo repo}) : _repo = repo, super(const ActivityState()) {
    _init();
  }

  Future<void> _init() async {
    final list = await _repo.getActivities();
    final unread = list.where((e) => !e.isRead).length;
    if (!isClosed) emit(ActivityState(activities: list, unreadCount: unread));

    _sub = _repo.watchActivities().listen((list) {
      if (isClosed) return;
      emit(state.copyWith(activities: list, unreadCount: list.where((e) => !e.isRead).length));
    });

    // listen to global AppEvents and auto-create notifications
    _eventSub = AppEvents.instance.stream.listen((event) {
      _handleAppEvent(event);
    });
  }

  void _handleAppEvent(AppEvent event) {
    switch (event.type) {
      case AppEventType.saleCreated:
        add(type: ActivityType.sale, title: 'تم تسجيل بيع جديد', body: 'فاتورة جديدة تمت إضافتها بنجاح');
        break;
      case AppEventType.returnCreated:
        add(type: ActivityType.returnAdd, title: 'تم تسجيل مرتجع', body: 'عملية مرتجع جديدة تمت إضافتها');
        break;
      case AppEventType.expenseCreated:
        add(type: ActivityType.expenseAdd, title: 'تم تسجيل مصروف', body: 'مصروف جديد تمت إضافته');
        break;
      case AppEventType.expenseUpdated:
        add(type: ActivityType.expenseUpdate, title: 'تم تعديل مصروف', body: 'تم تحديث بيانات مصروف');
        break;
      case AppEventType.expenseDeleted:
        add(type: ActivityType.expenseDelete, title: 'تم حذف مصروف', body: 'تم حذف مصروف من السجل');
        break;
      case AppEventType.productAdded:
        add(type: ActivityType.productAdd, title: 'تم إضافة منتج', body: 'منتج جديد أُضيف للمخزون');
        break;
      case AppEventType.productUpdated:
        add(type: ActivityType.productUpdate, title: 'تم تعديل منتج', body: 'تم تحديث بيانات منتج');
        break;
      case AppEventType.productDeleted:
        add(type: ActivityType.productDelete, title: 'تم حذف منتج', body: 'تم حذف منتج من المخزون');
        break;
      case AppEventType.productChanged:
        // generic fallback - still count but avoid duplicate if already handled
        // we already handle specific product events, so ignore generic here
        break;
    }
  }

  Future<void> add({required ActivityType type, required String title, required String body}) async {
    await _repo.addActivity(type: type, title: title, body: body);
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
  }

  Future<void> manualAdd({required ActivityType type, required String title, required String body}) => add(type: type, title: title, body: body);

  @override
  Future<void> close() {
    _sub?.cancel();
    _eventSub?.cancel();
    return super.close();
  }
}
