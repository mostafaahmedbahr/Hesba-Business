import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// مفتاح تبديل (حالة التوفر) بأسلوب Hesba.
class ProductFormToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String onLabel;
  final String offLabel;

  const ProductFormToggle({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.onLabel,
    required this.offLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 16.sp, color: AppTheme.primaryColor),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.ink,
              ),
            ),
          ),
          Text(
            value ? onLabel : offLabel,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: value ? AppTheme.successDark : AppTheme.mutedGray,
            ),
          ),
          SizedBox(width: 6.w),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.successDark,
          ),
        ],
      ),
    );
  }
}
