import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// حقل المبلغ الكبير.
class ExpenseBigAmountField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onChanged;
  final String Function(String) toLatin;

  const ExpenseBigAmountField({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onChanged,
    required this.toLatin,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 26.sp,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : AppTheme.ink,
      ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(
          fontSize: 26.sp,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFCBD5E1),
        ),
        suffixText: 'ج.م',
        suffixStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: AppTheme.danger,
        ),
        filled: true,
        fillColor: AppTheme.danger.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: AppTheme.danger.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppTheme.danger),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'المبلغ مطلوب';
        final a = double.tryParse(toLatin(v));
        if (a == null || a <= 0) return 'أدخل مبلغ صحيح';
        return null;
      },
      onChanged: (_) => onChanged(),
    );
  }
}
