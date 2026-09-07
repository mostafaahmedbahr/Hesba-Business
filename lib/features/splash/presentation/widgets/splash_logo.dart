import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165.w,
      height: 165.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withValues(
              alpha: 0.35,
            ),
            blurRadius: 45,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(
            alpha: 0.15,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.15,
            ),
            width: 1,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/playstore.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return const Icon(
                Icons.calculate_rounded,
                color: Colors.white,
                size: 70,
              );
            },
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
      duration: 450.ms,
    )
        .scale(
      begin: const Offset(0.25, 0.25),
      end: const Offset(1, 1),
      duration: 900.ms,
      curve: Curves.elasticOut,
    )
        .then()
        .shimmer(
      duration: 1400.ms,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}