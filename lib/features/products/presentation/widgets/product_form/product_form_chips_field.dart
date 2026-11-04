import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import 'product_form_text_field.dart';

/// حقل قائمة عناصر (الإضافات / المكونات): كتابة + إضافة + chips قابلة للحذف.
class ProductFormChipsField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String? Function(List<String>)? validator;

  const ProductFormChipsField({
    super.key,
    required this.label,
    required this.icon,
    required this.values,
    required this.onChanged,
    this.hint,
    this.validator,
  });

  @override
  State<ProductFormChipsField> createState() => _ProductFormChipsFieldState();
}

class _ProductFormChipsFieldState extends State<ProductFormChipsField> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (widget.values.contains(text)) {
      _input.clear();
      return;
    }
    HapticFeedback.selectionClick();
    widget.onChanged([...widget.values, text]);
    _input.clear();
  }

  void _remove(String item) {
    HapticFeedback.selectionClick();
    widget.onChanged(widget.values.where((v) => v != item).toList());
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.validator?.call(widget.values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductFormTextField(
          controller: _input,
          label: widget.label,
          hint: widget.hint,
          icon: widget.icon,
          suffixIcon: IconButton(
            onPressed: _add,
            icon: Icon(
              Icons.add_circle_rounded,
              size: 20.sp,
              color: AppTheme.primaryColor,
            ),
          ),
          onChanged: (_) => setState(() {}),
          validator: (_) => error,
        ),
        if (widget.values.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final item in widget.values)
                Chip(
                  label: Text(
                    item,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                  ),
                  deleteIcon: Icon(
                    Icons.close_rounded,
                    size: 14.sp,
                    color: AppTheme.primaryColor,
                  ),
                  onDeleted: () => _remove(item),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
