import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/local_reminder.dart';
import '../utils/reminder_labels.dart';

/// كارت تذكير (وقت + عنوان + تكرار + تفعيل/تجربة/تعديل/حذف).
class ReminderCard extends StatelessWidget {
  final LocalReminder reminder;
  final VoidCallback? onToggle;
  final VoidCallback? onTest;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onToggle,
    this.onTest,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = reminder.enabled;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimeBadge(reminder: reminder),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (onToggle != null)
                        Switch(
                          value: enabled,
                          activeThumbColor: const Color(0xFF1A4FD6),
                          onChanged: (_) => onToggle!(),
                        ),
                    ],
                  ),
                  if (reminder.body.trim().isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      reminder.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        height: 1.4,
                        color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      _RepeatPill(reminder: reminder),
                      const Spacer(),
                      // يبعت الإشعار فورًا عشان تتأكد إنه شغال.
                      if (onTest != null)
                        _SmallBtn(
                          icon: Icons.notifications_active_rounded,
                          color: const Color(0xFF059669),
                          onTap: onTest!,
                        ),
                      SizedBox(width: 6.w),
                      if (onEdit != null)
                        _SmallBtn(
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF1A4FD6),
                          onTap: onEdit!,
                        ),
                      SizedBox(width: 6.w),
                      if (onDelete != null)
                        _SmallBtn(
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFE11D48),
                          onTap: onDelete!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مربع الوقت (12h + AM/PM).
class _TimeBadge extends StatelessWidget {
  final LocalReminder reminder;
  const _TimeBadge({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final h12 = reminder.hour % 12 == 0 ? 12 : reminder.hour % 12;
    final isAm = reminder.hour < 12;
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        gradient: !reminder.enabled
            ? LinearGradient(colors: [
                Colors.grey.withValues(alpha: 0.35),
                Colors.grey.withValues(alpha: 0.25),
              ])
            : const LinearGradient(
                colors: [Color(0xFF1A4FD6), Color(0xFF7C4DFF)],
              ),
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: reminder.enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF1A4FD6).withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$h12:${reminder.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          Text(
            isAm ? 'AM' : 'PM',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة التكرار (يومي / أسبوعي + اليوم).
class _RepeatPill extends StatelessWidget {
  final LocalReminder reminder;
  const _RepeatPill({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = reminder.repeat == ReminderRepeat.weekly
        ? '${'repeatWeekly'.tr()} • ${weekdayShort(context, reminder.weekday ?? 1)}'
        : 'repeatDaily'.tr();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A4FD6).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF1A4FD6).withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_repeat_rounded, size: 12.sp, color: const Color(0xFF1A4FD6)),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF93B4FF) : const Color(0xFF1A4FD6),
            ),
          ),
        ],
      ),
    );
  }
}

/// زرار أيقونة صغير.
class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, size: 16.sp, color: color),
      ),
    );
  }
}
