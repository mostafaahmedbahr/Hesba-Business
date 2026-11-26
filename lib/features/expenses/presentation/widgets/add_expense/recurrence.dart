import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/expense_model.dart';
import 'package:easy_localization/easy_localization.dart';

/// خيار تكرار المصروف (مرة واحدة / يومي / أسبوعي / شهري).
class ExpenseRecurrenceOption {
  final String label;
  final IconData icon;
  final String value;
  const ExpenseRecurrenceOption(this.label, this.icon, this.value);
}

/// الخيارات المتاحة للتكرار (مُعرّفة مرة واحدة).
List<ExpenseRecurrenceOption> kExpenseRecurrenceOptions = [
  ExpenseRecurrenceOption('مرة واحدة'.tr(), Icons.looks_one_rounded,
      ExpenseModel.recurrenceNone),
  ExpenseRecurrenceOption(
      'يومي'.tr(), Icons.event_repeat_rounded, ExpenseModel.recurrenceDaily),
  ExpenseRecurrenceOption(
      'أسبوعي'.tr(), Icons.calendar_view_week_rounded, ExpenseModel.recurrenceWeekly),
  ExpenseRecurrenceOption(
      'شهري'.tr(), Icons.calendar_month_rounded, ExpenseModel.recurrenceMonthly),
];

/// شريحة اختيار التكرار.
class ExpenseRecurrenceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const ExpenseRecurrenceChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppTheme.primaryColor;
    return Material(
      color: selected ? selectedColor : (isDark ? AppTheme.darkSurfaceAlt : Colors.white),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: selected ? selectedColor : null,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
              width: selected ? 0 : 1.2,
            ),
            boxShadow: selected
                ? [BoxShadow(color: selectedColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15.sp, color: selected ? Colors.white : AppTheme.mutedGray),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.slateDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
