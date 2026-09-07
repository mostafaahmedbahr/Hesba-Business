import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final size = 145.w;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size + 35.w,
          height: size + 35.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .035),
            border: Border.all(
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
        ),

        Container(
          width: size + 15.w,
          height: size + 15.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryColor.withValues(alpha: .18),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
        ),

        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(38.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .20),
                blurRadius: 35,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/playstore.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, __) {
              return Icon(
                Icons.calculate_rounded,
                size: 65.sp,
                color: AppTheme.primaryColor,
              );
            },
          ),
        ),
      ],
    );
  }
}