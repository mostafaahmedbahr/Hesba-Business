import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hesba/core/theme/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 108.w,
          height: 108.w,
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryColor.withValues(
                  alpha: 0.28,
                ),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/playstore.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.calculate_rounded,
                  size: 55.sp,
                  color: AppTheme.primaryColor,
                );
              },
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 800.ms,
          curve: Curves.elasticOut,
        ),

        SizedBox(height: 20.h),

        Text(
          'مرحباً بعودتك',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: AppTheme.fontFamily,
            height: 1.1,
          ),
        )
            .animate()
            .fadeIn(
          delay: 150.ms,
          duration: 500.ms,
        )
            .slideY(
          begin: 0.3,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        ),

        SizedBox(height: 8.h),

        Text(
          'سجل دخولك وابدأ إدارة محلك بسهولة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.75),
            fontFamily: AppTheme.fontFamily,
          ),
        )
            .animate()
            .fadeIn(
          delay: 300.ms,
          duration: 500.ms,
        )
            .slideY(
          begin: 0.25,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}