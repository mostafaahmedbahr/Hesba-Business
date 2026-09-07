import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showLogo;

  const AuthHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showLogo) ...[
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/splash/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ],
    );
  }
}
