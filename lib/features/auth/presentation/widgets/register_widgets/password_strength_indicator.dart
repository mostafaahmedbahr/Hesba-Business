import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:hesba/core/theme/app_theme.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        _buildRule(context, 'strength8Chars'.tr(), password.length >= 8),
        SizedBox(height: 4.h),
        _buildRule(context, 'strengthUpper'.tr(), RegExp(r'[A-Z]').hasMatch(password)),
        SizedBox(height: 4.h),
        _buildRule(context, 'strengthLower'.tr(), RegExp(r'[a-z]').hasMatch(password)),
        SizedBox(height: 4.h),
        _buildRule(context, 'strengthDigit'.tr(), RegExp(r'[0-9]').hasMatch(password)),
        SizedBox(height: 4.h),
        _buildRule(
          context,
          'strengthSpecial'.tr(),
          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
        ),
      ],
    );
  }

  Widget _buildRule(BuildContext context, String text, bool passed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ruleColor = isDark ? AppTheme.successColor : const Color(0xFF4CAF50);
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 16.w,
          color: passed
              ? ruleColor
              : (isDark ? AppTheme.darkBorder : Colors.grey.shade400),
        ),
        SizedBox(width: 8.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: passed
                ? ruleColor
                : (isDark
                    ? AppTheme.darkTextSecondary
                    : Colors.grey.shade500),
            fontWeight: passed ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  static bool isStrong(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }
}
