import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  ProductVariantRow({this.color = '', this.size = '', this.qty = ''});

  Map<String, dynamic> toMap() => {'color': color, 'size': size, 'qty': qty};
}

/// جدول كميات لكل لون ومقاس (ملابس/أحذية).
///
/// الكمية الإجمالية للمنتج تُحسب كمجموع صفوف الجدول في ProductFormCubit.
class ProductFormVariantsEditor extends StatelessWidget {
  final List<ProductVariantRow> rows;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, ProductVariantRow row) onChange;
  final String? Function(List<ProductVariantRow>)? validator;

  const ProductFormVariantsEditor({
    super.key,
    required this.rows,
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
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 6.w),
              Text(
                '${'productFormVariantsTotal'.tr()}: ${totalQty(rows)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
        if (error != null) ...[
          SizedBox(height: 6.h),
          Text(
            error,
            style: TextStyle(fontSize: 11.5.sp, color: AppTheme.danger),
          ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, ProductVariantRow row, int index, String? error) {
    return Container(
      key: ValueKey(row.id),
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: row.color,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              decoration: productFormDecoration(
                context,
                label: 'productFormColor',
              ),
              onChanged: (v) => onChange(index, row..color = v),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: row.size,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              decoration: productFormDecoration(
                context,
                label: 'productFormSize',
              ),
              onChanged: (v) => onChange(index, row..size = v),
            ),
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
                label: 'productFormStock',
              ),
              onChanged: (v) => onChange(index, row..qty = v),
            ),
          ),
          IconButton(
            onPressed: () => onRemove(index),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 19.sp,
              color: AppTheme.danger,
            ),
          ),
        ],
      ),
    );
  }
}
