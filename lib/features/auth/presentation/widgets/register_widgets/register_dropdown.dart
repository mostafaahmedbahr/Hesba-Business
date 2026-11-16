import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

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

    return DropdownButtonFormField<String>(
      initialValue: hasValue ? currentValue : null,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: AppTheme.primaryColor, size: 22.sp),
      borderRadius: BorderRadius.circular(15.r),
      dropdownColor: Colors.white,
      elevation: 4,
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
        prefixIcon: Padding(
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
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 17.h),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: AppTheme.primaryColor, width: 1.6),
        errorBorder: _border(color: AppTheme.danger),
        focusedErrorBorder: _border(color: AppTheme.danger, width: 1.6),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: items.isEmpty
          ? null
          : (value) {
              controller.text = value ?? '';
            },
    );
  }

  OutlineInputBorder _border({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.r),
      borderSide: BorderSide(color: color ?? AppTheme.borderSoft, width: width),
    );
  }
}
