import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExpenseCard extends StatelessWidget {
  final String title;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseCard({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _categoryColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(_categoryIcon(), size: 18.sp, color: _categoryColor(context)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2.h),
                    Text(category, style: TextStyle(fontSize: 11.sp, color: theme.hintColor)),
                  ],
                ),
              ),
              Text(
                '${amount.toStringAsFixed(2)} ج.م',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _categoryColor(context)),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 20.sp),
                  tooltip: 'تعديل',
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20.sp),
                  tooltip: 'حذف',
                ),
            ],
          ),
          SizedBox(height: 8.h),
          if (note.isNotEmpty)
            Text(note, style: TextStyle(fontSize: 12.sp, color: theme.hintColor)),
          SizedBox(height: 4.h),
          Text(
            _formatDate(date),
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(BuildContext context) {
    switch (category) {
      case 'إيجار': return Colors.blue;
      case 'رواتب': return Colors.purple;
      case 'مرافق': return Colors.orange;
      case 'مستلزمات': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _categoryIcon() {
    switch (category) {
      case 'إيجار': return Icons.home_rounded;
      case 'رواتب': return Icons.payments_rounded;
      case 'مرافق': return Icons.bolt_rounded;
      case 'مستلزمات': return Icons.shopping_bag_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
