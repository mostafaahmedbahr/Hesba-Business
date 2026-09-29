import '../../../../core/services/app_events.dart';
import '../models/activity_model.dart';

/// عقد سجل النشاطات.
abstract class ActivityRepo {
  /// كل النشاطات (الأحدث أولاً).
  Future<List<ActivityModel>> getActivities();

  /// يضيف نشاط.
  Future<void> addActivity({required ActivityType type, required String title, required String body});

  /// يحول حدث عام لنشاط مسجل (بيع/منتج/مصروف...).
  Future<void> logAppEvent(AppEvent event);

  /// يعلم الكل كمقروء.
  Future<void> markAllRead();

  /// عدد الغير مقروء.
  Future<int> getUnreadCount();

  /// ستريم النشاطات.
  Stream<List<ActivityModel>> watchActivities();

  /// ستريم العداد.
  Stream<int> watchUnreadCount();
}
