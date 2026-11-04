import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// بطاقة قسم داخل فورم المنتج (أيقونة + عنوان + محتوى) بنفس هوية Hesba.
class ProductFormSectionCard extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final List<Color> gradient;
  final Widget child;

  const ProductFormSectionCard({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.gradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  titleKey.tr(),
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}
