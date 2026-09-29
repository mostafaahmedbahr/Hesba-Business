import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/app_events.dart';
import '../models/activity_model.dart';
import '../repos/activity_repo.dart';

/// تنفيذ سجل النشاطات (SharedPreferences + ستريم).
class ActivityRepoImpl implements ActivityRepo {
  final SharedPreferences _prefs;
  static const _kKey = 'activity_notifications_v1';
  final _controller = StreamController<List<ActivityModel>>.broadcast();

  ActivityRepoImpl(this._prefs) {
    Future.microtask(() => _controller.add(_loadSync()));
  }

  /// يقرأ المخزن (متزامن).
  List<ActivityModel> _loadSync() {
    final raw = _prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => ActivityModel.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<List<ActivityModel>> _load() async => _loadSync();

  /// يحفظ ويبث (آخر 100 بس).
  Future<void> _save(List<ActivityModel> list) async {
    await _prefs.setString(_kKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    if (!_controller.isClosed) _controller.add(List.of(list));
  }

  @override
  Future<List<ActivityModel>> getActivities() async => _load();

  @override
  Future<int> getUnreadCount() async {
    final list = await _load();
    return list.where((e) => !e.isRead).length;
  }

  @override
  Stream<List<ActivityModel>> watchActivities() async* {
    yield await _load();
    yield* _controller.stream;
  }

  @override
  Stream<int> watchUnreadCount() async* {
    yield await getUnreadCount();
    await for (final list in _controller.stream) {
      yield list.where((e) => !e.isRead).length;
    }
  }

  @override
  Future<void> addActivity({required ActivityType type, required String title, required String body}) async {
    final list = await _load();
    final now = DateTime.now();
    final item = ActivityModel(id: now.millisecondsSinceEpoch.toString(), type: type, title: title, body: body, createdAt: now, isRead: false);
    final updated = [item, ...list];
    await _save(updated.length > 100 ? updated.sublist(0, 100) : updated);
  }

  @override
  Future<void> logAppEvent(AppEvent event) async {
    // يحول كل حدث لنشاط مسجل.
    switch (event.type) {
      case AppEventType.saleCreated:
        await addActivity(type: ActivityType.sale, title: 'تم تسجيل بيع جديد', body: 'فاتورة جديدة تمت إضافتها بنجاح');
        break;
      case AppEventType.returnCreated:
        await addActivity(type: ActivityType.returnAdd, title: 'تم تسجيل مرتجع', body: 'عملية مرتجع جديدة تمت إضافتها');
        break;
      case AppEventType.expenseCreated:
        await addActivity(type: ActivityType.expenseAdd, title: 'تم تسجيل مصروف', body: 'مصروف جديد تمت إضافته');
        break;
      case AppEventType.expenseUpdated:
        await addActivity(type: ActivityType.expenseUpdate, title: 'تم تعديل مصروف', body: 'تم تحديث بيانات مصروف');
        break;
      case AppEventType.expenseDeleted:
        await addActivity(type: ActivityType.expenseDelete, title: 'تم حذف مصروف', body: 'تم حذف مصروف من السجل');
        break;
      case AppEventType.productAdded:
        await addActivity(type: ActivityType.productAdd, title: 'تم إضافة منتج', body: 'منتج جديد أُضيف للمخزون');
        break;
      case AppEventType.productUpdated:
        await addActivity(type: ActivityType.productUpdate, title: 'تم تعديل منتج', body: 'تم تحديث بيانات منتج');
        break;
      case AppEventType.productDeleted:
        await addActivity(type: ActivityType.productDelete, title: 'تم حذف منتج', body: 'تم حذف منتج من المخزون');
        break;
      case AppEventType.productChanged:
        break; // عام — متغطي بالحالات المحددة.
    }
  }

  @override
  Future<void> markAllRead() async {
    final list = await _load();
    await _save(list.map((e) => e.copyWith(isRead: true)).toList());
  }
}
