import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';

class SplashBrand extends StatelessWidget {
  const SplashBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'حسبة',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 45.sp,
            fontWeight: FontWeight.w900,
            height: 1,
            fontFamily: AppTheme.fontFamily,
            letterSpacing: .5,
          ),
        ),

        SizedBox(height: 12.h),

        Text(
          'إدارة محلك أصبحت أبسط',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .70),
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppTheme.fontFamily,
          ),
        ),

        SizedBox(height: 18.h),

        Container(
          width: 55.w,
          height: 3.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            gradient: LinearGradient(
              colors: [
                AppTheme.secondaryColor.withValues(alpha: .25),
                AppTheme.secondaryColor,
                AppTheme.secondaryColor.withValues(alpha: .25),
              ],
            ),
          ),
        ),
      ],
    );
  }
}