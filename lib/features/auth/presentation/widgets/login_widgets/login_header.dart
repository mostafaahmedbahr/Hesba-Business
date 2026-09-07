import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../core/theme/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64.w,
          height: 64.w,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Image.asset(
            'assets/images/playstore.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.calculate_rounded,
              size: 32.sp,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          'loginTitle'.tr(),
          style: TextStyle(
            fontSize: 25.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF102A43),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'loginSubtitle'.tr(),
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
