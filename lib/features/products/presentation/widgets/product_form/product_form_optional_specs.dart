import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/product_field.dart';

/// بطاقة "مواصفات إضافية": تعرض الحقول الاختيارية كأزرار تبديل
/// حتى يظهر/يخفي المستخدم ما يحتاجه فقط (لا حقول إضافية إجبارية للجميع).
class ProductFormOptionalSpecs extends StatelessWidget {
  final List<ProductFieldConfig> fields;
  final Set<String> visible;
  final ValueChanged<String> onToggle;

  const ProductFormOptionalSpecs({
    super.key,
    required this.fields,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.violetDeep, AppTheme.violetSoft],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'productFormOptionalSpecs'.tr(),
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'productFormOptionalSpecsHint'.tr(),
            style: TextStyle(fontSize: 11.5.sp, color: AppTheme.mutedGray),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final field in fields)
                _toggleChip(context, field, visible.contains(field.key)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleChip(BuildContext context, ProductFieldConfig field, bool on) {
    return FilterChip(
      selected: on,
      onSelected: (_) => onToggle(field.key),
      avatar: Icon(
        field.icon,
        size: 15.sp,
        color: on ? Colors.white : AppTheme.primaryColor,
      ),
      label: Text(
        field.labelKey.tr(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: on ? Colors.white : AppTheme.primaryColor,
        ),
      ),
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.07),
      side: BorderSide(
        color: AppTheme.primaryColor.withValues(alpha: on ? 0 : 0.3),
      ),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
    );
  }
}
