import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

class RegisterTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const RegisterTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),

        filled: true,
        fillColor: const Color(0xFFF8FAFD),

        contentPadding:
        EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),

        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(
          color: AppTheme.deepBlue,
        ),
        errorBorder: _border(
          color: Colors.redAccent,
        ),
        focusedErrorBorder: _border(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  OutlineInputBorder _border({
    Color? color,
  }) {
    return OutlineInputBorder(
      borderRadius:
      BorderRadius.circular(14.r),
      borderSide: BorderSide(
        color: color ?? Colors.grey.shade200,
      ),
    );
  }
}