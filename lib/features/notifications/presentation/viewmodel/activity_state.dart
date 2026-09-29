import 'package:equatable/equatable.dart';
import '../../data/models/activity_model.dart';

/// حالة سجل النشاطات.
class ActivityState extends Equatable {
  final List<ActivityModel> activities;
  final int unreadCount;
  const ActivityState({this.activities = const [], this.unreadCount = 0});

  /// نسخ مع تعديل.
  ActivityState copyWith({List<ActivityModel>? activities, int? unreadCount}) {
    return ActivityState(
      activities: activities ?? this.activities,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [activities, unreadCount];
}
