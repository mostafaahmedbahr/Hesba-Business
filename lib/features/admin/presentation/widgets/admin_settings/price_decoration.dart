import 'package:flutter/material.dart';
import 'package:hesba/features/admin/presentation/views/admin_ds.dart';

/// InputDecoration موحدة لكل حقول الأرقام/المحافظ في إعدادات الأسعار.
InputDecoration priceDecoration(
  BuildContext context,
  Color accent, {
  String? suffixText,
  String? hintText,
}) {
  final radius = BorderRadius.circular(AdminRadius.input);
  final border = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: AdminColors.border(context)),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AdminColors.surfaceAlt(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    hintText: hintText,
    suffixText: suffixText,
    suffixStyle: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AdminColors.textMuted(context),
    ),
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: accent, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AdminColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AdminColors.error, width: 1.6),
    ),
  );
}
