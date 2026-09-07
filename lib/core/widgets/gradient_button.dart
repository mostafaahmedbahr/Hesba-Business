import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hesba/core/theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const GradientButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.secondaryColor, AppTheme.secondaryDark]),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
        child: isLoading
            ? SizedBox(height: 24.h, width: 24.h, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: AppTheme.fontFamily)),
                  SizedBox(width: 8.w),
                  Icon(icon, size: 18, color: Colors.white),
                ],
              ),
      ),
    );
  }
}
