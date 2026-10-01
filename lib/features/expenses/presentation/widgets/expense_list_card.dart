import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../data/models/expense_model.dart';
import 'expense_category_meta.dart';

/// كارت مصروف مختصر — ضغطة تفتح الملاحظة والأزرار.
class ExpenseListCard extends StatefulWidget {
  final ExpenseModel expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseListCard({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ExpenseListCard> createState() => _ExpenseListCardState();
}

/// حالة الفتح/القفل للكارت.
class _ExpenseListCardState extends State<ExpenseListCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expense = widget.expense;
    final color = expenseCatColor(expense.category);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: _expanded
              ? color.withValues(alpha: 0.35)
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3)),
        ),
        boxShadow: _expanded
            ? [BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 22, offset: const Offset(0, 10))]
            : AppTheme.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الملخص الدائم.
                Row(children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.65)]),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(expenseCatIcon(expense.category), size: 21.sp, color: Colors.white),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        SizedBox(height: 3.h),
                        Row(children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8.r)),
                            child: Text(expense.category.isEmpty ? 'عام' : expense.category, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: color)),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            DateFormat('d MMM', 'ar').format(expense.date),
                            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('-${expense.amount.toStringAsFixed(expense.amount % 1 == 0 ? 0 : 2)}', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: const Color(0xFFE11D48), height: 1)),
                      Text('ج.م', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                  SizedBox(width: 4.w),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 22.sp, color: const Color(0xFF94A3B8)),
                  ),
                ]),
                // التفاصيل (تظهر بالضغطة).
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _Details(
                    expense: expense,
                    isDark: isDark,
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                  ),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 260),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// تفاصيل المصروف (ملاحظة + تعديل/حذف).
class _Details extends StatelessWidget {
  final ExpenseModel expense;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _Details({required this.expense, required this.isDark, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expense.note.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(11.w),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(13.r),
                border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE6EAF2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.notes_rounded, size: 14.sp, color: const Color(0xFF94A3B8)),
                SizedBox(width: 6.w),
                Expanded(child: Text(expense.note, style: TextStyle(fontSize: 12.sp, height: 1.5, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)))),
              ]),
            ),
            SizedBox(height: 10.h),
          ],
          Row(children: [
            Expanded(
              child: _RowBtn(
                icon: Icons.edit_outlined,
                label: 'تعديل',
                color: const Color(0xFF1A4FD6),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onEdit();
                },
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _RowBtn(
                icon: Icons.delete_outline_rounded,
                label: 'حذف',
                color: const Color(0xFFE11D48),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDelete();
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// زرار تعديل/حذف عريض.
class _RowBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _RowBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(width: 6.w),
            Text(label, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}
