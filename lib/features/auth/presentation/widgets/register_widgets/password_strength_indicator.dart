import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        _buildRule('strength8Chars'.tr(), password.length >= 8),
        SizedBox(height: 4.h),
        _buildRule('strengthUpper'.tr(), RegExp(r'[A-Z]').hasMatch(password)),
        SizedBox(height: 4.h),
        _buildRule('strengthLower'.tr(), RegExp(r'[a-z]').hasMatch(password)),
        SizedBox(height: 4.h),
        _buildRule('strengthDigit'.tr(), RegExp(r'[0-9]').hasMatch(password)),
        SizedBox(height: 4.h),
        _buildRule(
          'strengthSpecial'.tr(),
          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
        ),
      ],
    );
  }

  Widget _buildRule(String text, bool passed) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 16.w,
          color: passed ? const Color(0xFF4CAF50) : Colors.grey.shade400,
        ),
        SizedBox(width: 8.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: passed ? const Color(0xFF4CAF50) : Colors.grey.shade500,
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
