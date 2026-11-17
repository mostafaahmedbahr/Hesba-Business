import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// chip تصنيف بأيقونة ولون.
class ExpenseCategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const ExpenseCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
              : null,
          color: selected
              ? null
              : (isDark ? AppTheme.darkSurfaceAlt : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : AppTheme.cardShadow(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17.sp, color: selected ? Colors.white : color),
            SizedBox(width: 7.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
