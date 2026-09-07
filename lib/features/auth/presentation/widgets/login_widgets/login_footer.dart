import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hesba/core/theme/app_theme.dart';

class LoginFooter extends StatelessWidget {
  final VoidCallback onRegister;

  const LoginFooter({
    super.key,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppTheme.fontFamily,
          ),
        ),

        SizedBox(width: 7.w),

        InkWell(
          onTap: onRegister,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 13.w,
              vertical: 7.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              'إنشاء حساب',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(
      delay: 700.ms,
      duration: 500.ms,
    )
        .slideY(
      begin: 0.2,
      end: 0,
      duration: 500.ms,
    );
  }
}