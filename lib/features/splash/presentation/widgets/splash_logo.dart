import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = 132.w;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Pulsing halo rings
        Container(
          width: size + 56.w,
          height: size + 56.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? Colors.white : AppTheme.primaryColor)
                  .withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
        ),
        Container(
          width: size + 30.w,
          height: size + 30.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDark ? Colors.white : AppTheme.primaryColor)
                .withValues(alpha: 0.06),
            border: Border.all(
              color: (isDark ? Colors.white : AppTheme.primaryColor)
                  .withValues(alpha: 0.10),
            ),
          ),
        ),
        // Glow under card
        Container(
          width: size + 10.w,
          height: size + 10.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.45 : 0.28),
                blurRadius: 50.r,
                spreadRadius: 6.r,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: AppTheme.secondaryColor.withValues(alpha: 0.22),
                blurRadius: 30.r,
                spreadRadius: 2.r,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        // Gradient border wrapper
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(2.2.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.9),
                AppTheme.secondaryColor.withValues(alpha: 0.85),
                AppTheme.primaryColor.withValues(alpha: 0.7),
                Colors.white.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32.r),
            ),
            child: Image.asset(
              'assets/images/playstore.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.calculate_rounded,
                    size: 58.sp,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        // Floating gold badge
        Positioned(
          bottom: 6.h,
          right: -2.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.45),
                  blurRadius: 14.r,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 12.sp, color: Colors.white),
                SizedBox(width: 3.w),
                Text(
                  '2026',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}