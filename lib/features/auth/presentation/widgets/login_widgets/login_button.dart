import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hesba/core/theme/app_theme.dart';

class LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppTheme.secondaryDark,
              AppTheme.secondaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(17.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryColor.withValues(
                alpha: 0.28,
              ),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17.r),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLoading
                ? SizedBox(
              key: const ValueKey('loading'),
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
                : Row(
              key: const ValueKey('button'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                SizedBox(width: 10.w),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 21.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}