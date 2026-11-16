import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

/// حقل نص موحّد لشاشة التسجيل: أيقونة في شريحة ملوّنة، حدود ناعمة،
/// ولون مميز وقت التركيز أو الخطأ.
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
      style: TextStyle(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
        labelStyle: TextStyle(
          fontSize: 12.5.sp,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: _IconChip(icon: icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 17.h),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: AppTheme.primaryColor, width: 1.6),
        errorBorder: _border(color: AppTheme.danger),
        focusedErrorBorder: _border(color: AppTheme.danger, width: 1.6),
      ),
    );
  }

  OutlineInputBorder _border({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.r),
      borderSide: BorderSide(color: color ?? AppTheme.borderSoft, width: width),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;

  const _IconChip({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 4.w, 12.h),
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: AppTheme.primarySoft,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 17.sp, color: AppTheme.primaryColor),
      ),
    );
  }
}
