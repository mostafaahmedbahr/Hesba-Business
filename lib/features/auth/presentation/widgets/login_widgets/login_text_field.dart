import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hesba/core/theme/app_theme.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(
        color: const Color(0xFF172033),
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        fontFamily: AppTheme.fontFamily,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        labelStyle: TextStyle(
          color: const Color(0xFF7B8496),
          fontSize: 13.sp,
          fontFamily: AppTheme.fontFamily,
        ),

        hintStyle: TextStyle(
          color: const Color(0xFFC0C6D0),
          fontSize: 13.sp,
          fontFamily: AppTheme.fontFamily,
        ),

        prefixIcon: Container(
          margin: EdgeInsetsDirectional.only(
            start: 10.w,
            end: 8.w,
            top: 8.h,
            bottom: 8.h,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(
              alpha: 0.07,
            ),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20.sp,
          ),
        ),

        suffixIcon: suffixIcon,

        filled: true,
        fillColor: const Color(0xFFF7F9FC),

        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 18.h,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(
            color: Color(0xFFE8ECF2),
            width: 1,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}