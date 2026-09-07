import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';

class SplashLoader extends StatelessWidget {
  const SplashLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 90.w,
          height: 4.h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withValues(alpha: .08),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.secondaryColor,
              ),
            ),
          ),
        )
            .animate(
          onPlay: (controller) => controller.repeat(),
        )
            .shimmer(
          duration: 1300.ms,
        ),

        SizedBox(height: 13.h),

        Text(
          'جاري تجهيز حسابك...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .45),
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }
}