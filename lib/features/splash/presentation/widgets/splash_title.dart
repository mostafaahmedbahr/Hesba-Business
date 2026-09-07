import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

class SplashTitle extends StatelessWidget {
  const SplashTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// App name
        Text(
          'حسبة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 52.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: AppTheme.fontFamily,
            height: 1,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(
          delay: 250.ms,
          duration: 600.ms,
        )
            .slideY(
          begin: 0.35,
          end: 0,
          delay: 250.ms,
          duration: 650.ms,
          curve: Curves.easeOutCubic,
        )
            .shimmer(
          delay: 900.ms,
          duration: 1200.ms,
          color: AppTheme.secondaryColor.withValues(
            alpha: 0.35,
          ),
        ),

        SizedBox(height: 12.h),

        /// Tagline
        Text(
          'نظام إدارة المحلات الذكي',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(
              alpha: 0.88,
            ),
            fontFamily: AppTheme.fontFamily,
            height: 1.4,
          ),
        )
            .animate()
            .fadeIn(
          delay: 450.ms,
          duration: 600.ms,
        )
            .slideY(
          begin: 0.4,
          end: 0,
          delay: 450.ms,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}