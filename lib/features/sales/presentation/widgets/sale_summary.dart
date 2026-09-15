import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SaleSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double total;
  final int itemsCount;

  const SaleSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.itemsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.white,
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          if (itemsCount > 0)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('عدد الأصناف',
                      style: TextStyle(fontSize: 12.sp, color: theme.hintColor)),
                  Text('$itemsCount',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          _Row(
            title: 'المجموع',
            value: '${subtotal.toStringAsFixed(2)} ج.م',
          ),
          SizedBox(height: 8.h),
          _Row(
            title: 'الخصم',
            value: '- ${discount.toStringAsFixed(2)} ج.م',
            valueColor: discount > 0 ? Colors.red.shade600 : null,
          ),
          Divider(height: 24.h),
          _Row(
            title: 'الإجمالي النهائي',
            value: '${total.toStringAsFixed(2)} ج.م',
            isTotal: true,
          ),
          if (discount > subtotal) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14.sp, color: Colors.orange),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text('الخصم أكبر من المجموع، سيتم اعتباره مساوياً للمجموع',
                      style: TextStyle(fontSize: 11.sp, color: Colors.orange.shade800)),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _Row({
    required this.title,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 14.sp : 13.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 18.sp : 14.sp,
            color: valueColor ?? (isTotal ? Theme.of(context).colorScheme.primary : null),
          ),
        ),
      ],
    );
  }
}
