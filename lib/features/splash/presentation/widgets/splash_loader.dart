import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

class SplashLoader extends StatelessWidget {
  const SplashLoader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42.w,
      height: 42.w,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        backgroundColor: Colors.white.withValues(
          alpha: 0.12,
        ),
        valueColor: AlwaysStoppedAnimation<Color>(
          AppTheme.secondaryColor,
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: 800.ms,
      duration: 400.ms,
    )
        .scale(
      begin: const Offset(0.5, 0.5),
      end: const Offset(1, 1),
      delay: 800.ms,
      duration: 500.ms,
      curve: Curves.easeOutBack,
    );
  }
}