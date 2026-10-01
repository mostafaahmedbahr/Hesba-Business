import 'package:easy_localization/easy_localization.dart';
import '../../../../common_imports.dart';
import '../../data/repos/activity_repo.dart';
import '../../data/repos/notification_repo.dart';
import '../view_model/notification_cubit.dart';
import '../widgets/notifications_view_body.dart';

/// شاشة الإشعارات (تذكيراتي + سجل العمليات — اللوجيك في ViewModel).
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
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'reminders_fab',
            onPressed: () => context.read<NotificationCubit>().openForm(context),
            elevation: 0,
            backgroundColor: const Color(0xFF1A4FD6),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'remindersAddButton'.tr(),
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
            ),
          ),
          body: const NotificationsViewBody(),
        ),
      ),
    );
  }
}
