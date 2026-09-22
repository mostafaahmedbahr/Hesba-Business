import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../cubit/activity_cubit.dart';
import '../cubit/activity_state.dart';
import '../cubit/notification_cubit.dart';
import '../states/notification_state.dart';
import '../../data/models/activity_model.dart';
import '../../data/repos/activity_repo.dart';
import '../../data/repos/notification_repo.dart';
import 'reminders_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});
  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    // صفر العداد بعد ما يفتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      try {
        // mark via ActivityRepo directly if cubit not yet available, but we have cubit below
        final repo = sl<ActivityRepo>();
        await repo.markAllRead();
      } catch (_) {}
    });
  }

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
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => NotificationCubit(repo: sl<NotificationRepo>())..init()),
          BlocProvider(create: (_) => ActivityCubit(repo: sl<ActivityRepo>())),
        ],
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.all(18.w),
              children: [
                // ——— قسم الإشعارات / الأنشطة (الجديد) ———
                _ActivitySection(),
                SizedBox(height: 22.h),
                _buildHeroCard(context, state),
                SizedBox(height: 22.h),
                _sectionTitle('notifDailySection'.tr()),
                SizedBox(height: 10.h),
                _buildManageCard(context),
                SizedBox(height: 22.h),
                _sectionTitle('notifAppSection'.tr()),
                SizedBox(height: 10.h),
                _buildInfoCard(context),
                SizedBox(height: 22.h),
                _buildDeviceTokenCard(context, state),
                SizedBox(height: 22.h),
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
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4FD6), Color(0xFF3B6FF5), Color(0xFF7C4DFF)],
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [BoxShadow(color: const Color(0xFF1A4FD6).withValues(alpha: 0.35), blurRadius: 20.r, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 56.w, height: 56.w,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('notifHeroTitle'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(height: 4.h),
              Text('notifHeroDesc'.tr(), style: TextStyle(fontSize: 11.5.sp, color: Colors.white.withValues(alpha: 0.85), height: 1.4)),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(color: granted ? const Color(0xFF4CAF50).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20.r)),
                child: Text(granted ? 'notifEnabled'.tr() : 'notifEnable'.tr(), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface));
  }

  Widget _buildManageCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RemindersView())),
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18.r), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 14.r, offset: const Offset(0, 6))]),
        child: MoreTile(icon: Icons.event_note_rounded, iconGradient: const [Color(0xFF4CAF50), Color(0xFF8BC34A)], title: 'notifManageReminders'.tr(), subtitle: 'notifManageRemindersDesc'.tr(), trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18.r), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 14.r, offset: const Offset(0, 6))]),
      child: MoreTile(icon: Icons.campaign_rounded, iconGradient: const [Color(0xFF1A4FD6), Color(0xFF3B6FF5)], title: 'notifAppDesc'.tr(), subtitle: 'notifAppDescHint'.tr(), trailing: null),
    );
  }

  Widget _buildDeviceTokenCard(BuildContext context, NotificationState state) {
    final token = state.fcmToken;
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18.r), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 14.r, offset: const Offset(0, 6))]),
      child: MoreTile(
        icon: Icons.devices_rounded,
        iconGradient: const [Color(0xFF7C4DFF), Color(0xFFB388FF)],
        title: 'notifDeviceToken'.tr(),
        subtitle: token ?? 'notifDeviceTokenEmpty'.tr(),
        trailing: token == null ? null : InkWell(onTap: () async { await Clipboard.setData(ClipboardData(text: token)); if (!context.mounted) return; AppToast.success(context, 'notifTokenCopied'.tr()); }, borderRadius: BorderRadius.circular(8.r), child: Padding(padding: EdgeInsets.all(8.w), child: Icon(Icons.copy_rounded, size: 20.sp, color: Theme.of(context).colorScheme.primary))),
      ),
    );
  }

  Widget _buildTestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 50.h,
      child: ElevatedButton.icon(
        onPressed: () => _sendTest(context),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A4FD6), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))),
        icon: const Icon(Icons.notifications_rounded),
        label: Text('notifTest'.tr(), style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _sendTest(BuildContext context) async {
    final ok = await context.read<NotificationCubit>().sendTest(title: 'notifTestPushTitle'.tr(), body: 'notifTestPushBody'.tr());
    if (!context.mounted) return;
    if (ok) { AppToast.success(context, 'notifTestSent'.tr()); } else { AppToast.error(context, 'notifTestFailed'.tr()); }
  }
}

class _ActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        final list = state.activities;
        final unread = state.unreadCount;

        // auto mark read after view visible (extra safety)
        if (unread > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.read<ActivityCubit>().markAllRead();
          });
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 38.w, height: 38.w,
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(11.r)),
                child: Icon(Icons.notifications_rounded, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('النشاطات', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  SizedBox(width: 8.w),
                  if (unread > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(20.r)),
                      child: Text('$unread جديدة', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                ]),
                Text('كل إضافة / تعديل / حذف يتسجل هنا', style: TextStyle(fontSize: 11.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
              ])),
              if (list.isNotEmpty)
                TextButton(
                  onPressed: () => context.read<ActivityCubit>().markAllRead(),
                  child: Text('تعليم كمقروء', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                ),
            ]),
            SizedBox(height: 14.h),
            if (list.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24.h),
                decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                child: Column(children: [
                  Icon(Icons.inbox_rounded, size: 32.sp, color: const Color(0xFF94A3B8)),
                  SizedBox(height: 8.h),
                  Text('لا يوجد إشعارات بعد', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                  SizedBox(height: 4.h),
                  Text('أي عملية على المنتجات أو المبيعات أو المصروفات هتظهر هنا', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
                ]),
              )
            else
              Column(
                children: list.take(12).map((a) => _activityTile(context, a, isDark)).toList(),
              ),
            if (list.length > 12)
              Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Center(child: Text('+ ${list.length - 12} إشعار أقدم', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8)))),
              ),
          ]),
        );
      },
    );
  }

  Widget _activityTile(BuildContext context, ActivityModel a, bool isDark) {
    final iconData = _iconFor(a.type);
    final grad = _gradFor(a.type);
    final time = _timeAgo(a.createdAt);
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: a.isRead ? (isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC)) : (isDark ? const Color(0xFF1E2A44) : const Color(0xFFEFF6FF)),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: a.isRead ? (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)) : AppTheme.primaryColor.withValues(alpha: 0.14)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38.w, height: 38.w, decoration: BoxDecoration(gradient: LinearGradient(colors: grad), borderRadius: BorderRadius.circular(10.r)), child: Icon(iconData, color: Colors.white, size: 18.sp)),
        SizedBox(width: 10.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.title, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          SizedBox(height: 2.h),
          Text(a.body, style: TextStyle(fontSize: 11.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
          SizedBox(height: 6.h),
          Row(children: [
            Icon(Icons.access_time_rounded, size: 11.sp, color: const Color(0xFF94A3B8)),
            SizedBox(width: 4.w),
            Text(time, style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF94A3B8))),
            if (!a.isRead) ...[
              SizedBox(width: 8.w),
              Container(width: 6.w, height: 6.w, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE11D48))),
              SizedBox(width: 4.w),
              Text('جديد', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
            ],
          ]),
        ])),
      ]),
    );
  }

  IconData _iconFor(ActivityType t) {
    switch (t) {
      case ActivityType.sale: return Icons.point_of_sale_rounded;
      case ActivityType.saleUpdate: return Icons.edit_rounded;
      case ActivityType.saleDelete: return Icons.delete_rounded;
      case ActivityType.productAdd: return Icons.add_shopping_cart_rounded;
      case ActivityType.productUpdate: return Icons.edit_rounded;
      case ActivityType.productDelete: return Icons.delete_rounded;
      case ActivityType.returnAdd: return Icons.assignment_return_rounded;
      case ActivityType.expenseAdd: return Icons.savings_rounded;
      case ActivityType.expenseUpdate: return Icons.edit_rounded;
      case ActivityType.expenseDelete: return Icons.delete_rounded;
      case ActivityType.generic: return Icons.notifications_rounded;
    }
  }

  List<Color> _gradFor(ActivityType t) {
    switch (t) {
      case ActivityType.sale: return const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)];
      case ActivityType.productAdd: return const [Color(0xFFF59E0B), Color(0xFFFBBF24)];
      case ActivityType.productUpdate: return const [Color(0xFF7C3AED), Color(0xFFA78BFA)];
      case ActivityType.productDelete: return const [Color(0xFFE11D48), Color(0xFFFB7185)];
      case ActivityType.returnAdd: return const [Color(0xFFF59E0B), Color(0xFFFF8F3D)];
      case ActivityType.expenseAdd: return const [Color(0xFFE11D48), Color(0xFFFB7185)];
      case ActivityType.expenseUpdate: return const [Color(0xFF06B6D4), Color(0xFF22D3EE)];
      case ActivityType.expenseDelete: return const [Color(0xFF64748B), Color(0xFF94A3B8)];
      default: return const [Color(0xFF1A4FD6), Color(0xFF7C4DFF)];
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('d MMM', 'ar').format(dt);
  }
}

class MoreTile extends StatelessWidget {
  final IconData icon; final List<Color> iconGradient; final String title; final String subtitle; final Widget? trailing;
  const MoreTile({super.key, required this.icon, required this.iconGradient, required this.title, required this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(children: [
        Container(width: 44.w, height: 44.w, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: iconGradient), borderRadius: BorderRadius.circular(13.r)), child: Icon(icon, color: Colors.white, size: 22.sp)),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
          SizedBox(height: 2.h),
          Text(subtitle, style: TextStyle(fontSize: 11.5.sp, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.3)),
        ])),
        if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
      ]),
    );
  }
}
