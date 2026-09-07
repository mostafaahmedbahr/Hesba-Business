import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/theme/app_theme.dart';

class SplashFooter extends StatelessWidget {
  const SplashFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
            ),

            SizedBox(width: 8.w),

            Text(
              'splashFooter'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: .42),
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w500,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),

        SizedBox(height: 8.h),

        Text(
          'splashCopyright'.tr(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: .25),
            fontSize: 9.sp,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }
}