import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExpenseSummary extends StatelessWidget {
  final double totalAmount;
  final int itemsCount;

  const ExpenseSummary({
    super.key,
    required this.totalAmount,
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
          ),
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
                  Text('عدد المصروفات', style: TextStyle(fontSize: 12.sp, color: theme.hintColor)),
                  Text('$itemsCount', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          _SummaryRow(title: 'إجمالي المصروفات', value: '${totalAmount.toStringAsFixed(2)} ج.م', isTotal: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isTotal;

  const _SummaryRow({required this.title, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, fontSize: isTotal ? 14.sp : 13.sp)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTotal ? 18.sp : 14.sp, color: isTotal ? Theme.of(context).colorScheme.primary : null)),
      ],
    );
  }
}
