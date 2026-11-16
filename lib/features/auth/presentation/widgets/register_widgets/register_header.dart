import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/theme/app_theme.dart';

/// هيدر شاشة التسجيل: بانر ب-gradient مع شعار المحل ولمسة زخرفية خفيفة.
class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 30.h),
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Stack(
        children: [
          // زخارف خفيفة في الخلفية.
          Positioned(
            top: -70.h,
            left: -40.w,
            child: _Glow(size: 170.w, color: Colors.white),
          ),
          Positioned(
            bottom: -90.h,
            right: -50.w,
            child: _Glow(size: 190.w, color: AppTheme.secondaryColor),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                padding: EdgeInsets.all(9.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Image.asset(
                  'assets/images/playstore.png',
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.calculate_rounded, size: 30.sp, color: Colors.white),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'registerTitle'.tr(),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      'registerSubtitle'.tr(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
      ),
    );
  }
}
