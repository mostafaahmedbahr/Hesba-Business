import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import 'product_form_text_field.dart';

/// قائمة منسدلة عامة بحقل فورم موحّد (category-style) — نفس شكل باقي حقول
/// الفورم مع أيقونة سهم primary.
class ProductFormDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;
  const ProductFormDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: productFormDecoration(context, label: label, icon: icon),
      items: items,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 13.5.sp,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      borderRadius: BorderRadius.circular(16.r),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20.sp,
        color: AppTheme.primaryColor,
      ),
    );
  }
}
