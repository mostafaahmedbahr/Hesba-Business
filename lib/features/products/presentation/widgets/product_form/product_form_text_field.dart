import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// زخرفة الحقول الموحدة لفورم المنتج (فاتح/داكن).
InputDecoration productFormDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? icon,
  bool required = false,
  String? suffix,
  Widget? suffixIcon,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    labelText: required ? '$label *' : label,
    hintText: hint,
    hintStyle: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray),
    labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
    prefixIcon: icon == null
        ? null
        : Container(
            margin: EdgeInsets.all(8.w),
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 16.sp, color: AppTheme.primaryColor),
          ),
    suffixText: suffix,
    suffixStyle: TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.w700,
      color: AppTheme.primaryColor,
    ),
    suffixIcon: suffixIcon,
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
      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppTheme.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppTheme.danger, width: 1.6),
    ),
  );
}

/// حقل نصي موحّد بقوالب التحقق من نوع الحقل.
class ProductFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool required;
  final String? suffix;
  final TextInputType? keyboard;
  final int maxLines;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const ProductFormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.required = false,
    this.suffix,
    this.keyboard,
    this.maxLines = 1,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard ?? TextInputType.text,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
      decoration: productFormDecoration(
        context,
        label: label,
        hint: hint,
        icon: icon,
        required: required,
        suffix: suffix,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
