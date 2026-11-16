import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

/// عنوان قسم داخل الخطوة: شريط لوني + أيقونة + عنوان ووصف.
class RegisterSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const RegisterSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.description_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4.w,
          height: 42.h,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(icon, size: 18.sp, color: AppTheme.primaryColor),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  color: Colors.grey.shade500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
