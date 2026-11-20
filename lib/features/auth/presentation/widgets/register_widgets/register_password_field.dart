import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

/// حقل كلمة المرور مع زر إظهار/إخفاء وحدود تعكس حالة التحقق.
class RegisterPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  final String? Function(String?)? validator;

  const RegisterPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12.5.sp,
          color: accent,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 4.w, 12.h),
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.lock_outline_rounded,
                size: 17.sp, color: accent),
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          color: accent,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20.sp,
          ),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 17.h),
        border: _border(isDark: isDark),
        enabledBorder: _border(isDark: isDark),
        focusedBorder: _border(isDark: isDark, color: accent, width: 1.6),
        errorBorder: _border(isDark: isDark, color: AppTheme.danger),
        focusedErrorBorder: _border(isDark: isDark, color: AppTheme.danger, width: 1.6),
      ),
    );
  }

  OutlineInputBorder _border({
    required bool isDark,
    Color? color,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.r),
      borderSide: BorderSide(
        color: color ?? (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
        width: width,
      ),
    );
  }
}
