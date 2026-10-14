import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

/// الفاضي (مفيش تذكيرات).
class ReminderEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const ReminderEmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.12),
                  const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 44.sp,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'remindersEmpty'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.ink,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'remindersEmptyHint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, height: 1.6, color: AppTheme.slateGray),
            ),
            SizedBox(height: 20.h),

          ],
        ),
      ),
    );
  }
}
