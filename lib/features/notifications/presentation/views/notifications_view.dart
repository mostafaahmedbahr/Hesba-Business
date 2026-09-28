import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/local_reminder.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../data/repos/activity_repo.dart';
import '../../data/repos/notification_repo.dart';
import '../cubit/notification_cubit.dart';
import '../states/notification_state.dart';
import '../widgets/reminder_card.dart';
import '../widgets/reminder_empty_state.dart';
import '../widgets/reminder_form_sheet.dart';
import '../widgets/reminder_header.dart';

/// شاشة تذكيراتي (شخصية بس — إضافة / تعديل / حذف).
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    // يصفر شارة الجرس القديمة.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 600));
      try {
        await sl<ActivityRepo>().markAllRead();
      } catch (_) {}
    });
  }

  /// يفتح شيت الإضافة / التعديل.
  Future<void> _openForm(BuildContext context, {LocalReminder? reminder}) async {
    final cubit = context.read<NotificationCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (_) => ReminderFormSheet(cubit: cubit, reminder: reminder),
    );
  }

  /// يبعت التذكير فورًا (تجربة إنه شغال).
  Future<void> _testNow(BuildContext context, LocalReminder r) async {
    final ok = await context.read<NotificationCubit>().sendTest(
          title: r.title,
          body: r.body.isEmpty ? 'تذكير حسبة' : r.body,
        );
    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, 'وصل؟ كده الإشعارات شغالة وتذكيرك هييجي في وقته');
    } else {
      AppToast.error(context, 'موصلش — فعّل إذن الإشعارات من إعدادات الموبايل');
    }
  }

  /// تأكيد حذف تذكير.
  Future<void> _confirmDelete(BuildContext context, LocalReminder r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_rounded, size: 26.sp, color: const Color(0xFFE11D48)),
              ),
              SizedBox(height: 12.h),
              Text(
                'reminderDeleteConfirmTitle'.tr(),
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8.h),
              Text(
                'reminderDeleteConfirmBody'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF64748B)),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('cancel'.tr()),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'reminderDelete'.tr(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true && context.mounted) {
      context.read<NotificationCubit>().deleteReminder(r.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationCubit(repo: sl<NotificationRepo>())
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
          body: BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              final list = state.personalReminders;
              return CustomScrollView(
                slivers: [
                  ReminderHeader(count: list.length),
                  // بانر التفعيل (يظهر لو الإذن مقفول بس).
                  if (!state.permissionGranted)
                    SliverToBoxAdapter(child: _EnableBanner(
                      onEnable: () =>
                          context.read<NotificationCubit>().enablePermissions(),
                    )),
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
                                .read<NotificationCubit>()
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

/// بانر صغير لتفعيل إذن الإشعارات.
class _EnableBanner extends StatelessWidget {
  final VoidCallback onEnable;
  const _EnableBanner({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.notifications_off_rounded, size: 18.sp, color: Colors.white),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'notifEnable'.tr(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFF92400E),
                ),
              ),
            ),
            FilledButton(
              onPressed: onEnable,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text('تفعيل', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
