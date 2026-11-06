import '../../../../core/services/app_events.dart';
import '../activity_message.dart';
import '../models/activity_model.dart';

/// عقد سجل النشاطات.
abstract class ActivityRepo {
  /// كل النشاطات (الأحدث أولاً).
  Future<List<ActivityModel>> getActivities();

  /// يضيف نشاط. [payload] بيحدّد الشاشة اللي يفتحها لو اتنضغط عليه.
  Future<void> addActivity({required ActivityType type, required String title, required String body, String payload = ''});

  /// يحوّل حدث عام لنشاط مسجل (بيع/منتج/مصروف...) ويرجع النص الجاهز.
  /// بيرجع `null` للحدث العام اللي مالوش تسجيل.
  Future<ActivityMessage?> logAppEvent(AppEvent event);

  /// يعلم الكل كمقروء.
  Future<void> markAllRead();

  /// عدد الغير مقروء.
  Future<int> getUnreadCount();

  /// ستريم النشاطات.
  Stream<List<ActivityModel>> watchActivities();

  /// ستريم العداد.
  Stream<int> watchUnreadCount();
}
