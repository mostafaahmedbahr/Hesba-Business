import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/toast.dart';
import '../../data/models/local_reminder.dart';
import '../../data/repos/activity_repo.dart';
import '../../data/repos/notification_repo.dart';
import '../viewmodel/notification_state.dart';
import '../viewmodel/notification_viewmodel.dart';
import '../widgets/reminder_card.dart';
import '../widgets/reminder_delete_dialog.dart';
import '../widgets/reminder_empty_state.dart';
import '../widgets/reminder_enable_banner.dart';
import '../widgets/reminder_form_sheet.dart';
import '../widgets/reminder_header.dart';

/// شاشة تذكيراتي (عرض بس — اللوجيك في ViewModel).
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    // يصفر شارة الجرس (اللوجيك في ViewModel).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationViewModel>().markSeenAfterOpen();
    });
  }

  /// يفتح شيت الإضافة / التعديل.
  Future<void> _openForm(BuildContext context, {LocalReminder? reminder}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (_) => ReminderFormSheet(
        viewmodel: context.read<NotificationViewModel>(),
        reminder: reminder,
      ),
    );
  }

  /// يبعت التذكير فورًا (تجربة).
  Future<void> _testNow(BuildContext context, LocalReminder r) async {
    final ok = await context.read<NotificationViewModel>().testReminder(r);
    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, 'وصل؟ كده الإشعارات شغالة وتذكيرك هييجي في وقته');
    } else {
      AppToast.error(context, 'موصلش — فعّل إذن الإشعارات من إعدادات الموبايل');
    }
  }

  /// تأكيد ثم حذف.
  Future<void> _confirmDelete(BuildContext context, LocalReminder r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ReminderDeleteDialog(),
    );
    if (ok == true && context.mounted) {
      context.read<NotificationViewModel>().deleteReminder(r.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationViewModel(
        repo: sl<NotificationRepo>(),
        activityRepo: sl<ActivityRepo>(),
      )
        ..init()
        ..loadReminders(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'reminders_fab',
            onPressed: () => _openForm(context),
            elevation: 0,
            backgroundColor: const Color(0xFF1A4FD6),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'remindersAddButton'.tr(),
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
            ),
          ),
          body: BlocBuilder<NotificationViewModel, NotificationState>(
            builder: (context, state) {
              final list = state.personalReminders;
              return CustomScrollView(
                slivers: [
                  ReminderHeader(count: list.length),
                  if (!state.permissionGranted)
                    SliverToBoxAdapter(
                      child: ReminderEnableBanner(
                        onEnable: () => context
                            .read<NotificationViewModel>()
                            .enablePermissions(),
                      ),
                    ),
                  if (list.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ReminderEmptyState(
                        onAdd: () => _openForm(context),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10.h),
                        itemBuilder: (context, i) {
                          final r = list[i];
                          return ReminderCard(
                            reminder: r,
                            onToggle: () => context
                                .read<NotificationViewModel>()
                                .toggleReminderEnabled(r),
                            onTest: () => _testNow(context, r),
                            onEdit: () => _openForm(context, reminder: r),
                            onDelete: () => _confirmDelete(context, r),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
