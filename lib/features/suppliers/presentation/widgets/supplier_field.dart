import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';

/// زخرفة حقول المورد الموحدة (فاتح/داكن) — بنفس روح فورم المنتج.
InputDecoration supplierFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? icon,
  bool required = false,
  Widget? suffixIcon,
  bool hasError = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final borderColor = hasError ? AppTheme.danger : null;
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
              color: AppTheme.violetDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: AppTheme.violetDeep),
          ),
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(
        color:
            borderColor ?? (isDark ? AppTheme.darkBorder : AppTheme.hairline),
        width: hasError ? 1.4 : 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(
        color: hasError ? AppTheme.danger : AppTheme.violetDeep,
        width: 1.4,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppTheme.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppTheme.danger, width: 1.4),
    ),
    filled: true,
    fillColor: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
    floatingLabelStyle: const TextStyle(color: AppTheme.violetDeep),
  );
}

/// حقل نصي موحّد لفورم المورد (يمتلك كنترولره بنفسه).
///
/// القيم تُبلَّغ عبر [onChanged] إلى الـ Cubit — لا setState في أي مكان.
class SupplierField extends StatefulWidget {
  final String labelKey;
  final String? hintKey;
  final IconData? icon;
  final bool required;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? initialValue;
  final bool autofocus;
  final bool hasError;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String> onChanged;

  const SupplierField({
    super.key,
    required this.labelKey,
    required this.onChanged,
    this.hintKey,
    this.icon,
    this.required = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.initialValue,
    this.autofocus = false,
    this.hasError = false,
    this.onFieldSubmitted,
  });

  @override
  State<SupplierField> createState() => _SupplierFieldState();
}

class _SupplierFieldState extends State<SupplierField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onFieldSubmitted,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      textInputAction:
          widget.textInputAction ??
          (widget.maxLines > 1
              ? TextInputAction.newline
              : TextInputAction.next),
      inputFormatters: widget.inputFormatters,
      style: TextStyle(fontSize: 13.5.sp),
      decoration: supplierFieldDecoration(
        context,
        label: widget.labelKey.tr(),
        hint: widget.hintKey?.tr(),
        icon: widget.icon,
        required: widget.required,
        hasError: widget.hasError,
      ),
    );
  }
}
