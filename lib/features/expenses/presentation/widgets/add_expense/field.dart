import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// حقل عادي موحد.
class ExpenseField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final VoidCallback onChanged;
  final FormFieldValidator<String>? validator;

  const ExpenseField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: (_) => onChanged(),
      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray),
        labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
        prefixIcon: Container(
          margin: EdgeInsets.all(8.w),
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 16.sp, color: AppTheme.danger),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppTheme.danger),
        ),
      ),
    );
  }
}
