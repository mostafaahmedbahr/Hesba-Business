import '../models/activity_model.dart';

abstract class ActivityRepo {
  Future<List<ActivityModel>> getActivities();
  Future<void> addActivity({required ActivityType type, required String title, required String body});
  Future<void> markAllRead();
  Future<int> getUnreadCount();
  Stream<List<ActivityModel>> watchActivities();
  Stream<int> watchUnreadCount();
}
