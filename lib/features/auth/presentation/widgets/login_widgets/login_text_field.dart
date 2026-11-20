import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFD),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
        border: _border(isDark: isDark),
        enabledBorder: _border(isDark: isDark),
        focusedBorder: _border(
          isDark: isDark,
          color: isDark ? AppTheme.primaryLight : AppTheme.deepBlue,
        ),
        errorBorder: _border(isDark: isDark, color: Colors.redAccent),
        focusedErrorBorder: _border(isDark: isDark, color: Colors.redAccent),
      ),
    );
  }

  OutlineInputBorder _border({required bool isDark, Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(
        color: color ?? (isDark ? AppTheme.darkBorder : Colors.grey.shade200),
      ),
    );
  }
}
