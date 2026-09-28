import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
                  const Color(0xFF1A4FD6).withValues(alpha: 0.12),
                  const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 44.sp,
                color: const Color(0xFF1A4FD6),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'remindersEmpty'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'remindersEmptyHint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, height: 1.6, color: const Color(0xFF64748B)),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4FD6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'remindersAddButton'.tr(),
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
