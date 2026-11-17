import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// صف اختيار موعد الاستحقاق (للمصروف المكرر فقط).
class ExpenseTimePickerRow extends StatelessWidget {
  final TimeOfDay dueTime;
  final bool isDark;
  final VoidCallback onTap;

  const ExpenseTimePickerRow({
    super.key,
    required this.dueTime,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkSurface
              : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorder
                : AppTheme.hairline,
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: AppTheme.amberDeep.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.schedule_rounded,
                size: 19.sp,
                color: AppTheme.amberDeep,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'موعد الاستحقاق',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.mutedGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    MaterialLocalizations.of(context)
                        .formatTimeOfDay(dueTime),
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? Colors.white
                          : AppTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.mutedGray,
            ),
          ],
        ),
      ),
    );
  }
}
