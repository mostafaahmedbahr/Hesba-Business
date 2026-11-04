import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import 'product_form_text_field.dart';

/// حقل تاريخ (تاريخ الصلاحية) — يفتح منتقي التاريخ ويحفظ نص YYYY-MM-DD.
class ProductFormDateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final bool required;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const ProductFormDateField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.validator,
  });

  Future<void> _pick(BuildContext context, FormFieldState<String> state) async {
    final now = DateTime.now();
    DateTime initial = now;
    final current = DateTime.tryParse(value ?? '');
    if (current != null) initial = current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 15),
    );
    if (picked == null) return;
    final text =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    // تحديث قيمة الـ FormField نفسها، وإلا بقي داخليها قديماً
    // وظهر خطأ "مطلوب" رغم اختيار التاريخ.
    state.didChange(text);
    onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    // نعرض التاريخ بصيغة عربية مقروءة لكن القيمة المحفوظة تبقى YYYY-MM-DD.
    String display = value ?? '';
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed != null) {
      display = '${parsed.day}/${parsed.month}/${parsed.year}';
    }
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () => _pick(context, state),
              child: InputDecorator(
                decoration: productFormDecoration(
                  context,
                  label: label,
                  icon: icon,
                  required: required,
                  suffixIcon: Icon(
                    Icons.calendar_today_rounded,
                    size: 18.sp,
                    color: AppTheme.primaryColor,
                  ),
                ).copyWith(
                  errorText: state.errorText,
                  errorMaxLines: 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        display.isEmpty ? 'productFormDateHint'.tr() : display,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: display.isEmpty
                              ? AppTheme.mutedGray
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (display.isNotEmpty)
                      InkWell(
                        onTap: () {
                          state.didChange(null);
                          onChanged(null);
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 16.sp,
                          color: AppTheme.mutedGray,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
