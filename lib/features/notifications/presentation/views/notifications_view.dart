import '../../../../common_imports.dart';
import '../../data/repos/activity_repo.dart';
import '../../data/repos/notification_repo.dart';
import '../view_model/notification_cubit.dart';
import '../widgets/notifications_view_body.dart';

/// شاشة الإشعارات (تاب تذكيراتي | تاب سجل العمليات).
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationCubit(
        repo: sl<NotificationRepo>(),
        activityRepo: sl<ActivityRepo>(),
      )..bootstrap(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const NotificationsViewBody(),
        ),
      ),
    );
  }
}
