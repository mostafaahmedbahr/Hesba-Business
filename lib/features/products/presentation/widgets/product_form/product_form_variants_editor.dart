import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/number_parser.dart';
import 'product_form_text_field.dart';

/// صف واحد داخل جدول كميات اللون والمقاس.
class ProductVariantRow {
  /// هوية ثابتة لكل صف حتى لا يختلط نص الصفوف عند الحذف/الإضافة.
  static int _seq = 0;
  final int id = _seq++;

  String color;
  String size;
  String qty;

  /// هل اختار المستخدم "أخرى" للمقاس وبيكتب نص يدوي؟
  bool useCustomSize;

  ProductVariantRow({this.color = '', this.size = '', this.qty = '', this.useCustomSize = false});

  Map<String, dynamic> toMap() => {'color': color, 'size': size, 'qty': qty};
}

/// جدول كميات لكل لون ومقاس (ملابس/أحذية).
///
/// الكمية الإجمالية للمنتج تُحسب كمجموع صفوف الجدول في ProductFormCubit.
/// لو الكمية المتاحة معروفة ([availableStock]) يظهر تنبيه لو المجموع عداها.
class ProductFormVariantsEditor extends StatelessWidget {
  final List<ProductVariantRow> rows;

  /// الكمية المتاحة المُدخلة فوق — سقف لمجموع الصفوف.
  final int? availableStock;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, ProductVariantRow row) onChange;
  final String? Function(List<ProductVariantRow>)? validator;

  const ProductFormVariantsEditor({
    super.key,
    required this.rows,
    this.availableStock,
    required this.onAdd,
    required this.onRemove,
    required this.onChange,
    this.validator,
  });

  static int totalQty(List<ProductVariantRow> rows) {
    var total = 0;
    for (final row in rows) {
      total += int.tryParse(NumberParser.toLatin(row.qty)) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final error = validator?.call(rows);
    final total = totalQty(rows);
    final exceeds = availableStock != null && total > availableStock!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rows.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
              ),
            ),
            child: Text(
              'productFormVariantsEmpty'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray),
            ),
          ),
        for (var i = 0; i < rows.length; i++) _row(context, rows[i], i, error),
        if (rows.isNotEmpty) SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          height: 40.h,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            icon: Icon(Icons.add_rounded, size: 17.sp),
            label: Text(
              'productFormVariantsAdd'.tr(),
              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (rows.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.summarize_rounded,
                size: 14.sp,
                color: exceeds ? AppTheme.danger : AppTheme.primaryColor,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  availableStock != null
                      ? '${'productFormVariantsTotal'.tr()}: $total / ${'productFormStock'.tr()}: $availableStock'
                      : '${'productFormVariantsTotal'.tr()}: $total',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: exceeds ? AppTheme.danger : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (availableStock != null) ...[
            SizedBox(height: 4.h),
            Text(
              'productFormVariantsStockAuto'.tr(),
              style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray, height: 1.4),
            ),
          ],
        ],
        if (error != null) ...[
          SizedBox(height: 6.h),
          Text(
            error,
            style: TextStyle(fontSize: 11.5.sp, color: AppTheme.danger, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, ProductVariantRow row, int index, String? error) {
    return Container(
      key: ValueKey(row.id),
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkSurfaceAlt
            : AppTheme.canvasLight,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkBorder
              : AppTheme.borderSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: row.color,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  decoration: productFormDecoration(
                    context,
                    label: 'productFormColor'.tr(),
                    hint: 'productFormColorHint'.tr(),
                  ),
                  onChanged: (v) => onChange(index, row..color = v),
                ),
              ),
              IconButton(
                tooltip: 'productDelete'.tr(),
                onPressed: () => onRemove(index),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19.sp,
                  color: AppTheme.danger,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _sizeDropdown(context, row, index),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: row.qty,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  decoration: productFormDecoration(
                    context,
                    label: 'productFormVariantsStockQty'.tr(),
                  ),
                  onChanged: (v) => onChange(index, row..qty = v),
                ),
              ),
            ],
          ),
          if (row.useCustomSize) ...[
            SizedBox(height: 8.h),
            TextFormField(
              initialValue: row.size,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              decoration: productFormDecoration(
                context,
                label: 'productFormCustomSize'.tr(),
                hint: 'productFormSizeHint'.tr(),
                icon: Icons.edit_rounded,
              ),
              onChanged: (v) => onChange(index, row..size = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sizeDropdown(BuildContext context, ProductVariantRow row, int index) {
    final sizes = AppConstants.productSizes;
    final selected = row.useCustomSize
        ? 'أخرى'
        : (row.size.isEmpty ? null : row.size);
    final items = <DropdownMenuItem<String>>[
      for (final s in sizes)
        DropdownMenuItem(
          value: s,
          child: Text(s, style: TextStyle(fontSize: 13.sp)),
        ),
      if (selected != null && !sizes.contains(selected))
        DropdownMenuItem(
          value: selected,
          child: Text(selected, style: TextStyle(fontSize: 13.sp)),
        ),
    ];

    return DropdownButtonFormField<String>(
      key: ValueKey('variantSize_${row.id}_$selected'),
      initialValue: selected,
      isExpanded: true,
      decoration: productFormDecoration(
        context,
        label: 'productFormSize'.tr(),
        hint: 'productFormSizeHint'.tr(),
        icon: Icons.straighten_rounded,
      ),
      items: items,
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
      onChanged: (v) {
        if (v == 'أخرى') {
          row.useCustomSize = true;
          row.size = '';
        } else {
          row.useCustomSize = false;
          row.size = v ?? '';
        }
        onChange(index, row);
      },
    );
  }
}
