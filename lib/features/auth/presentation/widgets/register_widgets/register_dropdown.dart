import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

/// قائمة اختيار بنفس مظهر باقي حقول التسجيل.
class RegisterDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final List<String> items;
  final String? Function(String?)? validator;

  const RegisterDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.items,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = controller.text;
    final hasValue = currentValue.isNotEmpty && items.contains(currentValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return DropdownButtonFormField<String>(
      initialValue: hasValue ? currentValue : null,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: accent, size: 22.sp),
      borderRadius: BorderRadius.circular(15.r),
      dropdownColor: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
      elevation: 4,
      style: TextStyle(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12.sp,
          color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade400,
        ),
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
            child: Icon(icon, size: 17.sp, color: accent),
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
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e.tr())))
          .toList(),
      onChanged: items.isEmpty
          ? null
          : (value) {
              controller.text = value ?? '';
            },
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
