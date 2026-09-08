import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/toast.dart';
import '../cubit/notification_cubit.dart';
import '../states/notification_state.dart';
import 'reminders_view.dart';
import '../../data/repos/notification_repo.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('notifTitle'.tr()),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocProvider(
        create: (_) => NotificationCubit(repo: sl<NotificationRepo>())..init(),
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                _buildHeroCard(context, state),
                SizedBox(height: 24.h),
                _sectionTitle('notifDailySection'.tr()),
                SizedBox(height: 12.h),
                _buildManageCard(context),
                SizedBox(height: 24.h),
                _sectionTitle('notifAppSection'.tr()),
                SizedBox(height: 12.h),
                _buildInfoCard(context),
                SizedBox(height: 24.h),
                _buildDeviceTokenCard(context, state),
                SizedBox(height: 24.h),
                _buildTestButton(context),
                SizedBox(height: 16.h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, NotificationState state) {
    final granted = state.permissionGranted;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A4FD6),
            Color(0xFF3B6FF5),
            Color(0xFF7C4DFF),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4FD6).withValues(alpha: 0.35),
            blurRadius: 20.r,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 30.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'notifHeroTitle'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'notifHeroDesc'.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: granted
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    granted
                        ? 'notifEnabled'.tr()
                        : 'notifEnable'.tr(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildManageCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RemindersView()),
      ),
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.12),
              blurRadius: 14.r,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: MoreTile(
          icon: Icons.event_note_rounded,
          iconGradient: const [Color(0xFF4CAF50), Color(0xFF8BC34A)],
          title: 'notifManageReminders'.tr(),
          subtitle: 'notifManageRemindersDesc'.tr(),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 14.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: MoreTile(
        icon: Icons.campaign_rounded,
        iconGradient: const [Color(0xFF1A4FD6), Color(0xFF3B6FF5)],
        title: 'notifAppDesc'.tr(),
        subtitle: 'notifAppDescHint'.tr(),
        trailing: null,
      ),
    );
  }

  Widget _buildDeviceTokenCard(BuildContext context, NotificationState state) {
    final token = state.fcmToken;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 14.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          MoreTile(
            icon: Icons.devices_rounded,
            iconGradient: const [Color(0xFF7C4DFF), Color(0xFFB388FF)],
            title: 'notifDeviceToken'.tr(),
            subtitle: token ?? 'notifDeviceTokenEmpty'.tr(),
            trailing: token == null
                ? null
                : InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: token));
                      if (!context.mounted) return;
                      AppToast.success(context, 'notifTokenCopied'.tr());
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 20.sp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: () => _sendTest(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A4FD6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        icon: const Icon(Icons.notifications_rounded),
        label: Text(
          'notifTest'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _sendTest(BuildContext context) async {
    final ok = await context
        .read<NotificationCubit>()
        .sendTest(
          title: 'notifTestPushTitle'.tr(),
          body: 'notifTestPushBody'.tr(),
        );
    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, 'notifTestSent'.tr());
    } else {
      AppToast.error(context, 'notifTestFailed'.tr());
    }
  }
}

class MoreTile extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const MoreTile({
    super.key,
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: iconGradient,
              ),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(icon, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
        ],
      ),
    );
  }
}