import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/shop_image_view.dart';
import '../../../../dashboard/presentation/states/dashboard_state.dart';
import '../../../../notifications/presentation/view_model/activity_cubit.dart';
import '../../../../notifications/presentation/view_model/activity_state.dart';
import '../../../../notifications/presentation/views/notifications_view.dart';

/// شريط الـ Home العلوي: زر القائمة + صورة المحل + اسمه + التاريخ + الإشعارات.
class HomeHeaderBar extends StatelessWidget {
  final DashboardState state;
  final VoidCallback? onOpenDrawer;
  const HomeHeaderBar({super.key, required this.state, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final date = DateFormat('EEEE d MMMM', context.locale.languageCode)
        .format(DateTime.now());

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, topPad + 8.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
        ),
      ),
      child: Row(
        children: [
          // زر القائمة (Drawer)
          InkWell(
            onTap: onOpenDrawer ??
                () {
                  final scaffold = Scaffold.maybeOf(context);
                  scaffold?.openDrawer();
                },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
              ),
              child: Icon(Icons.menu_rounded, size: 20.sp, color: isDark ? Colors.white : AppTheme.ink),
            ),
          ),
          SizedBox(width: 8.w),
          // صورة المحل
          ShopImageView(
            imageUrl: state.shopImageUrl,
            size: 44.w,
            borderRadius: 14,
            fallbackIcon: Icons.storefront_rounded,
            withShadow: true,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.shopName.isEmpty ? 'appName'.tr() : state.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11.sp,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.mutedGray),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.slateGray,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // الإشعارات مع عدّاد
          BlocBuilder<ActivityCubit, ActivityState>(
            builder: (context, activity) {
              final unread = activity.unreadCount;
              return InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsView())),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 22.sp,
                          color: isDark ? Colors.white : AppTheme.ink),
                      if (unread > 0)
                        Positioned(
                          top: 6.h,
                          right: 6.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: unread > 9 ? 5.w : 0, vertical: 2.h),
                            constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: isDark ? AppTheme.darkSurfaceAlt : Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text(unread > 99 ? '99+' : '$unread',
                                  style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                            ),
                          ),
                        )
                      else if (state.lowStockCount > 0)
                        Positioned(
                          top: 10.h,
                          right: 10.w,
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: AppTheme.warningAmber,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppTheme.darkSurfaceAlt : Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
